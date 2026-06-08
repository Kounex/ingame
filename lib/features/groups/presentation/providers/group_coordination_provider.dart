import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../data/group_coordination_repository.dart';
import '../../domain/coordination_model.dart';

final groupCoordinationLoadTimeoutProvider = Provider<Duration>(
  (_) => const Duration(seconds: 15),
);

class GroupCoordinationState {
  const GroupCoordinationState({
    this.windows = const [],
    this.sessions = const [],
    this.activity = const [],
    this.pendingRsvpSessionIds = const {},
  });

  final List<ScheduledReadyWindow> windows;
  final List<GroupSession> sessions;
  final List<GroupActivityEvent> activity;
  final Set<String> pendingRsvpSessionIds;

  GroupCoordinationState copyWith({
    List<ScheduledReadyWindow>? windows,
    List<GroupSession>? sessions,
    List<GroupActivityEvent>? activity,
    Set<String>? pendingRsvpSessionIds,
  }) {
    return GroupCoordinationState(
      windows: windows ?? this.windows,
      sessions: sessions ?? this.sessions,
      activity: activity ?? this.activity,
      pendingRsvpSessionIds:
          pendingRsvpSessionIds ?? this.pendingRsvpSessionIds,
    );
  }
}

class GroupCoordinationNotifier extends AsyncNotifier<GroupCoordinationState> {
  GroupCoordinationNotifier(this._groupId);

  StreamSubscription<dynamic>? _subscription;
  final String _groupId;

  @override
  Future<GroupCoordinationState> build() async {
    ref.watch(sessionResetSignalProvider);
    _subscription?.cancel();
    ref.onDispose(() => _subscription?.cancel());
    _subscription = ref
        .read(websocketClientProvider)
        .events
        .listen(_handleEvent);
    return _loadState();
  }

