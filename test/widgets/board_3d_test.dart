import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lichess_mobile/src/model/settings/board_preferences.dart';
import 'package:lichess_mobile/src/widgets/board_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every 3D piece set has all its images in the app assets', () async {
    for (final pieceSet in PieceSet3d.values) {
      for (final orientation in Side.values) {
        for (final asset in board3dPieceAssets(pieceSet, orientation).values) {
          expect(await rootBundle.load(asset.assetName), isA<ByteData>(), reason: asset.assetName);
        }
      }
    }
  });

  test('every 3D board has its image in the app assets', () async {
    for (final boardTheme in BoardTheme3d.values) {
      expect(await rootBundle.load(boardTheme.imagePath), isA<ByteData>());
    }
  });

  test('draws the bishops and knights of the opponent facing the other way', () {
    final assets = board3dPieceAssets(PieceSet3d.wood, Side.white);
    expect(assets[PieceKind.blackKnight]!.assetName, endsWith('Black-Knight-Flipped.webp'));
    expect(assets[PieceKind.whiteKnight]!.assetName, endsWith('White-Knight.webp'));
    expect(assets[PieceKind.blackRook]!.assetName, endsWith('Black-Rook.webp'));

    final staunton = board3dPieceAssets(PieceSet3d.staunton, Side.white);
    expect(staunton[PieceKind.blackKnight]!.assetName, endsWith('Black-Knight.webp'));
  });
}
