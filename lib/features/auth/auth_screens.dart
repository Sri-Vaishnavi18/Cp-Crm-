import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../shared/widgets/powered_by_branding.dart';

class LoginScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToRegister;

  const LoginScreen({
    super.key,
    required this.state,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter mobile number or email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.state.login(
      identifier: identifier,
      password: password,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Welcome back, ${result.user?.name ?? "Partner"}!'),
              ],
            ),
          ),
        );
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Invalid credentials.';
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.state.biometricLogin();
    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.fingerprint, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Biometric Verified: ${result.user?.firmName}'),
              ],
            ),
          ),
        );
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Biometric unlock failed.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Cover Scaling
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFFEEF2F6), const Color(0xFFE2E8F0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),

          // Vignette Overlay for Crisp Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.70),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.65),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Top Floating Theme Toggle Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: isDark ? Colors.amber : Colors.white,
                          size: 18,
                        ),
                        onPressed: widget.state.toggleTheme,
                        tooltip: 'Switch Theme',
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Minimized, Sleek Glassmorphic Login Box (Shifted Downwards)
          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.28),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 330),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.65),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.20),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact Brand Header
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CP CRM',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Channel Partner Portal',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Error Banner (Compact)
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.danger, size: 15),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Input: Mobile or Email
                          Text(
                            'Mobile / Email',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'e.g. 9876543210 or email',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                fontSize: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                size: 16,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                  : const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Input: Password
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Enter password',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                fontSize: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 16,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                  : const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Compact Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Compact Biometric Unlock Button
                          SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleBiometricLogin,
                              icon: const Icon(Icons.fingerprint, size: 17, color: AppColors.primary),
                              label: Text(
                                'Quick Biometric Unlock',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Compact Register Link CTA
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'New Partner? ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onNavigateToRegister,
                                  child: const Text(
                                    'Register Here',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          PoweredByBranding(isDark: isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onRegisterSuccess;
  final VoidCallback onNavigateToLogin;

  const RegisterScreen({
    super.key,
    required this.state,
    required this.onRegisterSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isAgency = true;
  final _nameController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _reraController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bangalore, Karnataka');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _firmNameController.dispose();
    _reraController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter authorized contact person name.');
      return;
    }
    if (_isAgency && _firmNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter agency or firm name.');
      return;
    }
    if (_reraController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter RERA registration number.');
      return;
    }
    if (_phoneController.text.trim().length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await widget.state.register(
      name: _nameController.text.trim(),
      firmName: _isAgency ? _firmNameController.text.trim() : _nameController.text.trim(),
      reraNumber: _reraController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      city: _cityController.text.trim(),
      isAgency: _isAgency,
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Account created for ${result.user?.firmName}!'),
                ),
              ],
            ),
          ),
        );
        widget.onRegisterSuccess();
      } else {
        setState(() => _errorMessage = result.errorMessage ?? 'Registration failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Registration', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: widget.onNavigateToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Partner Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Register your firm or realtor profile to get instant access',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Partner Type Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: Icon(Icons.business_outlined, size: 16, color: _isAgency ? Colors.white : AppColors.primary),
                      label: const Center(child: Text('Agency / Firm')),
                      selected: _isAgency,
                      onSelected: (val) => setState(() => _isAgency = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      avatar: Icon(Icons.person_outline, size: 16, color: !_isAgency ? Colors.white : AppColors.primary),
                      label: const Center(child: Text('Individual Realtor')),
                      selected: !_isAgency,
                      onSelected: (val) => setState(() => _isAgency = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_isAgency) ...[
                _buildFieldLabel('Agency / Firm Name *', isDark),
                TextField(
                  controller: _firmNameController,
                  decoration: _buildInputDecoration('e.g. Skyline Realty Advisors', Icons.business, isDark),
                ),
                const SizedBox(height: 16),
              ],

              _buildFieldLabel('Authorized Contact Person *', isDark),
              TextField(
                controller: _nameController,
                decoration: _buildInputDecoration('Full Name', Icons.person_outline, isDark),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('RERA Registration Number *', isDark),
              TextField(
                controller: _reraController,
                textCapitalization: TextCapitalization.characters,
                decoration: _buildInputDecoration('e.g. PRM/KA/RERA/...', Icons.verified_user_outlined, isDark),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Mobile Number * (Sign-In ID)', isDark),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration('10-digit mobile number', Icons.phone_outlined, isDark),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Email Address', isDark),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration('partner@firm.com', Icons.email_outlined, isDark),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Operating City / State', isDark),
              TextField(
                controller: _cityController,
                decoration: _buildInputDecoration('Bangalore, Karnataka', Icons.location_on_outlined, isDark),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Password *', isDark),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _buildInputDecoration('At least 6 characters', Icons.lock_outline, isDark),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Confirm Password *', isDark),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: _buildInputDecoration('Re-enter password', Icons.lock_reset_outlined, isDark),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Create Account & Sign In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login Link
              Center(
                child: TextButton(
                  onPressed: widget.onNavigateToLogin,
                  child: const Text('Already have an account? Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              PoweredByBranding(isDark: isDark),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
