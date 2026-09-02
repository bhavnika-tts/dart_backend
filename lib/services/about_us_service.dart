import '../models/about_us.dart';
import '../repositories/about_us_repository.dart';

/// Business service for About Us information.
class AboutUsService {
  AboutUsService({AboutUsRepository? repository})
      : _repository = repository ?? AboutUsRepository.instance;

  final AboutUsRepository _repository;

  static AboutUsService? _instance;
  static AboutUsService get instance => _instance ??= AboutUsService();

  Future<AboutUs?> getAboutUsData() async {
    return _repository.findAboutUs();
  }

  Future<AboutUs> createAboutUsData(Map<String, dynamic> data) async {
    return _repository.createAboutUs(data);
  }

  Future<AboutUs?> updateAboutUsData(Map<String, dynamic> data) async {
    return _repository.updateAboutUs(data);
  }
}
