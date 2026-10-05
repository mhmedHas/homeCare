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
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: type == InformationPageType.contact
            ? _ContactContent()
            : _PolicyContent(type: type),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('شفاء', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 16),
        ...sections.map((section) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              Text(section['body']!, style: const TextStyle(fontSize: 15, height: 1.65)),
            ],
          ),
        )),
      ],
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent();

  Future<void> _call() async {
    await launchUrl(Uri.parse('tel:01119684470'));
  }

  Future<void> _email() async {
    await launchUrl(Uri.parse('mailto:mhmed.hassan.antaka@gmail.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.support_agent, size: 72, color: AppColors.primary),
        const SizedBox(height: 12),
        Text('يسعدنا تواصلك معنا', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('للاستفسارات أو الشكاوى أو المساعدة المتعلقة بالحجز والدفع، يمكنك التواصل مع فريق شفاء.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.6)),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                title: const Text('الهاتف'),
                subtitle: const Text('01119684470'),
                trailing: const Icon(Icons.call_outlined),
                onTap: _call,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text('البريد الإلكتروني'),
                subtitle: const Text('mhmed.hassan.antaka@gmail.com'),
                trailing: const Icon(Icons.mail_outline),
                onTap: _email,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
