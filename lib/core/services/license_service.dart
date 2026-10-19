import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum LicenseStatus {
  active,
  inactive,
  expired,
  pending,
  verificationRequired,
}

class LicenseCheckResult {
  final LicenseStatus status;
  final bool isAllowed;
  final String message;
  final DateTime? validUntil;
  final String? plan;
  final bool isOfflineGrace;

  const LicenseCheckResult({
    required this.status,
    required this.isAllowed,
    required this.message,
    this.validUntil,
    this.plan,
    this.isOfflineGrace = false,
  });
}

class LicenseService {
  static const String _keyStatus = 'cp_crm_license_status';
  static const String _keyValidUntil = 'cp_crm_license_valid_until';
  static const String _keyPlan = 'cp_crm_license_plan';
  static const String _keyLastVerified = 'cp_crm_license_last_verified_at';
  static const String _keySheetUrl = 'cp_crm_license_sheet_url';
  static const String _keyAdminPhone = 'cp_crm_admin_phone';
  static const String _keyAdminWhatsApp = 'cp_crm_admin_whatsapp';

  // Default demo / fallback Google Apps Script Web App URL
  // Can be configured by the admin anytime via settings or code
  static const String defaultSheetUrl = '';
  static const String defaultAdminPhone = '+919014547044';
  static const String defaultAdminWhatsApp = '919014547044';

  /// Maximum offline grace period before requiring a compulsory internet check (8 hours = ~3 times/day)
  static const Duration maxOfflineGrace = Duration(hours: 8);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isChecking = false;

  LicenseStatus _currentStatus = LicenseStatus.active;
  DateTime? _validUntil;
  String _plan = 'Active Plan';
  DateTime? _lastVerifiedAt;
  String _sheetUrl = defaultSheetUrl;
  String _adminPhone = defaultAdminPhone;
  String _adminWhatsApp = defaultAdminWhatsApp;

  LicenseStatus get currentStatus => _currentStatus;
  bool get isAllowed => _currentStatus == LicenseStatus.active;
  DateTime? get validUntil => _validUntil;
  String get plan => _plan;
  DateTime? get lastVerifiedAt => _lastVerifiedAt;
  String get sheetUrl => _sheetUrl;
  String get adminPhone => _adminPhone;
  String get adminWhatsApp => _adminWhatsApp;
  bool get isChecking => _isChecking;

  /// Initialize and restore cached license state from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sheetUrl = prefs.getString(_keySheetUrl) ?? defaultSheetUrl;
      _adminPhone = prefs.getString(_keyAdminPhone) ?? defaultAdminPhone;
      _adminWhatsApp = prefs.getString(_keyAdminWhatsApp) ?? defaultAdminWhatsApp;

      final cachedStatusStr = prefs.getString(_keyStatus);
      if (cachedStatusStr != null) {
        _currentStatus = _statusFromString(cachedStatusStr);
      }

      final cachedValidUntil = prefs.getString(_keyValidUntil);
      if (cachedValidUntil != null) {
        _validUntil = DateTime.tryParse(cachedValidUntil);
      }

      _plan = prefs.getString(_keyPlan) ?? 'Active Plan';

