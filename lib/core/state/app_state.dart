import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/mock_data_service.dart';
import '../services/auth_storage_service.dart';

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
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Auth State
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  List<UserModel> _savedUsers = [];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  List<UserModel> get savedUsers => _savedUsers;

  // Active Data Stores
  List<LeadModel> _leads = [];
  List<ProjectModel> _projects = [];
  List<SiteVisitModel> _siteVisits = [];
  List<SpocModel> _spocs = [];
  List<CollateralModel> _collaterals = [];
  List<AppNotificationModel> _notifications = [];

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

  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  // Constructor
  AppState() {
    _initData();
  }

  Future<void> _initData() async {
    _projects = MockDataService.getProjects();
    _leads = MockDataService.getInitialLeads();
    _siteVisits = MockDataService.getInitialVisits();
    _spocs = MockDataService.getSpocs();
    _collaterals = MockDataService.getCollaterals();
    _notifications = MockDataService.getNotifications();

    // Check saved session in local device storage
    try {
      _savedUsers = await AuthStorageService.getRegisteredUsers();
      final activeUser = await AuthStorageService.getActiveUser();
      if (activeUser != null) {
        _currentUser = activeUser;
        _isAuthenticated = true;
      } else {
        // Default to active demo user session so Dashboard & Leads are immediately accessible
        _currentUser = _savedUsers.isNotEmpty ? _savedUsers.first : MockDataService.getInitialUser();
        if (_currentUser != null) {
          await AuthStorageService.setActiveSession(_currentUser!.id);
        }
        _isAuthenticated = true;
      }
    } catch (_) {
      _currentUser = MockDataService.getInitialUser();
      _isAuthenticated = true;
    }

    // Load saved theme preference
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
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
    final users = await AuthStorageService.getRegisteredUsers();
    if (users.isNotEmpty) {
      final user = _currentUser ?? users.first;
      await AuthStorageService.setActiveSession(user.id);
      _currentUser = user;
      _isAuthenticated = true;
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

    notifyListeners();
    return AuthResult(success: true, user: saved);
  }

  Future<void> switchUser(String userId) async {
    final users = await AuthStorageService.getRegisteredUsers();
    final target = users.firstWhere((u) => u.id == userId, orElse: () => users.first);
    await AuthStorageService.setActiveSession(target.id);
    _currentUser = target;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthStorageService.clearActiveSession();
    _isAuthenticated = false;
    notifyListeners();
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

  void syncOfflineQueue() {
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
        );
      }
    }
    notifyListeners();
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

    final newLead = LeadModel(
      id: 'lead_${now.millisecondsSinceEpoch}',
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
      stage: LeadStage.newLead,
      temperature: computedTemp,
      source: source,
      createdAt: now,
      isQueuedOffline: _isOffline,
      notesList: notes.trim().isNotEmpty
          ? [
              LeadNoteItem(
                id: 'note_${now.millisecondsSinceEpoch}',
                text: notes.trim(),
                author: _currentUser?.name ?? 'You',
                createdAt: now,
              )
            ]
          : [],
      activityList: [
        LeadActivityItem(
          id: 'act_${now.millisecondsSinceEpoch}',
          title: 'Lead registered under ${_currentUser?.firmName ?? "Channel Partner"} (Zero-OTP protection locked)',
          timestamp: now,
        ),
      ],
    );

    _leads.insert(0, newLead);

    // Also trigger notification
    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lead Registered: $firstName $lastName',
        message: 'Zero-OTP protection locked under ${_currentUser?.firmName ?? "your agency"} for 60 days.',
        type: 'lead',
        timestamp: DateTime.now(),
        targetRoute: '/leads',
        targetId: newLead.id,
      ),
    );

    notifyListeners();
    return true;
  }

  void updateLeadStage(String leadId, LeadStage newStage) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      lead.stage = newStage;
      // Automatically cascade lead temperature based on stage
      lead.temperature = LeadModel.getTemperatureForStage(newStage);

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'lead status updated to ${newStage.displayName}',
          timestamp: DateTime.now(),
        ),
      );

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
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'lead temperature updated to ${newTemperature.displayName.toUpperCase()}',
          timestamp: DateTime.now(),
        ),
      );

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
          id: 'note_${now.millisecondsSinceEpoch}',
          text: noteText.trim(),
          author: _currentUser?.name ?? 'You',
          createdAt: now,
        ),
      );

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${now.millisecondsSinceEpoch}',
          title: 'New note added',
          timestamp: now,
        ),
      );

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
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Lead information updated',
          timestamp: DateTime.now(),
        ),
      );

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
      id: 'vis_${DateTime.now().millisecondsSinceEpoch}',
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

    // Update lead stage to VISIT_SCHEDULED and temperature to WARM
    if (lead.stage == LeadStage.newLead || lead.stage == LeadStage.contacted) {
      lead.stage = LeadStage.visitScheduled;
    }
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
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'site visit status updated to SCHEDULED',
        timestamp: DateTime.now(),
      ),
    );

    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Visit Scheduled: $visitCode',
        message: 'Digital entry pass generated for ${lead.fullName} at ${project.name}.',
        type: 'visit',
        timestamp: DateTime.now(),
        targetRoute: '/visits',
        targetId: visit.id,
      ),
    );

    notifyListeners();
    return visitCode;
  }

  void markVisitCheckedIn(String visitId) {
    final index = _siteVisits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _siteVisits[index].status = 'CHECKED_IN';
      
      // Also update lead stage to visitCompleted and temperature to warm
      final lead = _leads.firstWhere((l) => l.id == _siteVisits[index].leadId, orElse: () => _leads.first);
      lead.stage = LeadStage.visitCompleted;
      lead.temperature = LeadModel.getTemperatureForStage(LeadStage.visitCompleted);

      // Add direct Zero-OTP check-in history log
      lead.siteVisitHistory.insert(
        0,
        'Site visit completed & verified directly. Accompanied by CP: ${_currentUser?.name ?? "Partner"}',
      );

      lead.activityList.insert(
        0,
        LeadActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'site visit status updated to COMPLETED',
          timestamp: DateTime.now(),
        ),
      );

      _notifications.insert(
        0,
        AppNotificationModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Client Checked-in at Site! 📍',
          message: '${_siteVisits[index].clientName} checked in at ${_siteVisits[index].projectName}. Priority entry pass verified.',
          type: 'visit',
          timestamp: DateTime.now(),
        ),
      );

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
    }
  }

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
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
        final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
        final yesterdayEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59, 999);
        return !date.isBefore(yesterdayStart) && !date.isAfter(yesterdayEnd);
      case DashboardDatePreset.last7Days:
        final start7Days = DateTime(now.year, now.month, now.day - 6);
        return !date.isBefore(start7Days) && !date.isAfter(todayEnd);
      case DashboardDatePreset.last30Days:
        final start30Days = DateTime(now.year, now.month, now.day - 29);
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

  // Dynamic Date-Filtered KPI Calculations
  int get activeLeadsCount =>
      dashboardLeads.where((l) => l.stage != LeadStage.lost && l.stage != LeadStage.tokenPaid).length;
  int get visitsScheduledCount =>
      dashboardSiteVisits.where((v) => v.status == 'SCHEDULED').length;
  int get visitsCompletedCount =>
      dashboardSiteVisits.where((v) => v.status == 'COMPLETED' || v.status == 'CHECKED_IN').length;
  int get bookingsCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.tokenPaid).length;

  // Dynamic Funnel Calculations
  int get funnelNewLeadsCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.newLead).length;
  int get funnelContactedCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.contacted).length;
  int get funnelVisitScheduledCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.visitScheduled).length;
  int get funnelVisitCompletedCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.visitCompleted).length;
  int get funnelBookingsCount =>
      dashboardLeads.where((l) => l.stage == LeadStage.tokenPaid).length;

  // Commission Analytics
  String get commissionPendingFormatted {
    switch (_dashboardDatePreset) {
      case DashboardDatePreset.today:
        return '₹0.85 L';
      case DashboardDatePreset.yesterday:
        return '₹1.20 L';
      case DashboardDatePreset.last7Days:
        return '₹2.75 L';
      case DashboardDatePreset.last30Days:
      case DashboardDatePreset.allTime:
      case DashboardDatePreset.custom:
        return '₹4.20 Lakhs';
    }
  }

  String get commissionReceivedFormatted {
    switch (_dashboardDatePreset) {
      case DashboardDatePreset.today:
        return '₹2.10 L';
      case DashboardDatePreset.yesterday:
        return '₹3.40 L';
      case DashboardDatePreset.last7Days:
        return '₹8.50 L';
      case DashboardDatePreset.last30Days:
      case DashboardDatePreset.allTime:
      case DashboardDatePreset.custom:
        return '₹12.80 Lakhs';
    }
  }
}
