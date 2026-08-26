import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/shared_preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Icons.health_and_safety,
      title: 'الرعاية اللي تحتاجها، أقرب ليك',
      description: 'وصل لأفضل مقدمي خدمات الرعاية المنزلية بسهولة وأمان.',
    ),
    OnboardingItem(
      icon: Icons.verified_user,
      title: 'ممرضين موثوقين',
      description:
          'اختار مقدم الرعاية المناسب بناءً على الخبرة والتقييم والتخصص.',
    ),
    OnboardingItem(
      icon: Icons.calendar_month,
      title: 'احجز وتابع بسهولة',
      description: 'احجز الشيفت وتابع تفاصيل الرعاية من مكان واحد.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await SharedPreferencesService().setOnboardingCompleted(true);
    if (mounted) context.go('/role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 120, color: AppColors.primary),
                        const SizedBox(height: 32),
                        Text(item.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(item.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('تخطي',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Row(
                    children: List.generate(
                        _items.length,
                        (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == _items.length - 1
                        ? 'ابدأ الآن'
                        : 'التالي'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  OnboardingItem(
      {required this.icon, required this.title, required this.description});
}
