import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/locale_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/shared_preferences_service.dart';

class SplashScreen extends StatefulWidget{const SplashScreen({super.key});@override State<SplashScreen> createState()=>_SplashScreenState();}
class _SplashScreenState extends State<SplashScreen>{String _status='loading';bool _error=false;String _message='';String t(String k)=>AppStrings.t(k);String tx(String ar,String english)=>LocaleController.instance.isEnglish?english:ar;
 @override void initState(){super.initState();_initialize();}
 Future<void> _initialize()async{try{if(mounted)setState(()=>_status=tx('جاري تهيئة التطبيق...','Initializing app...'));final auth=AuthService();final prefs=SharedPreferencesService();final user=auth.currentUser;if(user==null){if(prefs.isOnboardingCompleted()){if(mounted)context.go('/login');}else{if(mounted)context.go('/onboarding');}return;}if(mounted)setState(()=>_status=tx('جاري تحميل بيانات الحساب...','Loading account data...'));final appUser=await UserService().getUser(user.uid);if(appUser==null){if(mounted)context.go('/role');return;}if(appUser.role=='client'){if(mounted)context.go('/client/home');}else if(appUser.role=='nurse'){if(mounted)context.go('/nurse/home');}else{await auth.logout();if(mounted)context.go('/login');}}catch(_){if(mounted)setState((){_error=true;_message=tx('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.','An unexpected error occurred. Please try again.');});}}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AppColors.primary,body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:120,height:120,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.2),shape:BoxShape.circle),child:const Icon(Icons.health_and_safety,size:60,color:Colors.white)),const SizedBox(height:24),Text(t('app_name'),style:const TextStyle(fontSize:36,fontWeight:FontWeight.bold,color:Colors.white)),const SizedBox(height:8),Text(tx('خدمات الرعاية المنزلية','Home care services'),style:const TextStyle(fontSize:18,color:Colors.white70)),const SizedBox(height:40),if(_error)...[Text(_message,style:const TextStyle(color:Colors.white),textAlign:TextAlign.center),const SizedBox(height:16),ElevatedButton(onPressed:(){setState(()=>_error=false);_initialize();},style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:AppColors.primary),child:Text(tx('إعادة المحاولة','Retry')))]else...[const CircularProgressIndicator(color:Colors.white),const SizedBox(height:16),Text(_status=='loading'?t('loading'):_status,style:const TextStyle(color:Colors.white70))]]))));}
}
