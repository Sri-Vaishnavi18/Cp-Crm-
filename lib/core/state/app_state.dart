import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/mock_data_service.dart';
import '../services/auth_storage_service.dart';
import '../services/biometric_service.dart';
import '../services/license_service.dart';

class DuplicateCheckResult {
  final bool isDuplicate;
  final String? message;
  final String? existingPartner;

  DuplicateCheckResult({
    required this.isDuplicate,
    this.message,
    this.existingPartner,
  });
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });
}

enum DashboardDatePreset {
  allTime,
  today,
  yesterday,
  last7Days,
  last30Days,
  custom,
}

class AppState extends ChangeNotifier {
  // Theme Management
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Auth State
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  List<UserModel> _savedUsers = [];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  List<UserModel> get savedUsers => _savedUsers;

  // Licensing & Subscription Control
  final LicenseService _licenseService = LicenseService();
  LicenseService get licenseService => _licenseService;
  bool get isSubscriptionActive => _licenseService.isAllowed;

  // Active Data Stores
  List<LeadModel> _leads = MockDataService.getInitialLeads();
  List<ProjectModel> _projects = MockDataService.getProjects();
  List<SiteVisitModel> _siteVisits = MockDataService.getInitialVisits();
  List<SpocModel> _spocs = MockDataService.getSpocs();
  List<CollateralModel> _collaterals = MockDataService.getCollaterals();
  List<AppNotificationModel> _notifications = MockDataService.getNotifications();
  List<CommissionInvoiceModel> _invoices = MockDataService.getInitialInvoices();
  BankDetailsModel? _savedBankDetails = MockDataService.getInitialBankDetails();
  List<CpDocumentModel> _cpDocuments = MockDataService.getInitialCpDocuments();
  List<ReceivedInvoiceModel> _receivedInvoices = MockDataService.getInitialReceivedInvoices();

  // Date Filter State
  DashboardDatePreset _dashboardDatePreset = DashboardDatePreset.allTime;
  DateTimeRange? _customDateRange;

  DashboardDatePreset get dashboardDatePreset => _dashboardDatePreset;
  DateTimeRange? get customDateRange => _customDateRange;
  bool get isDateFilterActive => _dashboardDatePreset != DashboardDatePreset.allTime;

  // Offline Simulation State
  bool _isOffline = false;
  bool get isOffline => _isOffline;
  int get offlineQueueCount => _leads.where((l) => l.isQueuedOffline).length;

  DateTime _lastSyncedAt = DateTime.now();
  DateTime get lastSyncedAt => _lastSyncedAt;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Search & Filter State
  String _leadSearchQuery = '';
  String? _leadStageFilter;
  String? _leadProjectFilter;
  String? _leadTemperatureFilter;
  String? _leadSourceFilter;

  String get leadSearchQuery => _leadSearchQuery;
  String? get leadStageFilter => _leadStageFilter;
  String? get leadProjectFilter => _leadProjectFilter;
  String? get leadTemperatureFilter => _leadTemperatureFilter;
  String? get leadSourceFilter => _leadSourceFilter;

  // Getters
  List<LeadModel> get allLeads => _leads;
  List<ProjectModel> get projects => _projects;
  List<SiteVisitModel> get siteVisits => _siteVisits;
  List<SpocModel> get spocs => _spocs;
  List<CollateralModel> get collaterals => _collaterals;
  List<AppNotificationModel> get notifications => _notifications;
  List<CommissionInvoiceModel> get allInvoices => _invoices;
  BankDetailsModel? get savedBankDetails => _savedBankDetails;
  List<CpDocumentModel> get cpDocuments => _cpDocuments;
  List<ReceivedInvoiceModel> get receivedInvoices => _receivedInvoices;

  int get missingMandatoryDocsCount =>
      _cpDocuments.where((d) => d.isMandatory && (d.status == CpDocumentStatus.missing || d.status == CpDocumentStatus.expired)).length;

  int get pendingReviewDocsCount =>
      _cpDocuments.where((d) => d.status == CpDocumentStatus.underReview).length;

  double get kycCompletionPercentage {
    final mandatory = _cpDocuments.where((d) => d.isMandatory).toList();
    if (mandatory.isEmpty) return 1.0;
    final submitted = mandatory.where((d) =>
        d.status == CpDocumentStatus.verified || d.status == CpDocumentStatus.underReview).length;
    return submitted / mandatory.length;
  }

  double get totalReceivedDisbursedAmount =>
      _receivedInvoices.fold(0.0, (acc, item) => acc + item.grossAmount);

  double get totalNetReceivedAmount =>
      _receivedInvoices.fold(0.0, (acc, item) => acc + item.netAmount);

  double get totalTdsDeductedAmount =>
      _receivedInvoices.fold(0.0, (acc, item) => acc + item.tdsAmount);

  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  // User-Scoped Storage Keys
  String get _currentUserId => _currentUser?.id ?? 'guest';
  String get _leadsStorageKey => 'persisted_leads_$_currentUserId';
  String get _invoicesStorageKey => 'persisted_invoices_$_currentUserId';
  String get _siteVisitsStorageKey => 'persisted_visits_$_currentUserId';

  // Constructor
  AppState({bool initialIsDark = false}) {
    _themeMode = initialIsDark ? ThemeMode.dark : ThemeMode.light;
    _initData();
  }

  /// Load user-scoped leads, visits, and invoices.
  /// If the user has no stored data, clean pipeline starts completely from scratch (all 0).
  /// Only default demo user ('usr_9014') loads initial sample mock leads if uninitialized.
  Future<void> _loadUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userLeadsKey = 'persisted_leads_$userId';
      final userVisitsKey = 'persisted_visits_$userId';
      final userInvoicesKey = 'persisted_invoices_$userId';

      // 1. Leads
      if (prefs.containsKey(userLeadsKey)) {
        final raw = prefs.getString(userLeadsKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _leads = decoded.map((item) => LeadModel.fromJson(item as Map<String, dynamic>)).toList();
          // Sanitize legacy mock lead_4 if stored with today's date from prior run
          final l4Idx = _leads.indexWhere((l) => l.id == 'lead_4');
          if (l4Idx != -1) {
            final l4 = _leads[l4Idx];
            final now = DateTime.now();
            if (l4.createdAt.year == now.year && l4.createdAt.month == now.month && l4.createdAt.day == now.day) {
              _leads[l4Idx] = l4.copyWith(createdAt: now.subtract(const Duration(days: 5, hours: 2)));
            }
          }
        } else {
          _leads = [];
        }
      } else {
        if (userId == 'usr_9014') {
          _leads = MockDataService.getInitialLeads();
        } else {
          _leads = [];
        }
      }

      // 2. Site Visits
      if (prefs.containsKey(userVisitsKey)) {
        final raw = prefs.getString(userVisitsKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _siteVisits = decoded.map((item) => SiteVisitModel.fromJson(item as Map<String, dynamic>)).toList();
        } else {
          _siteVisits = [];
        }
      } else {
        if (userId == 'usr_9014') {
          _siteVisits = MockDataService.getInitialVisits();
        } else {
          _siteVisits = [];
        }
      }

