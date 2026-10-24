import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/core/services/auth_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserModel Serialization Tests', () {
    test('UserModel toJson and fromJson match correctly', () {
      final user = UserModel(
        id: 'usr_test_101',
        name: 'Test Partner',
        firmName: 'Test Realty Firm',
        reraNumber: 'PRM/KA/RERA/TEST/001',
        phone: '9876543210',
        email: 'test@realty.com',
        city: 'Bangalore',
        isAgency: true,
        password: 'password123',
        registeredAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();
      final decoded = UserModel.fromJson(json);

      expect(decoded.id, 'usr_test_101');
      expect(decoded.name, 'Test Partner');
      expect(decoded.firmName, 'Test Realty Firm');
      expect(decoded.reraNumber, 'PRM/KA/RERA/TEST/001');
      expect(decoded.phone, '9876543210');
      expect(decoded.email, 'test@realty.com');
      expect(decoded.city, 'Bangalore');
      expect(decoded.isAgency, true);
      expect(decoded.password, 'password123');
    });
  });

  group('AuthStorageService Device Persistence Tests', () {
    test('starts with an empty registered users list on fresh device', () async {
      final users = await AuthStorageService.getRegisteredUsers();
      expect(users, isEmpty);
    });

    test('registers a new CP user and persists in device storage', () async {
      final newUser = UserModel(
        id: 'usr_new_999',
        name: 'Kavita Reddy',
        firmName: 'Kavita Elite Properties',
        reraNumber: 'PRM/KA/RERA/999/001',
        phone: '9123456780',
        email: 'kavita@eliteproperties.in',
        city: 'Bangalore, Karnataka',
        isAgency: true,
        password: 'securePassword!',
      );

      await AuthStorageService.registerUser(newUser);

      final users = await AuthStorageService.getRegisteredUsers();
      expect(users.any((u) => u.phone == '9123456780'), true);

      final activeUser = await AuthStorageService.getActiveUser();
      expect(activeUser?.id, 'usr_new_999');
      expect(activeUser?.name, 'Kavita Reddy');
    });

    test('authenticates with correct credentials and rejects invalid', () async {
      final user = UserModel(
        id: 'usr_test_auth',
        name: 'Rahul Sharma',
        firmName: 'Apex Realty',
        reraNumber: 'RERA123',
        phone: '9876543210',
        email: 'rahul@apex.com',
        city: 'Bangalore',
        isAgency: true,
        password: 'password123',
      );
      await AuthStorageService.registerUser(user);

      final success = await AuthStorageService.authenticate(
        identifier: '9876543210',
        password: 'password123',
      );
      expect(success, isNotNull);
      expect(success?.name, 'Rahul Sharma');

      final failed = await AuthStorageService.authenticate(
        identifier: '9876543210',
        password: 'wrongPassword',
      );
      expect(failed, isNull);
    });

    test('session management sets and clears active user', () async {
      final user = UserModel(
        id: 'usr_active_8819',
        name: 'Active User',
        firmName: 'Active Firm',
        reraNumber: 'RERA456',
        phone: '9988776655',
        email: 'active@user.com',
        city: 'Bangalore',
        isAgency: false,
        password: 'mypassword',
      );
      await AuthStorageService.registerUser(user);

      await AuthStorageService.setActiveSession('usr_active_8819');
      final active = await AuthStorageService.getActiveUser();
      expect(active?.id, 'usr_active_8819');

      await AuthStorageService.clearActiveSession();
      final cleared = await AuthStorageService.getActiveUser();
      expect(cleared, isNull);
    });
  });
}
