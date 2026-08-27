import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/care_request_service.dart';
import '../../shared/models/care_request.dart';

class CreateCareRequestScreen extends StatefulWidget {
  const CreateCareRequestScreen({super.key});

  @override
  State<CreateCareRequestScreen> createState() => _CreateCareRequestScreenState();
}

class _CreateCareRequestScreenState extends State<CreateCareRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender = 'male';
  String? _selectedCareType = 'elderly';
  String? _selectedGovernorate = 'القاهرة';
  String? _selectedArea = 'مدينة نصر';
  List<String> _selectedServices = [];
  int _shiftHours = 12;
  int _daysCount = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _careTypes = ['elderly','post_surgery','chronic_disease','disability','maternity','general'];
  final List<String> _careTypeLabels = ['رعاية كبار السن','رعاية ما بعد العمليات','أمراض مزمنة','ذوي الاحتياجات الخاصة','رعاية الأمومة','عام'];
  final List<String> _governorates = ['القاهرة','الإسكندرية','الجيزة','القليوبية','الشرقية','الدقهلية','المنوفية','الغربية','البحيرة','كفر الشيخ','دمياط','بورسعيد','الإسماعيلية','السويس','الفيوم','بني سويف','المنيا','أسيوط','سوهاج','قنا','الأقصر','أسوان','مطروح','الوادي الجديد','شمال سيناء','جنوب سيناء','البحر الأحمر'];
  final List<String> _areas = ['مدينة نصر','مصر الجديدة','الزمالك','الدقي','المهندسين','مصر القديمة'];
  final List<String> _allServices = ['متابعة الحالة','إعطاء الأدوية','قياس الضغط','قياس السكر','تغيير الجروح','مساعدة الحركة','رعاية كبار السن','رعاية ما بعد العمليات'];
  static const List<int> _shiftOptions = [6, 12, 24];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      setState(() => _errorMessage = 'اختار خدمة واحدة على الأقل');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('unauthenticated');
      final request = CareRequest(
        id: '', clientId: user.uid,
        patientName: _patientNameController.text.trim(),
        patientAge: int.parse(_patientAgeController.text.trim()),
        patientGender: _selectedGender!, careType: _selectedCareType!,
        services: List<String>.from(_selectedServices), shiftHours: _shiftHours,
        daysCount: _daysCount, startDate: _selectedDate, startTime: _selectedTime,
        governorate: _selectedGovernorate!, area: _selectedArea!,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final requestId = await CareRequestService().createRequest(request);
      if (mounted) context.go('/client/request-details/$requestId');
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ أثناء إنشاء الطلب، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateFormat.jm().format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب رعاية جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('بيانات الحالة', Icons.person_outline),
            TextFormField(controller: _patientNameController, decoration: const InputDecoration(labelText: 'اسم الحالة', prefixIcon: Icon(Icons.person)), validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _patientAgeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر', prefixIcon: Icon(Icons.numbers)), validator: (v) { final age = int.tryParse(v ?? ''); return age == null || age < 1 || age > 120 ? 'اكتب عمر صحيح' : null; }),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _selectedGender, decoration: const InputDecoration(labelText: 'الجنس', prefixIcon: Icon(Icons.people_outline)), items: const [DropdownMenuItem(value: 'male', child: Text('ذكر')), DropdownMenuItem(value: 'female', child: Text('أنثى'))], onChanged: (v) => setState(() => _selectedGender = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _selectedCareType, decoration: const InputDecoration(labelText: 'نوع الرعاية', prefixIcon: Icon(Icons.medical_services_outlined)), items: _careTypes.asMap().entries.map((e) => DropdownMenuItem(value: e.value, child: Text(_careTypeLabels[e.key]))).toList(), onChanged: (v) => setState(() => _selectedCareType = v)),
            const SizedBox(height: 20),
            _sectionTitle('الخدمات المطلوبة', Icons.medical_information_outlined),
            Wrap(spacing: 8, runSpacing: 8, children: _allServices.map((service) { final selected = _selectedServices.contains(service); return FilterChip(label: Text(service), selected: selected, onSelected: (value) => setState(() { if (value) { _selectedServices.add(service); } else { _selectedServices.remove(service); } })); }).toList()),
            const SizedBox(height: 20),
            _sectionTitle('نظام الشيفت', Icons.access_time),
            SegmentedButton<int>(segments: _shiftOptions.map((h) => ButtonSegment<int>(value: h, label: Text('$h ساعة'), icon: const Icon(Icons.schedule))).toList(), selected: {_shiftHours}, onSelectionChanged: (value) => setState(() => _shiftHours = value.first)),
            const SizedBox(height: 12),
            Row(children: [const Text('عدد الأيام'), const Spacer(), IconButton(onPressed: _daysCount > 1 ? () => setState(() => _daysCount--) : null, icon: const Icon(Icons.remove_circle_outline)), Text('$_daysCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(onPressed: _daysCount < 30 ? () => setState(() => _daysCount++) : null, icon: const Icon(Icons.add_circle_outline))]),
            const SizedBox(height: 8),
            Card(child: Column(children: [ListTile(title: const Text('تاريخ البداية'), subtitle: Text(DateFormat.yMMMMd('ar').format(_selectedDate)), leading: const Icon(Icons.calendar_today), onTap: () async { final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90))); if (date != null) setState(() => _selectedDate = date); }), ListTile(title: const Text('وقت البداية'), subtitle: Text(_formatTime(_selectedTime)), leading: const Icon(Icons.access_time), onTap: () async { final time = await showTimePicker(context: context, initialTime: _selectedTime); if (time != null) setState(() => _selectedTime = time); })])),
            const SizedBox(height: 20),
            _sectionTitle('مكان الرعاية', Icons.location_on_outlined),
            DropdownButtonFormField<String>(value: _selectedGovernorate, decoration: const InputDecoration(labelText: 'المحافظة', prefixIcon: Icon(Icons.location_city)), items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _selectedGovernorate = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _selectedArea, decoration: const InputDecoration(labelText: 'المنطقة', prefixIcon: Icon(Icons.place_outlined)), items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(), onChanged: (v) => setState(() => _selectedArea = v)),
            const SizedBox(height: 12),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل', prefixIcon: Icon(Icons.home_outlined)), validator: (v) => v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات إضافية (اختياري)', alignLabelWithHint: true)),
            const SizedBox(height: 16),
            if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error))),
            SizedBox(height: 52, child: FilledButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('نشر طلب الرعاية'))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]));
}