      // 3. Invoices
      if (prefs.containsKey(userInvoicesKey)) {
        final raw = prefs.getString(userInvoicesKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _invoices = decoded.map((item) => CommissionInvoiceModel.fromJson(item as Map<String, dynamic>)).toList();
        } else {
          _invoices = [];
        }
      } else {
        if (userId == 'usr_9014') {
          _invoices = MockDataService.getInitialInvoices();
        } else {
          _invoices = [];
        }
      }

      // 4. Notifications
      final userNotifsKey = 'persisted_notifications_$userId';
      if (prefs.containsKey(userNotifsKey)) {
        final raw = prefs.getString(userNotifsKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _notifications = decoded
              .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          _notifications = [];
        }
      } else {
        if (userId == 'usr_9014') {
          _notifications = MockDataService.getNotifications();
        } else {
          _notifications = [];
        }
      }

      // 5. Last Synced Time
      final syncKey = 'last_synced_$userId';
      if (prefs.containsKey(syncKey)) {
        final syncRaw = prefs.getString(syncKey);
        if (syncRaw != null && syncRaw.isNotEmpty) {
          _lastSyncedAt = DateTime.tryParse(syncRaw) ?? DateTime.now();
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Reset the currently active user's pipeline to a completely clean slate (all 0s).
  Future<void> resetToCleanSlate() async {
    _leads = [];
    _siteVisits = [];
    _invoices = [];
    _notifications = [];
    await _persistLeads();
    await _persistSiteVisits();
    await _persistInvoices();
    await _persistNotifications();
    notifyListeners();
  }

  /// Load sample demo leads, site visits, and invoices into the current user's pipeline.
  Future<void> loadSampleDemoData() async {
    _leads = MockDataService.getInitialLeads();
    _siteVisits = MockDataService.getInitialVisits();
    _invoices = MockDataService.getInitialInvoices();
    _notifications = MockDataService.getNotifications();
    await _persistLeads();
    await _persistSiteVisits();
    await _persistInvoices();
    await _persistNotifications();
    notifyListeners();
  }

  Future<void> _initData() async {
    _projects = MockDataService.getProjects();
    _spocs = MockDataService.getSpocs();
    _collaterals = MockDataService.getCollaterals();
    _notifications = MockDataService.getNotifications();
    _savedBankDetails = MockDataService.getInitialBankDetails();
    _cpDocuments = MockDataService.getInitialCpDocuments();
    _receivedInvoices = MockDataService.getInitialReceivedInvoices();

    // Check saved session in local device storage first
    try {
      _savedUsers = await AuthStorageService.getRegisteredUsers();
      final activeUser = await AuthStorageService.getActiveUser();
      if (activeUser != null) {
        _currentUser = activeUser;
        _isAuthenticated = true;
      } else {
        // Fresh start: do not auto-authenticate, prompt Login Screen
        _currentUser = null;
        _isAuthenticated = false;
      }
    } catch (_) {
      _currentUser = null;
      _isAuthenticated = false;
    }

    // Load active user's pipeline data (scoped by user ID)
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.id);
    } else {
      // In unauthenticated context (e.g. unit test runner without login), provide mock data
      _leads = MockDataService.getInitialLeads();
      _siteVisits = MockDataService.getInitialVisits();
      _invoices = MockDataService.getInitialInvoices();
    }

    // Load persisted projects if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsRaw = prefs.getString('persisted_projects');
      if (projectsRaw != null && projectsRaw.isNotEmpty) {
        final decoded = jsonDecode(projectsRaw) as List<dynamic>;
        final stored = decoded.map((item) => ProjectModel.fromJson(item as Map<String, dynamic>)).toList();
        if (stored.isNotEmpty) {
          for (final proj in stored) {
            if (!_projects.any((p) => p.id == proj.id)) {
              _projects.insert(0, proj);
            }
          }
        }
      }
    } catch (_) {}

    // Load saved bank details and documents from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final bankRaw = prefs.getString('saved_bank_details');
      if (bankRaw != null && bankRaw.isNotEmpty) {
        _savedBankDetails = BankDetailsModel.fromJson(jsonDecode(bankRaw));
      }

      final docsRaw = prefs.getString('persisted_cp_documents');
      if (docsRaw != null && docsRaw.isNotEmpty) {
        final decoded = jsonDecode(docsRaw) as List<dynamic>;
        final stored = decoded.map((item) => CpDocumentModel.fromJson(item as Map<String, dynamic>)).toList();
        if (stored.isNotEmpty) {
          const legacyMockFiles = {
            'rera_agent_cert_2024.pdf',
            'cp_pan_card.jpg',
            'gstin_certificate_reg06.pdf',
            'authorized_id_proof.jpg',
            'signed_developer_mou_2024.pdf',
            'cancelled_cheque_hdfc.jpg',
            'Attach document (PDF, PNG, JPG)',
          };
          _cpDocuments = stored.map((doc) {
            if (doc.fileName != null && legacyMockFiles.contains(doc.fileName)) {
              return CpDocumentModel(
                id: doc.id,
                type: doc.type,
                title: doc.title,
                documentNumber: '',
                fileName: null,
                fileSize: null,
                uploadedAt: null,
                expiresAt: null,
                status: CpDocumentStatus.missing,
                isMandatory: doc.isMandatory,
                remarks: 'Pending document upload and verification.',
              );
            }
            return doc;
          }).toList();
        }
      }

