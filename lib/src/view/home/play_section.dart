import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/account/home_preferences.dart';
import 'package:lichess_mobile/src/model/auth/auth_controller.dart';
import 'package:lichess_mobile/src/model/common/time_increment.dart';
import 'package:lichess_mobile/src/model/lobby/game_seek.dart';
import 'package:lichess_mobile/src/network/connectivity.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/tab_navigation.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/view/game/game_screen.dart';
import 'package:lichess_mobile/src/view/game/game_screen_providers.dart';
import 'package:lichess_mobile/src/view/offline_computer/offline_computer_game_screen.dart';
import 'package:lichess_mobile/src/view/play/quick_game_matrix.dart';
import 'package:material_ui/material_ui.dart';

/// The time control of a game against someone in the beginner mode: 10 minutes each.
const kBeginnerTimeControl = TimeIncrement(600, 0);

/// Strings of the beginner and pro modes, not translated by Lichess: French or English.
extension on BuildContext {
  bool get _isFrench => Localizations.localeOf(this).languageCode == 'fr';

  String get beginnerLabel => _isFrench ? 'Débutant' : 'Beginner';

  String get proLabel => 'Pro';

  String get playAgainstSomeone => _isFrench ? 'Jouer contre quelqu’un' : 'Play against someone';

  String get tenMinutesEach => _isFrench ? '10 minutes chacun' : '10 minutes each';

  String get atYourOwnPace =>
      _isFrench ? 'À ton rythme, sans connexion' : 'At your own pace, offline';
}

/// Switches the home screen between the beginner and the pro modes.
class const HomeModeToggle() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proMode = ref.watch(homePreferencesProvider.select((prefs) => prefs.proMode));
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: false, label: Text(context.beginnerLabel)),
        ButtonSegment(value: true, label: Text(context.proLabel)),
      ],
      selected: {proMode},
      onSelectionChanged: (selection) =>
          ref.read(homePreferencesProvider.notifier).setProMode(selection.first),
    );
  }
}

/// The ways to start a game, at the top of the home screen.
///
/// In the beginner mode, two big buttons: a game against the computer, or a 10 minutes game against
/// someone. In the pro mode, all the time controls, and the game against the computer.
class const PlaySection() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proMode = ref.watch(homePreferencesProvider.select((prefs) => prefs.proMode));
    final isOnline = ref.watch(lichessConnectionStatusProvider) == LichessConnectionStatus.online;

    void playAgainstComputer() {
      Navigator.of(context).pushHidingTabBar(OfflineComputerGameScreen.buildRoute());
    }

    if (proMode) {
      return Padding(
        padding: Styles.bodySectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QuickGameMatrix(),
            const SizedBox(height: 8.0),
            FilledButton.tonalIcon(
              onPressed: playAgainstComputer,
              icon: const Icon(Icons.memory),
              label: Text(context.l10n.playAgainstComputer),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: Styles.bodySectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigPlayButton(
            icon: Icons.memory,
            title: context.l10n.playAgainstComputer,
            subtitle: context.atYourOwnPace,
            onPressed: playAgainstComputer,
          ),
          const SizedBox(height: 16.0),
          _BigPlayButton(
            icon: Icons.people_outline,
            title: context.playAgainstSomeone,
            subtitle: context.tenMinutesEach,
            onPressed: isOnline
                ? () {
                    final authUser = ref.read(authControllerProvider);
                    Navigator.of(context).pushHidingTabBar(
                      GameScreen.buildRoute(
                        source: LobbySource(GameSeek.fastPairing(kBeginnerTimeControl, authUser)),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class const _BigPlayButton({
  required final IconData icon,
  required final String title,
  required final String subtitle,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40.0),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleLarge),
                const SizedBox(height: 4.0),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
