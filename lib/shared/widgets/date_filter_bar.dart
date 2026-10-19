import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Reusable Date Filter Bar with:
/// - Today
/// - Yesterday
/// - 7 Days
/// - 30 Days
/// - Manual Calendar (Date Range Picker)
/// - Reset Button
class DateFilterBar extends StatelessWidget {
  final AppState state;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onFilterChanged;

  const DateFilterBar({
    super.key,
    required this.state,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.onFilterChanged,
  });

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final isDark = state.isDarkMode;

    final initialRange = state.customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: initialRange,
      helpText: 'SELECT DATE RANGE',
      cancelText: 'CANCEL',
      confirmText: 'APPLY FILTER',
      saveText: 'APPLY',
      builder: (context, child) {
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              primary: const Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF0F172A) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      state.setCustomDateRange(picked);
      onFilterChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final currentPreset = state.dashboardDatePreset;
    final isCustom = currentPreset == DashboardDatePreset.custom;
    final isFilterActive = state.isDateFilterActive;

    String calendarLabel = 'Calendar';
    if (isCustom && state.customDateRange != null) {
      final range = state.customDateRange!;
      calendarLabel = '${_formatDate(range.start)} - ${_formatDate(range.end)}';
    }

    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. All Time (Default / Baseline)
            _buildFilterPill(
              context: context,
              label: 'All Time',
              isSelected: currentPreset == DashboardDatePreset.allTime,
              isDark: isDark,
              onTap: () {
                state.resetDashboardDateFilter();
                onFilterChanged?.call();
              },
            ),
            const SizedBox(width: 8),

            // 2. Today
            _buildFilterPill(
              context: context,
              label: 'Today',
              isSelected: currentPreset == DashboardDatePreset.today,
              isDark: isDark,
              onTap: () {
                state.setDashboardDatePreset(DashboardDatePreset.today);
                onFilterChanged?.call();
              },
            ),
            const SizedBox(width: 8),

            // 3. Yesterday
            _buildFilterPill(
              context: context,
              label: 'Yesterday',
              isSelected: currentPreset == DashboardDatePreset.yesterday,
              isDark: isDark,
              onTap: () {
                state.setDashboardDatePreset(DashboardDatePreset.yesterday);
                onFilterChanged?.call();
              },
            ),
            const SizedBox(width: 8),

            // 4. 7 Days
            _buildFilterPill(
              context: context,
              label: '7 Days',
              isSelected: currentPreset == DashboardDatePreset.last7Days,
              isDark: isDark,
              onTap: () {
                state.setDashboardDatePreset(DashboardDatePreset.last7Days);
                onFilterChanged?.call();
              },
            ),
            const SizedBox(width: 8),

            // 5. 30 Days
            _buildFilterPill(
              context: context,
              label: '30 Days',
              isSelected: currentPreset == DashboardDatePreset.last30Days,
              isDark: isDark,
              onTap: () {
                state.setDashboardDatePreset(DashboardDatePreset.last30Days);
                onFilterChanged?.call();
              },
            ),
            const SizedBox(width: 8),

            // 6. Manual Calendar
            _buildCalendarPill(
              context: context,
              label: calendarLabel,
              isSelected: isCustom,
              isDark: isDark,
              onTap: () => _pickDateRange(context),
            ),

            // 7. Reset Button (Visible when any filter is active)
            if (isFilterActive) ...[
              const SizedBox(width: 8),
              _buildResetButton(
                context: context,
                isDark: isDark,
                onTap: () {
                  state.resetDashboardDateFilter();
                  onFilterChanged?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton({
    required BuildContext context,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2).withValues(alpha: isDark ? 0.2 : 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restart_alt_rounded,
              size: 14,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 4),
            Text(
              'Reset',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
