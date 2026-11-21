import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lichess_mobile/src/model/settings/board_preferences.dart';
import 'package:material_ui/material_ui.dart';

// The 3D board of lichess.org: pre-rendered Staunton board and pieces, laid out on a board grid
// flattened vertically. The geometry comes from lila's `ui/lib/css/theme/board/_board-3d.scss`.

/// The height of the 3D board grid relative to its width.
const kBoard3dHeightRatio = 464.5 / 512;

/// Where a 3D piece is drawn, in square units relative to its square, before the board grid is
/// flattened by [kBoard3dHeightRatio]: wider than the square and standing on it.
const kBoard3dPieceRect = Rect.fromLTWH(-0.148, -0.728, 1.3393, 1.885);

/// The top of the 3D board image relative to the board grid, in board heights.
const _kBoardImageTop = -0.007307;

/// The height of the 3D board image relative to the board grid, in board heights.
const _kBoardImageHeight = 1.032;

/// The images of the 3D [pieceSet], for a board seen from the [orientation] side.
///
/// The bishops and knights of the opponent are drawn facing the other way, like on lichess.org.
PieceAssets board3dPieceAssets(PieceSet3d pieceSet, Side orientation) => {
  for (final kind in PieceKind.values)
    kind: AssetImage(
      pieceSet.assetPath(
        kind.side == Side.white ? 'White' : 'Black',
        _roleName(kind.role),
        flipped: kind.side != orientation && (kind.role == Role.bishop || kind.role == Role.knight),
      ),
    ),
};

String _roleName(Role role) => switch (role) {
  Role.pawn => 'Pawn',
  Role.knight => 'Knight',
  Role.bishop => 'Bishop',
  Role.rook => 'Rook',
  Role.queen => 'Queen',
  Role.king => 'King',
};

/// The [settings] of a board turned to 3D, with the [pieceSet] on the [boardTheme], seen from the
/// [orientation] side.
///
/// The board must also be flattened vertically by [kBoard3dHeightRatio], see [Board3dTransform].
ChessboardSettings board3dSettings(
  ChessboardSettings settings, {
  required PieceSet3d pieceSet,
  required BoardTheme3d boardTheme,
  required Side orientation,
}) {
  final colorScheme = settings.colorScheme;
  final background = _Board3dBackground(
    image: AssetImage(boardTheme.imagePath),
    lightSquare: colorScheme.lightSquare,
    darkSquare: colorScheme.darkSquare,
  );
  return settings.copyWith(
    pieceAssets: board3dPieceAssets(pieceSet, orientation),
    pieceRect: kBoard3dPieceRect,
    // The coordinates would be drawn on the flat squares, not on the 3D board image.
    enableCoordinates: false,
    colorScheme: colorScheme.copyWith(
      background: background,
      whiteCoordBackground: background,
      blackCoordBackground: background,
    ),
  );
}

/// Flattens a board vertically by [kBoard3dHeightRatio], against the bottom of its square.
///
/// The space freed at the top of the square holds the heads of the pieces of the far row.
class const Board3dTransform({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.diagonal3Values(1.0, kBoard3dHeightRatio, 1.0),
      child: child,
    );
  }
}

/// The pre-rendered 3D board image, which overflows the board grid a little.
class const _Board3dBackground({
  required final AssetImage image,
  required super.lightSquare,
  required super.darkSquare,
}) extends ChessboardBackground {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: size * _kBoardImageHeight,
          maxHeight: size * _kBoardImageHeight,
          child: Transform.translate(
            offset: Offset(0, size * _kBoardImageTop),
            child: Image(image: image, fit: BoxFit.fill),
          ),
        );
      },
    );
  }
}
