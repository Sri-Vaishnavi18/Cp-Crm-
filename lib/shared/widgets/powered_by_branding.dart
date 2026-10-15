import 'package:flutter/material.dart';

/// A sleek, subtle footer branding widget that displays "Powered by Diradz Solutions".
/// Designed to be small, elegant, and non-intrusive so it does not distract from main UI flows.
class PoweredByBranding extends StatelessWidget {
  final bool? isDark;
  final EdgeInsetsGeometry padding;

  const PoweredByBranding({
    super.key,
    this.isDark,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final prefixColor = dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final brandColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: padding,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Powered by ',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: prefixColor,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Diradz Solutions',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: brandColor,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
