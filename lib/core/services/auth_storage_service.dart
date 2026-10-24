import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class AuthStorageService {
  static const String _usersKey = 'cp_crm_registered_users_v1';
  static const String _activeUserIdKey = 'cp_crm_active_user_id';
  static const String _isAuthenticatedKey = 'cp_crm_is_authenticated';

  static const Set<String> _legacyDemoIds = {
    'usr_9014',
    'usr_8819',
    'usr_9420',
    'usr_3108',
  };

  static bool isLegacyDemoId(String? id) => id != null && _legacyDemoIds.contains(id);

  /// Retrieve all registered CP/SP profiles from local device storage
  static Future<List<UserModel>> getRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      List<UserModel> users = [];
      if (usersJson != null && usersJson.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        users = decoded
            .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
            .where((u) => !isLegacyDemoId(u.id))
            .toList();
      }
      return users;
    } catch (_) {
      return [];
    }
  }

  /// Purge any legacy pre-seeded demo accounts from local device storage
  static Future<void> purgeLegacyDemoAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeUserId = prefs.getString(_activeUserIdKey);
      if (isLegacyDemoId(activeUserId)) {
        await clearActiveSession();
      }
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null && usersJson.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        final cleanUsers = decoded
            .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
            .where((u) => !isLegacyDemoId(u.id))
            .toList();
        await _saveUsersList(cleanUsers);
      }
    } catch (_) {}
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
        // Require explicit registered password match
        if (user.password != null && user.password!.isNotEmpty && user.password == password) {
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

      if (!isAuth || activeUserId == null || isLegacyDemoId(activeUserId)) {
        return null;
      }

      final users = await getRegisteredUsers();
      final found = users.where((u) => u.id == activeUserId);
      if (found.isNotEmpty) {
        return found.first;
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
