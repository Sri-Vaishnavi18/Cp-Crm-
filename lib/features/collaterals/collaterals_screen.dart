import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';

class CollateralsScreen extends StatefulWidget {
  final AppState state;

  const CollateralsScreen({super.key, required this.state});

  @override
  State<CollateralsScreen> createState() => _CollateralsScreenState();
}

class _CollateralsScreenState extends State<CollateralsScreen> {
  String _selectedCategory = 'ALL';
  bool _enableCoBranding = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final allCollaterals = widget.state.collaterals;
    final collaterals = _selectedCategory == 'ALL'
        ? allCollaterals
        : allCollaterals.where((c) => c.category == _selectedCategory).toList();

    return Scaffold(
      body: Column(
        children: [
          // Dynamic Co-Branding Watermark Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dynamic Co-Branding Watermark',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Stamps your firm info on all shared PDFs & floor plans',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _enableCoBranding,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _enableCoBranding = val),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCatChip('ALL', 'All Collateral (${allCollaterals.length})'),
                      _buildCatChip('Brochure', 'Brochures (PDF)'),
                      _buildCatChip('Floor Plan', 'Floor Plans'),
                      _buildCatChip('Price Sheet', 'Price Sheets'),
                      _buildCatChip('Approval', 'RERA Clearances'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Collaterals List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: collaterals.length,
              itemBuilder: (context, index) {
                final item = collaterals[index];
                return _buildCollateralCard(context, item, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    final isDark = widget.state.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = key),
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

  Widget _buildCollateralCard(BuildContext context, CollateralModel item, bool isDark) {
    IconData icon;
    Color iconColor;
    switch (item.category) {
      case 'Brochure':
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'Floor Plan':
        icon = Icons.layers_outlined;
        iconColor = Colors.teal;
        break;
      case 'Price Sheet':
        icon = Icons.table_chart_outlined;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.verified_outlined;
        iconColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.projectName} • ${item.fileSize}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                if (item.isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('OFFLINE READY', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Co-branding watermark preview badge (if enabled)
            if (_enableCoBranding)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final rera = widget.state.currentUser?.reraNumber ?? '';
                          final safeRera = rera.length > 14 ? '${rera.substring(0, 14)}...' : rera;
                          return Text(
                            'Co-Brand Watermark: ${widget.state.currentUser?.firmName} | RERA: $safeRera',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Share Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareCollateral(context, item, isWhatsApp: true),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Share WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.whatsapp,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareCollateral(context, item, isWhatsApp: false),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Native Share', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareCollateral(BuildContext context, CollateralModel item, {required bool isWhatsApp}) {
    final brandingFooter = _enableCoBranding
        ? '\n\n*Presented Exclusively by:*\n${widget.state.currentUser?.firmName}\nRERA: ${widget.state.currentUser?.reraNumber}\nContact: +91 ${widget.state.currentUser?.phone}'
        : '';

    final shareText = '''
*${item.projectName} — ${item.title}*
Category: ${item.category}
Download Asset: ${item.fileUrl}
$brandingFooter
''';

    UrlActionService.shareContent(context, text: shareText, subject: '${item.projectName} - ${item.title}');
  }
}
