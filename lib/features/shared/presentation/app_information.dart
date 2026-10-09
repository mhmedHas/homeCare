import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

enum InformationPageType { about, terms, privacy, refund, contact }

class AppInformationScreen extends StatelessWidget {
  final InformationPageType type;
  const AppInformationScreen({super.key, required this.type});

  String get title {
    switch (type) {
      case InformationPageType.about: return 'عن شفاء';
      case InformationPageType.terms: return 'الشروط والأحكام';
      case InformationPageType.privacy: return 'سياسة الخصوصية';
      case InformationPageType.refund: return 'سياسة الإلغاء والاسترداد';
      case InformationPageType.contact: return 'تواصل معنا';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InformationHero(type: type, title: title),
            const SizedBox(height: 18),
            if (type == InformationPageType.contact)
              const _ContactContent()
            else
              _PolicyContent(type: type),
          ],
        ),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  final InformationPageType type;
  const _PolicyContent({required this.type});

  List<Map<String, String>> get sections {
    switch (type) {
      case InformationPageType.about:
        return [
          {'title': 'من نحن', 'body': 'شفاء منصة رقمية تهدف إلى تسهيل الوصول إلى خدمات الرعاية المنزلية وربط العملاء بمقدمي خدمات الرعاية المناسبين، مع توفير تجربة واضحة ومنظمة لإدارة الطلبات والحجوزات والتواصل.'},
          {'title': 'هدف شفاء', 'body': 'نسعى إلى جعل الوصول إلى خدمات الرعاية المنزلية أكثر سهولة، مع عرض بيانات مقدمي الخدمة المتاحة على المنصة ومساعدة العميل على اختيار الخدمة المناسبة لاحتياجه.'},
          {'title': 'طبيعة المنصة', 'body': 'شفاء منصة وسيطة لتنظيم والتواصل بين العملاء ومقدمي خدمات الرعاية. تفاصيل الخدمة والتوافر والأسعار تعتمد على البيانات التي يقدمها مقدم الخدمة وعلى الحجز المؤكد داخل المنصة.'},
          {'title': 'التواصل', 'body': 'للاستفسارات والدعم والشكاوى يمكنك التواصل معنا من خلال بيانات الاتصال الموجودة في صفحة «تواصل معنا» داخل التطبيق.'},
        ];
      case InformationPageType.terms:
        return [
          {'title': '1. قبول الشروط', 'body': 'باستخدام تطبيق شفاء أو إنشاء حساب أو إجراء حجز، فإنك تقر بأنك قرأت هذه الشروط ووافقت عليها. إذا كنت لا توافق عليها، يرجى عدم استخدام خدمات التطبيق.'},
          {'title': '2. الحساب والبيانات', 'body': 'يلتزم المستخدم بتقديم بيانات صحيحة ومحدثة، والمحافظة على سرية بيانات الدخول وعدم مشاركة الحساب مع الآخرين. يتحمل المستخدم مسؤولية الأنشطة التي تتم من خلال حسابه.'},
          {'title': '3. الحجوزات والخدمات', 'body': 'الحجز يصبح نافذاً وفق حالة الحجز الموضحة داخل التطبيق وبعد استكمال الإجراءات المطلوبة. يجب على العميل ومقدم الخدمة الالتزام بالبيانات المتفق عليها في الحجز والتواصل من خلال الوسائل المتاحة في التطبيق عند الحاجة.'},
          {'title': '4. مقدمو الخدمة', 'body': 'مقدمو خدمات الرعاية مسؤولون عن صحة بياناتهم المهنية والمستندات التي يقدمونها، وعن أداء الخدمة المتفق عليها ضمن حدود مؤهلاتهم وصلاحياتهم. عرض مقدم الخدمة داخل المنصة لا يعني أن شفاء يحل محل الجهات التنظيمية أو الطبية المختصة.'},
          {'title': '5. الأسعار والمدفوعات', 'body': 'تظهر قيمة الخدمة وفق البيانات والأسعار المعروضة قبل إتمام الحجز. عند توفر الدفع الإلكتروني، يتم تنفيذ عملية الدفع من خلال مزود الدفع المعتمد، وتخضع العملية أيضاً لشروط مزود الدفع.'},
          {'title': '6. السلوك الممنوع', 'body': 'يُمنع استخدام المنصة في أي نشاط غير قانوني أو احتيالي، أو تقديم بيانات مزيفة، أو إساءة استخدام الحساب، أو محاولة تعطيل الخدمة، أو الإساءة أو التهديد لأي مستخدم أو مقدم خدمة.'},
          {'title': '7. إلغاء الحجز والاسترداد', 'body': 'تخضع عمليات الإلغاء والاسترداد لسياسة الإلغاء والاسترداد المنشورة داخل التطبيق. قد تختلف نتيجة الإلغاء بحسب توقيت الإلغاء وحالة الحجز وما إذا كانت الخدمة قد بدأت.'},
          {'title': '8. حدود المسؤولية', 'body': 'تعمل شفاء كمنصة لتنظيم خدمات الرعاية المنزلية. يجب على المستخدم تقييم مدى ملاءمة الخدمة لحالته واحتياجاته، ولا يُفهم استخدام المنصة على أنه بديل عن الطوارئ الطبية أو الاستشارة الطبية المتخصصة.'},
          {'title': '9. التعديلات', 'body': 'يجوز لشفاء تحديث هذه الشروط أو خصائص المنصة عند الحاجة. استمرار استخدام التطبيق بعد نشر التعديلات يعني قبول الشروط المحدثة.'},
        ];
      case InformationPageType.privacy:
        return [
          {'title': '1. البيانات التي نجمعها', 'body': 'قد يجمع التطبيق بيانات الحساب مثل الاسم ورقم الهاتف والبريد الإلكتروني، وبيانات الملف الشخصي، وبيانات الحجز والخدمة، والمعلومات التي يضيفها المستخدم إلى حسابه أو طلبه، وبيانات المستندات المهنية لمقدمي الخدمة عند الحاجة للتحقق.'},
          {'title': '2. استخدام البيانات', 'body': 'نستخدم البيانات لتسجيل الحسابات، وتشغيل الحجوزات والطلبات، وربط العملاء بمقدمي الخدمة، وإتاحة التواصل، وتحسين الخدمة، ومعالجة المدفوعات، وإرسال الإشعارات المهمة المتعلقة بالحساب والحجز.'},
          {'title': '3. مشاركة البيانات', 'body': 'قد تتم مشاركة البيانات اللازمة لتنفيذ الحجز أو التواصل بين أطراف الخدمة، أو مع مزودي الخدمات التقنية والدفع والإشعارات الذين نحتاجهم لتشغيل المنصة، أو عندما يكون الإفصاح مطلوباً بموجب القانون.'},
          {'title': '4. حماية البيانات', 'body': 'نتخذ إجراءات تقنية وتنظيمية مناسبة للمساعدة في حماية بيانات المستخدمين، مع العلم أن أي خدمة عبر الإنترنت لا يمكن ضمان حمايتها بشكل مطلق من جميع المخاطر.'},
          {'title': '5. الاحتفاظ بالبيانات', 'body': 'نحتفظ بالبيانات بالقدر اللازم لتشغيل الحساب والخدمات والامتثال للالتزامات القانونية وحل النزاعات ومنع الاحتيال، ثم يتم حذفها أو إخفاء هويتها عندما لا تعود هناك حاجة مشروعة للاحتفاظ بها.'},
          {'title': '6. حقوق المستخدم', 'body': 'يمكن للمستخدم طلب تصحيح بياناته أو الاستفسار عن طريقة استخدامها أو طلب المساعدة بشأن بيانات حسابه من خلال التواصل مع شفاء عبر بيانات الاتصال المنشورة في التطبيق، مع مراعاة المتطلبات القانونية والبيانات التي يلزم الاحتفاظ بها.'},
          {'title': '7. خدمات الطرف الثالث', 'body': 'قد يعتمد التطبيق على خدمات تقنية خارجية مثل Firebase وSupabase ومزودي الدفع والإشعارات. قد تخضع البيانات التي تتم معالجتها عبر هذه الخدمات لسياسات الخصوصية الخاصة بها بالإضافة إلى هذه السياسة.'},
          {'title': '8. التحديثات', 'body': 'قد يتم تحديث سياسة الخصوصية عند إضافة خصائص أو خدمات جديدة. سيتم نشر النسخة المحدثة داخل التطبيق.'},
        ];
      case InformationPageType.refund:
        return [
          {'title': '1. نطاق السياسة', 'body': 'تنطبق هذه السياسة على الحجوزات المدفوعة داخل تطبيق شفاء، وتشمل الإلغاء والاسترداد المتعلقين بخدمات الرعاية المنزلية.'},
          {'title': '2. الإلغاء قبل بدء الخدمة', 'body': 'إذا طلب العميل إلغاء الحجز قبل بدء الشيفت، يتم تقييم الاسترداد وفق حالة الحجز وتوقيت الإلغاء وأي رسوم أو التزامات مستحقة مرتبطة بالحجز. يتم توضيح أي مبلغ مسترد للمستخدم عند معالجة الإلغاء.'},
          {'title': '3. بعد بدء الخدمة', 'body': 'بعد بدء الشيفت لا يضمن الإلغاء استرداد كامل قيمة الحجز. يتم تقييم الحالات الاستثنائية، مثل عدم قدرة مقدم الخدمة على تنفيذ الحجز أو وجود مشكلة جوهرية في الخدمة، من خلال شفاء وفق تفاصيل الحالة.'},
          {'title': '4. إلغاء مقدم الخدمة', 'body': 'إذا تعذر على مقدم الخدمة تنفيذ حجز مؤكد قبل بدء الخدمة، تعمل شفاء على معالجة الحالة ومساعدة العميل في الوصول إلى حل مناسب، وقد يشمل ذلك إعادة الحجز أو استرداد المبلغ المدفوع بحسب الحالة.'},
          {'title': '5. طلب الاسترداد', 'body': 'يجب تقديم طلب الإلغاء أو الشكوى في أقرب وقت ممكن عبر قنوات الدعم الموضحة في التطبيق، مع ذكر رقم الحجز وتفاصيل المشكلة.'},
          {'title': '6. مدة الاسترداد', 'body': 'بعد اعتماد الاسترداد من شفاء، قد تستغرق إعادة المبلغ مدة إضافية وفق إجراءات مزود الدفع والبنك أو وسيلة الدفع المستخدمة. لا تتحكم شفاء في المدة البنكية النهائية.'},
          {'title': '7. الحالات الاستثنائية', 'body': 'تُدرس النزاعات والحالات الاستثنائية كل حالة على حدة بناءً على بيانات الحجز والتواصل والمستندات المتاحة، وبما لا يخالف القوانين واللوائح المعمول بها.'},
        ];
      case InformationPageType.contact:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.asMap().entries.map((entry) {
        final section = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE5ECF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      (entry.key + 1).toString(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        section['title']!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                section['body']!,
                style: const TextStyle(fontSize: 14, height: 1.75, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


class _InformationHero extends StatelessWidget {
  final InformationPageType type;
  final String title;
  const _InformationHero({required this.type, required this.title});

  IconData get _icon {
    switch (type) {
      case InformationPageType.about: return Icons.volunteer_activism_outlined;
      case InformationPageType.terms: return Icons.description_outlined;
      case InformationPageType.privacy: return Icons.shield_outlined;
      case InformationPageType.refund: return Icons.receipt_long_outlined;
      case InformationPageType.contact: return Icons.support_agent_rounded;
    }
  }

  String get _subtitle {
    switch (type) {
      case InformationPageType.about: return 'رعاية منزلية أقرب ليك وراحة بال لأسرتك.';
      case InformationPageType.terms: return 'اقرأ القواعد المنظمة لاستخدام خدمات شفاء.';
      case InformationPageType.privacy: return 'معلوماتك وخصوصيتك جزء مهم من تجربتك معانا.';
      case InformationPageType.refund: return 'كل التفاصيل المتعلقة بالإلغاء واسترداد المدفوعات.';
      case InformationPageType.contact: return 'محتاج مساعدة؟ فريق شفاء يسعده التواصل معاك.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF155E75)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(_icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(_subtitle, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent();

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق التواصل. حاول مرة أخرى.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق التواصل. حاول مرة أخرى.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5ECF1)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إحنا موجودين علشان نساعدك',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              SizedBox(height: 8),
              Text(
                'لو عندك استفسار عن الحجز أو الدفع أو واجهتك مشكلة في استخدام التطبيق، تواصل معانا من خلال الوسيلة المناسبة ليك.',
                style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ContactMethodCard(
          icon: Icons.phone_in_talk_outlined,
          title: 'اتصل بينا',
          detail: '01119684470',
          actionLabel: 'إجراء مكالمة',
          onTap: () => _openLink(context, Uri.parse('tel:01119684470')),
        ),
        const SizedBox(height: 10),
        _ContactMethodCard(
          icon: Icons.email_outlined,
          title: 'البريد الإلكتروني',
          detail: 'mhmed.hassan.antaka@gmail.com',
          actionLabel: 'إرسال رسالة',
          onTap: () => _openLink(context, Uri.parse('mailto:mhmed.hassan.antaka@gmail.com')),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'لو بتتواصل بخصوص حجز، جهّز رقم الحجز ووصف مختصر للمشكلة علشان نقدر نساعدك بشكل أسرع.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;

  const _ContactMethodCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(detail, textDirection: TextDirection.ltr, textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(actionLabel, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