      final cachedLastVerified = prefs.getString(_keyLastVerified);
      if (cachedLastVerified != null) {
        _lastVerifiedAt = DateTime.tryParse(cachedLastVerified);
      }
    } catch (_) {
      // In unit tests or initial storage creation, continue with default active state
    }
  }

  /// Start opportunistic listener: checks license whenever phone connects to Wi-Fi / Mobile Data
  void startOpportunisticListener({
    required String? Function()? getPhone,
    required void Function(LicenseCheckResult result) onStatusChanged,
  }) {
    try {
      _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
        final hasInternet = results.any((r) => r != ConnectivityResult.none);
        if (hasInternet) {
          final phone = getPhone?.call();
          if (phone != null && phone.trim().isNotEmpty) {
            final result = await verifyLicense(phone: phone, isSilent: true);
            onStatusChanged(result);
          }
        }
      });
    } catch (_) {}
  }

  void dispose() {
    try {
      _connectivitySubscription?.cancel();
    } catch (_) {}
  }

  /// Core verification method:
  /// 1. Checks internet connectivity.
  /// 2. If connected & sheet URL configured: pings Google Sheets Web App.
  /// 3. If no sheet URL configured: defaults to active for demo/testing until configured.
  /// 4. If offline: checks if last check was within 8 hours grace period.
  Future<LicenseCheckResult> verifyLicense({
    required String phone,
    bool force = false,
    bool isSilent = false,
  }) async {
    if (_isChecking) {
      return _buildCurrentResult();
    }
    _isChecking = true;

    try {
      // 1. Check current network connectivity
      final connectivityList = await Connectivity().checkConnectivity();
      final isOnline = connectivityList.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        // Online: verify with Google Sheet Web App
        final result = await _fetchFromGoogleSheet(phone);
        _isChecking = false;
        return result;
      } else {
        // Offline: evaluate grace period logic
        final result = _evaluateOfflineGrace();
        _isChecking = false;
        return result;
      }
    } catch (_) {
      final result = _evaluateOfflineGrace();
      _isChecking = false;
      return result;
    }
  }

  /// Pings Google Sheets Web App endpoint
  Future<LicenseCheckResult> _fetchFromGoogleSheet(String phone) async {
    // If no URL configured yet, keep active for smooth onboarding/testing
    if (_sheetUrl.trim().isEmpty) {
      _currentStatus = LicenseStatus.active;
      _lastVerifiedAt = DateTime.now();
      _validUntil ??= DateTime.now().add(const Duration(days: 365));
      await _persistState();
      return LicenseCheckResult(
        status: LicenseStatus.active,
        isAllowed: true,
        message: 'No Google Sheet URL set. Running in demo active mode.',
        validUntil: _validUntil,
        plan: _plan,
      );
    }

    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final uri = Uri.parse(_sheetUrl).replace(queryParameters: {'phone': cleanPhone});

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final statusStr = (data['status']?.toString() ?? 'ACTIVE').toUpperCase();
        final planStr = data['plan']?.toString() ?? 'Standard CP Plan';
        final validUntilStr = data['validUntil']?.toString();

        DateTime? parsedExpiry;
        if (validUntilStr != null && validUntilStr.isNotEmpty) {
          parsedExpiry = DateTime.tryParse(validUntilStr);
        }

        _plan = planStr;
        _validUntil = parsedExpiry;
        _lastVerifiedAt = DateTime.now();

        if (statusStr == 'ACTIVE') {
          // Check if subscription date is expired
          if (parsedExpiry != null && DateTime.now().isAfter(parsedExpiry)) {
            _currentStatus = LicenseStatus.expired;
            await _persistState();
            return LicenseCheckResult(
              status: LicenseStatus.expired,
              isAllowed: false,
              message: 'Your subscription expired on ${parsedExpiry.day}/${parsedExpiry.month}/${parsedExpiry.year}. Please contact Admin to renew.',
              validUntil: parsedExpiry,
              plan: planStr,
            );
          }

          _currentStatus = LicenseStatus.active;
          await _persistState();
          return LicenseCheckResult(
            status: LicenseStatus.active,
            isAllowed: true,
            message: 'Subscription is active.',
            validUntil: parsedExpiry,
            plan: planStr,
          );
        } else if (statusStr == 'PENDING') {
          _currentStatus = LicenseStatus.pending;
          await _persistState();
          return LicenseCheckResult(
            status: LicenseStatus.pending,
            isAllowed: false,
            message: 'Your account is pending admin approval. Once payment is confirmed, your app will unlock automatically.',
            validUntil: parsedExpiry,
            plan: planStr,
          );
        } else {
          _currentStatus = LicenseStatus.inactive;
          await _persistState();
          return LicenseCheckResult(
            status: LicenseStatus.inactive,
            isAllowed: false,
            message: data['message']?.toString() ?? 'Account is disabled. Please contact admin to activate.',
            validUntil: parsedExpiry,
            plan: planStr,
          );
        }
      } else {
        // Fallback to offline grace if HTTP error
        return _evaluateOfflineGrace();
      }
    } catch (e) {
      debugPrint('Google Sheet query error: $e');
      return _evaluateOfflineGrace();
    }
  }

  /// Evaluates offline state and the 8-hour (~3 times/day) grace period
  LicenseCheckResult _evaluateOfflineGrace() {
    final now = DateTime.now();

    // 1. If never verified before, allow temporary first-time access or require net
    if (_lastVerifiedAt == null) {
      _lastVerifiedAt = now;
      _currentStatus = LicenseStatus.active;
      _validUntil ??= now.add(const Duration(days: 30));
      return LicenseCheckResult(
        status: LicenseStatus.active,
        isAllowed: true,
        message: 'Initial launch grace period active.',
        validUntil: _validUntil,
        plan: _plan,
        isOfflineGrace: true,
      );
    }

    // 2. Check how long it has been since the last successful check
    final timeSinceLastCheck = now.difference(_lastVerifiedAt!);

    // If within 8 hours and was previously active: ALLOW offline use
    if (timeSinceLastCheck <= maxOfflineGrace && _currentStatus == LicenseStatus.active) {
      // Check if validUntil date was crossed
      if (_validUntil != null && now.isAfter(_validUntil!)) {
        _currentStatus = LicenseStatus.expired;
        return LicenseCheckResult(
          status: LicenseStatus.expired,
          isAllowed: false,
          message: 'Your plan has expired. Please connect to internet to renew.',
          validUntil: _validUntil,
          plan: _plan,
        );
      }

      return LicenseCheckResult(
        status: LicenseStatus.active,
        isAllowed: true,
        message: 'Offline mode active (Last checked ${(timeSinceLastCheck.inHours)}h ago).',
        validUntil: _validUntil,
        plan: _plan,
        isOfflineGrace: true,
      );
    }

    // 3. Grace period exceeded (> 8 hours offline) -> Require compulsory internet check
    _currentStatus = LicenseStatus.verificationRequired;
    return LicenseCheckResult(
      status: LicenseStatus.verificationRequired,
      isAllowed: false,
      message: 'Compulsory daily security check required. Please connect to mobile data or Wi-Fi for a moment to verify your license.',
      validUntil: _validUntil,
      plan: _plan,
    );
  }

  LicenseCheckResult _buildCurrentResult() {
    return LicenseCheckResult(
      status: _currentStatus,
      isAllowed: _currentStatus == LicenseStatus.active,
      message: _currentStatus == LicenseStatus.active ? 'Active' : 'Verification required',
      validUntil: _validUntil,
      plan: _plan,
    );
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStatus, _currentStatus.name);
      if (_validUntil != null) {
        await prefs.setString(_keyValidUntil, _validUntil!.toIso8601String());
      }
      await prefs.setString(_keyPlan, _plan);
      if (_lastVerifiedAt != null) {
        await prefs.setString(_keyLastVerified, _lastVerifiedAt!.toIso8601String());
      }
    } catch (_) {}
  }

  /// Update Google Sheet script URL
  Future<void> setSheetUrl(String url) async {
    _sheetUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySheetUrl, _sheetUrl);
  }

  /// Update Admin Contact Info
  Future<void> setAdminContact({required String phone, required String whatsApp}) async {
    _adminPhone = phone.trim();
    _adminWhatsApp = whatsApp.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdminPhone, _adminPhone);
    await prefs.setString(_keyAdminWhatsApp, _adminWhatsApp);
  }

  /// Manual override for admin testing / bypass
  Future<void> overrideStatus(LicenseStatus status, {DateTime? validUntil, String? plan}) async {
    _currentStatus = status;
    if (validUntil != null) _validUntil = validUntil;
    if (plan != null) _plan = plan;
    _lastVerifiedAt = DateTime.now();
    await _persistState();
  }

  LicenseStatus _statusFromString(String str) {
    switch (str.toLowerCase()) {
      case 'active':
        return LicenseStatus.active;
      case 'inactive':
        return LicenseStatus.inactive;
      case 'expired':
        return LicenseStatus.expired;
      case 'pending':
        return LicenseStatus.pending;
      case 'verificationrequired':
      case 'verification_required':
        return LicenseStatus.verificationRequired;
      default:
        return LicenseStatus.active;
    }
  }
}
