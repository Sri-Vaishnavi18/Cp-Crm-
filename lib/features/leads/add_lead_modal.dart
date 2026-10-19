import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class AddLeadModalSheet extends StatefulWidget {
  final AppState state;

  const AddLeadModalSheet({super.key, required this.state});

  @override
  State<AddLeadModalSheet> createState() => _AddLeadModalSheetState();
}

class _AddLeadModalSheetState extends State<AddLeadModalSheet> {
  final _formKey = GlobalKey<FormState>();

  // Part 1: Basic Info Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();

  // Part 2: Project & Lead Details
  late String _selectedProjectId;
  String _selectedSource = 'Digital Ads';
  final LeadTemperature _selectedTemperature = LeadTemperature.cold;
  String _selectedBudget = '₹80 Lakhs - ₹1.2 Cr';
  String _selectedTimeline = 'Immediate (<15 days)';
  final List<String> _selectedConfigs = ['2 BHK', '3 BHK'];
  final _notesController = TextEditingController();

  final List<String> _sources = [
    'Digital Ads',
    'Walk-in',
    'Referral',
    'Social Media',
    'Channel Partner',
    'Cold Calling',
    'Website Inquiry',
    'Property Expo',
  ];

  final List<String> _budgets = [
    '₹50L - ₹80L',
    '₹80 Lakhs - ₹1.2 Cr',
    '₹1.2 Cr - ₹2 Cr',
    '₹2 Cr+',
  ];

  final List<String> _configs = [
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK Luxury',
    'Penthouse',
    'Villa / Plot',
  ];

  final List<String> _timelines = [
    'Immediate (<15 days)',
    '1 Month',
    '3 Months',
    'Exploring',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.state.projects.isNotEmpty ? widget.state.projects.first.id : '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitLead() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client phone number')),
      );
      return;
    }

    // Algorithmic Zero-OTP Duplicate Exclusivity Check
    final dupCheck = widget.state.checkLeadDuplicate(rawPhone);
    if (dupCheck.isDuplicate) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
              SizedBox(width: 8),
              Text('Duplicate Exclusivity Conflict', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            dupCheck.message ?? 'This phone number is already actively protected in the CP pipeline.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final project = widget.state.projects.firstWhere(
      (p) => p.id == _selectedProjectId,
      orElse: () => widget.state.projects.first,
    );

    widget.state.addLead(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? 'Client' : _lastNameController.text.trim(),
      phone: rawPhone,
      altPhone: _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      budget: _selectedBudget,
      configurations: _selectedConfigs.isEmpty ? ['2 BHK'] : _selectedConfigs,
      projectId: project.id,
      projectName: project.name,
      timeline: _selectedTimeline,
      notes: _notesController.text.trim(),
      temperature: _selectedTemperature,
      source: _selectedSource,
    );

    final messenger = ScaffoldMessenger.of(context);
    final leadName = _firstNameController.text.trim();
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lead "$leadName" registered with 60-day Zero-OTP exclusivity!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle Pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Headline: Lead Creation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead Creation',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Register prospect with algorithmic exclusivity protection',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1),
                    ),
                    child: const Text(
                      'ZERO-OTP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // PART 1: BASIC INFO
              _buildSectionHeader(
                stepNumber: '1',
                title: 'Basic Info',
                subtitle: 'Primary client contact details',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3A4F) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              hintText: 'e.g. Rahul',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              hintText: 'e.g. Sharma',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Primary) *',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Phone number required';
                        if (val.trim().replaceAll(RegExp(r'\D'), '').length < 10) return 'Valid 10-digit phone required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Optional)',
                        hintText: 'e.g. rahul@example.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _altPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Alternate Phone (Optional)',
                        hintText: 'e.g. 9811002233',
                        prefixIcon: Icon(Icons.phone_iphone_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // PART 2: PROJECT & LEAD DETAILS
              _buildSectionHeader(
                stepNumber: '2',
                title: 'Project & Lead Details',
                subtitle: 'Select project, source, temperature & preferences',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3A4F) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Project *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (widget.state.projects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProjectId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.apartment_outlined, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: widget.state.projects.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProjectId = val);
                        },
                      ),
                    const SizedBox(height: 16),

                    Text(
                      'Lead Source *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSource,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.hub_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _sources.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSource = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Temperature of the Lead',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C243B) : const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text('❄️', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Cold Lead',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0284C7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'All new leads start as Cold. Upgraded to Warm/Hot upon site visit & qualification.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0EA5E9),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Budget Range',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _budgets.map((b) {
                        final isSelected = _selectedBudget == b;
                        return ChoiceChip(
                          label: Text(b, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedBudget = b),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Preferred Configurations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _configs.map((c) {
                        final isSelected = _selectedConfigs.contains(c);
                        return FilterChip(
                          label: Text(c, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedConfigs.add(c);
                              } else {
                                _selectedConfigs.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Expected Purchase Timeline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _timelines.map((t) {
                        final isSelected = _selectedTimeline == t;
                        return ChoiceChip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedTimeline = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Requirements & Specific Notes',
                        hintText: 'e.g., East facing, Higher floor, Vastu compliant entrance',
                        prefixIcon: Icon(Icons.notes, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submitLead,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text(
                  'Create Lead (Zero-OTP Protected)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
