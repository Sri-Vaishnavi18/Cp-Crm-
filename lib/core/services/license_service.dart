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
  banned,
}

class LicenseCheckResult {
  final LicenseStatus status;
  final bool isAllowed;
  final String message;
  final DateTime? validUntil;
  final String? plan;
  final bool isOfflineGrace;
  final String? banReason;

  const LicenseCheckResult({
    required this.status,
    required this.isAllowed,
    required this.message,
    this.validUntil,
    this.plan,
    this.isOfflineGrace = false,
    this.banReason,
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
  static const String _keySupabaseUrl = 'cp_crm_supabase_url';
  static const String _keySupabaseAnonKey = 'cp_crm_supabase_anon_key';
  static const String _keyBanReason = 'cp_crm_license_ban_reason';

  // Fallback Google Apps Script Web App URL (Legacy dual-read support)
  static const String defaultSheetUrl =
      'https://script.google.com/macros/s/AKfycbwkzzhYIFaT4S8S3tYViEyIr6v9YFgJvII26dhdU7PYdPAK6v1JdmH56brJB5sRiCkKuw/exec';
  static const String defaultSupabaseUrl = 'https://hjlpaaqqykfgjzgcdgud.supabase.co';
  static const String defaultSupabaseAnonKey = 'sb_publishable_GO0L8ver0cD0NB9X-kU88w_arATLrRj';
  static const String defaultAdminPhone = '';
  static const String defaultAdminWhatsApp = '';

  /// Maximum offline grace period before requiring a compulsory internet check (8 hours)
  static const Duration maxOfflineGrace = Duration(hours: 8);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isChecking = false;

  LicenseStatus _currentStatus = LicenseStatus.active;
  DateTime? _validUntil;
  String _plan = 'Active Plan';
  DateTime? _lastVerifiedAt;
  String? _banReason;

  String _sheetUrl = defaultSheetUrl;
  String _adminPhone = defaultAdminPhone;
  String _adminWhatsApp = defaultAdminWhatsApp;

  // Supabase Configuration
  String _supabaseUrl = defaultSupabaseUrl;
  String _supabaseAnonKey = defaultSupabaseAnonKey;

  LicenseStatus get currentStatus => _currentStatus;
  bool get isAllowed => _currentStatus == LicenseStatus.active;
  DateTime? get validUntil => _validUntil;
  String get plan => _plan;
  DateTime? get lastVerifiedAt => _lastVerifiedAt;
  String? get banReason => _banReason;

  String get sheetUrl =>
      (_sheetUrl.trim().isNotEmpty && _sheetUrl.trim().startsWith('http'))
          ? _sheetUrl.trim()
          : defaultSheetUrl;

  String get adminPhone => _adminPhone;
  String get adminWhatsApp => _adminWhatsApp;
  String get supabaseUrl => _supabaseUrl;
  String get supabaseAnonKey => _supabaseAnonKey;
  bool get isChecking => _isChecking;
  bool get isSupabaseConfigured =>
      _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;

  /// Initialize and restore cached license state from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString(_keySheetUrl);
      if (storedUrl != null && storedUrl.trim().isNotEmpty && storedUrl.trim().startsWith('http')) {
        _sheetUrl = storedUrl.trim();
      } else {
        _sheetUrl = defaultSheetUrl;
        await prefs.setString(_keySheetUrl, defaultSheetUrl);
      }

      final storedSupabaseUrl = prefs.getString(_keySupabaseUrl);
      if (storedSupabaseUrl == null || storedSupabaseUrl.isEmpty || storedSupabaseUrl.contains('hjlpaaqykfgjzgcdgud.')) {
        _supabaseUrl = defaultSupabaseUrl;
        await prefs.setString(_keySupabaseUrl, defaultSupabaseUrl);
      } else {
        _supabaseUrl = storedSupabaseUrl;
      }
      final storedSupabaseAnon = prefs.getString(_keySupabaseAnonKey);
      _supabaseAnonKey = (storedSupabaseAnon != null && storedSupabaseAnon.isNotEmpty) ? storedSupabaseAnon : defaultSupabaseAnonKey;
      _adminPhone = prefs.getString(_keyAdminPhone) ?? defaultAdminPhone;
      _adminWhatsApp = prefs.getString(_keyAdminWhatsApp) ?? defaultAdminWhatsApp;
      _banReason = prefs.getString(_keyBanReason);

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
      // Continue with default active state in tests
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
  /// 2. If Supabase is configured: verifies with Supabase REST PostgREST API (ultra-fast <50ms).
  /// 3. If Supabase is not configured or query fails: falls back to Google Sheets.
  /// 4. If offline: applies offline grace period (preserving banned states).
  Future<LicenseCheckResult> verifyLicense({
    required String phone,
    String? name,
    bool force = false,
    bool isSilent = false,
  }) async {
    if (_isChecking) {
      return _buildCurrentResult();
    }
    _isChecking = true;

    try {
      final connectivityList = await Connectivity().checkConnectivity();
      final isOnline = connectivityList.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        // Priority 1: Supabase
        if (isSupabaseConfigured) {
          try {
            final result = await _fetchFromSupabase(phone, name);
            _isChecking = false;
            return result;
          } catch (e) {
            debugPrint('Supabase verification error, falling back to Sheet: $e');
          }
        }

        // Priority 2: Fallback to Google Sheet Web App
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

  /// Queries Supabase PostgREST endpoint
  Future<LicenseCheckResult> _fetchFromSupabase(String phone, [String? name]) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final queryPhone = cleanPhone.isNotEmpty ? cleanPhone : phone.trim();

    final endpoint = Uri.parse('$_supabaseUrl/rest/v1/channel_partners').replace(
      queryParameters: {
        'phone': 'eq.$queryPhone',
        'select': '*',
      },
    );

    final response = await http.get(
      endpoint,
      headers: {
        'apikey': _supabaseAnonKey,
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isNotEmpty) {
        final data = list.first as Map<String, dynamic>;
        return await _parsePartnerRecord(data);
      } else {
        // Record not found in Supabase: auto-enroll 7-day trial in Supabase
        return await registerPartner(phone: phone, name: name ?? 'Channel Partner');
      }
    } else {
      throw Exception('Supabase returned HTTP ${response.statusCode}');
    }
  }

  /// Parses record from Supabase or structured API
  Future<LicenseCheckResult> _parsePartnerRecord(Map<String, dynamic> data) async {
    final isBanned = data['is_banned'] == true || (data['status']?.toString().toUpperCase() == 'BANNED');
    final banReason = data['ban_reason']?.toString();
    final planStr = data['plan_name']?.toString() ?? data['plan']?.toString() ?? 'Standard CP Plan';
    final validUntilStr = data['valid_until']?.toString() ?? data['validUntil']?.toString();
    final statusStr = (data['status']?.toString() ?? 'ACTIVE').toUpperCase();

    DateTime? parsedExpiry;
    if (validUntilStr != null && validUntilStr.isNotEmpty) {
      parsedExpiry = DateTime.tryParse(validUntilStr);
    }

    _plan = planStr;
    _validUntil = parsedExpiry;
    _lastVerifiedAt = DateTime.now();

    // 1. Check Ban First
    if (isBanned) {
      _currentStatus = LicenseStatus.banned;
      _banReason = banReason ?? 'Account suspended by administrator.';
      await _persistState();
      return LicenseCheckResult(
        status: LicenseStatus.banned,
        isAllowed: false,
        message: 'Your account has been suspended: $_banReason',
        validUntil: parsedExpiry,
        plan: planStr,
        banReason: _banReason,
      );
    }

    _banReason = null;

    // 2. Check Expiration
    if (parsedExpiry != null && DateTime.now().isAfter(parsedExpiry)) {
      _currentStatus = LicenseStatus.expired;
      await _persistState();
      return LicenseCheckResult(
        status: LicenseStatus.expired,
        isAllowed: false,
        message:
            'Your subscription expired on ${parsedExpiry.day}/${parsedExpiry.month}/${parsedExpiry.year}. Contact Admin to renew.',
        validUntil: parsedExpiry,
        plan: planStr,
      );
    }

    // 3. Status checks
    if (statusStr == 'ACTIVE') {
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
        message: 'Your account is pending admin approval. Once approved, the app will unlock automatically.',
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
  }

  /// Pings Google Sheets Web App endpoint (Fallback)
  Future<LicenseCheckResult> _fetchFromGoogleSheet(String phone) async {
    final effectiveUrl = sheetUrl.trim();
    if (effectiveUrl.isEmpty) {
      _currentStatus = LicenseStatus.active;
      _lastVerifiedAt = DateTime.now();
      _validUntil ??= DateTime.now().add(const Duration(days: 365));
      await _persistState();
      return LicenseCheckResult(
        status: LicenseStatus.active,
        isAllowed: true,
        message: 'Demo active mode.',
        validUntil: _validUntil,
        plan: _plan,
      );
    }

    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final queryPhone = cleanPhone.isNotEmpty ? cleanPhone : '8074212851';
      final uri = Uri.parse(effectiveUrl).replace(queryParameters: {'phone': queryPhone});

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return await _parsePartnerRecord(data);
      } else {
        return _evaluateOfflineGrace();
      }
    } catch (e) {
      debugPrint('Google Sheet query error: $e');
      return _evaluateOfflineGrace();
    }
  }

  /// Registers a newly signed up Channel Partner directly to Supabase and Google Sheet
  Future<LicenseCheckResult> registerPartner({
    required String phone,
    required String name,
    String plan = '7-Day Free Trial',
    int trialDays = 7,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final validUntilDate = DateTime.now().add(Duration(days: trialDays));
    final validUntilStr = validUntilDate.toIso8601String();

    // 1. Try Supabase first
    if (isSupabaseConfigured) {
      try {
        final queryPhone = cleanPhone.isNotEmpty ? cleanPhone : phone.trim();

        // 1. Check if partner already exists in Supabase
        final checkEndpoint = Uri.parse('$_supabaseUrl/rest/v1/channel_partners').replace(
          queryParameters: {'phone': 'eq.$queryPhone', 'select': '*'},
        );
        final checkRes = await http.get(
          checkEndpoint,
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        if (checkRes.statusCode == 200) {
          final list = jsonDecode(checkRes.body) as List<dynamic>;
          if (list.isNotEmpty) {
            return await _parsePartnerRecord(list.first as Map<String, dynamic>);
          }
        }

        // 2. Insert new row
        final endpoint = Uri.parse('$_supabaseUrl/rest/v1/channel_partners');
        final response = await http.post(
          endpoint,
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation',
          },
          body: jsonEncode({
            'phone': queryPhone,
            'full_name': name.trim(),
            'status': 'ACTIVE',
            'plan_name': plan,
            'valid_until': validUntilStr,
            'is_banned': false,
            'last_active_at': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          _plan = plan;
          _validUntil = validUntilDate;
          _lastVerifiedAt = DateTime.now();
          _currentStatus = LicenseStatus.active;
          _banReason = null;
          await _persistState();

          return LicenseCheckResult(
            status: LicenseStatus.active,
            isAllowed: true,
            message: '7-Day Free Trial activated on Supabase!',
            validUntil: _validUntil,
            plan: _plan,
          );
        } else {
          debugPrint('Supabase registration status: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('Supabase self-registration error: $e');
      }
    }

    // 2. Fallback to Google Sheet
    return await registerPartnerOnSheet(
      phone: phone,
      name: name,
      plan: plan,
      trialDays: trialDays,
    );
  }

  /// Backward-compatible alias for existing code calling registerPartnerOnSheet
  Future<LicenseCheckResult> registerPartnerOnSheet({
    required String phone,
    required String name,
    String plan = '7-Day Free Trial',
    int trialDays = 7,
  }) async {
    final effectiveUrl = sheetUrl.trim();
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final validUntilDate = DateTime.now().add(Duration(days: trialDays));
    final validUntilStr =
        '${validUntilDate.year}-${validUntilDate.month.toString().padLeft(2, '0')}-${validUntilDate.day.toString().padLeft(2, '0')}';

    if (effectiveUrl.isEmpty) {
      _currentStatus = LicenseStatus.active;
      _validUntil = validUntilDate;
      _plan = plan;
      _lastVerifiedAt = DateTime.now();
      await _persistState();
      return LicenseCheckResult(
        status: LicenseStatus.active,
        isAllowed: true,
        message: '7-Day Free Trial activated!',
        validUntil: validUntilDate,
        plan: plan,
      );
    }

    try {
      final uri = Uri.parse(effectiveUrl).replace(queryParameters: {
        'action': 'register',
        'phone': cleanPhone.isNotEmpty ? cleanPhone : phone.trim(),
        'name': name.trim(),
        'status': 'Active',
        'validUntil': validUntilStr,
        'plan': plan,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statusStr = (data['status']?.toString() ?? 'ACTIVE').toUpperCase();
        final planStr = data['plan']?.toString() ?? plan;
        final resDate = data['validUntil']?.toString();
        DateTime? expiry = resDate != null ? DateTime.tryParse(resDate) : validUntilDate;

        _plan = planStr;
        _validUntil = expiry ?? validUntilDate;
        _lastVerifiedAt = DateTime.now();
        _currentStatus = statusStr == 'ACTIVE' ? LicenseStatus.active : LicenseStatus.inactive;
        await _persistState();

        return LicenseCheckResult(
          status: _currentStatus,
          isAllowed: _currentStatus == LicenseStatus.active,
          message: data['message']?.toString() ?? '7-Day Free Trial activated!',
          validUntil: _validUntil,
          plan: _plan,
        );
      }
    } catch (e) {
      debugPrint('Auto-enroll sheet error: $e');
    }

    _plan = plan;
    _validUntil = validUntilDate;
    _currentStatus = LicenseStatus.active;
    _lastVerifiedAt = DateTime.now();
    await _persistState();
    return LicenseCheckResult(
      status: LicenseStatus.active,
      isAllowed: true,
      message: '7-Day Free Trial activated!',
      validUntil: validUntilDate,
      plan: plan,
    );
  }

  /// Evaluates offline state and the 8-hour grace period
  LicenseCheckResult _evaluateOfflineGrace() {
    final now = DateTime.now();

    // Security check: If previously marked as banned, NEVER allow offline bypass!
    if (_currentStatus == LicenseStatus.banned) {
      return LicenseCheckResult(
        status: LicenseStatus.banned,
        isAllowed: false,
        message: 'Account access has been revoked: ${_banReason ?? "Suspended by admin."}',
        validUntil: _validUntil,
        plan: _plan,
        banReason: _banReason,
      );
    }

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

    final timeSinceLastCheck = now.difference(_lastVerifiedAt!);

    if (timeSinceLastCheck <= maxOfflineGrace && _currentStatus == LicenseStatus.active) {
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
        message: 'Offline mode active (Last checked ${timeSinceLastCheck.inHours}h ago).',
        validUntil: _validUntil,
        plan: _plan,
        isOfflineGrace: true,
      );
    }

    _currentStatus = LicenseStatus.verificationRequired;
    return LicenseCheckResult(
      status: LicenseStatus.verificationRequired,
      isAllowed: false,
      message:
          'Daily security check required. Please connect to mobile data or Wi-Fi for a moment to verify your license.',
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
      banReason: _banReason,
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
      if (_banReason != null) {
        await prefs.setString(_keyBanReason, _banReason!);
      } else {
        await prefs.remove(_keyBanReason);
      }
    } catch (_) {}
  }

  /// Update Supabase Configuration
  Future<void> setSupabaseConfig({required String url, required String anonKey}) async {
    _supabaseUrl = url.trim();
    _supabaseAnonKey = anonKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySupabaseUrl, _supabaseUrl);
    await prefs.setString(_keySupabaseAnonKey, _supabaseAnonKey);
  }

  /// Update Google Sheet script URL
  Future<void> setSheetUrl(String url) async {
    final trimmed = url.trim();
    _sheetUrl = (trimmed.isNotEmpty && trimmed.startsWith('http')) ? trimmed : defaultSheetUrl;
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
  Future<void> overrideStatus(LicenseStatus status, {DateTime? validUntil, String? plan, String? banReason}) async {
    _currentStatus = status;
    if (validUntil != null) _validUntil = validUntil;
    if (plan != null) _plan = plan;
    _banReason = banReason;
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
      case 'banned':
        return LicenseStatus.banned;
      case 'verificationrequired':
      case 'verification_required':
        return LicenseStatus.verificationRequired;
      default:
        return LicenseStatus.active;
    }
  }
}
