# Flutter CI/CD And Android Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a GitHub-based delivery pipeline where pushes to `main` run validation, `v*` tags publish Web to GitHub Pages and Android APKs to GitHub Releases, and the Android app can detect a new release from `version.json` and guide the user through downloading and installing the APK.

**Architecture:** Keep infrastructure minimal. GitHub Actions handles CI and release publishing, GitHub Pages serves the Web build, GitHub Releases stores the Android APK and `version.json`, and the Flutter app contains a small update module that fetches release metadata, compares versions, and shows an in-app update dialog. The app remains simple and testable by separating metadata parsing, version comparison, network access, and UI coordination.

**Tech Stack:** Flutter, Dart, GitHub Actions, GitHub Pages, GitHub Releases, `package_info_plus`, `http`, `path_provider`, `dio`, `open_filex`, `flutter_test`

---

## File Structure

- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`
- Create: `tool/generate_version_json.dart`
- Create: `lib/app.dart`
- Create: `lib/features/update/domain/app_update_info.dart`
- Create: `lib/features/update/domain/version_comparator.dart`
- Create: `lib/features/update/data/update_manifest_remote_data_source.dart`
- Create: `lib/features/update/data/update_repository.dart`
- Create: `lib/features/update/application/update_service.dart`
- Create: `lib/features/update/presentation/update_prompt.dart`
- Create: `test/tool/generate_version_json_test.dart`
- Create: `test/features/update/version_comparator_test.dart`
- Create: `test/features/update/update_service_test.dart`
- Create: `test/features/update/update_prompt_test.dart`
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

### Task 1: Establish Validation CI

**Files:**
- Create: `.github/workflows/ci.yml`
- Modify: `README.md`

- [ ] **Step 1: Write the failing validation workflow definition**

Create `.github/workflows/ci.yml` with this initial content:

```yaml
name: ci

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test

      - name: Build web
        run: flutter build web --release

      - name: Build Android debug APK
        run: flutter build apk --debug
```

- [ ] **Step 2: Commit the workflow file and push a branch to verify Actions starts**

Run:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add validation workflow"
git push origin HEAD
```

Expected:

```text
GitHub Actions shows a new "ci" workflow run for the branch or pull request.
```

- [ ] **Step 3: Harden the workflow for deterministic builds**

Update `.github/workflows/ci.yml` to pin Java and enable Flutter caching:

```yaml
name: ci

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test

      - name: Build web
        run: flutter build web --release

      - name: Build Android debug APK
        run: flutter build apk --debug
```

- [ ] **Step 4: Document the CI purpose**

Append this section to `README.md`:

```md
## CI/CD

- Pushes and pull requests to `main` run validation in GitHub Actions.
- Version tags like `v1.0.0` trigger a release workflow.
- Web releases are published to GitHub Pages.
- Android releases are uploaded to GitHub Releases together with `version.json`.
```

- [ ] **Step 5: Verify locally before moving on**

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

Expected:

```text
All commands complete successfully with no analyzer errors and passing tests.
```

- [ ] **Step 6: Commit the validated CI setup**

Run:

```bash
git add .github/workflows/ci.yml README.md
git commit -m "docs: document validation workflow"
```

### Task 2: Build the Release Workflow for Pages and Releases

**Files:**
- Create: `.github/workflows/release.yml`
- Modify: `README.md`

- [ ] **Step 1: Write the failing release workflow**

Create `.github/workflows/release.yml`:

```yaml
name: release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Resolve version from tag
        id: version
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Build web
        run: flutter build web --release --base-href "/${{ github.event.repository.name }}/"

      - name: Build Android release APK
        run: flutter build apk --release

      - name: Upload web artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
```

- [ ] **Step 2: Add release publication and GitHub Release asset upload**

Replace `.github/workflows/release.yml` with:

