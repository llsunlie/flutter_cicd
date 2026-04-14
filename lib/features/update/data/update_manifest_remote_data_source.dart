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
