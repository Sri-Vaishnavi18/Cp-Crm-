import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import '../../shared/widgets/app_widgets.dart';

class SiteVisitsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onOpenSchedule;

  const SiteVisitsScreen({super.key, required this.state, required this.onOpenSchedule});

  @override
  State<SiteVisitsScreen> createState() => _SiteVisitsScreenState();
}

class _SiteVisitsScreenState extends State<SiteVisitsScreen> {
  String _selectedTab = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final allVisits = widget.state.siteVisits;
    final visits = _selectedTab == 'ALL'
        ? allVisits
        : (_selectedTab == 'SCHEDULED'
            ? allVisits.where((v) => v.status == 'SCHEDULED').toList()
            : allVisits.where((v) => v.status == 'COMPLETED' || v.status == 'CHECKED_IN').toList());

    return Scaffold(
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Row(
              children: [
                _buildTab('ALL', 'All Visits (${allVisits.length})'),
                const SizedBox(width: 8),
                _buildTab('SCHEDULED', 'Upcoming (${allVisits.where((v) => v.status == "SCHEDULED").length})'),
                const SizedBox(width: 8),
                _buildTab('COMPLETED', 'Completed'),
              ],
            ),
          ),

          // Visits List
          Expanded(
            child: visits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 54, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No site visits scheduled',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: widget.onOpenSchedule,
                          icon: const Icon(Icons.add_task),
                          label: const Text('Schedule Site Visit'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    itemCount: visits.length,
                    itemBuilder: (context, index) {
                      final visit = visits[index];
                      return _buildVisitCard(context, visit, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onOpenSchedule,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: const Text('Book Visit (QR Pass)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTab(String key, String label) {
    final isSelected = _selectedTab == key;
    final isDark = widget.state.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedTab = key),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, SiteVisitModel visit, bool isDark) {
    final dateFormat = DateFormat('EEE, d MMM yyyy • hh:mm a');
    final isScheduled = visit.status == 'SCHEDULED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pass Code & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        visit.visitCode,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isScheduled ? 'Zero-OTP Pass' : 'Completed',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ],
                ),
                StatusBadge(
                  text: visit.status,
                  color: isScheduled ? AppColors.warning : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Client & Project Info
            Text(
              visit.clientName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              '${visit.projectName} • +91 ${visit.clientPhone}',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 10),

            // Time & Logistics
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateFormat.format(visit.scheduledAt),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (visit.cabRequired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('CAB PICKUP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showQrPassDialog(context, visit),
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    label: const Text('View QR Pass', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final msg = '''
*Digital Site Visit Pass — ${visit.projectName}*
Visit ID: *${visit.visitCode}*
Client: ${visit.clientName}
Scheduled Time: ${dateFormat.format(visit.scheduledAt)}
--------------------------------
*Zero-OTP Pass:* Show this pass at site reception for priority entry.
Partner: ${widget.state.currentUser?.firmName}
''';
                      UrlActionService.openWhatsApp(context, phoneNumber: visit.clientPhone, message: msg);
                    },
                    icon: const Icon(Icons.send, size: 16, color: AppColors.whatsapp),
                    label: const Text('WhatsApp Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQrPassDialog(BuildContext context, SiteVisitModel visit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: const Text('ZERO-OTP DIGITAL VISIT PASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            const SizedBox(height: 14),

            // QR Code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: 'https://cp.builder.com/visit/${visit.visitCode}',
                version: QrVersions.auto,
                size: 160.0,
              ),
            ),
            const SizedBox(height: 14),

            Text(
              visit.visitCode,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Text(visit.clientName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(visit.projectName, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 14),

            // Reception Simulation Action
            if (visit.status == 'SCHEDULED')
              TextButton.icon(
                onPressed: () {
                  widget.state.markVisitCheckedIn(visit.id);
                  Navigator.of(ctx).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reception Scan Simulated: Client Checked-In! (Zero-OTP)')),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Simulate Reception Desk Scan', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}

class ScheduleVisitModalSheet extends StatefulWidget {
  final AppState state;
  final String? preselectedLeadId;

  const ScheduleVisitModalSheet({super.key, required this.state, this.preselectedLeadId});

  @override
  State<ScheduleVisitModalSheet> createState() => _ScheduleVisitModalSheetState();
}

class _ScheduleVisitModalSheetState extends State<ScheduleVisitModalSheet> {
  late String _selectedLeadId;
  late String _selectedProjectId;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1, hours: 4));
  bool _cabRequired = false;
  bool _accompanying = true;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedLeadId != null && widget.state.allLeads.any((l) => l.id == widget.preselectedLeadId)) {
      _selectedLeadId = widget.preselectedLeadId!;
      final lead = widget.state.allLeads.firstWhere((l) => l.id == widget.preselectedLeadId);
      _selectedProjectId = lead.projectId;
    } else {
      _selectedLeadId = widget.state.allLeads.isNotEmpty ? widget.state.allLeads.first.id : '';
      _selectedProjectId = widget.state.projects.isNotEmpty ? widget.state.projects.first.id : '';
    }
  }

  void _submit() {
    final visitCode = widget.state.scheduleSiteVisit(
      leadId: _selectedLeadId,
      projectId: _selectedProjectId,
      scheduledAt: _selectedDateTime,
      cabRequired: _cabRequired,
      accompanying: _accompanying,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Visit $visitCode Scheduled! Digital QR Pass generated.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final dateFormat = DateFormat('EEE, d MMM • hh:mm a');

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Schedule Digital Site Visit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Text('Select Lead', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedLeadId,
            items: widget.state.allLeads.map((l) => DropdownMenuItem(value: l.id, child: Text('${l.fullName} (${l.phone})'))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLeadId = val);
            },
          ),
          const SizedBox(height: 14),

          Text('Target Project', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedProjectId,
            items: widget.state.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedProjectId = val);
            },
          ),
          const SizedBox(height: 14),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: const Text('Visit Date & Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(dateFormat.format(_selectedDateTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            trailing: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null && context.mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
              child: const Text('Change'),
            ),
          ),
          const SizedBox(height: 10),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Request Builder Cab Pickup for Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: _cabRequired,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _cabRequired = val),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Broker Accompanying Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: _accompanying,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _accompanying = val),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _submit,
            child: const Text('Generate Digital QR Entry Pass (Zero-OTP)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