```yaml
name: release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Resolve version from tag
        id: version
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Build web
        run: flutter build web --release --base-href "/${{ github.event.repository.name }}/"

      - name: Build Android release APK
        run: flutter build apk --release

      - name: Generate version.json
        run: dart run tool/generate_version_json.dart
          --version "${{ steps.version.outputs.version }}"
          --build-number "${{ github.run_number }}"
          --apk-url "https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/app-release.apk"
          --output build/version.json

      - name: Upload web artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: build/web

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            build/app/outputs/flutter-apk/app-release.apk
            build/version.json

  deploy-pages:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 3: Verify the workflow syntax before tag testing**

Run:

```bash
git add .github/workflows/release.yml
git commit -m "ci: add release workflow"
git push origin HEAD
```

Expected:

```text
The workflow file is accepted by GitHub. No YAML syntax errors appear in the Actions UI.
```

- [ ] **Step 4: Document the release trigger and outputs**

Append this section to `README.md`:

```md
### Release Flow

1. Update `pubspec.yaml` version.
2. Create a tag such as `v1.0.0`.
3. Push the tag to GitHub.
4. GitHub Actions builds the Web bundle and Android APK.
5. The workflow publishes Web to GitHub Pages and uploads the APK plus `version.json` to GitHub Releases.
```

- [ ] **Step 5: Perform a release dry run with a disposable tag**

Run:

```bash
git tag v0.0.1-test
git push origin v0.0.1-test
```

Expected:

```text
GitHub Actions runs the "release" workflow, publishes a Pages deployment, and creates a GitHub Release containing app-release.apk and version.json.
```

- [ ] **Step 6: Delete the disposable release tag after verifying behavior**

Run:

```bash
git push --delete origin v0.0.1-test
git tag -d v0.0.1-test
```

Expected:

```text
The temporary tag is removed locally and remotely. The workflow definition remains ready for real version tags.
```

### Task 3: Generate and Validate `version.json`

**Files:**
- Create: `tool/generate_version_json.dart`
- Create: `test/tool/generate_version_json_test.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add runtime dependencies needed later by the app**

Update `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.8.0+1
  http: ^1.2.2
  open_filex: ^4.5.0
  package_info_plus: ^8.0.2
  path_provider: ^2.1.4
```

- [ ] **Step 2: Write the failing generator test**

Create `test/tool/generate_version_json_test.dart`:

```dart
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
```

- [ ] **Step 3: Run the test to confirm the generator is missing**

Run:

```bash
flutter test test/tool/generate_version_json_test.dart
```

Expected:

```text
FAIL because tool/generate_version_json.dart does not exist yet.
```

- [ ] **Step 4: Implement the generator**

Create `tool/generate_version_json.dart`:

```dart
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
```

- [ ] **Step 5: Re-run the test and inspect the manifest**

Run:

```bash
flutter test test/tool/generate_version_json_test.dart
dart run tool/generate_version_json.dart --version 1.2.3 --build-number 42 --apk-url https://example.com/app-release.apk --output build/version.json
sed -n '1,120p' build/version.json
```

Expected:

```text
The test passes and build/version.json contains the expected JSON keys and values.
```

- [ ] **Step 6: Commit the manifest generator**

Run:

```bash
git add pubspec.yaml tool/generate_version_json.dart test/tool/generate_version_json_test.dart
git commit -m "build: generate android update manifest"
```

### Task 4: Add the Update Domain and Service Layer

**Files:**
- Create: `lib/app.dart`
- Create: `lib/features/update/domain/app_update_info.dart`
- Create: `lib/features/update/domain/version_comparator.dart`
- Create: `lib/features/update/data/update_manifest_remote_data_source.dart`
- Create: `lib/features/update/data/update_repository.dart`
- Create: `lib/features/update/application/update_service.dart`
- Create: `test/features/update/version_comparator_test.dart`
- Create: `test/features/update/update_service_test.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write failing unit tests for version comparison**

Create `test/features/update/version_comparator_test.dart`:

```dart
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
```

- [ ] **Step 2: Write the failing service test**

Create `test/features/update/update_service_test.dart`:

```dart
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
```

- [ ] **Step 3: Run the tests to verify the update module is not implemented**

Run:

```bash
flutter test test/features/update/version_comparator_test.dart
flutter test test/features/update/update_service_test.dart
```

Expected:

```text
FAIL because the update module files are missing.
```

- [ ] **Step 4: Implement the domain model and comparison logic**

Create `lib/features/update/domain/app_update_info.dart`:

```dart
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
```

Create `lib/features/update/domain/version_comparator.dart`:

```dart
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
```

- [ ] **Step 5: Implement the remote data source, repository, and service**

Create `lib/features/update/data/update_manifest_remote_data_source.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';

