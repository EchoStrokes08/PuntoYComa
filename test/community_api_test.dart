import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:punto_y_coma/data/community/community_api.dart';

void main() {
  late CommunityApiClient api;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient((request) async {
      return http.Response('{}', 200);
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );
  });

  tearDown(() {
    api.dispose();
  });

  test('postReport sends correct payload and accepts 202', () async {
    mockClient = MockClient((request) async {
      expect(request.headers['content-type'], 'application/json');
      final body = request.body;
      final json = Uri.decodeFull(body);
      expect(json, contains('ruta-A'));
      expect(json, contains('crowded'));
      expect(json, contains('4.668'));
      expect(json, contains('-74.0519'));
      return http.Response('{"accepted": true}', 202);
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );

    await api.postReport(
      routeId: 'ruta-A',
      latitude: 4.6680,
      longitude: -74.0519,
      category: 'crowded',
      installationId: 'installer-1',
    );
  });

  test('postReport throws on 429 rate limit', () async {
    mockClient = MockClient((request) async {
      return http.Response('{"error": "reporter_rate_limited"}', 429);
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );

    expect(
      () => api.postReport(
        routeId: 'ruta-A',
        latitude: 4.6680,
        longitude: -74.0519,
        category: 'crowded',
        installationId: 'installer-1',
      ),
      throwsA(isA<RateLimitedException>()),
    );
  });

  test('postReport throws on 500 server error', () async {
    mockClient = MockClient((request) async {
      return http.Response('Internal error', 500);
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );

    expect(
      () => api.postReport(
        routeId: 'ruta-A',
        latitude: 4.6680,
        longitude: -74.0519,
        category: 'crowded',
        installationId: 'installer-1',
      ),
      throwsA(isA<HttpException>()),
    );
  });

  test('getFeed returns counts map', () async {
    mockClient = MockClient((request) async {
      expect(request.url.queryParameters['routeId'], 'ruta-A');
      expect(request.url.queryParameters['latitude'], '4.668');
      expect(request.url.queryParameters['longitude'], '-74.0519');
      return http.Response(
        '{"reports": [{"category": "crowded", "count": 3}, {"category": "delay", "count": 1}]}',
        200,
      );
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );

    final counts = await api.getFeed(
      routeId: 'ruta-A',
      latitude: 4.6680,
      longitude: -74.0519,
    );

    expect(counts['crowded'], 3);
    expect(counts['delay'], 1);
    expect(counts.length, 2);
  });

  test('healthCheck returns true on 200', () async {
    mockClient = MockClient((request) async {
      return http.Response('{"status": "ok"}', 200);
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );

    expect(await api.healthCheck(), isTrue);
  });

  test('healthCheck returns false on error', () async {
    mockClient = MockClient((request) async {
      throw Exception('connection refused');
    });
    api = CommunityApiClient(
      baseUrl: 'https://api.puntoycoma.example',
      client: mockClient,
      timeoutSeconds: 10,
    );

    expect(await api.healthCheck(), isFalse);
  });
}
