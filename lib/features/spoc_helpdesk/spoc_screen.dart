import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';

class SpocHelpdeskScreen extends StatelessWidget {
  final AppState state;

  const SpocHelpdeskScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final spocs = state.spocs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Builder SPOCs & Helpdesk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Builder SPOC Directory',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connect directly with Builder SPOCs & Site Reception without intermediary delays.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Assigned Project Personnel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // SPOC Cards
            ...spocs.map((spoc) => _buildSpocCard(context, spoc, isDark)),
            const SizedBox(height: 20),

            // Quick Enquiry / Unit Hold Box
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Broker Support & Unit Hold Desk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Need an emergency 24h inventory hold, special payment slab approval, or facing layout queries?',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Support ticket created. Partner manager will connect within 15 minutes.')),
                        );
                      },
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: const Text('Raise Priority Broker Query'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpocCard(BuildContext context, SpocModel spoc, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                spoc.name[0],
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spoc.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spoc.role,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  Text(
                    spoc.projectName,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.primary, size: 20),
                  tooltip: 'Call SPOC',
                  onPressed: () => UrlActionService.makePhoneCall(context, spoc.phone),
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: AppColors.whatsapp, size: 20),
                  tooltip: 'WhatsApp SPOC',
                  onPressed: () {
                    final msg = 'Hello ${spoc.name}, this is ${state.currentUser?.name} from ${state.currentUser?.firmName} regarding ${spoc.projectName}.';
                    UrlActionService.openWhatsApp(context, phoneNumber: spoc.phone, message: msg);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
