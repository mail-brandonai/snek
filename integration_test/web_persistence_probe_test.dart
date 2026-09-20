import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'drift_probe_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Drift web storage persists chunks across database close and reopen',
    (_) async {
      await verifyPersistentRunRoundTrip('sprint0-web-persistence-probe');
    },
  );
}
