import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class UrlActionService {
  /// 1-Tap Phone Dialer Launch (`tel:`)
  static Future<bool> makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer for $cleanNumber')),
        );
      }
      return false;
    }
  }

  /// 1-Tap Pre-configured WhatsApp Chat (`https://wa.me/`)
  static Future<bool> openWhatsApp(
    BuildContext context, {
    required String phoneNumber,
    required String message,
  }) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    // Ensure country code is present (defaulting to 91 if 10-digit Indian number)
    final formattedNumber = cleanNumber.length == 10 ? '91$cleanNumber' : cleanNumber;
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$formattedNumber?text=$encodedMessage';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed on this device.')),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e')),
        );
      }
      return false;
    }
  }

  /// 1-Tap SMS
  static Future<bool> sendSms(BuildContext context, String phoneNumber, String message) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('sms:$cleanNumber?body=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Native Share Sheet (iOS UIActivityViewController / Android Intent.ACTION_SEND)
  static Future<void> shareContent(
    BuildContext context, {
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  /// 1-Tap Email Composer (`mailto:`)
  static Future<bool> sendEmail(
    BuildContext context, {
    required String email,
    String? subject,
    String? body,
  }) async {
    final query = <String, String>{};
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (body != null && body.isNotEmpty) query['body'] = body;

    final uri = Uri(
      scheme: 'mailto',
      path: email.trim(),
      query: query.isNotEmpty ? query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&') : null,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email client for $email')),
        );
      }
      return false;
    }
  }
}
