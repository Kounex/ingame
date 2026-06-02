import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/api_endpoints.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';

void main() {
  test('leaveGroup uses the dedicated leave endpoint', () async {
    final dio = Dio();
    final repository = GroupsRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.leaveGroup('group-1'));
          handler.resolve(Response(requestOptions: options, data: null));
        },
      ),
    );

    await repository.leaveGroup('group-1');
  });

  test('updateMemberRole sends role patch to member role endpoint', () async {
    final dio = Dio();
    final repository = GroupsRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(
            options.path,
            ApiEndpoints.groupMemberRole('group-1', 'user-2'),
          );
          expect(options.data, {'role': 'admin'});
          handler.resolve(Response(requestOptions: options, data: null));
        },
      ),
    );

    await repository.updateMemberRole('group-1', 'user-2', 'admin');
  });

  test('transferOwnership posts target user to transfer endpoint', () async {
    final dio = Dio();
    final repository = GroupsRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.transferGroupOwnership('group-1'));
          expect(options.data, {'user_id': 'user-2'});
          handler.resolve(Response(requestOptions: options, data: null));
        },
      ),
    );

    await repository.transferOwnership('group-1', 'user-2');
  });
}
