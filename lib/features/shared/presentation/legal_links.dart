import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key});

  static const _links = <_InfoLink>[
    _InfoLink(
      icon: Icons.volunteer_activism_outlined,
      title: 'عن شفاء',
      subtitle: 'اعرف رسالتنا وإزاي بنساعدك توصل لرعاية منزلية مناسبة',
      route: '/info/about',
    ),
    _InfoLink(
      icon: Icons.description_outlined,
      title: 'الشروط والأحكام',
      subtitle: 'حقوقك والتزاماتك عند استخدام التطبيق',
      route: '/info/terms',
    ),
    _InfoLink(
      icon: Icons.privacy_tip_outlined,
      title: 'سياسة الخصوصية',
      subtitle: 'إزاي بنستخدم بياناتك ونحافظ على خصوصيتها',
      route: '/info/privacy',
    ),
    _InfoLink(
      icon: Icons.receipt_long_outlined,
      title: 'الإلغاء والاسترداد',
      subtitle: 'اعرف قواعد إلغاء الطلبات واسترداد المدفوعات',
      route: '/info/refund',
    ),
    _InfoLink(
      icon: Icons.support_agent_rounded,
      title: 'تواصل معنا',
      subtitle: 'إحنا هنا لمساعدتك والإجابة عن استفساراتك',
      route: '/info/contact',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'معلومات ومساعدة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'كل اللي تحتاج تعرفه عن شفاء واستخدام الخدمة.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _LinkTile(link: link),
            )),
      ],
    );
  }
}

class _InfoLink {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _InfoLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class _LinkTile extends StatelessWidget {
  final _InfoLink link;

  const _LinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(link.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(link.icon, color: AppColors.primary, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
