import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _item(context, Icons.info_outline, 'عن شفاء', '/info/about'),
          _item(context, Icons.description_outlined, 'الشروط والأحكام', '/info/terms'),
          _item(context, Icons.privacy_tip_outlined, 'سياسة الخصوصية', '/info/privacy'),
          _item(context, Icons.receipt_long_outlined, 'سياسة الإلغاء والاسترداد', '/info/refund'),
          _item(context, Icons.support_agent, 'تواصل معنا', '/info/contact'),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: () => context.push(route),
    );
  }
}
