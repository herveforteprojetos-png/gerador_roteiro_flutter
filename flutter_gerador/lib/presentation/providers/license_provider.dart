import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/license_service.dart';
import '../../data/models/license.dart';

final licenseServiceProvider = Provider<LicenseService>((ref) {
  return LicenseService();
});

final licenseProvider = StateNotifierProvider<LicenseNotifier, AsyncValue<License>>((ref) {
  final licenseService = ref.watch(licenseServiceProvider);
  return LicenseNotifier(licenseService);
});

class LicenseNotifier extends StateNotifier<AsyncValue<License>> {
  final LicenseService _licenseService;

  LicenseNotifier(this._licenseService) : super(const AsyncValue.loading()) {
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    try {
      state = const AsyncValue.loading();
      final license = await _licenseService.loadLicense();
      state = AsyncValue.data(license);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> canUseApp() async {
    return await _licenseService.canUseApp();
  }

  Future<void> incrementUsage() async {
    await _licenseService.incrementUsage();
    await _loadLicense(); // Recarrega para atualizar o estado
  }

  Future<bool> activateLifetimeLicense(String key) async {
    try {
      final success = await _licenseService.activateLifetimeLicense(key);
      if (success) {
        await _loadLicense(); // Recarrega para atualizar o estado
      }
      return success;
    } catch (error) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getLicenseInfo() async {
    return await _licenseService.getLicenseInfo();
  }

  String generateLicenseKey(String clientInfo) {
    return _licenseService.generateLicenseKey(clientInfo);
  }

  Future<void> resetToDemo() async {
    await _licenseService.resetToDemo();
    await _loadLicense();
  }

  String generateDeviceId() {
    return _licenseService.generateDeviceId();
  }
}