      final recRaw = prefs.getString('persisted_received_invoices');
      if (recRaw != null && recRaw.isNotEmpty) {
        final decoded = jsonDecode(recRaw) as List<dynamic>;
        final stored = decoded.map((item) => ReceivedInvoiceModel.fromJson(item as Map<String, dynamic>)).toList();
        if (stored.isNotEmpty) {
          _receivedInvoices = stored;
        }
      }
    } catch (_) {}

    // Load saved theme preference
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('is_dark_mode')) {
        final isDark = prefs.getBool('is_dark_mode')!;
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}

    // Initialize Licensing Service & Start Opportunistic Listener
    try {
      await _licenseService.init();
      _licenseService.startOpportunisticListener(
        getPhone: () => _currentUser?.phone,
        onStatusChanged: (result) {
          notifyListeners();
        },
      );
      if (_currentUser != null) {
        _licenseService.verifyLicense(phone: _currentUser!.phone, isSilent: true).then((_) {
          notifyListeners();
        });
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> refreshSavedUsers() async {
    _savedUsers = await AuthStorageService.getRegisteredUsers();
    notifyListeners();
  }

  // Theme Toggler
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
    } catch (_) {}
  }

  // Authentication Actions
  Future<AuthResult> login({required String identifier, required String password}) async {
    if (identifier.trim().isEmpty) {
      return AuthResult(success: false, errorMessage: 'Please enter your registered mobile number or email.');
    }
    if (password.trim().isEmpty) {
      return AuthResult(success: false, errorMessage: 'Please enter your password.');
    }

    final user = await AuthStorageService.authenticate(
      identifier: identifier,
      password: password,
    );

    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      _savedUsers = await AuthStorageService.getRegisteredUsers();
      await _licenseService.verifyLicense(phone: user.phone);
      await _loadUserData(user.id);
      notifyListeners();
      return AuthResult(success: true, user: user);
    }

    final isRegistered = await AuthStorageService.isIdentifierRegistered(identifier);
    if (!isRegistered) {
      return AuthResult(
        success: false,
        errorMessage: 'Account not found for "$identifier". Tap "Register Firm" to create your CP/SP account on this device.',
      );
    }

    return AuthResult(
      success: false,
      errorMessage: 'Invalid credentials. Please verify your password.',
    );
  }

  Future<AuthResult> biometricLogin() async {
    final bool didAuthenticate = await BiometricService.authenticate(
      reason: 'Scan Face ID or Fingerprint to unlock CP CRM',
    );
    if (!didAuthenticate) {
      return AuthResult(
        success: false,
        errorMessage: 'Biometric verification cancelled or not recognized.',
      );
    }

    final users = await AuthStorageService.getRegisteredUsers();
    if (users.isNotEmpty) {
      final user = _currentUser ?? users.first;
      await AuthStorageService.setActiveSession(user.id);
      _currentUser = user;
      _isAuthenticated = true;
      await _licenseService.verifyLicense(phone: user.phone);
      await _loadUserData(user.id);
      notifyListeners();
      return AuthResult(success: true, user: user);
    }
    return AuthResult(success: false, errorMessage: 'No registered CP accounts found on this device.');
  }

  Future<AuthResult> register({
    required String name,
    required String firmName,
    required String reraNumber,
    required String phone,
    required String email,
    required String city,
    required bool isAgency,
    required String password,
  }) async {
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      firmName: isAgency ? firmName.trim() : name.trim(),
      reraNumber: reraNumber.trim().toUpperCase(),
      phone: phone.trim(),
      email: email.trim(),
      city: city.trim(),
      isAgency: isAgency,
      password: password,
      registeredAt: DateTime.now(),
    );

    final saved = await AuthStorageService.registerUser(newUser);
    _currentUser = saved;
    _isAuthenticated = true;
    _savedUsers = await AuthStorageService.getRegisteredUsers();
    await _licenseService.verifyLicense(phone: saved.phone);

    // New registered account starts completely clean from scratch
    _leads = [];
    _siteVisits = [];
    _invoices = [];
    await _persistLeads();
    await _persistSiteVisits();
    await _persistInvoices();

    // Trigger welcoming notification
    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Welcome to CP CRM! 🏢',
        message: 'Account registered for ${saved.firmName}. Zero-OTP lock active.',
        type: 'broadcast',
        timestamp: DateTime.now(),
      ),
    );
    await _persistNotifications();

    notifyListeners();
    return AuthResult(success: true, user: saved);
  }

  Future<void> switchUser(String userId) async {
    final users = await AuthStorageService.getRegisteredUsers();
    final target = users.firstWhere((u) => u.id == userId, orElse: () => users.first);
    await AuthStorageService.setActiveSession(target.id);
    _currentUser = target;
    _isAuthenticated = true;
    await _licenseService.verifyLicense(phone: target.phone);
    await _loadUserData(target.id);
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthStorageService.clearActiveSession();
    _currentUser = null;
    _isAuthenticated = false;
    _leads = [];
    _siteVisits = [];
    _invoices = [];
    _notifications = [];
    notifyListeners();
  }

  Future<LicenseCheckResult> checkSubscription({bool force = false}) async {
    final phone = _currentUser?.phone ?? '';
    final result = await _licenseService.verifyLicense(phone: phone, force: force);
    notifyListeners();
    return result;
  }

  Future<void> updateLicenseConfig({required String sheetUrl, required String phone, required String whatsApp}) async {
    await _licenseService.setSheetUrl(sheetUrl);
    await _licenseService.setAdminContact(phone: phone, whatsApp: whatsApp);
    notifyListeners();
  }

  Future<void> overrideLicenseStatus(LicenseStatus status, {DateTime? validUntil, String? plan}) async {
    await _licenseService.overrideStatus(status, validUntil: validUntil, plan: plan);
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _licenseService.dispose();
    super.dispose();
  }

  // Offline Simulation
  void toggleOfflineMode() {
    _isOffline = !_isOffline;
    if (!_isOffline) {
      // Auto-sync queued offline leads
      syncOfflineQueue();
    }
    notifyListeners();
  }

  int syncOfflineQueue() {
    int syncedCount = 0;
    final now = DateTime.now();

    for (int i = 0; i < _leads.length; i++) {
      if (_leads[i].isQueuedOffline) {
        _leads[i] = LeadModel(
          id: _leads[i].id,
          firstName: _leads[i].firstName,
          lastName: _leads[i].lastName,
          phone: _leads[i].phone,
          altPhone: _leads[i].altPhone,
          email: _leads[i].email,
          budget: _leads[i].budget,
          configurations: _leads[i].configurations,
          projectId: _leads[i].projectId,
          projectName: _leads[i].projectName,
          timeline: _leads[i].timeline,
          notes: _leads[i].notes,
          stage: _leads[i].stage,
          temperature: _leads[i].temperature,
          source: _leads[i].source,
          createdAt: _leads[i].createdAt,
          isQueuedOffline: false,
          notesList: _leads[i].notesList,
          activityList: [
            LeadActivityItem(
              id: 'act_${now.microsecondsSinceEpoch}_$i',
              title: 'Offline lead synced to central cloud server',
              timestamp: now,
            ),
            ..._leads[i].activityList,
          ],
        );
        syncedCount++;
      }
    }

    if (syncedCount > 0) {
      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${now.microsecondsSinceEpoch}',
          title: 'Cloud Sync Complete! ☁️',
          message: '$syncedCount offline lead(s) successfully synchronized with the central cloud database.',
          type: 'lead',
          timestamp: now,
        ),
      );
      _persistLeads();
      _persistNotifications();
    }

    notifyListeners();
    return syncedCount;
  }

  Future<int> triggerCloudSync() async {
    _isSyncing = true;
    notifyListeners();

    // Realistic brief sync delay for tactile UI feedback
    await Future.delayed(const Duration(milliseconds: 600));

    final count = syncOfflineQueue();
    _lastSyncedAt = DateTime.now();
    _isSyncing = false;

    final uid = _currentUser?.id;
    if (uid != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_synced_$uid', _lastSyncedAt.toIso8601String());
      } catch (_) {}
    }

    notifyListeners();
    return count;
  }

  // Algorithmic Duplicate Check (Zero-OTP)
  DuplicateCheckResult checkLeadDuplicate(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check known conflict phone numbers for demonstration or existing leads
    if (cleanPhone == '9999999999' || cleanPhone == '9888888888') {
      return DuplicateCheckResult(
        isDuplicate: true,
        message: 'Conflict Detected: Phone number +91 $cleanPhone is currently active under another Channel Partner (RERA: PRM/KA/1014) within the 60-day protection window.',
        existingPartner: 'SquareSpace Realty',
      );
    }

    final exists = _leads.any((l) => l.phone.replaceAll(RegExp(r'[^\d]'), '') == cleanPhone);
    if (exists) {
      return DuplicateCheckResult(
        isDuplicate: true,
        message: 'Lead already exists in your active pipeline. You can view or update their stage directly.',
        existingPartner: _currentUser?.firmName ?? 'Your Agency',
      );
    }

    return DuplicateCheckResult(isDuplicate: false);
  }

  // Add Lead
  bool addLead({
    required String firstName,
    required String lastName,
    required String phone,
    String? altPhone,
    String? email,
    required String budget,
    required List<String> configurations,
    required String projectId,
    required String projectName,
    required String timeline,
    required String notes,
    LeadTemperature? temperature,
    String source = 'CHANNEL_PARTNER',
  }) {
    final computedTemp = temperature ?? LeadTemperature.cold;
    final now = DateTime.now();
    final randomSalt = Random().nextInt(999999);
    final uniqueLeadId = 'lead_${now.microsecondsSinceEpoch}_$randomSalt';

    final newLead = LeadModel(
      id: uniqueLeadId,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      altPhone: altPhone,
      email: email,
      budget: budget,
      configurations: configurations,
      projectId: projectId,
      projectName: projectName,
      timeline: timeline,
      notes: notes,
      stage: LeadStage.cold,
      temperature: computedTemp,
      source: source,
      createdAt: now,
      isQueuedOffline: _isOffline,
      notesList: notes.trim().isNotEmpty
          ? [
              LeadNoteItem(
                id: 'note_${now.microsecondsSinceEpoch}_$randomSalt',
                text: notes.trim(),
                author: _currentUser?.name ?? 'You',
                createdAt: now,
              )
            ]
          : [],
      activityList: [
        LeadActivityItem(
          id: 'act_${now.microsecondsSinceEpoch}_$randomSalt',
          title: 'Lead registered under ${_currentUser?.firmName ?? "Channel Partner"} (Zero-OTP protection locked)',
          timestamp: now,
        ),
      ],
    );

    _leads.insert(0, newLead);
    _persistLeads();

    // Also trigger notification
    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Lead Registered: $firstName $lastName',
        message: 'Zero-OTP protection locked under ${_currentUser?.firmName ?? "your agency"} for 60 days.',
        type: 'lead',
        timestamp: DateTime.now(),
        targetRoute: '/leads',
        targetId: newLead.id,
      ),
    );

    _persistNotifications();
    notifyListeners();
    return true;
  }

  Future<void> _persistLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _leadsStorageKey,
        jsonEncode(_leads.map((l) => l.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _persistSiteVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _siteVisitsStorageKey,
        jsonEncode(_siteVisits.map((v) => v.toJson()).toList()),
      );
    } catch (_) {}
  }

  // Bulk Import Leads
  int bulkImportLeads(List<LeadImportRow> validRows) {
    if (validRows.isEmpty) return 0;
    final now = DateTime.now();
    int importedCount = 0;

    for (int i = 0; i < validRows.length; i++) {
      final row = validRows[i];
      if (!row.isValid || row.isDuplicate) continue;

      final lead = LeadModel(
        id: 'lead_${now.millisecondsSinceEpoch}_$i',
        firstName: row.firstName,
        lastName: row.lastName,
        phone: row.phone,
        email: row.email,
        budget: row.budget,
        configurations: row.configurations,
        projectId: row.projectId,
        projectName: row.projectName,
        timeline: 'Immediate (0-30 Days)',
        notes: 'Bulk Imported on ${now.day}/${now.month}/${now.year}',
        stage: LeadStage.cold,
        temperature: LeadTemperature.cold,
        source: row.source,
        createdAt: now,
        isQueuedOffline: _isOffline,
        notesList: [
          LeadNoteItem(
            id: 'note_${now.millisecondsSinceEpoch}_$i',
            text: 'Bulk imported via CSV upload into ${row.projectName}',
            author: _currentUser?.name ?? 'You',
            createdAt: now,
          ),
        ],
        activityList: [
          LeadActivityItem(
            id: 'act_${now.millisecondsSinceEpoch}_$i',
            title: 'Lead imported via Bulk CSV Upload (Zero-OTP protection locked)',
            timestamp: now,
          ),
        ],
      );

      _leads.insert(0, lead);
      importedCount++;
    }

    if (importedCount > 0) {
      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${now.millisecondsSinceEpoch}',
          title: '📥 Bulk Lead Import Completed ($importedCount Leads)',
          message: 'Successfully imported $importedCount leads into active pipeline with Zero-OTP exclusivity locked.',
          type: 'lead',
          timestamp: now,
          targetRoute: '/leads',
        ),
      );
      _persistNotifications();
      notifyListeners();
    }

    return importedCount;
  }

  // Add a New Project
  void addProject(ProjectModel project) {
    _projects.insert(0, project);

    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: '🏢 New Project Added: ${project.name}',
        message: '${project.name} in ${project.location} is now live with ${project.units.length} inventory units.',
        type: 'broadcast',
        timestamp: DateTime.now(),
        targetRoute: '/projects',
        targetId: project.id,
      ),
    );

    _persistNotifications();
    notifyListeners();
    _persistProjects();
  }

  // Bulk Import Units for a Project
  int bulkImportUnits(String projectId, List<UnitModel> newUnits) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx == -1 || newUnits.isEmpty) return 0;

    final project = _projects[idx];
    int addedCount = 0;

    for (final unit in newUnits) {
      // Deduplicate unit number within same project
      final exists = project.units.any((u) => u.unitNo.trim().toUpperCase() == unit.unitNo.trim().toUpperCase());
      if (!exists) {
        project.units.add(unit);
        addedCount++;
      }
    }

    // Update project starting price if lower priced available unit found
    final availablePrices = project.units
        .where((u) => u.status == UnitStatus.available && u.basePrice > 0)
        .map((u) => u.basePrice)
        .toList();
    if (availablePrices.isNotEmpty) {
      availablePrices.sort();
      final minPrice = availablePrices.first;
      if (minPrice >= 10000000) {
        project.startingPrice = '${(minPrice / 10000000).toStringAsFixed(2)} Cr';
      } else {
        project.startingPrice = '${(minPrice / 100000).toStringAsFixed(0)} L';
      }
    }

    if (addedCount > 0) {
      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: '📦 Inventory Units Updated: ${project.name}',
          message: 'Added $addedCount new units to inventory matrix for ${project.name}.',
          type: 'broadcast',
          timestamp: DateTime.now(),
          targetRoute: '/projects',
          targetId: project.id,
        ),
      );
      _persistNotifications();
      notifyListeners();
      _persistProjects();
    }

    return addedCount;
  }

  void updateLeadStage(String leadId, LeadStage newStage) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      lead.stage = newStage;
      // Automatically cascade lead temperature based on stage
      lead.temperature = LeadModel.getTemperatureForStage(newStage);

      final now = DateTime.now();
      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${now.microsecondsSinceEpoch}',
          title: 'lead status updated to ${newStage.displayName}',
          timestamp: now,
        ),
      );

      String notifTitle;
      String notifMessage;
      String notifType = 'lead';

      switch (newStage) {
        case LeadStage.siteVisited:
          notifTitle = 'Site Visit Completed: ${lead.fullName}';
          notifMessage = '${lead.fullName} completed site visit for ${lead.projectName}. Follow up to close booking token!';
          notifType = 'visit';
          break;
        case LeadStage.booked:
          notifTitle = '🎉 Booking Confirmed: ${lead.fullName}!';
          notifMessage = 'Booking locked for ${lead.projectName}! Payout claim is now unlocked.';
          notifType = 'lead';
          break;
        case LeadStage.cold:
          notifTitle = 'Lead Stage Updated: ${lead.fullName}';
          notifMessage = 'Status updated to ${newStage.displayName} on ${lead.projectName}.';
          notifType = 'lead';
          break;
      }

      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${now.microsecondsSinceEpoch}',
          title: notifTitle,
          message: notifMessage,
          type: notifType,
          timestamp: now,
          targetRoute: '/leads',
          targetId: lead.id,
        ),
      );

      _persistLeads();
      _persistNotifications();
      notifyListeners();
    }
  }

  void updateLeadTemperature(String leadId, LeadTemperature newTemperature) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      lead.temperature = newTemperature;

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${DateTime.now().microsecondsSinceEpoch}',
          title: 'lead temperature updated to ${newTemperature.displayName.toUpperCase()}',
          timestamp: DateTime.now(),
        ),
      );

      _persistLeads();
      notifyListeners();
    }
  }

  void addLeadNote(String leadId, String noteText) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1 && noteText.trim().isNotEmpty) {
      final lead = _leads[index];
      final now = DateTime.now();
      lead.notesList.insert(
        0,
        LeadNoteItem(
          id: 'note_${now.microsecondsSinceEpoch}',
          text: noteText.trim(),
          author: _currentUser?.name ?? 'You',
          createdAt: now,
        ),
      );

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${now.microsecondsSinceEpoch}',
          title: 'New note added',
          timestamp: now,
        ),
      );

      _persistLeads();
      notifyListeners();
    }
  }

  void updateLeadInfo({
    required String leadId,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String projectId,
    required String projectName,
    required String source,
    required String budget,
    String? timeline,
  }) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      lead.firstName = firstName;
      lead.lastName = lastName;
      lead.phone = phone;
      lead.email = email;
      lead.projectId = projectId;
      lead.projectName = projectName;
      lead.source = source;
      lead.budget = budget;
      if (timeline != null && timeline.isNotEmpty) {
        lead.timeline = timeline;
      }

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${DateTime.now().microsecondsSinceEpoch}',
          title: 'Lead information updated',
          timestamp: DateTime.now(),
        ),
      );

      _persistLeads();
      notifyListeners();
    }
  }

  // Filtered Leads
  List<LeadModel> get filteredLeads {
    return _leads.where((lead) {
      final query = _leadSearchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          lead.fullName.toLowerCase().contains(query) ||
          lead.phone.contains(query) ||
          (lead.email != null && lead.email!.toLowerCase().contains(query)) ||
          lead.projectName.toLowerCase().contains(query) ||
          lead.source.toLowerCase().contains(query);

      final matchesStage = _leadStageFilter == null ||
          _leadStageFilter == 'ALL' ||
          lead.stage.displayName.toUpperCase() == _leadStageFilter!.toUpperCase();

      final matchesProject = _leadProjectFilter == null ||
          _leadProjectFilter == 'ALL' ||
          lead.projectId == _leadProjectFilter;

      final matchesTemperature = _leadTemperatureFilter == null ||
          _leadTemperatureFilter == 'ALL' ||
          lead.temperature.name.toUpperCase() == _leadTemperatureFilter!.toUpperCase() ||
          lead.temperature.displayName.toUpperCase() == _leadTemperatureFilter!.toUpperCase();

      final matchesSource = _leadSourceFilter == null ||
          _leadSourceFilter == 'ALL' ||
          lead.source.toLowerCase() == _leadSourceFilter!.toLowerCase();

      return matchesSearch && matchesStage && matchesProject && matchesTemperature && matchesSource;
    }).toList();
  }

  void setLeadSearch(String query) {
    _leadSearchQuery = query;
    notifyListeners();
  }

  void setLeadFilters({
    String? stage,
    String? project,
    String? temperature,
    String? source,
  }) {
    if (stage != null) _leadStageFilter = stage;
    if (project != null) _leadProjectFilter = project;
    if (temperature != null) _leadTemperatureFilter = temperature;
    if (source != null) _leadSourceFilter = source;
    notifyListeners();
  }

  void resetLeadFilters() {
    _leadSearchQuery = '';
    _leadStageFilter = null;
    _leadProjectFilter = null;
    _leadTemperatureFilter = null;
    _leadSourceFilter = null;
    notifyListeners();
  }

  // Site Visits
  String scheduleSiteVisit({
    required String leadId,
    required String projectId,
    required DateTime scheduledAt,
    required bool cabRequired,
    required bool accompanying,
  }) {
    final lead = _leads.firstWhere((l) => l.id == leadId, orElse: () => _leads.first);
    final project = _projects.firstWhere((p) => p.id == projectId, orElse: () => _projects.first);
    final visitCode = 'VIS-${(1000 + _siteVisits.length + 1)}';

    final visit = SiteVisitModel(
      id: 'vis_${DateTime.now().microsecondsSinceEpoch}',
      visitCode: visitCode,
      leadId: leadId,
      clientName: lead.fullName,
      clientPhone: lead.phone,
      projectId: projectId,
      projectName: project.name,
      scheduledAt: scheduledAt,
      cabRequired: cabRequired,
      accompanying: accompanying,
      status: 'SCHEDULED',
    );

    _siteVisits.insert(0, visit);

    // Update lead temperature
    lead.temperature = LeadModel.getTemperatureForStage(lead.stage);

    // Add visit history log and activity (Zero-OTP)
    final dateStr = '${scheduledAt.year}-${scheduledAt.month.toString().padLeft(2, '0')}-${scheduledAt.day.toString().padLeft(2, '0')}';
    final timeStr = '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    lead.siteVisitHistory.insert(
      0,
      'Scheduled site visit for $dateStr at $timeStr.',
    );

    lead.activityList.insert(
      0,
      LeadActivityItem(
        id: 'act_${DateTime.now().microsecondsSinceEpoch}',
        title: 'site visit status updated to SCHEDULED',
        timestamp: DateTime.now(),
      ),
    );

    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Visit Scheduled: $visitCode',
        message: 'Digital entry pass generated for ${lead.fullName} at ${project.name}.',
        type: 'visit',
        timestamp: DateTime.now(),
        targetRoute: '/visits',
        targetId: visit.id,
      ),
    );

    _persistSiteVisits();
    _persistLeads();
    _persistNotifications();
    notifyListeners();
    return visitCode;
  }

  void markVisitCheckedIn(String visitId) {
    final index = _siteVisits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _siteVisits[index].status = 'CHECKED_IN';
      
      // Also update lead stage to siteVisited and temperature to warm
      final lead = _leads.firstWhere((l) => l.id == _siteVisits[index].leadId, orElse: () => _leads.first);
      lead.stage = LeadStage.siteVisited;
      lead.temperature = LeadModel.getTemperatureForStage(LeadStage.siteVisited);

      // Add direct Zero-OTP check-in history log
      lead.siteVisitHistory.insert(
        0,
        'Site visit completed & verified directly. Accompanied by CP: ${_currentUser?.name ?? "Partner"}',
      );

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${DateTime.now().microsecondsSinceEpoch}',
          title: 'site visit status updated to COMPLETED',
          timestamp: DateTime.now(),
        ),
      );

      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
          title: 'Client Checked-in at Site! 📍',
          message: '${_siteVisits[index].clientName} checked in at ${_siteVisits[index].projectName}. Priority entry pass verified.',
          type: 'visit',
          timestamp: DateTime.now(),
        ),
      );

      _persistSiteVisits();
      _persistLeads();
      _persistNotifications();
      notifyListeners();
    }
  }

  // 24-Hour Temporary Unit Hold
  bool requestUnitHold({
    required String projectId,
    required String unitNo,
    required String leadId,
    required String notes,
  }) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final unitIndex = project.units.indexWhere((u) => u.unitNo == unitNo);

    if (unitIndex != -1 && project.units[unitIndex].status == UnitStatus.available) {
      project.units[unitIndex].status = UnitStatus.blocked;
      project.units[unitIndex].holdExpiresAt = '24h 00m left';

      final lead = _leads.firstWhere((l) => l.id == leadId, orElse: () => _leads.first);

      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Unit Hold Approved: $unitNo',
          message: 'Unit $unitNo in ${project.name} is placed on 24-hr hold for ${lead.fullName}.',
          type: 'broadcast',
          timestamp: DateTime.now(),
          targetRoute: '/projects',
          targetId: projectId,
        ),
      );

      _persistNotifications();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Notifications
  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      _persistNotifications();
    }
  }

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    _persistNotifications();
  }

  // Date Filter Actions
  void setDashboardDatePreset(DashboardDatePreset preset) {
    _dashboardDatePreset = preset;
    if (preset != DashboardDatePreset.custom) {
      _customDateRange = null;
    }
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange range) {
    _dashboardDatePreset = DashboardDatePreset.custom;
    _customDateRange = range;
    notifyListeners();
  }

  void resetDashboardDateFilter() {
    _dashboardDatePreset = DashboardDatePreset.allTime;
    _customDateRange = null;
    notifyListeners();
  }

  bool isDateInActiveRange(DateTime date) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (_dashboardDatePreset) {
      case DashboardDatePreset.allTime:
        return true;
      case DashboardDatePreset.today:
        return !date.isBefore(todayStart) && !date.isAfter(todayEnd);
      case DashboardDatePreset.yesterday:
        final yDate = now.subtract(const Duration(days: 1));
        final yesterdayStart = DateTime(yDate.year, yDate.month, yDate.day);
        final yesterdayEnd = DateTime(yDate.year, yDate.month, yDate.day, 23, 59, 59, 999);
        return !date.isBefore(yesterdayStart) && !date.isAfter(yesterdayEnd);
      case DashboardDatePreset.last7Days:
        final d7 = now.subtract(const Duration(days: 6));
        final start7Days = DateTime(d7.year, d7.month, d7.day);
        return !date.isBefore(start7Days) && !date.isAfter(todayEnd);
      case DashboardDatePreset.last30Days:
        final d30 = now.subtract(const Duration(days: 29));
        final start30Days = DateTime(d30.year, d30.month, d30.day);
        return !date.isBefore(start30Days) && !date.isAfter(todayEnd);
      case DashboardDatePreset.custom:
        if (_customDateRange == null) return true;
        final customStart = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final customEnd = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
          999,
        );
        return !date.isBefore(customStart) && !date.isAfter(customEnd);
    }
  }

  String get dateFilterLabel {
    switch (_dashboardDatePreset) {
      case DashboardDatePreset.allTime:
        return 'All Time';
      case DashboardDatePreset.today:
        return 'Today';
      case DashboardDatePreset.yesterday:
        return 'Yesterday';
      case DashboardDatePreset.last7Days:
        return 'Last 7 Days';
      case DashboardDatePreset.last30Days:
        return 'Last 30 Days';
      case DashboardDatePreset.custom:
        if (_customDateRange == null) return 'Custom Range';
        return '${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}';
    }
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  // Date-Filtered Data Sets
  List<LeadModel> get dashboardLeads {
    if (_dashboardDatePreset == DashboardDatePreset.allTime) return _leads;
    return _leads.where((l) => isDateInActiveRange(l.createdAt)).toList();
  }

  List<SiteVisitModel> get dashboardSiteVisits {
    if (_dashboardDatePreset == DashboardDatePreset.allTime) return _siteVisits;
    return _siteVisits.where((v) => isDateInActiveRange(v.scheduledAt)).toList();
  }

  List<CommissionInvoiceModel> get dashboardInvoices {
    if (_dashboardDatePreset == DashboardDatePreset.allTime) return _invoices;
    return _invoices.where((inv) => isDateInActiveRange(inv.date)).toList();
  }

  double get dashboardTotalCommissionEarned =>
      dashboardInvoices.fold(0.0, (sum, inv) => sum + inv.amount);

  int get dashboardInvoicesCount => dashboardInvoices.length;

  double get dashboardPendingCommissionAmount =>
      dashboardInvoices.where((inv) => inv.status == InvoiceStatus.pending || inv.status == InvoiceStatus.approved).fold(0.0, (sum, inv) => sum + inv.amount);

  double get dashboardPaidCommissionAmount =>
      dashboardInvoices.where((inv) => inv.status == InvoiceStatus.paid).fold(0.0, (sum, inv) => sum + inv.amount);

  // Dynamic Date-Filtered KPI Calculations
  int get totalLeadsCount => dashboardLeads.length;
  int get coldLeadsCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.cold).length;
  int get activeLeadsCount =>
      dashboardLeads.where((l) => l.stage != LeadStage.booked).length;
  int get siteVisitedLeadsCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.siteVisited).length;
  int get visitsScheduledCount =>
      dashboardSiteVisits.where((v) => v.status == 'SCHEDULED').length;
  int get visitsCompletedCount =>
      dashboardSiteVisits.where((v) => v.status == 'COMPLETED' || v.status == 'CHECKED_IN').length;
  int get bookingsCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.booked).length;
  int get bookedLeadsCount => bookingsCount;

  // Dynamic Funnel Calculations
  int get funnelColdLeadsCount => coldLeadsCount;
  int get funnelSiteVisitedCount => siteVisitedLeadsCount;
  int get funnelBookingsCount => bookedLeadsCount;

  // Commission & Invoices Management
  List<CommissionInvoiceModel> getInvoicesForLead(String leadId) {
    return _invoices.where((inv) => inv.leadId == leadId).toList();
  }

  double get totalCommissionClaimed =>
      _invoices.fold(0.0, (sum, inv) => sum + inv.amount);

  double get totalCommissionEarned => totalCommissionClaimed;

  int get totalInvoicesCount => _invoices.length;

  double get pendingCommissionAmount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.pending || inv.status == InvoiceStatus.approved).fold(0.0, (sum, inv) => sum + inv.amount);

  double get paidCommissionAmount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.paid).fold(0.0, (sum, inv) => sum + inv.amount);

  double get siteVisitCommissionTotal =>
      _invoices.where((inv) => inv.type == InvoiceType.siteVisit).fold(0.0, (sum, inv) => sum + inv.amount);

  double get bookingCommissionTotal =>
      _invoices.where((inv) => inv.type == InvoiceType.booking).fold(0.0, (sum, inv) => sum + inv.amount);

  // Formatter for Indian Rupee Amounts (e.g. ₹6,000, ₹1,88,000, ₹1,94,000)
  static String formatCurrency(double amount) {
    final intVal = amount.toInt();
    final str = intVal.abs().toString();
    final prefix = amount < 0 ? '-₹' : '₹';
    if (str.length <= 3) return '$prefix$str';
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '$prefix${buffer.toString()},$last3';
  }

  // Commission Analytics (Format as INR Lakhs or standard amount)
  String get commissionPendingFormatted {
    if (pendingCommissionAmount >= 100000) {
      return '₹${(pendingCommissionAmount / 100000).toStringAsFixed(2)} Lakhs';
    } else if (pendingCommissionAmount > 0) {
      return '₹${pendingCommissionAmount.toStringAsFixed(0)}';
    }
    return '₹0';
  }

  String get commissionReceivedFormatted {
    if (paidCommissionAmount >= 100000) {
      return '₹${(paidCommissionAmount / 100000).toStringAsFixed(2)} Lakhs';
    } else if (paidCommissionAmount > 0) {
      return '₹${paidCommissionAmount.toStringAsFixed(0)}';
    }
    return '₹0';
  }

  CommissionInvoiceModel submitCommissionInvoice({
    required String leadId,
    required InvoiceType type,
    required double amount,
    required BankDetailsModel bankDetails,
    String? notes,
  }) {
    final lead = _leads.firstWhere((l) => l.id == leadId, orElse: () => _leads.first);
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.year}-${(1000 + _invoices.length + 1)}';

    final invoice = CommissionInvoiceModel(
      id: 'inv_${now.millisecondsSinceEpoch}',
      invoiceNumber: invoiceNumber,
      leadId: lead.id,
      clientName: lead.fullName,
      clientPhone: lead.phone,
      projectId: lead.projectId,
      projectName: lead.projectName,
      type: type,
      amount: amount,
      date: now,
      status: InvoiceStatus.pending,
      bankDetails: bankDetails,
      notes: notes,
    );

    _invoices.insert(0, invoice);
    _savedBankDetails = bankDetails;

    // Log Activity on Lead
    final typeName = type == InvoiceType.siteVisit ? 'Site Visit Payout' : 'Booking Commission';
    final formattedAmt = amount >= 100000
        ? '₹${(amount / 100000).toStringAsFixed(2)} Lakhs'
        : '₹${amount.toStringAsFixed(0)}';

    lead.activityList.insert(
      0,
      LeadActivityItem(
        id: 'act_${now.millisecondsSinceEpoch}',
        title: '$typeName Invoice Generated: $formattedAmt ($invoiceNumber)',
        timestamp: now,
      ),
    );

    // Trigger In-App Notification
    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${now.millisecondsSinceEpoch}',
        title: '$typeName Claim Submitted! 🧾',
        message: 'Invoice $invoiceNumber for $formattedAmt submitted for ${lead.fullName} (${lead.projectName}). Sent for builder audit.',
        type: 'broadcast',
        timestamp: now,
      ),
    );

    notifyListeners();
    _persistInvoices();
    _persistBankDetails();
    _persistNotifications();
    return invoice;
  }

  // Project-Level Invoices & Commission Aggregations
  List<CommissionInvoiceModel> getInvoicesForProject(String projectId) {
    return _invoices.where((inv) => inv.projectId == projectId).toList();
  }

  double getProjectTotalCommission(String projectId) {
    return _invoices
        .where((inv) => inv.projectId == projectId)
        .fold(0.0, (sum, inv) => sum + inv.amount);
  }

  double getProjectReceivedCommission(String projectId) {
    return _invoices
        .where((inv) => inv.projectId == projectId && inv.status == InvoiceStatus.paid)
        .fold(0.0, (sum, inv) => sum + inv.amount);
  }

  double getProjectPendingCommission(String projectId) {
    return _invoices
        .where((inv) => inv.projectId == projectId && (inv.status == InvoiceStatus.pending || inv.status == InvoiceStatus.approved))
        .fold(0.0, (sum, inv) => sum + inv.amount);
  }

  int getProjectLeadsCount(String projectId) {
    return _leads.where((l) => l.projectId == projectId).length;
  }

  void toggleInvoiceReceivedStatus(
    String invoiceId, {
    required bool isReceived,
    String? note,
  }) {
    final idx = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (idx != -1) {
      final inv = _invoices[idx];
      final newStatus = isReceived ? InvoiceStatus.paid : InvoiceStatus.pending;
      inv.status = newStatus;

      final now = DateTime.now();
      final statusLabel = isReceived ? 'RECEIVED / PAID' : 'PENDING';
      final formattedAmt = inv.amount >= 100000
          ? '₹${(inv.amount / 100000).toStringAsFixed(2)} Lakhs'
          : '₹${inv.amount.toStringAsFixed(0)}';

      // Log activity on lead
      final leadIdx = _leads.indexWhere((l) => l.id == inv.leadId);
      if (leadIdx != -1) {
        _leads[leadIdx].activityList.insert(
          0,
          LeadActivityItem(
            id: 'act_${now.millisecondsSinceEpoch}',
            title: 'Invoice ${inv.invoiceNumber} payment marked as $statusLabel ($formattedAmt)',
            timestamp: now,
          ),
        );
      }

      // Notification
      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${now.millisecondsSinceEpoch}',
          title: 'Invoice Payment Updated: ${inv.invoiceNumber}',
          message: 'Payment for $formattedAmt (${inv.clientName}) marked as $statusLabel by Channel Partner.',
          type: 'broadcast',
          timestamp: now,
        ),
      );

      _persistInvoices();
      _persistLeads();
      _persistNotifications();
      notifyListeners();
    }
  }

  void updateInvoiceStatus(String invoiceId, InvoiceStatus newStatus) {
    final idx = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (idx != -1) {
      final inv = _invoices[idx];
      inv.status = newStatus;

      final now = DateTime.now();
      final formattedAmt = inv.amount >= 100000
          ? '₹${(inv.amount / 100000).toStringAsFixed(2)} Lakhs'
          : '₹${inv.amount.toStringAsFixed(0)}';

      String notifTitle;
      String notifMsg;

      if (newStatus == InvoiceStatus.paid) {
        notifTitle = '💰 Commission Payout Received: $formattedAmt';
        notifMsg = 'Payout for invoice ${inv.invoiceNumber} (${inv.clientName}) has been credited! Check your settlement account.';
      } else if (newStatus == InvoiceStatus.approved) {
        notifTitle = 'Invoice Approved! 📑: ${inv.invoiceNumber}';
        notifMsg = 'Invoice for $formattedAmt (${inv.clientName} - ${inv.projectName}) approved by builder finance. Payout scheduled.';
      } else if (newStatus == InvoiceStatus.rejected) {
        notifTitle = 'Invoice Action Needed: ${inv.invoiceNumber}';
        notifMsg = 'Invoice for $formattedAmt (${inv.projectName}) was queried. Please verify documentation.';
      } else {
        notifTitle = 'Invoice Status: ${inv.invoiceNumber}';
        notifMsg = 'Status updated to ${newStatus.displayName} for $formattedAmt.';
      }

      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${now.microsecondsSinceEpoch}',
          title: notifTitle,
          message: notifMsg,
          type: 'broadcast',
          timestamp: now,
          targetRoute: '/commissions',
          targetId: inv.id,
        ),
      );

      notifyListeners();
      _persistInvoices();
      _persistNotifications();
    }
  }

  void saveDefaultBankDetails(BankDetailsModel bankDetails) {
    _savedBankDetails = bankDetails;
    notifyListeners();
    _persistBankDetails();
  }

  Future<void> _persistInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _invoices.map((inv) => inv.toJson()).toList();
      await prefs.setString(_invoicesStorageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _persistBankDetails() async {
    if (_savedBankDetails == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_bank_details', jsonEncode(_savedBankDetails!.toJson()));
    } catch (_) {}
  }

  Future<void> _persistProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _projects.map((p) => p.toJson()).toList();
      await prefs.setString('persisted_projects', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> updateProjectBrochure({
    required String projectId,
    required String fileName,
    required String fileSize,
  }) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      _projects[idx].brochureFileName = fileName;
      _projects[idx].brochureFileSize = fileSize;
      _projects[idx].brochureUpdatedAt = DateTime.now();
      notifyListeners();
      await _persistProjects();
    }
  }

  // ==========================================
  // CP DOCUMENTS & RECEIVED INVOICES ACTIONS
  // ==========================================

  Future<void> uploadOrUpdateDocument({
    required String documentId,
    required String documentNumber,
    required String fileName,
    String? fileSize,
    DateTime? expiresAt,
    String? remarks,
    CpDocumentType? documentType,
    String? title,
    List<int>? fileBytes,
  }) async {
    final idx = _cpDocuments.indexWhere((d) => d.id == documentId);
    final now = DateTime.now();
    if (idx != -1) {
      final old = _cpDocuments[idx];
      _cpDocuments[idx] = old.copyWith(
        documentNumber: documentNumber,
        fileName: fileName,
        fileSize: fileSize ?? '1.4 MB',
        uploadedAt: now,
        expiresAt: expiresAt,
        status: CpDocumentStatus.underReview,
        remarks: remarks ?? 'Uploaded on ${now.day}/${now.month}/${now.year} - verification in review',
        fileBytes: fileBytes,
      );
    } else {
      _cpDocuments.add(
        CpDocumentModel(
          id: documentId,
          type: documentType ?? CpDocumentType.other,
          title: title ?? 'Uploaded Document',
          documentNumber: documentNumber,
          fileName: fileName,
          fileSize: fileSize ?? '1.2 MB',
          uploadedAt: now,
          expiresAt: expiresAt,
          status: CpDocumentStatus.underReview,
          isMandatory: false,
          remarks: remarks ?? 'Uploaded on ${now.day}/${now.month}/${now.year}',
          fileBytes: fileBytes,
        ),
      );
    }

    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${now.millisecondsSinceEpoch}',
        title: 'Document Uploaded for Verification',
        message: 'Document #$documentNumber submitted successfully and is currently under compliance review.',
        type: 'broadcast',
        timestamp: now,
      ),
    );

    notifyListeners();
    _persistCpDocuments();
    _persistNotifications();
  }

  Future<void> deleteDocument(String documentId) async {
    final idx = _cpDocuments.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      final doc = _cpDocuments[idx];
      if (doc.isMandatory) {
        _cpDocuments[idx] = CpDocumentModel(
          id: doc.id,
          type: doc.type,
          title: doc.title,
          documentNumber: '',
          fileName: null,
          fileSize: null,
          uploadedAt: null,
          expiresAt: null,
          status: CpDocumentStatus.missing,
          isMandatory: true,
          remarks: 'Pending document upload and verification.',
        );
      } else {
        _cpDocuments.removeAt(idx);
      }
      notifyListeners();
      _persistCpDocuments();
    }
  }

  void addReceivedInvoice(ReceivedInvoiceModel invoice) {
    _receivedInvoices.insert(0, invoice);

    final now = DateTime.now();
    final formattedAmt = invoice.netAmount >= 100000
        ? '₹${(invoice.netAmount / 100000).toStringAsFixed(2)} Lakhs'
        : '₹${invoice.netAmount.toStringAsFixed(0)}';

    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${now.microsecondsSinceEpoch}',
        title: 'Payment Credit Advice Received 💵',
        message: '$formattedAmt received for ${invoice.projectName} (Ref: ${invoice.voucherNumber}).',
        type: 'broadcast',
        timestamp: now,
        targetRoute: '/docs',
      ),
    );

    notifyListeners();
    _persistReceivedInvoices();
    _persistNotifications();
  }

  Future<void> _persistCpDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _cpDocuments.map((d) => d.toJson()).toList();
      await prefs.setString('persisted_cp_documents', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _persistReceivedInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _receivedInvoices.map((inv) => inv.toJson()).toList();
      await prefs.setString('persisted_received_invoices', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _persistNotifications() async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('persisted_notifications_$uid', jsonEncode(jsonList));
    } catch (_) {}
  }
}



