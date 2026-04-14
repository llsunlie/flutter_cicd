import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate_version_json writes expected manifest fields', () async {
    final outputFile = File('build/test-version.json');

    final result = await Process.run(
      'dart',
      [
        'run',
        'tool/generate_version_json.dart',
        '--version',
        '1.2.3',
        '--build-number',
        '42',
        '--apk-url',
        'https://example.com/app-release.apk',
        '--output',
        outputFile.path,
      ],
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(outputFile.existsSync(), isTrue);

    final manifest = jsonDecode(outputFile.readAsStringSync()) as Map<String, dynamic>;

    expect(manifest['version'], '1.2.3');
    expect(manifest['build_number'], 42);
    expect(manifest['platform'], 'android');
    expect(manifest['apk_url'], 'https://example.com/app-release.apk');
    expect(manifest['mandatory'], isFalse);
  });
}
