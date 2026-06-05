import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../domain/coordination_model.dart';


class GroupCoordinationRepository {
  GroupCoordinationRepository({required this.dio});

  final Dio dio;

  Future<List<ScheduledReadyWindow>> listScheduledReady(String groupId) async {
    final response = await dio.get(ApiEndpoints.groupScheduledReady(groupId));
    final list = response.data as List<dynamic>;
    return list
        .map(
          (item) =>
              ScheduledReadyWindow.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ScheduledReadyWindow> createScheduledReady(
    String groupId, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final response = await dio.post(
      ApiEndpoints.groupScheduledReady(groupId),
      data: {
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
      },
    );
    return ScheduledReadyWindow.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ScheduledReadyWindow> updateScheduledReady(
    String groupId,
    String windowId, {
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final response = await dio.patch(
      ApiEndpoints.groupScheduledReadyWindow(groupId, windowId),
      data: {
        if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
      },
    );
    return ScheduledReadyWindow.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteScheduledReady(String groupId, String windowId) async {
    await dio.delete(ApiEndpoints.groupScheduledReadyWindow(groupId, windowId));
  }

  Future<List<GroupSession>> listSessions(String groupId) async {
    final response = await dio.get(ApiEndpoints.groupSessions(groupId));
    final list = response.data as List<dynamic>;
    return list
        .map((item) => GroupSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GroupSession> createSession(
    String groupId, {
    String? title,
    String? game,
    String? notes,
    required DateTime startsAt,
  }) async {
    final response = await dio.post(
      ApiEndpoints.groupSessions(groupId),
      data: {
        'title': title,
        'game': game,
        'notes': notes,
        'starts_at': startsAt.toUtc().toIso8601String(),
      },
    );
    return GroupSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupSession> updateSession(
    String groupId,
    String sessionId, {
    String? title,
    String? game,
    DateTime? startsAt,
    String? notes,
    String? status,
  }) async {
    final response = await dio.patch(
      ApiEndpoints.groupSession(groupId, sessionId),
      data: {
        'title': title,
        'game': game,
        'starts_at': startsAt?.toUtc().toIso8601String(),
        'notes': notes,
        'status': status,
      },
    );
    return GroupSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionRsvp> rsvpToSession(
    String groupId,
    String sessionId,
    String responseValue,
  ) async {
    final response = await dio.post(
      ApiEndpoints.groupSessionRsvp(groupId, sessionId),
      data: {'response': responseValue},
    );
    return SessionRsvp.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GroupActivityEvent>> listActivity(String groupId) async {
    final response = await dio.get(ApiEndpoints.groupActivity(groupId));
    final list = response.data as List<dynamic>;
    return list
        .map(
          (item) => GroupActivityEvent.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}


final groupCoordinationRepositoryProvider =
    Provider<GroupCoordinationRepository>((ref) {
      return GroupCoordinationRepository(dio: ref.read(dioProvider));
    });
