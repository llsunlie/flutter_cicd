import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cicd/features/update/domain/version_comparator.dart';

void main() {
  group('VersionComparator', () {
    test('returns true when remote build number is higher', () {
      expect(
        VersionComparator.isUpdateAvailable(
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
          remoteVersion: '1.0.0',
          remoteBuildNumber: 2,
        ),
        isTrue,
      );
    });

    test('returns false when versions match', () {
      expect(
        VersionComparator.isUpdateAvailable(
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
          remoteVersion: '1.0.0',
          remoteBuildNumber: 1,
        ),
        isFalse,
      );
    });
  });
}
