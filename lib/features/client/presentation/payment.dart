import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}
class _PaymentScreenState extends State<PaymentScreen> {
  Booking? _booking; bool _isLoading=true; bool _isProcessing=false; String? _errorMessage; String _selectedMethod='card';
  List<PaymentMethod> get _methods => [
    PaymentMethod(id:'card', label:t('card_payment'), icon:Icons.credit_card),
    PaymentMethod(id:'fawry', label:t('fawry'), icon:Icons.qr_code),
    PaymentMethod(id:'cash', label:t('cash_on_visit'), icon:Icons.money),
  ];
  String t(String k)=>AppStrings.t(k);
  @override void initState(){super.initState();_loadBooking();}
  Future<void> _loadBooking() async {if(mounted)setState((){_isLoading=true;_errorMessage=null;});try{final booking=await BookingService().getBooking(widget.bookingId);if(booking==null){if(mounted)setState(()=>_errorMessage=t('booking_not_found'));return;}if(mounted)setState(()=>_booking=booking);}catch(_){if(mounted)setState(()=>_errorMessage=t('error_generic'));}finally{if(mounted)setState(()=>_isLoading=false);}}
  Future<void> _processPayment() async {final booking=_booking;if(booking==null)return;if(mounted)setState((){_isProcessing=true;_errorMessage=null;});try{await Future.delayed(const Duration(seconds:2));await BookingService().updateBookingStatus(widget.bookingId,'confirmed');if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('payment_success'))));context.go('/client/booking-details/${booking.id}');}catch(_){if(mounted)setState(()=>_errorMessage=t('payment_failed'));}finally{if(mounted)setState(()=>_isProcessing=false);}}
  @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:Text(t('payment'))),body:_isLoading?const Center(child:CircularProgressIndicator()):_errorMessage!=null||_booking==null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_errorMessage??t('booking_not_found')),const SizedBox(height:12),FilledButton(onPressed:_loadBooking,child:Text(t('retry')))])):Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('payment_details'),style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:16),_row(t('service_price'),'${(_booking!.totalAmount-_booking!.platformFee).toStringAsFixed(2)} ${t('currency_egp')}'),_row(t('service_fee'),'${_booking!.platformFee.toStringAsFixed(2)} ${t('currency_egp')}'),const Divider(),_row(t('total'),'${_booking!.totalAmount.toStringAsFixed(2)} ${t('currency_egp')}',total:true),const SizedBox(height:24),Text(t('payment_method'),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),..._methods.map((m)=>RadioListTile<String>(title:Row(children:[Icon(m.icon,color:AppColors.primary),const SizedBox(width:8),Text(m.label)]),value:m.id,groupValue:_selectedMethod,onChanged:_isProcessing?null:(v)=>setState(()=>_selectedMethod=v!))),const Spacer(),if(_errorMessage!=null)Padding(padding:const EdgeInsets.only(bottom:10),child:Text(_errorMessage!,style:const TextStyle(color:AppColors.error))),SizedBox(width:double.infinity,height:50,child:ElevatedButton(onPressed:_isProcessing?null:_processPayment,child:_isProcessing?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):Text(t('pay_now')))),const SizedBox(height:16)]));}
  Widget _row(String label,String value,{bool total=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:TextStyle(fontWeight:total?FontWeight.bold:FontWeight.normal)),Text(value,style:TextStyle(fontWeight:total?FontWeight.bold:FontWeight.normal,fontSize:total?18:16))]));
}
class PaymentMethod{final String id;final String label;final IconData icon;PaymentMethod({required this.id,required this.label,required this.icon});}
