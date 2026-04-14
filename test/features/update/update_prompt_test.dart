import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';
import 'package:flutter_cicd/features/update/presentation/update_prompt.dart';

void main() {
  testWidgets('renders update metadata and action buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdatePrompt(
          updateInfo: AppUpdateInfo(
            version: '1.0.1',
            buildNumber: 2,
            title: '发现新版本',
            description: '修复问题',
            apkUrl: 'https://example.com/app-release.apk',
            mandatory: false,
          ),
        ),
      ),
    );

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('修复问题'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
    expect(find.text('稍后再说'), findsOneWidget);
  });
}
