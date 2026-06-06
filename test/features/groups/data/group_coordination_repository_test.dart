import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/api_endpoints.dart';
import 'package:ingame/features/groups/data/group_coordination_repository.dart';

void main() {
  test('listScheduledReady uses the scheduled-ready endpoint', () async {
    final dio = Dio();
    final repository = GroupCoordinationRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.groupScheduledReady('group-1'));
          handler.resolve(Response(requestOptions: options, data: const []));
        },
      ),
    );

    await repository.listScheduledReady('group-1');
  });

  test('createSession posts to the group session endpoint', () async {
    final dio = Dio();
    final repository = GroupCoordinationRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.groupSessions('group-1'));
          expect(options.data['title'], 'Valheim Night');
          expect(options.data['game'], 'Valheim');
          expect(options.data['notes'], 'Bring potions');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'id': 'session-1',
                'group_id': 'group-1',
                'proposed_by': 'owner-1',
                'proposed_by_display_name': 'Owner',
                'title': 'Valheim Night',
                'game': 'Valheim',
                'starts_at': '2026-06-06T20:00:00Z',
                'notes': null,
                'status': 'proposed',
                'created_at': '2026-06-05T10:00:00Z',
                'updated_at': null,
                'rsvps': const [],
              },
            ),
          );
        },
      ),
    );

    await repository.createSession(
      'group-1',
      title: 'Valheim Night',
      game: 'Valheim',
      notes: 'Bring potions',
      startsAt: DateTime.utc(2026, 6, 6, 20),
    );
  });

  test('updateSession sends notes and status fields', () async {
    final dio = Dio();
    final repository = GroupCoordinationRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(
            options.path,
            ApiEndpoints.groupSession('group-1', 'session-1'),
          );
          expect(options.data['notes'], 'Voice chat in Discord');
          expect(options.data['status'], 'confirmed');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'id': 'session-1',
                'group_id': 'group-1',
                'proposed_by': 'owner-1',
                'proposed_by_display_name': 'Owner',
                'title': 'Valheim Night',
                'game': 'Valheim',
                'starts_at': '2026-06-06T20:00:00Z',
                'notes': 'Voice chat in Discord',
                'status': 'confirmed',
                'created_at': '2026-06-05T10:00:00Z',
                'updated_at': '2026-06-05T10:05:00Z',
                'rsvps': const [],
              },
            ),
          );
        },
      ),
    );

    await repository.updateSession(
      'group-1',
      'session-1',
      notes: 'Voice chat in Discord',
      status: 'confirmed',
    );
  });

  test('rsvpToSession posts the selected response', () async {
    final dio = Dio();
    final repository = GroupCoordinationRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(
            options.path,
            ApiEndpoints.groupSessionRsvp('group-1', 'session-1'),
          );
          expect(options.data, {'response': 'maybe'});
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'id': 'rsvp-1',
                'session_id': 'session-1',
                'user_id': 'member-1',
                'display_name': 'Member',
                'response': 'maybe',
                'updated_at': '2026-06-05T10:05:00Z',
              },
            ),
          );
        },
      ),
    );

    await repository.rsvpToSession('group-1', 'session-1', 'maybe');
  });

  test('deleteSession uses the group session endpoint', () async {
    final dio = Dio();
    final repository = GroupCoordinationRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(
            options.path,
            ApiEndpoints.groupSession('group-1', 'session-1'),
          );
          expect(options.method, 'DELETE');
          handler.resolve(Response(requestOptions: options, statusCode: 204));
        },
      ),
    );

    await repository.deleteSession('group-1', 'session-1');
  });

  test('listActivity uses the activity endpoint', () async {
    final dio = Dio();
    final repository = GroupCoordinationRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.groupActivity('group-1'));
          handler.resolve(
            Response(
              requestOptions: options,
              data: [
                {
                  'id': 'activity-1',
                  'group_id': 'group-1',
                  'actor_user_id': 'owner-1',
                  'actor_display_name': 'Owner',
                  'type': 'session_proposed',
                  'message': 'Owner proposed a session',
                  'session_id': 'session-1',
                  'scheduled_ready_window_id': null,
                  'created_at': '2026-06-05T10:00:00Z',
                },
              ],
            ),
          );
        },
      ),
    );

    final activity = await repository.listActivity('group-1');
    expect(activity.single.id, 'activity-1');
  });
}
