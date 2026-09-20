import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temporary formatter output probe', () async {
    final result = await Process.run(
      'dart',
      <String>['format', '--output=show', 'lib/main.dart'],
    );
    expect(result.exitCode, 0);
    print('FORMAT_PROBE_START');
    print(result.stdout);
    print('FORMAT_PROBE_END');
  });
}
