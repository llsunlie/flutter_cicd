import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cicd/features/update/application/update_service.dart';
import 'package:flutter_cicd/features/update/data/update_repository.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';

class FakeUpdateRepository implements UpdateRepository {
  FakeUpdateRepository(this.info);

  final AppUpdateInfo info;

  @override
  Future<AppUpdateInfo> fetchLatestUpdate() async => info;
}

void main() {
  test('checkForUpdate returns manifest when remote build number is newer', () async {
    final service = UpdateService(
      repository: FakeUpdateRepository(
        const AppUpdateInfo(
          version: '1.0.0',
          buildNumber: 2,
          title: '发现新版本',
          description: '修复问题',
          apkUrl: 'https://example.com/app-release.apk',
          mandatory: false,
        ),
      ),
    );

    final result = await service.checkForUpdate(
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
    );

    expect(result, isNotNull);
    expect(result!.buildNumber, 2);
  });
}
