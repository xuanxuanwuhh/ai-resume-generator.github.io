import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_resume_generator_flutter/main.dart';

void main() {
  testWidgets('enters workspace and updates scenario preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ResumeStudioApp());

    expect(find.text('简历生成与优化工作台'), findsOneWidget);
    expect(find.text('进入工作台'), findsOneWidget);

    await tester.tap(find.text('进入工作台'));
    await tester.pumpAndSettle();

    expect(find.text('岗位投递版'), findsOneWidget);

    await tester.tap(find.text('考研').last);
    await tester.pumpAndSettle();

    expect(find.text('考研复试版'), findsOneWidget);
  });
}
