import 'package:flutter_cicd/features/update/data/update_repository.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';
import 'package:flutter_cicd/features/update/domain/version_comparator.dart';

class UpdateService {
  UpdateService({required this.repository});

  final UpdateRepository repository;

  Future<AppUpdateInfo?> checkForUpdate({
    required String currentVersion,
    required int currentBuildNumber,
  }) async {
    final latest = await repository.fetchLatestUpdate();
    final hasUpdate = VersionComparator.isUpdateAvailable(
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      remoteVersion: latest.version,
      remoteBuildNumber: latest.buildNumber,
    );

    return hasUpdate ? latest : null;
  }
}
