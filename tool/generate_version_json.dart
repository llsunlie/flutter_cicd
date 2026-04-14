import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final arguments = _Arguments.parse(args);

  final outputFile = File(arguments.outputPath);
  outputFile.parent.createSync(recursive: true);

  final manifest = <String, Object>{
    'version': arguments.version,
    'build_number': arguments.buildNumber,
    'release_date': DateTime.now().toUtc().toIso8601String(),
    'platform': 'android',
    'mandatory': false,
    'title': '发现新版本',
    'description': '修复已知问题并优化体验',
    'apk_url': arguments.apkUrl,
  };

  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
}

class _Arguments {
  const _Arguments({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.outputPath,
  });

  final String version;
  final int buildNumber;
  final String apkUrl;
  final String outputPath;

  static _Arguments parse(List<String> args) {
    String? version;
    int? buildNumber;
    String? apkUrl;
    String? outputPath;

    for (var index = 0; index < args.length; index += 2) {
      final key = args[index];
      final value = args[index + 1];

      switch (key) {
        case '--version':
          version = value;
        case '--build-number':
          buildNumber = int.parse(value);
        case '--apk-url':
          apkUrl = value;
        case '--output':
          outputPath = value;
      }
    }

    if (version == null ||
        buildNumber == null ||
        apkUrl == null ||
        outputPath == null) {
      throw ArgumentError('Missing required arguments.');
    }

    return _Arguments(
      version: version,
      buildNumber: buildNumber,
      apkUrl: apkUrl,
      outputPath: outputPath,
    );
  }
}
