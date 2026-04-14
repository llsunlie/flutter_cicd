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
