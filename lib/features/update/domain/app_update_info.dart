class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.title,
    required this.description,
    required this.apkUrl,
    required this.mandatory,
  });

  final String version;
  final int buildNumber;
  final String title;
  final String description;
  final String apkUrl;
  final bool mandatory;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      apkUrl: json['apk_url'] as String,
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
}
