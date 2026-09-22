import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hela_service/main.dart';
import 'package:hela_service/features/admin/admin_shell.dart';

void main() {
  testWidgets('HelaServiceApp loads AuthScreen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HelaServiceApp());
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('AdminShell renders Operations Core and Dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminShell(),
      ),
    );
    expect(find.text('OPERATIONS CORE'), findsOneWidget);
    expect(find.text('Island Operations & Live Dispatch'), findsOneWidget);

    await tester.tap(find.text('Verifications'));
    await tester.pumpAndSettle();
    expect(find.text('Technician Identity Verification Desk'), findsOneWidget);

    await tester.tap(find.text('Coverage & Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Service Categories & District Coverage'), findsOneWidget);
  });
}
