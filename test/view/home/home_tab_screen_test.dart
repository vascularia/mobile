import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lichess_mobile/src/app.dart';
import 'package:lichess_mobile/src/model/account/home_preferences.dart';
import 'package:lichess_mobile/src/model/game/game_storage.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:lichess_mobile/src/view/account/profile_screen.dart';
import 'package:lichess_mobile/src/view/game/game_list_tile.dart';
import 'package:lichess_mobile/src/view/home/games_carousel.dart';
import 'package:lichess_mobile/src/view/home/play_section.dart';
import 'package:lichess_mobile/src/view/play/quick_game_matrix.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/widgets/server_outage_display.dart';
import 'package:material_ui/material_ui.dart';

import '../../example_data.dart';
import '../../mock_server_responses.dart';
import '../../model/auth/fake_auth_storage.dart';
import '../../network/fake_http_client_factory.dart';
import '../../network/server_down_client.dart';
import '../../test_helpers.dart';
import '../../test_provider_scope.dart';

void main() {
  group('Home online', () {
    testWidgets('authUser, no played game: do not show welcome screen', (tester) async {
      int nbUserGamesRequests = 0;
      final mockClient = MockClient((request) {
        if (request.url.path == '/api/games/user/testuser') {
          nbUserGamesRequests++;
          return mockResponse('', 200);
        }
        if (request.url.path == '/tournament/featured') {
          return mockResponse('{"featured":[]}', 200);
        }
        return mockResponse('', 200);
      });
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        authUser: fakeAuthUser,
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith(
            (ref) => FakeHttpClientFactory(() => mockClient),
          ),
        },
      );
      await tester.pumpWidget(app);
      // wait for connectivity
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(nbUserGamesRequests, 1);
      expect(find.text('Sign in'), findsNothing);
      expect(find.text('About Lichess...'), findsNothing);
    });

    testWidgets('no authUser, with stored games: shows list of recent games', (tester) async {
      final mockClient = MockClient((request) {
        if (request.url.path == '/tournament/featured') {
          return mockResponse('{"featured":[]}', 200);
        }
        return mockResponse('', 200);
      });
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith(
            (ref) => FakeHttpClientFactory(() => mockClient),
          ),
        },
      );
      await tester.pumpWidget(app);

      final container = ProviderScope.containerOf(tester.element(find.byType(Application)));
      final storage = await container.read(gameStorageProvider.future);
      final games = generateExportedGames(count: 3);
      for (final game in games) {
        await storage.save(game);
      }

      // wait for connectivity
      await tester.pumpAndSettle();

      expect(find.text('About Lichess...'), findsNothing);
      expect(find.text('Recent games'), findsOneWidget);
      expect(find.byType(GameListTile), findsNWidgets(3));
      expect(find.text('Anonymous'), findsNWidgets(3));
    });

    testWidgets('authUser, with played games: shows recent games', (tester) async {
      int nbUserGamesRequests = 0;
      final mockClient = MockClient((request) {
        if (request.url.path == '/api/games/user/testuser') {
          nbUserGamesRequests++;
          return mockResponse(mockUserRecentGameResponse('testUser'), 200);
        }
        if (request.url.path == '/tournament/featured') {
          return mockResponse('{"featured":[]}', 200);
        }
        return mockResponse('', 200);
      });
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        authUser: fakeAuthUser,
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith(
            (ref) => FakeHttpClientFactory(() => mockClient),
          ),
        },
      );
      await tester.pumpWidget(app);
      // wait for connectivity
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(nbUserGamesRequests, 1);
      expect(find.text('About Lichess...'), findsNothing);
      expect(find.text('Recent games'), findsOneWidget);
      expect(find.byType(GameListTile), findsNWidgets(3));
      expect(find.text('MightyNanook'), findsOneWidget);
    });

    testWidgets('shows ongoing games if any', (tester) async {
      int nbOngoingGamesRequests = 0;
      final mockClient = MockClient((request) {
        if (request.url.path == '/api/account/playing') {
          nbOngoingGamesRequests++;
          return mockResponse(mockAccountOngoingGamesResponse(), 200);
        }
        if (request.url.path == '/tournament/featured') {
          return mockResponse('{"featured":[]}', 200);
        }
        return mockResponse('', 200);
      });
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        authUser: fakeAuthUser,
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith(
            (ref) => FakeHttpClientFactory(() => mockClient),
          ),
        },
      );
      await tester.pumpWidget(app);
      // wait for connectivity
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(nbOngoingGamesRequests, 1);
      expect(find.text('About Lichess...'), findsNothing);
      expect(find.text('Recent games'), findsNothing);
      expect(find.text('1 game in play'), findsOneWidget);
      expect(find.byType(OngoingGameCarouselItem), findsOneWidget);
    });
  });

  group('Home offline', () {
    testWidgets('shows offline subtitle', (tester) async {
      final app = await makeOfflineTestProviderScope(tester, child: const Application());

      await tester.pumpWidget(app);
      // wait for connectivity
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump();

      expect(find.widgetWithText(PlatformAppBar, 'Offline'), findsOneWidget);
    });

    testWidgets('no authUser, with stored games: shows list of recent games', (tester) async {
      final app = await makeOfflineTestProviderScope(tester, child: const Application());
      await tester.pumpWidget(app);

      final container = ProviderScope.containerOf(tester.element(find.byType(Application)));
      final storage = await container.read(gameStorageProvider.future);
      final games = generateExportedGames(count: 3);
      for (final game in games) {
        await storage.save(game);
      }

      // wait for connectivity
      await tester.pumpAndSettle();

      expect(find.text('About Lichess...'), findsNothing);
      expect(find.text('Recent games'), findsOneWidget);
      expect(find.byType(GameListTile), findsNWidgets(3));
      expect(find.text('Anonymous'), findsNWidgets(3));
    });

    testWidgets('authUser, with stored games: shows list of recent games', (tester) async {
      final app = await makeOfflineTestProviderScope(
        tester,
        child: const Application(),
        authUser: fakeAuthUser,
      );
      await tester.pumpWidget(app);

      final container = ProviderScope.containerOf(tester.element(find.byType(Application)));
      final storage = await container.read(gameStorageProvider.future);
      final games = generateExportedGames(count: 3, username: 'testUser');
      for (final game in games) {
        await storage.save(game);
      }

      // wait for connectivity
      await tester.pumpAndSettle();

      expect(find.text('About Lichess...'), findsNothing);
      expect(find.text('Recent games'), findsOneWidget);
      expect(find.byType(GameListTile), findsNWidgets(3));
    });
  });

  group('Server offline', () {
    testWidgets('offline-capable widgets are kept, server-backed ones are replaced', (
      tester,
    ) async {
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        authUser: fakeAuthUser,
        // Tall surface so the whole list is laid out and nothing is missed
        // simply for being below the fold.
        surfaceSize: const Size(390, 1600),
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith((ref) {
            return FakeHttpClientFactory(() => serverDownClient());
          }),
        },
      );
      await tester.pumpWidget(app);

      final container = ProviderScope.containerOf(tester.element(find.byType(Application)));
      final storage = await container.read(gameStorageProvider.future);
      for (final game in generateExportedGames(count: 3, username: 'testUser')) {
        await storage.save(game);
      }

      await tester.pumpAndSettle();

      // The outage message replaces the widgets that need the server...
      expect(find.byType(ServerOutageDisplay), findsOneWidget);
      expect(find.byType(QuickGameMatrix), findsNothing);
      expect(find.byType(AccountPerfCards), findsNothing);

      // ...but the locally stored games are still listed below it.
      expect(find.text('Recent games'), findsOneWidget);
      expect(find.byType(GameListTile), findsNWidgets(3));
    });

    testWidgets('a 502 shows the outage message', (tester) async {
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith((ref) {
            return FakeHttpClientFactory(() => serverDownClient(statusCode: 502));
          }),
        },
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.textContaining('Lichess is down'), findsOneWidget);
      expect(find.textContaining('scheduled maintenance'), findsNothing);
      // The website shows this drawing on its outage page; mirror that.
      expect(imageAssetNames(tester), contains('assets/images/maintenance.webp'));
    });

    testWidgets('a 503 shows the maintenance message', (tester) async {
      final app = await makeTestProviderScope(
        tester,
        child: const Application(),
        overrides: {
          httpClientFactoryProvider: httpClientFactoryProvider.overrideWith((ref) {
            return FakeHttpClientFactory(() => serverDownClient(statusCode: 503));
          }),
        },
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.textContaining('scheduled maintenance'), findsOneWidget);
      expect(find.textContaining('Lichess is down'), findsNothing);
      // The website's maintenance page has no drawing, only the logo.
      expect(imageAssetNames(tester), isNot(contains('assets/images/maintenance.webp')));
    });
  });

  group('Échecs 3D home', () {
    testWidgets('shows the two big buttons of the beginner mode by default', (tester) async {
      final app = await makeTestProviderScope(tester, child: const Application());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Échecs 3D'), findsOneWidget);
      expect(find.text('Play against computer'), findsOneWidget);
      expect(find.text('Play against someone'), findsOneWidget);
      expect(find.text('10 minutes each'), findsOneWidget);
      expect(find.byType(QuickGameMatrix), findsNothing);
    });

    testWidgets('has no sign in, blog or tournaments', (tester) async {
      final app = await makeTestProviderScope(tester, child: const Application());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Blog'), findsNothing);
      expect(find.text('Open tournaments'), findsNothing);
    });

    testWidgets('switches to the pro mode, which shows all the time controls', (tester) async {
      final app = await makeTestProviderScope(tester, child: const Application());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pro'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickGameMatrix), findsOneWidget);
      expect(find.text('Play against someone'), findsNothing);
      final container = ProviderScope.containerOf(tester.element(find.byType(PlaySection)));
      expect(container.read(homePreferencesProvider).proMode, isTrue);
    });
  });
}
