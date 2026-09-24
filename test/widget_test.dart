import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hela_service/main.dart';
import 'package:hela_service/features/admin/admin_shell.dart';
import 'package:hela_service/state/role_provider.dart';
import 'package:hela_service/state/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('HelaServiceApp boots splash screen and routes to LoginScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HelaServiceApp());
    expect(find.text('HelaService'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the splash timer finish (900ms)
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Now on LoginScreen
    expect(find.text('Welcome to HelaService'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets(
      'AdminShell renders desktop sidebar, dashboard, and switches tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: AdminShell(),
        ),
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

  testWidgets(
      'AdminShell renders mobile layout with BottomNavigationBar below 768px',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: AdminShell(),
        ),
      ),
    );

    // No desktop sidebar
    expect(find.text('OPERATIONS CORE'), findsNothing);

    // Mobile Top Bar & Live Dispatch
    expect(find.text('HelaService Ops'), findsOneWidget);
    expect(find.text('Island Operations & Live Dispatch'), findsOneWidget);

    // Mobile Bottom Nav items exist
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Coverage'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Switch to Verify tab
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Technician Identity Verification Desk'), findsOneWidget);

    // Switch to Coverage tab
    await tester.tap(find.text('Coverage'));
    await tester.pumpAndSettle();
    expect(find.text('Service Categories & Coverage'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Console Settings'), findsOneWidget);
  });
}