class UpdateManifestRemoteDataSource {
  UpdateManifestRemoteDataSource({
    required this.client,
    required this.manifestUrl,
  });

  final http.Client client;
  final String manifestUrl;

  Future<AppUpdateInfo> fetchLatestUpdate() async {
    final response = await client.get(Uri.parse(manifestUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load update manifest.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUpdateInfo.fromJson(json);
  }
}
```

Create `lib/features/update/data/update_repository.dart`:

```dart
import 'package:flutter_cicd/features/update/data/update_manifest_remote_data_source.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';

abstract class UpdateRepository {
  Future<AppUpdateInfo> fetchLatestUpdate();
}

class DefaultUpdateRepository implements UpdateRepository {
  DefaultUpdateRepository(this.remoteDataSource);

  final UpdateManifestRemoteDataSource remoteDataSource;

  @override
  Future<AppUpdateInfo> fetchLatestUpdate() {
    return remoteDataSource.fetchLatestUpdate();
  }
}
```

Create `lib/features/update/application/update_service.dart`:

```dart
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
```

- [ ] **Step 6: Introduce an app shell entry point**

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CI/CD Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Flutter CI/CD Demo'),
        ),
      ),
    );
  }
}
```

Replace `lib/main.dart` with:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_cicd/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
```

- [ ] **Step 7: Re-run the tests and general project checks**

Run:

```bash
flutter test test/features/update/version_comparator_test.dart
flutter test test/features/update/update_service_test.dart
flutter analyze
flutter test
```

Expected:

```text
The new unit tests pass and the project still analyzes and tests cleanly.
```

- [ ] **Step 8: Commit the update core**

Run:

```bash
git add lib/main.dart lib/app.dart lib/features/update test/features/update
git commit -m "feat: add update manifest domain and service"
```

### Task 5: Add Android Download and Install Prompt

**Files:**
- Create: `lib/features/update/presentation/update_prompt.dart`
- Modify: `lib/app.dart`
- Create: `test/features/update/update_prompt_test.dart`

- [ ] **Step 1: Write the failing widget test for the update prompt**

Create `test/features/update/update_prompt_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the test to confirm the widget is missing**

Run:

```bash
flutter test test/features/update/update_prompt_test.dart
```

Expected:

```text
FAIL because UpdatePrompt does not exist yet.
```

- [ ] **Step 3: Implement the dialog widget**

Create `lib/features/update/presentation/update_prompt.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';

class UpdatePrompt extends StatelessWidget {
  const UpdatePrompt({
    super.key,
    required this.updateInfo,
    this.onConfirm,
    this.onCancel,
  });

  final AppUpdateInfo updateInfo;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(updateInfo.title),
      content: Text(updateInfo.description),
      actions: [
        if (!updateInfo.mandatory)
          TextButton(
            onPressed: onCancel,
            child: const Text('稍后再说'),
          ),
        FilledButton(
          onPressed: onConfirm,
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Wire the prompt into the root app using a temporary manual trigger**

Replace `lib/app.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';
import 'package:flutter_cicd/features/update/presentation/update_prompt.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CI/CD Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flutter CI/CD Demo')),
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const UpdatePrompt(
                      updateInfo: AppUpdateInfo(
                        version: '1.0.1',
                        buildNumber: 2,
                        title: '发现新版本',
                        description: '修复问题',
                        apkUrl: 'https://example.com/app-release.apk',
                        mandatory: false,
                      ),
                    ),
                  );
                },
                child: const Text('检查更新'),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Re-run the widget test and perform a manual smoke test**

