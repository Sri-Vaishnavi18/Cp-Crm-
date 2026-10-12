import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class AuthStorageService {
  static const String _usersKey = 'cp_crm_registered_users_v1';
  static const String _activeUserIdKey = 'cp_crm_active_user_id';
  static const String _isAuthenticatedKey = 'cp_crm_is_authenticated';

  /// Seed realistic demo Channel Partners if device storage is currently empty
  static List<UserModel> get _defaultDemoUsers => [
    UserModel(
      id: 'usr_9014',
      name: 'Vaishu',
      firmName: 'Channel Partner (Realtor)',
      reraNumber: '0283838',
      phone: '9014547044',
      email: 'vaishu@cp-crm.com',
      city: 'Hyderabad, Telangana',
      isAgency: false,
      password: 'password123',
      logoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80',
      registeredAt: DateTime(2024, 1, 10),
    ),
    UserModel(
      id: 'usr_8819',
      name: 'Rahul Sharma',
      firmName: 'Apex Realty Advisors',
      reraNumber: 'PRM/KA/RERA/1251/310/AG/230101/004218',
      phone: '9876543210',
      email: 'rahul@apexrealty.com',
      city: 'Bangalore, Karnataka',
      isAgency: true,
      password: 'password123',
      logoUrl: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200&q=80',
      registeredAt: DateTime(2023, 1, 15),
    ),
    UserModel(
      id: 'usr_9420',
      name: 'Priya Nair',
      firmName: 'Horizon Elite Properties',
      reraNumber: 'PRM/KA/RERA/1251/520/AG/220815/007812',
      phone: '9811223344',
      email: 'priya@horizonproperties.in',
      city: 'Bangalore, Karnataka',
      isAgency: true,
      password: 'password123',
      logoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80',
      registeredAt: DateTime(2023, 5, 20),
    ),
    UserModel(
      id: 'usr_3108',
      name: 'Vikram Seth',
      firmName: 'Vikram Seth Real Estate',
      reraNumber: 'PRM/KA/RERA/1251/412/AG/230410/009142',
      phone: '9988776655',
      email: 'vikram.seth@realtor.in',
      city: 'Bangalore, Karnataka',
      isAgency: false,
      password: 'password123',
      logoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      registeredAt: DateTime(2023, 8, 10),
    ),
  ];

  /// Retrieve all registered CP/SP profiles from local device storage
  static Future<List<UserModel>> getRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      List<UserModel> users = [];
      if (usersJson != null && usersJson.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        users = decoded.map((item) => UserModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }

      // Ensure all default demo users (including 9014547044) are available in storage
      for (final demo in _defaultDemoUsers) {
        final cleanDemoPhone = demo.phone.replaceAll(RegExp(r'[^\d]'), '');
        final exists = users.any((u) => u.phone.replaceAll(RegExp(r'[^\d]'), '') == cleanDemoPhone);
        if (!exists) {
          users.add(demo);
        }
      }

      await _saveUsersList(users);
      return users;
    } catch (_) {
      return _defaultDemoUsers;
    }
  }

  /// Internal helper to save users list to SharedPreferences
  static Future<void> _saveUsersList(List<UserModel> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, encoded);
    } catch (_) {}
  }

  /// Save a newly registered CP/SP to the local device storage
  static Future<UserModel> registerUser(UserModel newUser) async {
    final users = await getRegisteredUsers();

    // Check if user with same phone or email already exists
    final cleanPhone = newUser.phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanEmail = newUser.email.trim().toLowerCase();

    final existingIndex = users.indexWhere((u) {
      final uPhone = u.phone.replaceAll(RegExp(r'[^\d]'), '');
      final uEmail = u.email.trim().toLowerCase();
      return uPhone == cleanPhone || (cleanEmail.isNotEmpty && uEmail == cleanEmail);
    });

    if (existingIndex != -1) {
      // Overwrite/update existing
      users[existingIndex] = newUser;
    } else {
      users.insert(0, newUser);
    }

    await _saveUsersList(users);
    await setActiveSession(newUser.id);
    return newUser;
  }

  /// Authenticate credentials against locally stored CP/SP accounts
  static Future<UserModel?> authenticate({
    required String identifier,
    required String password,
  }) async {
    final users = await getRegisteredUsers();
    final cleanIdentifier = identifier.trim().toLowerCase().replaceAll(RegExp(r'[^\d]'), '');
    final rawIdentifier = identifier.trim().toLowerCase();

    for (final user in users) {
      final userPhone = user.phone.replaceAll(RegExp(r'[^\d]'), '');
      final userEmail = user.email.trim().toLowerCase();

      final matchesPhone = cleanIdentifier.isNotEmpty &&
          (userPhone == cleanIdentifier || userPhone.endsWith(cleanIdentifier) || cleanIdentifier.endsWith(userPhone));
      final matchesEmail = rawIdentifier.isNotEmpty && userEmail == rawIdentifier;

      if (matchesPhone || matchesEmail) {
        // Accept user's set password or demo master passwords
        if (user.password == null ||
            user.password == password ||
            password == 'password123' ||
            password == 'admin123') {
          await setActiveSession(user.id);
          return user;
        }
        // Identifier matched an existing user but password did not match
        return null;
      }
    }

    return null;
  }

  /// Get the currently active user session from device storage
  static Future<UserModel?> getActiveUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool(_isAuthenticatedKey) ?? false;
      final activeUserId = prefs.getString(_activeUserIdKey);

      if (!isAuth || activeUserId == null) {
        return null;
      }

      final users = await getRegisteredUsers();
      final found = users.where((u) => u.id == activeUserId);
      if (found.isNotEmpty) {
        return found.first;
      }
      // If active ID not found, return first available user
      if (users.isNotEmpty) {
        return users.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Set the active user session on the device
  static Future<void> setActiveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeUserIdKey, userId);
      await prefs.setBool(_isAuthenticatedKey, true);
    } catch (_) {}
  }

  /// Clear the active user session upon logout
  static Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeUserIdKey);
      await prefs.setBool(_isAuthenticatedKey, false);
    } catch (_) {}
  }

  /// Check if a phone number or email is already registered on this device
  static Future<bool> isIdentifierRegistered(String identifier) async {
    final users = await getRegisteredUsers();
    final clean = identifier.replaceAll(RegExp(r'[^\d]'), '');
    final raw = identifier.trim().toLowerCase();
    return users.any((u) {
      final uPhone = u.phone.replaceAll(RegExp(r'[^\d]'), '');
      final uEmail = u.email.trim().toLowerCase();
      return (clean.isNotEmpty && uPhone == clean) || (raw.isNotEmpty && uEmail == raw);
    });
  }
}
