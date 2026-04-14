import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_cicd/features/update/application/update_service.dart';
import 'package:flutter_cicd/features/update/data/update_manifest_remote_data_source.dart';
import 'package:flutter_cicd/features/update/data/update_repository.dart';
import 'package:flutter_cicd/features/update/presentation/update_prompt.dart';

const _manifestUrl = 'https://github.com/llsunlie/flutter_cicd/releases/latest/download/version.json';

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
          child: Text('Flutter CI/CD Demo!'),
        ),
      ),
    );
  }
}