Run:

```bash
flutter test test/features/update/update_prompt_test.dart
flutter run -d linux
```

Expected:

```text
The widget test passes. In the running app, clicking "检查更新" opens the update prompt.
```

- [ ] **Step 6: Commit the prompt UI**

Run:

```bash
git add lib/app.dart lib/features/update/presentation/update_prompt.dart test/features/update/update_prompt_test.dart
git commit -m "feat: add android update prompt"
```

### Task 6: Integrate Real Update Checks and Final Verification

**Files:**
- Modify: `lib/app.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [ ] **Step 1: Replace the temporary button flow with a startup update check**

Update `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_cicd/features/update/application/update_service.dart';
import 'package:flutter_cicd/features/update/data/update_manifest_remote_data_source.dart';
import 'package:flutter_cicd/features/update/data/update_repository.dart';
import 'package:flutter_cicd/features/update/presentation/update_prompt.dart';

const _manifestUrl = 'https://github.com/<owner>/<repo>/releases/latest/download/version.json';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final UpdateService _updateService;

  @override
  void initState() {
    super.initState();
    _updateService = UpdateService(
      repository: DefaultUpdateRepository(
        UpdateManifestRemoteDataSource(
          client: http.Client(),
          manifestUrl: _manifestUrl,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(info.buildNumber) ?? 0;
    final update = await _updateService.checkForUpdate(
      currentVersion: info.version,
      currentBuildNumber: currentBuildNumber,
    );

    if (!mounted || update == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => UpdatePrompt(updateInfo: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CI/CD Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Flutter CI/CD Demo'),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Replace the default widget test with a simple app smoke test**

Replace `test/widget_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cicd/app.dart';

void main() {
  testWidgets('app renders root title', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter CI/CD Demo'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Document the required repository settings**

Append this section to `README.md`:

```md
## GitHub Configuration

- Enable GitHub Pages and configure the source as GitHub Actions.
- Allow workflow permissions to read and write repository contents.
- Create releases by pushing `v*` tags.
- Keep the update manifest URL in sync with the repository owner and name.
```

- [ ] **Step 4: Run the full verification suite**

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

Expected:

```text
All checks pass, and the release artifacts are produced in build/web and build/app/outputs/flutter-apk/app-release.apk.
```

- [ ] **Step 5: Verify the live release behavior in GitHub**

Run:

```bash
git add .
git commit -m "feat: wire github release update flow"
git push origin HEAD
git tag v0.1.0
git push origin v0.1.0
```

Expected:

```text
The CI workflow passes on the branch, the release workflow publishes GitHub Pages, and the GitHub Release contains the APK and version.json.
```

- [ ] **Step 6: Manually verify Android update detection**

Manual procedure:

```text
1. Install the older APK on an Android device.
2. Publish a newer tag with a higher build number.
3. Launch the installed app.
4. Confirm that the update prompt appears.
5. Tap "立即更新" and verify that the APK download starts.
6. Confirm that Android opens the installer for the downloaded APK.
```

- [ ] **Step 7: Commit the integrated release flow**

Run:

```bash
git add lib/app.dart test/widget_test.dart README.md
git commit -m "feat: integrate github-based app updates"
```

## Self-Review

- Spec coverage: this plan covers validation CI, tag-based release automation, manifest generation, Web publishing, GitHub Release asset publication, Android metadata parsing, version comparison, update prompt UI, and final verification. The only intentionally deferred items are signing, HTTPS customization, and iOS support, which the spec explicitly excluded for this phase.
- Placeholder scan: no task uses `TODO`, `TBD`, or vague steps without code or commands.
- Type consistency: the plan consistently uses `AppUpdateInfo`, `UpdateRepository`, `UpdateService`, `UpdatePrompt`, and `build_number` across generator, app code, and tests.
