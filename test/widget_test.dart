import 'package:flutter_test/flutter_test.dart';
import 'package:clinicalshark/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicalSharkApp());
    expect(find.byType(ClinicalSharkApp), findsOneWidget);
  });
}
