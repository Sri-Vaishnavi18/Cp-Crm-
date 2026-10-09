import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';

class NotificationCenterScreen extends StatefulWidget {
  final AppState state;

  const NotificationCenterScreen({super.key, required this.state});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final allNotifs = widget.state.notifications;
    final notifs = _selectedFilter == 'ALL'
        ? allNotifs
        : allNotifs.where((n) => n.type == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Broadcasts'),
        actions: [
          if (widget.state.unreadNotificationCount > 0)
            TextButton(
              onPressed: () {
                widget.state.markAllNotificationsRead();
                setState(() {});
              },
              child: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All (${allNotifs.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('visit', 'Site Visits'),
                const SizedBox(width: 8),
                _buildFilterChip('lead', 'Leads'),
                const SizedBox(width: 8),
                _buildFilterChip('broadcast', 'Broadcasts'),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: notifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 54, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications in this category',
                          style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      return _buildNotificationTile(context, n, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    final isDark = widget.state.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = key),
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

  Widget _buildNotificationTile(BuildContext context, AppNotificationModel notif, bool isDark) {
    IconData icon;
    Color iconColor;
    switch (notif.type) {
      case 'visit':
        icon = Icons.event_available;
        iconColor = Colors.teal;
        break;
      case 'lead':
        icon = Icons.person_add_alt;
        iconColor = AppColors.primary;
        break;
      default:
        icon = Icons.campaign;
        iconColor = Colors.orange;
    }

    final timeStr = DateFormat('d MMM, hh:mm a').format(notif.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          widget.state.markNotificationRead(notif.id);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
