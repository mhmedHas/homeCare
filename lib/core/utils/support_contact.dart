import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// رقم واتساب الدعم الفني والشكاوى
const String kSupportWhatsAppNumber = '01119684470';

/// نفس الرقم لكن بصيغة دولية (مصر +20) مطلوبة لروابط واتساب
const String kSupportWhatsAppIntl = '201119684470';

/// يفتح محادثة واتساب مع رقم الدعم الفني، ويعرض رسالة خطأ لو تعذر ذلك
Future<void> openSupportWhatsApp(BuildContext context) async {
  final uri = Uri.parse('https://wa.me/$kSupportWhatsAppIntl');
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showError(context);
    }
  } catch (_) {
    if (context.mounted) {
      _showError(context);
    }
  }
}

void _showError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
          'تعذر فتح واتساب. تواصل معنا على الرقم: $kSupportWhatsAppNumber'),
    ),
  );
}
