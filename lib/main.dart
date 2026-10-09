import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'features/auth/auth_screens.dart';
import 'features/home/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CpCrmApp());
}

class CpCrmApp extends StatefulWidget {
  const CpCrmApp({super.key});

  @override
  State<CpCrmApp> createState() => _CpCrmAppState();
}

class _CpCrmAppState extends State<CpCrmApp> {
  late final AppState _state;
  bool _showingRegister = false;

  @override
  void initState() {
    super.initState();
    _state = AppState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return MaterialApp(
          title: 'CP CRM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _state.themeMode,
          home: _buildRootScreen(),
        );
      },
    );
  }

  Widget _buildRootScreen() {
    if (_state.isAuthenticated) {
      return MainNavigationShell(state: _state);
    }

    if (_showingRegister) {
      return RegisterScreen(
        state: _state,
        onRegisterSuccess: () {
          setState(() => _showingRegister = false);
        },
        onNavigateToLogin: () {
          setState(() => _showingRegister = false);
        },
      );
    }

    return LoginScreen(
      state: _state,
      onLoginSuccess: () {
        setState(() {});
      },
      onNavigateToRegister: () {
        setState(() => _showingRegister = true);
      },
    );
  }
}
