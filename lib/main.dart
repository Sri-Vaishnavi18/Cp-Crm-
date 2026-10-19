import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'features/auth/auth_screens.dart';
import 'features/auth/subscription_lock_screen.dart';
import 'features/home/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool initialIsDark = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    initialIsDark = prefs.getBool('is_dark_mode') ?? false;
  } catch (_) {}
  runApp(CpCrmApp(initialIsDark: initialIsDark));
}

class CpCrmApp extends StatefulWidget {
  final bool initialIsDark;
  const CpCrmApp({super.key, this.initialIsDark = false});

  @override
  State<CpCrmApp> createState() => _CpCrmAppState();
}

class _CpCrmAppState extends State<CpCrmApp> with WidgetsBindingObserver {
  late final AppState _state;
  bool _showingRegister = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = AppState(initialIsDark: widget.initialIsDark);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Every time the user resumes or re-opens the app from background
    if (state == AppLifecycleState.resumed && _state.isAuthenticated) {
      _state.checkSubscription();
    }
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
      // If payment is pending, expired, or daily verification is required
      if (!_state.isSubscriptionActive) {
        return SubscriptionLockScreen(
          state: _state,
          onUnlocked: () => setState(() {}),
        );
      }
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
