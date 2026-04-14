class VersionComparator {
  static bool isUpdateAvailable({
    required String currentVersion,
    required int currentBuildNumber,
    required String remoteVersion,
    required int remoteBuildNumber,
  }) {
    if (remoteBuildNumber != currentBuildNumber) {
      return remoteBuildNumber > currentBuildNumber;
    }

    return _normalize(remoteVersion).compareTo(_normalize(currentVersion)) > 0;
  }

  static String _normalize(String value) {
    return value.split('.').map((segment) => segment.padLeft(4, '0')).join();
  }
}
