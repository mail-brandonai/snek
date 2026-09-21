import 'package:flutter_test/flutter_test.dart';

import 'package:slither/main.dart';

void main() {
  testWidgets('renders the Slither game shell', (tester) async {
    await tester.pumpWidget(const SlitherApp());
    await tester.pump();

    expect(find.textContaining('SCORE'), findsOneWidget);
    expect(find.text('RUN LIBRARY'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(
      find.text(
        'MOVE POINTER / DRAG TO STEER\n'
        'CLICK AND HOLD OR SPACE TO SPRINT',
      ),
      findsOneWidget,
    );
  });
}
