import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:punto_y_coma/data/community/community_api.dart';
import 'package:punto_y_coma/data/community/community_radar_repository.dart';

void main() {
  late CommunityRadarRepository repository;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient((request) async {
      return http.Response('{}', 200);
    });
    repository = CommunityRadarRepository(
      api: CommunityApiClient(
        baseUrl: 'https://api.puntoycoma.example',
        client: mockClient,
        timeoutSeconds: 10,
      ),
    );
  });

  tearDown(() {
    // CommunityApiClient.dispose() cierra el MockClient; no es necesario aquí
    // porque MockClient no tiene recursos que liberar.
  });

  test('report stores the report via API client', () async {
    mockClient = MockClient((request) async {
      expect(request.body, contains('ruta-A'));
      expect(request.body, contains('crowded'));
      return http.Response('{"accepted": true}', 202);
    });
    repository = CommunityRadarRepository(
      api: CommunityApiClient(
        baseUrl: 'https://api.puntoycoma.example',
        client: mockClient,
        timeoutSeconds: 10,
      ),
    );

    await repository.report(
      routeId: 'ruta-A',
      latitude: 4.6680,
      longitude: -74.0519,
      category: 'crowded',
      installationId: 'installer-1',
    );
  });

  test('feed returns counts from API client', () async {
    mockClient = MockClient((request) async {
      return http.Response(
        '{"reports": [{"category": "crowded", "count": 3}, {"category": "delay", "count": 1}]}',
        200,
      );
    });
    repository = CommunityRadarRepository(
      api: CommunityApiClient(
        baseUrl: 'https://api.puntoycoma.example',
        client: mockClient,
        timeoutSeconds: 10,
      ),
    );

    final counts = await repository.feed(
      routeId: 'ruta-A',
      latitude: 4.6680,
      longitude: -74.0519,
    );

    expect(counts['crowded'], 3);
    expect(counts['delay'], 1);
    expect(counts.length, 2);
  });

  test('feed returns empty map when server returns no reports', () async {
    mockClient = MockClient((request) async {
      return http.Response('{"reports": []}', 200);
    });
    repository = CommunityRadarRepository(
      api: CommunityApiClient(
        baseUrl: 'https://api.puntoycoma.example',
        client: mockClient,
        timeoutSeconds: 10,
      ),
    );

    final counts = await repository.feed(
      routeId: 'ruta-A',
      latitude: 4.6680,
      longitude: -74.0519,
    );

    expect(counts, isEmpty);
  });

  test('healthCheck returns true on 200', () async {
    mockClient = MockClient((request) async {
      return http.Response('{"status": "ok"}', 200);
    });
    repository = CommunityRadarRepository(
      api: CommunityApiClient(
        baseUrl: 'https://api.puntoycoma.example',
        client: mockClient,
        timeoutSeconds: 10,
      ),
    );

    expect(await repository.healthCheck(), isTrue);
  });

  test('healthCheck returns false on error', () async {
    mockClient = MockClient((request) async {
      return http.Response('error', 500);
    });
    repository = CommunityRadarRepository(
      api: CommunityApiClient(
        baseUrl: 'https://api.puntoycoma.example',
        client: mockClient,
        timeoutSeconds: 10,
      ),
    );

    expect(await repository.healthCheck(), isFalse);
  });
}
