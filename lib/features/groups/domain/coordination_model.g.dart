// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coordination_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduledReadyWindow _$ScheduledReadyWindowFromJson(
  Map<String, dynamic> json,
) => _ScheduledReadyWindow(
  id: json['id'] as String,
  groupId: json['group_id'] as String,
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  startsAt: DateTime.parse(json['starts_at'] as String),
  endsAt: DateTime.parse(json['ends_at'] as String),
  source: json['source'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ScheduledReadyWindowToJson(
  _ScheduledReadyWindow instance,
) => <String, dynamic>{
  'id': instance.id,
  'group_id': instance.groupId,
  'user_id': instance.userId,
  'display_name': instance.displayName,
  'starts_at': instance.startsAt.toIso8601String(),
  'ends_at': instance.endsAt.toIso8601String(),
  'source': instance.source,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

_SessionRsvp _$SessionRsvpFromJson(Map<String, dynamic> json) => _SessionRsvp(
  id: json['id'] as String,
  sessionId: json['session_id'] as String,
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  response: json['response'] as String,
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SessionRsvpToJson(_SessionRsvp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'response': instance.response,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_GroupSession _$GroupSessionFromJson(Map<String, dynamic> json) =>
    _GroupSession(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      proposedBy: json['proposed_by'] as String,
      proposedByDisplayName: json['proposed_by_display_name'] as String,
      title: json['title'] as String?,
      game: json['game'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      rsvps:
          (json['rsvps'] as List<dynamic>?)
              ?.map((e) => SessionRsvp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$GroupSessionToJson(_GroupSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'proposed_by': instance.proposedBy,
      'proposed_by_display_name': instance.proposedByDisplayName,
      'title': instance.title,
      'game': instance.game,
      'starts_at': instance.startsAt.toIso8601String(),
      'notes': instance.notes,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'rsvps': instance.rsvps,
    };

_GroupActivityEvent _$GroupActivityEventFromJson(Map<String, dynamic> json) =>
    _GroupActivityEvent(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      actorUserId: json['actor_user_id'] as String,
      actorDisplayName: json['actor_display_name'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      sessionId: json['session_id'] as String?,
      scheduledReadyWindowId: json['scheduled_ready_window_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GroupActivityEventToJson(_GroupActivityEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'actor_user_id': instance.actorUserId,
      'actor_display_name': instance.actorDisplayName,
      'type': instance.type,
      'message': instance.message,
      'session_id': instance.sessionId,
      'scheduled_ready_window_id': instance.scheduledReadyWindowId,
      'created_at': instance.createdAt.toIso8601String(),
    };
