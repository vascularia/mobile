import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/settings/board_preferences.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user choose the pieces of the 3D board.
class const PieceSet3dScreen({super.key}) extends ConsumerWidget {
  static Route<dynamic> buildRoute() {
    return buildScreenRoute(screen: const PieceSet3dScreen());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(boardPreferencesProvider.select((prefs) => prefs.pieceSet3d));
    final imageHeight = (64 * MediaQuery.devicePixelRatioOf(context)).round();

    return PlatformScaffold(
      appBar: const PlatformAppBar(title: Text('3D pieces')),
      body: SafeArea(
        child: ListView.separated(
          itemCount: PieceSet3d.values.length,
          separatorBuilder: (_, _) => Theme.of(context).platform == TargetPlatform.iOS
              ? const PlatformDivider()
              : const SizedBox.shrink(),
          itemBuilder: (context, index) {
            final pieceSet = PieceSet3d.values[index];
            return ListTile(
              title: Text(pieceSet.label),
              subtitle: Row(
                children: [
                  for (final (color, role) in const [
                    ('White', 'King'),
                    ('Black', 'Queen'),
                    ('White', 'Rook'),
                    ('Black', 'Bishop'),
                    ('White', 'Knight'),
                    ('Black', 'Pawn'),
                  ])
                    Image(
                      image: ResizeImage(
                        AssetImage(pieceSet.assetPath(color, role, flipped: false)),
                        height: imageHeight,
                      ),
                      height: 64,
                    ),
                ],
              ),
              trailing: selected == pieceSet ? const Icon(Icons.check) : null,
              selected: selected == pieceSet,
              onTap: () => ref.read(boardPreferencesProvider.notifier).setPieceSet3d(pieceSet),
            );
          },
        ),
      ),
    );
  }
}

/// Lets the user choose the board of the 3D board.
class const BoardTheme3dScreen({super.key}) extends ConsumerWidget {
  static Route<dynamic> buildRoute() {
    return buildScreenRoute(screen: const BoardTheme3dScreen());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(boardPreferencesProvider.select((prefs) => prefs.boardTheme3d));
    final imageWidth = (120 * MediaQuery.devicePixelRatioOf(context)).round();

    return PlatformScaffold(
      appBar: const PlatformAppBar(title: Text('3D board')),
      body: SafeArea(
        child: ListView.separated(
          itemCount: BoardTheme3d.values.length,
          separatorBuilder: (_, _) => Theme.of(context).platform == TargetPlatform.iOS
              ? const PlatformDivider()
              : const SizedBox.shrink(),
          itemBuilder: (context, index) {
            final boardTheme = BoardTheme3d.values[index];
            return ListTile(
              title: Text(boardTheme.label),
              subtitle: Align(
                alignment: Alignment.topLeft,
                child: Image(
                  image: ResizeImage(AssetImage(boardTheme.imagePath), width: imageWidth),
                  width: 120,
                ),
              ),
              trailing: selected == boardTheme ? const Icon(Icons.check) : null,
              selected: selected == boardTheme,
              onTap: () => ref.read(boardPreferencesProvider.notifier).setBoardTheme3d(boardTheme),
            );
          },
        ),
      ),
    );
  }
}
