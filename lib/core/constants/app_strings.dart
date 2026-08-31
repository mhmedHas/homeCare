import 'locale_controller.dart';

/// Centralized Arabic/English strings used by the application.
///
/// Keep user-facing text here so every screen uses the same terminology and
/// changing the app locale updates both client and nurse experiences.
class AppStrings {
  AppStrings._();

  static const Map<String, String> _ar = {
    'app_name': 'شفاء', 'save': 'حفظ', 'cancel': 'إلغاء', 'retry': 'إعادة المحاولة',
    'loading': 'جاري التحميل...', 'error_generic': 'حدث خطأ، حاول مرة أخرى',
    'error_load_home': 'حدث خطأ في تحميل البيانات', 'ok': 'تمام', 'edit': 'تعديل',
    'language': 'اللغة', 'arabic': 'العربية', 'english': 'الإنجليزية',
    'currency_egp': 'ج.م', 'none': 'لا يوجد', 'hours_short': 'ساعة', 'days_short': 'يوم',
    'nav_home': 'الرئيسية', 'nav_requests': 'الطلبات', 'nav_care_requests': 'طلبات الرعاية',
    'nav_bookings': 'حجوزاتي', 'nav_messages': 'الرسائل', 'nav_profile': 'حسابي',
    'onboarding_title_1': 'رعاية منزلية موثوقة',
    'onboarding_desc_1': 'احجز ممرضًا أو ممرضة مؤهلين لرعاية أحبائك في المنزل',
    'get_started': 'ابدأ الآن', 'login_title': 'تسجيل الدخول', 'phone_number': 'رقم الهاتف',
    'password': 'كلمة المرور', 'login_button': 'دخول', 'no_account': 'ليس لديك حساب؟',
    'register_now': 'سجل الآن', 'register_title': 'إنشاء حساب', 'full_name': 'الاسم بالكامل',
    'register_button': 'إنشاء الحساب', 'have_account': 'لديك حساب بالفعل؟',
    'login_now': 'تسجيل الدخول', 'role_selection_title': 'اختر نوع الحساب',
    'role_client': 'أحتاج إلى رعاية', 'role_nurse': 'أنا ممرض/ممرضة',
    'client_home_greeting': 'أهلاً بك', 'create_request': 'اطلب رعاية الآن',
    'my_recent_requests': 'طلباتي الأخيرة', 'view_all': 'عرض الكل', 'no_requests_yet': 'لا توجد طلبات بعد',
    'welcome_hi': 'أهلاً يا', 'welcome_subtitle': 'إحنا هنا عشان نسهّل عليك رعاية الحالة في البيت.',
    'need_nurse_title': 'محتاج ممرض؟',
    'need_nurse_desc': 'أنشئ طلب رعاية وحدد احتياجات الحالة، وبعدها اختار مقدم الرعاية المناسب.',
    'request_care_action': 'اطلب رعاية',
    'care_requests_shortcut_desc': 'تابع طلباتك وشوف عروض الممرضين واختار المناسب',
    'create_request_short': 'إنشاء طلب',
    'nurse_home_title': 'لوحة الممرض', 'nurse_new_requests': 'طلبات جديدة',
    'nurse_today_shifts': 'شيفت اليوم', 'nurse_earnings': 'الأرباح', 'nurse_rating': 'التقييم',
    'nurse_available_requests': 'الطلبات المتاحة', 'nurse_no_requests': 'لا توجد طلبات حالياً',
    'nurse_complete_verification': 'أكمل بيانات عملك وارفع مستنداتك عشان تقدر تستقبل طلبات',
    'status_open': 'مفتوح', 'status_booked': 'تم اختيار ممرض', 'status_in_progress': 'جاري',
    'status_completed': 'مكتمل', 'status_cancelled': 'ملغي', 'status_pending': 'قيد المراجعة',
    'my_account': 'حسابي', 'edit_info': 'تعديل البيانات', 'my_bookings': 'حجوزاتي',
    'my_requests': 'طلباتي', 'help': 'المساعدة', 'logout': 'تسجيل الخروج',
    'professional_profile': 'الملف المهني', 'work_settings': 'إعدادات العمل والمحافظات',
    'documents': 'المستندات', 'verification_status': 'حالة التحقق', 'previous_shifts': 'الشيفتات',
    'reviews': 'تقييماتي', 'verified_account': 'حساب موثق',
  };

  static const Map<String, String> _en = {
    'app_name': 'Shifaa', 'save': 'Save', 'cancel': 'Cancel', 'retry': 'Retry',
    'loading': 'Loading...', 'error_generic': 'Something went wrong, please try again',
    'error_load_home': 'An error occurred while loading your data', 'ok': 'OK', 'edit': 'Edit',
    'language': 'Language', 'arabic': 'Arabic', 'english': 'English', 'currency_egp': 'EGP',
    'none': 'None', 'hours_short': 'hrs', 'days_short': 'days', 'nav_home': 'Home',
    'nav_requests': 'Requests', 'nav_care_requests': 'Care Requests', 'nav_bookings': 'Bookings',
    'nav_messages': 'Messages', 'nav_profile': 'Profile', 'onboarding_title_1': 'Trusted home care',
    'onboarding_desc_1': 'Book qualified nurses to care for your loved ones at home',
    'get_started': 'Get Started', 'login_title': 'Login', 'phone_number': 'Phone number',
    'password': 'Password', 'login_button': 'Login', 'no_account': "Don't have an account?",
    'register_now': 'Register now', 'register_title': 'Create account', 'full_name': 'Full name',
    'register_button': 'Create account', 'have_account': 'Already have an account?',
    'login_now': 'Login', 'role_selection_title': 'Choose account type',
    'role_client': 'I need care', 'role_nurse': "I'm a nurse", 'client_home_greeting': 'Welcome',
    'create_request': 'Request care now', 'my_recent_requests': 'My recent requests',
    'view_all': 'View all', 'no_requests_yet': 'No requests yet', 'welcome_hi': 'Hi',
    'welcome_subtitle': "We're here to make caring for your loved one at home easier.",
    'need_nurse_title': 'Need a nurse?',
    'need_nurse_desc': 'Create a care request, describe what is needed, then choose the right caregiver.',
    'request_care_action': 'Request care',
    'care_requests_shortcut_desc': 'Track your requests and review nurse offers',
    'create_request_short': 'New request', 'nurse_home_title': 'Nurse dashboard',
    'nurse_new_requests': 'New requests', 'nurse_today_shifts': "Today's shifts",
    'nurse_earnings': 'Earnings', 'nurse_rating': 'Rating', 'nurse_available_requests': 'Available requests',
    'nurse_no_requests': 'No requests right now',
    'nurse_complete_verification': 'Complete your work details and upload your documents to start receiving requests',
    'status_open': 'Open', 'status_booked': 'Nurse assigned', 'status_in_progress': 'In progress',
    'status_completed': 'Completed', 'status_cancelled': 'Cancelled', 'status_pending': 'Under review',
    'my_account': 'My account', 'edit_info': 'Edit info', 'my_bookings': 'My bookings',
    'my_requests': 'My requests', 'help': 'Help', 'logout': 'Logout',
    'professional_profile': 'Professional profile', 'work_settings': 'Work settings & governorates',
    'documents': 'Documents', 'verification_status': 'Verification status', 'previous_shifts': 'Shifts',
    'reviews': 'My reviews', 'verified_account': 'Verified account',
  };

  static String t(String key) {
    final map = LocaleController.instance.isEnglish ? _en : _ar;
    return map[key] ?? _ar[key] ?? key;
  }
}
