import 'package:flutter_test/flutter_test.dart';

import 'package:slither/main.dart';

void main() {
  testWidgets('renders landing screen without arena HUD', (tester) async {
    await tester.pumpWidget(const SlitherApp());
    await tester.pump();

    expect(find.textContaining('SCORE'), findsNothing);
    expect(find.text('RUN LIBRARY'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsNothing);
    expect(
      find.text(
        'MOVE POINTER / DRAG TO STEER\n'
        'CLICK AND HOLD OR SPACE TO SPRINT',
      ),
      findsNothing,
    );
  });
}
