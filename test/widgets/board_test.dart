import 'dart:convert';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/game/game_board_params.dart';
import 'package:lichess_mobile/src/model/settings/board_preferences.dart';
import 'package:lichess_mobile/src/model/settings/preferences_storage.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/widgets/board_3d.dart';
import 'package:lichess_mobile/src/widgets/game_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../test_provider_scope.dart';

void main() {
  group('iOS back swipe', () {
    Future<void> pushBoardScreen(
      WidgetTester tester,
      GameBoardParams boardParams, {
      double sideMargin = 0,
    }) async {
      final app = await makeTestProviderScope(
        tester,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                buildScreenRoute<void>(
                  screen: Scaffold(
                    body: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideMargin),
                      child: GameLayout(
                        orientation: Side.white,
                        boardParams: boardParams,
                        topTable: const SizedBox(height: 100, child: Text('Top table')),
                        bottomTable: const SizedBox(height: 100, child: Text('Bottom table')),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Chessboard), findsOneWidget);
    }

    final interactiveParams = GameBoardParams.interactive(
      variant: Variant.standard,
      position: Chess.initial,
      playerSide: PlayerSide.white,
      onMove: (_, {viaDragAndDrop}) {},
    );
    const readonlyParams = GameBoardParams.readonly(
      variant: Variant.standard,
      position: Chess.initial,
    );

    testWidgets('does not pop the screen when the drag starts on an interactive board', (
      tester,
    ) async {
      await pushBoardScreen(tester, interactiveParams);

      final boardRect = tester.getRect(find.byType(Chessboard));
      await tester.dragFrom(Offset(boardRect.left + 5, boardRect.center.dy), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsOneWidget);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('pops the screen when the drag starts on a non-interactive board', (tester) async {
      await pushBoardScreen(tester, readonlyParams);

      final boardRect = tester.getRect(find.byType(Chessboard));
      await tester.dragFrom(Offset(boardRect.left + 5, boardRect.center.dy), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('pops the screen when the drag starts outside of the board', (tester) async {
      await pushBoardScreen(tester, interactiveParams);

      final boardRect = tester.getRect(find.byType(Chessboard));
      await tester.dragFrom(Offset(5, boardRect.top - 20), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('does not pop the screen when the drag starts beside an interactive board', (
      tester,
    ) async {
      await pushBoardScreen(tester, interactiveParams, sideMargin: 12);

      final boardRect = tester.getRect(find.byType(Chessboard));
      expect(boardRect.left, greaterThanOrEqualTo(12));
      await tester.dragFrom(Offset(5, boardRect.center.dy), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsOneWidget);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('pops the screen when the drag starts beside a non-interactive board', (
      tester,
    ) async {
      await pushBoardScreen(tester, readonlyParams, sideMargin: 12);

      final boardRect = tester.getRect(find.byType(Chessboard));
      await tester.dragFrom(Offset(5, boardRect.center.dy), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('pops the screen when the drag starts beside an inset board, above it', (
      tester,
    ) async {
      await pushBoardScreen(tester, interactiveParams, sideMargin: 12);

      final boardRect = tester.getRect(find.byType(Chessboard));
      await tester.dragFrom(Offset(5, boardRect.top - 20), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));
  });

  group('3D board', () {
    Future<List<Move>> pumpBoard(WidgetTester tester, {required bool board3d}) async {
      final moves = <Move>[];
      final app = await makeTestProviderScope(
        tester,
        defaultPreferences: {
          PrefCategory.board.storageKey: jsonEncode(
            BoardPrefs.defaults.copyWith(pieceAnimation: false, board3d: board3d).toJson(),
          ),
        },
        child: MaterialApp(
          home: Scaffold(
            body: GameLayout(
              orientation: Side.white,
              boardParams: GameBoardParams.interactive(
                variant: Variant.standard,
                position: Chess.initial,
                playerSide: PlayerSide.white,
                onMove: (move, {viaDragAndDrop}) => moves.add(move),
              ),
              topTable: const SizedBox(height: 100, child: Text('Top table')),
              bottomTable: const SizedBox(height: 100, child: Text('Bottom table')),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      return moves;
    }

    /// The point of the screen where the center of [square] is displayed, through the 3D transform.
    Offset displayedSquareCenter(WidgetTester tester, Square square) {
      final box = tester.renderObject<RenderBox>(find.byType(Chessboard));
      final squareSize = box.size.width / 8;
      return box.localToGlobal(
        Offset((square.file.value + 0.5) * squareSize, (7 - square.rank.value + 0.5) * squareSize),
      );
    }

    testWidgets('flattens the board grid like the 3D board of lichess.org', (tester) async {
      await pumpBoard(tester, board3d: true);

      final box = tester.renderObject<RenderBox>(find.byType(Chessboard));
      final top = box.localToGlobal(Offset.zero);
      final bottom = box.localToGlobal(Offset(box.size.width, box.size.height));

      expect(bottom.dx - top.dx, moreOrLessEquals(box.size.width));
      expect(bottom.dy - top.dy, moreOrLessEquals(box.size.height * kBoard3dHeightRatio));
    });

    testWidgets('plays a move by tapping the squares where they are displayed', (tester) async {
      final moves = await pumpBoard(tester, board3d: true);

      await tester.tapAt(displayedSquareCenter(tester, Square.g1));
      await tester.pump();
      await tester.tapAt(displayedSquareCenter(tester, Square.f3));
      await tester.pump();

      expect(moves, [const NormalMove(from: Square.g1, to: Square.f3)]);
    });

    testWidgets('is flat by default', (tester) async {
      await pumpBoard(tester, board3d: false);

      final box = tester.renderObject<RenderBox>(find.byType(Chessboard));
      final top = box.localToGlobal(Offset.zero);
      final bottom = box.localToGlobal(Offset(box.size.width, box.size.height));
      expect(bottom.dy - top.dy, moreOrLessEquals(box.size.height));
    });
  });
}
