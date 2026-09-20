import 'package:flutter_test/flutter_test.dart';

import 'drift_probe_support.dart';

void main() {
  test(
    'Drift web storage persists chunks across database close and reopen',
    () => verifyPersistentRunRoundTrip('sprint0-web-persistence-probe'),
  );
}
