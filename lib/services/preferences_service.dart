import 'package:shared_preferences/shared_preferences.dart';

/// Service managing small settings and user preferences using SharedPreferences
class PreferencesService {
  static final PreferencesService instance = PreferencesService._internal();
  PreferencesService._internal();

  SharedPreferences? _prefs;

  static const String _keyIsLoggedIn = 'pref_is_logged_in';
  static const String _keyCashierName = 'pref_cashier_name';
  static const String _keyStoreName = 'pref_store_name';
  static const String _keyStoreAddress = 'pref_store_address';
  static const String _keyStorePhone = 'pref_store_phone';
  static const String _keyLastBackupDate = 'pref_last_backup_date';

  /// Initialize SharedPreferences instance
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Inject mock/testing SharedPreferences if needed
  void setPreferencesInstance(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // ==================== LOGIN STATUS ====================

  bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? true;

  Future<bool> setLoggedIn(bool value) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_keyIsLoggedIn, value);
  }

  // ==================== CASHIER / OPERATOR ====================

  String get cashierName => _prefs?.getString(_keyCashierName) ?? 'Store Admin';

  Future<bool> setCashierName(String name) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_keyCashierName, name.trim());
  }

  // ==================== STORE INFO ====================

  String get storeName => _prefs?.getString(_keyStoreName) ?? 'Melangadi Store';

  Future<bool> setStoreName(String name) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_keyStoreName, name.trim());
  }

  String get storeAddress => _prefs?.getString(_keyStoreAddress) ?? 'Stationery & General Store';

  Future<bool> setStoreAddress(String address) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_keyStoreAddress, address.trim());
  }

  String get storePhone => _prefs?.getString(_keyStorePhone) ?? '';

  Future<bool> setStorePhone(String phone) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_keyStorePhone, phone.trim());
  }

  // ==================== BACKUP TRACKING ====================

  String? get lastBackupDate => _prefs?.getString(_keyLastBackupDate);

  Future<bool> setLastBackupDate(String isoString) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_keyLastBackupDate, isoString);
  }

  // ==================== CLEAR PREFERENCES ====================

  Future<bool> clear() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }
}
