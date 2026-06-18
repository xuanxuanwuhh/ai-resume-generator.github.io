import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_resume_generator_flutter/main.dart';

void main() {
  testWidgets('renders upgraded flutter workbench', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ResumeWorkbenchApp());
    await tester.pumpAndSettle();

    expect(find.text('AI 简历工作台'), findsOneWidget);
    expect(find.text('移动端增强'), findsOneWidget);
    expect(find.text('上传头像'), findsOneWidget);
    expect(find.text('教育经历'), findsWidgets);
    expect(find.text('项目经历'), findsWidgets);
  });
}
