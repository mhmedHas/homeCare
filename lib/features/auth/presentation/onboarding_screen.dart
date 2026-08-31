import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/shared_preferences_service.dart';

class OnboardingScreen extends StatefulWidget { const OnboardingScreen({super.key}); @override State<OnboardingScreen> createState()=>_OnboardingScreenState(); }
class _OnboardingScreenState extends State<OnboardingScreen>{final PageController _pageController=PageController();int _currentPage=0;String t(String k)=>AppStrings.t(k);List<OnboardingItem> get _items=>[
 OnboardingItem(icon:Icons.health_and_safety,title:t('onboarding_care_title'),description:t('onboarding_care_desc')),
 OnboardingItem(icon:Icons.verified_user,title:t('onboarding_trusted_title'),description:t('onboarding_trusted_desc')),
 OnboardingItem(icon:Icons.calendar_month,title:t('onboarding_booking_title'),description:t('onboarding_booking_desc')),
 ];
 void _nextPage(){if(_currentPage<_items.length-1){_pageController.nextPage(duration:const Duration(milliseconds:300),curve:Curves.easeIn);}else{_completeOnboarding();}}
 Future<void> _completeOnboarding()async{await SharedPreferencesService().setOnboardingCompleted(true);if(mounted)context.go('/role');}
 @override Widget build(BuildContext context){final items=_items;return Scaffold(body:SafeArea(child:Column(children:[Expanded(child:PageView.builder(controller:_pageController,onPageChanged:(i)=>setState(()=>_currentPage=i),itemCount:items.length,itemBuilder:(context,index){final item=items[index];return Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(item.icon,size:120,color:AppColors.primary),const SizedBox(height:32),Text(item.title,style:Theme.of(context).textTheme.headlineMedium,textAlign:TextAlign.center),const SizedBox(height:16),Text(item.description,style:Theme.of(context).textTheme.bodyLarge,textAlign:TextAlign.center)]));})),Padding(padding:const EdgeInsets.symmetric(horizontal:24,vertical:16),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[TextButton(onPressed:_completeOnboarding,child:Text(t('skip'),style:const TextStyle(color:AppColors.textSecondary))),Row(children:List.generate(items.length,(i)=>Container(margin:const EdgeInsets.symmetric(horizontal:4),width:_currentPage==i?24:8,height:8,decoration:BoxDecoration(color:_currentPage==i?AppColors.primary:Colors.grey.shade300,borderRadius:BorderRadius.circular(4))))),ElevatedButton(onPressed:_nextPage,child:Text(_currentPage==items.length-1?t('get_started'):t('next')))])])));}
 @override void dispose(){_pageController.dispose();super.dispose();}}
class OnboardingItem{final IconData icon;final String title;final String description;OnboardingItem({required this.icon,required this.title,required this.description});}
