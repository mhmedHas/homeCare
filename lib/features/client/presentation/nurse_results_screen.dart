import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/locale_controller.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class NurseResultsScreen extends StatefulWidget{final String requestId;const NurseResultsScreen({super.key,required this.requestId});@override State<NurseResultsScreen> createState()=>_NurseResultsScreenState();}
class _NurseResultsScreenState extends State<NurseResultsScreen>{List<AppUser> _nurses=[];bool _loading=true;String? _error;bool get en=>LocaleController.instance.isEnglish;String tx(String ar,String english)=>en?english:ar;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{if(mounted)setState((){_loading=true;_error=null;});try{final snapshot=await FirebaseFirestore.instance.collection('users').where('role',isEqualTo:'nurse').where('isActive',isEqualTo:true).where('isVerified',isEqualTo:true).get();final nurses=snapshot.docs.map((doc)=>AppUser.fromFirestore(doc)).toList()..sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase()));if(mounted)setState(()=>_nurses=nurses);}catch(_){if(mounted)setState(()=>_error=tx('حدث خطأ في تحميل الممرضين','Unable to load nurses'));}finally{if(mounted)setState(()=>_loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(tx('الممرضين المتاحين','Available nurses')),actions:[IconButton(onPressed:_load,tooltip:tx('تحديث','Refresh'),icon:const Icon(Icons.refresh))]),body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(_error!,style:const TextStyle(color:AppColors.error)),const SizedBox(height:16),ElevatedButton(onPressed:_load,child:Text(tx('إعادة المحاولة','Retry')))])):_nurses.isEmpty?Center(child:Text(tx('لا يوجد ممرضين متاحين حالياً','No nurses are available right now'))):ListView.builder(padding:const EdgeInsets.all(8),itemCount:_nurses.length,itemBuilder:(context,index){final nurse=_nurses[index];return Card(margin:const EdgeInsets.symmetric(vertical:6),child:ListTile(leading:CircleAvatar(backgroundColor:AppColors.primary,child:Text(nurse.name.isNotEmpty?nurse.name[0]:'?')),title:Row(children:[Expanded(child:Text(nurse.name,maxLines:1,overflow:TextOverflow.ellipsis)),if(nurse.isVerified)const Icon(Icons.verified,color:AppColors.success,size:16)]),subtitle:Text('${nurse.phone} • ${tx('ممرض','Nurse')}'),trailing:Icon(en?Icons.arrow_forward_ios:Icons.arrow_back_ios,size:16),onTap:()=>context.go('/client/nurse-profile/${nurse.uid}?requestId=${widget.requestId}')));});
}
