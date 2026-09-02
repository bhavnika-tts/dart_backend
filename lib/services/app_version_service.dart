import '../models/app_version.dart';
import '../repositories/app_version_repository.dart';

/// Service handling AppVersion business logic and semver validation.
class AppVersionService {
  AppVersionService({AppVersionRepository? repository})
      : _repository = repository ?? AppVersionRepository.instance;

  final AppVersionRepository _repository;

  static AppVersionService? _instance;
  static AppVersionService get instance => _instance ??= AppVersionService();

  static final _semverRegex = RegExp(r'^\d+\.\d+\.\d+$');

  Future<AppVersion> createAppVersion(Map<String, dynamic> data) async {
    final version = data['version']?.toString().trim() ?? '';
    final versionName = data['versionName']?.toString().trim() ?? '';
    final apkLink = data['apkLink']?.toString().trim() ?? '';
    final changes = data['changes']?.toString() ?? '';

    if (!_semverRegex.hasMatch(version)) {
      throw ArgumentError("Invalid version format. Use format like '1.1.0', '1.1.1', etc.");
    }

    final existingVersion = await _repository.findByVersionNumber(version);
    if (existingVersion != null) {
      throw StateError('Version $version already exists');
    }

    final existingName = await _repository.findByVersionName(versionName);
    if (existingName != null) {
      throw StateError('Version name $versionName already exists');
    }

    final newVersion = AppVersion(
      version: version,
      versionName: versionName,
      apkLink: apkLink,
      changes: changes,
      isActive: data['isActive'] != false,
    );

    return _repository.create(newVersion);
  }

  Future<List<AppVersion>> getAllVersions() async {
    return _repository.findAllSorted();
  }

  Future<AppVersion?> getLatestVersion() async {
    return _repository.findLatestActive();
  }

  Future<AppVersion?> getVersionById(String id) async {
    return _repository.findById(id);
  }

  Future<AppVersion?> updateVersion(String id, Map<String, dynamic> data) async {
    final version = data['version']?.toString().trim();
    if (version != null && !RegExp(r'^\d+\.\d+').hasMatch(version)) {
      throw ArgumentError("Invalid version format. Use format like '1.0', '1.1', etc.");
    }

    return _repository.update(id, data);
  }

  Future<bool> deleteVersion(String id) async {
    return _repository.delete(id);
  }
}
