import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/app_user.dart';

class BookingConfirmationScreen extends StatefulWidget { final String bookingId; const BookingConfirmationScreen({super.key,required this.bookingId}); @override State<BookingConfirmationScreen> createState()=>_BookingConfirmationScreenState(); }
class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>{ Booking? _booking; AppUser? _nurse; bool _isLoading=true; String? _errorMessage; String t(String k)=>AppStrings.t(k);
 @override void initState(){super.initState();_loadData();}
 Future<void> _loadData() async {setState((){_isLoading=true;_errorMessage=null;});try{final booking=await BookingService().getBooking(widget.bookingId);if(booking==null){setState(()=>_errorMessage=t('booking_not_found'));return;}setState(()=>_booking=booking);final nurse=await UserService().getUser(booking.nurseId);setState(()=>_nurse=nurse);}catch(_){setState(()=>_errorMessage=t('something_wrong'));}finally{if(mounted)setState(()=>_isLoading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(t('booking_confirmation'))),body:_isLoading?const Center(child:CircularProgressIndicator()):_errorMessage!=null||_booking==null?Center(child:Text(_errorMessage??t('no_data'))):Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Center(child:Icon(Icons.check_circle,color:AppColors.success,size:80)),const SizedBox(height:16),Center(child:Text(t('booking_created_successfully'),style:TextStyle(fontSize:22,fontWeight:FontWeight.bold))),const SizedBox(height:24),_buildInfoRow(t('nurse'),_nurse?.name??t('unknown')), _buildInfoRow(t('hours_count'),'${_booking!.shiftHours} ${t('hours_short')}'),_buildInfoRow(t('hourly_price'),'${_booking!.pricePerHour} ${t('currency_egp')}'),_buildInfoRow(t('service_fee'),'${_booking!.platformFee} ${t('currency_egp')}'),const Divider(thickness:2),_buildInfoRow(t('total'),'${_booking!.totalAmount} ${t('currency_egp')}',isTotal:true),const Spacer(),SizedBox(width:double.infinity,height:50,child:ElevatedButton.icon(onPressed:()=>context.go('/client/booking-details/${_booking!.id}'),icon:const Icon(Icons.visibility),label:Text(t('view_booking_details'))))]));
 Widget _buildInfoRow(String label,String value,{bool isTotal=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:TextStyle(fontWeight:isTotal?FontWeight.bold:FontWeight.normal)),Text(value,style:TextStyle(fontWeight:isTotal?FontWeight.bold:FontWeight.normal,fontSize:isTotal?18:16))]));
}