  Future<void> refresh() async {
    if (state.value == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(_loadState);
  }

  Future<void> createScheduledReady({
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    final window = await ref
        .read(groupCoordinationRepositoryProvider)
        .createScheduledReady(_groupId, startsAt: startsAt, endsAt: endsAt);
    final latest = state.value ?? current;
    _setState(latest.copyWith(windows: _upsertWindow(latest.windows, window)));
  }

  Future<void> updateScheduledReady(
    String windowId, {
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    final window = await ref
        .read(groupCoordinationRepositoryProvider)
        .updateScheduledReady(
          _groupId,
          windowId,
          startsAt: startsAt,
          endsAt: endsAt,
        );
    final latest = state.value ?? current;
    _setState(latest.copyWith(windows: _upsertWindow(latest.windows, window)));
  }

  Future<void> deleteScheduledReady(String windowId) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    await ref
        .read(groupCoordinationRepositoryProvider)
        .deleteScheduledReady(_groupId, windowId);
    final latest = state.value ?? current;
    _setState(
      latest.copyWith(
        windows: latest.windows
            .where((window) => window.id != windowId)
            .toList(),
      ),
    );
  }

  Future<void> createSession({
    String? title,
    String? game,
    String? notes,
    required DateTime startsAt,
  }) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    final session = await ref
        .read(groupCoordinationRepositoryProvider)
        .createSession(
          _groupId,
          title: title,
          game: game,
          notes: notes,
          startsAt: startsAt,
        );
    final latest = state.value ?? current;
    _setState(
      latest.copyWith(sessions: _upsertSession(latest.sessions, session)),
    );
  }

  Future<void> updateSession(
    String sessionId, {
    String? title,
    String? game,
    DateTime? startsAt,
    String? notes,
    String? status,
  }) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    final session = await ref
        .read(groupCoordinationRepositoryProvider)
        .updateSession(
          _groupId,
          sessionId,
          title: title,
          game: game,
          startsAt: startsAt,
          notes: notes,
          status: status,
        );
    final latest = state.value ?? current;
    _setState(
      latest.copyWith(sessions: _upsertSession(latest.sessions, session)),
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    await ref
        .read(groupCoordinationRepositoryProvider)
        .deleteSession(_groupId, sessionId);
    final latest = state.value ?? current;
    _setState(
      latest.copyWith(
        sessions: latest.sessions
            .where((session) => session.id != sessionId)
            .toList(),
        pendingRsvpSessionIds: {...latest.pendingRsvpSessionIds}
          ..remove(sessionId),
      ),
    );
  }

  Future<void> rsvpToSession(String sessionId, String response) async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return;
    }
    _setState(
      current.copyWith(
        pendingRsvpSessionIds: {...current.pendingRsvpSessionIds, sessionId},
      ),
    );
    try {
      final rsvp = await ref
          .read(groupCoordinationRepositoryProvider)
          .rsvpToSession(_groupId, sessionId, response);
      final latest = state.value ?? current;
      _setState(
        latest.copyWith(
          sessions: _mergeRsvp(latest.sessions, rsvp),
          pendingRsvpSessionIds: {...latest.pendingRsvpSessionIds}
            ..remove(sessionId),
        ),
      );
    } catch (_) {
      final latest = state.value ?? current;
      _setState(
        latest.copyWith(
          pendingRsvpSessionIds: {...latest.pendingRsvpSessionIds}
            ..remove(sessionId),
        ),
      );
      rethrow;
    }
  }

  Future<GroupCoordinationState> _loadState() async {
    final repo = ref.read(groupCoordinationRepositoryProvider);
    final timeout = ref.read(groupCoordinationLoadTimeoutProvider);
    final results = await Future.wait<Object>([
      repo.listScheduledReady(_groupId),
      repo.listSessions(_groupId),
      repo.listActivity(_groupId),
    ]).timeout(timeout);

    final windows = results[0] as List<ScheduledReadyWindow>;
    final sessions = results[1] as List<GroupSession>;
    final activity = results[2] as List<GroupActivityEvent>;
    return GroupCoordinationState(
      windows: windows,
      sessions: sessions,
      activity: activity,
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final groupId = event['group_id'] as String?;
    if (groupId != _groupId) return;
    final current = state.value;
    if (current == null) return;

    switch (event['type']) {
      case 'scheduled_ready_updated':
        final rawWindow = event['window'];
        if (rawWindow is! Map<String, dynamic>) return;
        _setState(
          current.copyWith(
            windows: _upsertWindow(
              current.windows,
              ScheduledReadyWindow.fromJson(rawWindow),
            ),
          ),
        );
        break;
      case 'scheduled_ready_deleted':
        final windowId = event['window_id'] as String?;
        if (windowId == null) return;
        _setState(
          current.copyWith(
            windows: current.windows
                .where((window) => window.id != windowId)
                .toList(),
          ),
        );
        break;
      case 'session_proposed':
      case 'session_updated':
        final rawSession = event['session'];
        if (rawSession is! Map<String, dynamic>) return;
        _setState(
          current.copyWith(
            sessions: _upsertSession(
              current.sessions,
              GroupSession.fromJson(rawSession),
            ),
          ),
        );
        break;
      case 'session_deleted':
        final sessionId = event['session_id'] as String?;
        if (sessionId == null) return;
        _setState(
          current.copyWith(
            sessions: current.sessions
                .where((session) => session.id != sessionId)
                .toList(),
            pendingRsvpSessionIds: {...current.pendingRsvpSessionIds}
              ..remove(sessionId),
          ),
        );
        break;
      case 'session_rsvp_updated':
        final rawRsvp = event['rsvp'];
        if (rawRsvp is! Map<String, dynamic>) return;
        _setState(
          current.copyWith(
            sessions: _mergeRsvp(
              current.sessions,
              SessionRsvp.fromJson(rawRsvp),
            ),
            pendingRsvpSessionIds: {...current.pendingRsvpSessionIds}
              ..remove(rawRsvp['session_id'] as String? ?? ''),
          ),
        );
        break;
      case 'activity_recorded':
        final rawActivity = event['activity'];
        if (rawActivity is! Map<String, dynamic>) return;
        final activity = GroupActivityEvent.fromJson(rawActivity);
        _setState(
          current.copyWith(
            activity: [
              activity,
              ...current.activity.where((item) => item.id != activity.id),
            ],
          ),
        );
        break;
      default:
        break;
    }
  }

  List<ScheduledReadyWindow> _upsertWindow(
    List<ScheduledReadyWindow> current,
    ScheduledReadyWindow window,
  ) {
    final next = [...current.where((item) => item.id != window.id), window];
    next.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return next;
  }

  List<GroupSession> _upsertSession(
    List<GroupSession> current,
    GroupSession session,
  ) {
    final next = [...current.where((item) => item.id != session.id), session];
    next.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return next;
  }

  List<GroupSession> _mergeRsvp(List<GroupSession> current, SessionRsvp rsvp) {
    return current.map((session) {
      if (session.id != rsvp.sessionId) return session;
      final nextRsvps = [
        ...session.rsvps.where((item) => item.userId != rsvp.userId),
        rsvp,
      ];
      return session.copyWith(rsvps: nextRsvps);
    }).toList();
  }

  void _setState(GroupCoordinationState next) {
    state = AsyncValue.data(next);
  }
}

final groupCoordinationNotifierProvider =
    AsyncNotifierProvider.family<
      GroupCoordinationNotifier,
      GroupCoordinationState,
      String
    >(GroupCoordinationNotifier.new);
