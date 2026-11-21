import 'package:lichess_mobile/src/binding/binding_fdroid.dart';
import 'package:lichess_mobile/src/bootstrap.dart';

// Échecs 3D does not use the Firebase project of Lichess (push notifications, crash reports).
Future<void> main() {
  return bootstrapApp(FdroidLichessBinding.ensureInitialized);
}
