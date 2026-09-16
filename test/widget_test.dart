import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melangadi_store/main.dart';

void main() {
  testWidgets('Melangadi Store App renders Dashboard and Navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MelangadiStoreApp());
    await tester.pumpAndSettle();

    // Verify app title and store branding
    expect(find.text('Melangadi Store'), findsOneWidget);

    // Verify key dashboard elements
    expect(find.text("Today's Total Sales"), findsOneWidget);
    expect(find.text("Today's Purchases"), findsOneWidget);
    expect(find.text('Cash in Hand'), findsOneWidget);
    expect(find.text('Available Products'), findsOneWidget);

    // Verify Bottom Navigation Bar destinations
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Purchase'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);

    // Tap on Products navigation tab
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    // Verify Products screen title
    expect(find.text('Products & Stock'), findsOneWidget);

    // Tap on Sales tab
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    // Verify Sales management title
    expect(find.text('Sales Management'), findsOneWidget);
    expect(find.text('New Sale (POS)'), findsOneWidget);

    // Tap on Purchase tab
    await tester.tap(find.text('Purchase'));
    await tester.pumpAndSettle();

    // Verify Purchase screen title
    expect(find.text('Purchase Management'), findsOneWidget);
  });
}
