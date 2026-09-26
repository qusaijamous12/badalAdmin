import 'package:badal_admin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('admin login shows email and password fields', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: LoginPage()),
    ));
    expect(find.text('مرحبًا بعودتك'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
