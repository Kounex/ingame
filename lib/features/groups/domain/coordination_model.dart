import 'package:freezed_annotation/freezed_annotation.dart';

part 'coordination_model.freezed.dart';
part 'coordination_model.g.dart';

@freezed
abstract class ScheduledReadyWindow with _$ScheduledReadyWindow {
  const factory ScheduledReadyWindow({
    required String id,
    required String groupId,
    required String userId,
    required String displayName,
    required DateTime startsAt,
    required DateTime endsAt,
    required String source,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ScheduledReadyWindow;

  factory ScheduledReadyWindow.fromJson(Map<String, dynamic> json) =>
      _$ScheduledReadyWindowFromJson(json);
}

@freezed
abstract class SessionRsvp with _$SessionRsvp {
  const factory SessionRsvp({
    required String id,
    required String sessionId,
    required String userId,
    required String displayName,
    required String response,
    required DateTime updatedAt,
  }) = _SessionRsvp;

  factory SessionRsvp.fromJson(Map<String, dynamic> json) =>
      _$SessionRsvpFromJson(json);
}

@freezed
abstract class GroupSession with _$GroupSession {
  const factory GroupSession({
    required String id,
    required String groupId,
    required String proposedBy,
    required String proposedByDisplayName,
    String? title,
    String? game,
    required DateTime startsAt,
    String? notes,
    required String status,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<SessionRsvp> rsvps,
  }) = _GroupSession;

  factory GroupSession.fromJson(Map<String, dynamic> json) =>
      _$GroupSessionFromJson(json);
}

@freezed
abstract class GroupActivityEvent with _$GroupActivityEvent {
  const factory GroupActivityEvent({
    required String id,
    required String groupId,
    required String actorUserId,
    required String actorDisplayName,
    required String type,
    required String message,
    String? sessionId,
    String? scheduledReadyWindowId,
    required DateTime createdAt,
  }) = _GroupActivityEvent;

  factory GroupActivityEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupActivityEventFromJson(json);
}
