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
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'male';
  String _selectedCareType = 'elderly';
  String _selectedGovernorate = 'القاهرة';
  final List<String> _selectedServices = [];
  int _shiftHours = 12;
  int _daysCount = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;
  String? _errorMessage;

  static const _careTypes = <String, String>{
    'elderly': 'رعاية كبار السن',
    'post_surgery': 'رعاية ما بعد العمليات',
    'chronic_disease': 'رعاية الأمراض المزمنة',
    'disability': 'رعاية ذوي الاحتياجات الخاصة',
    'maternity': 'رعاية الأمومة',
    'general': 'رعاية عامة',
  };

  static const _governorates = <String>[
    'القاهرة', 'الجيزة', 'الإسكندرية', 'القليوبية', 'الدقهلية', 'الشرقية',
    'الغربية', 'المنوفية', 'البحيرة', 'كفر الشيخ', 'دمياط', 'بورسعيد',
    'الإسماعيلية', 'السويس', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط',
    'سوهاج', 'قنا', 'الأقصر', 'أسوان', 'مطروح', 'الوادي الجديد',
    'شمال سيناء', 'جنوب سيناء', 'البحر الأحمر',
  ];

  static const _allServices = <String>[
    'متابعة الحالة',
    'إعطاء الأدوية',
    'قياس الضغط',
    'قياس السكر',
    'تغيير الجروح',
    'مساعدة الحركة',
    'رعاية كبار السن',
    'رعاية ما بعد العمليات',
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      setState(() => _errorMessage = 'اختار خدمة واحدة على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService().currentUser;
      if (user == null) throw StateError('unauthenticated');

      final request = CareRequest(
        id: '',
        clientId: user.uid,
        patientName: _patientNameController.text.trim(),
        patientAge: int.parse(_patientAgeController.text.trim()),
        patientGender: _selectedGender,
        careType: _selectedCareType,
        services: List.unmodifiable(_selectedServices),
        shiftHours: _shiftHours,
        daysCount: _daysCount,
        startDate: _selectedDate,
        startTime: _selectedTime,
        governorate: _selectedGovernorate,
        area: _areaController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final requestId = await CareRequestService().createRequest(request);
      if (!mounted) return;
      context.go('/client/request-details/$requestId');
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ أثناء إنشاء الطلب. تأكد من الاتصال وحاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateFormat.jm('ar').format(
      DateTime(now.year, now.month, now.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب رعاية جديد')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _sectionTitle('بيانات الحالة', Icons.person_outline),
              TextFormField(
                controller: _patientNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم الحالة',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اسم الحالة مطلوب'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _patientAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'العمر',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
                validator: (value) {
                  final age = int.tryParse(value?.trim() ?? '');
                  return age == null || age < 1 || age > 120
                      ? 'اكتب عمر صحيح من 1 إلى 120'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'الجنس',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('ذكر')),
                  DropdownMenuItem(value: 'female', child: Text('أنثى')),
                ],
                onChanged: _isLoading ? null : (value) {
                  if (value != null) setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCareType,
                decoration: const InputDecoration(
                  labelText: 'نوع الرعاية',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: _careTypes.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: _isLoading ? null : (value) {
                  if (value != null) setState(() => _selectedCareType = value);
                },
              ),
              const SizedBox(height: 20),
              _sectionTitle('الخدمات المطلوبة', Icons.medical_information_outlined),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allServices.map((service) {
                  final selected = _selectedServices.contains(service);
                  return FilterChip(
                    label: Text(service),
                    selected: selected,
                    onSelected: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              if (value) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                              _errorMessage = null;
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle('نظام الشيفت', Icons.access_time_outlined),
              SegmentedButton<int>(
                segments: CareRequest.allowedShiftHours
                    .map((hours) => ButtonSegment<int>(
                          value: hours,
                          label: Text('$hours ساعة'),
                          icon: const Icon(Icons.schedule_outlined),
                        ))
                    .toList(),
                selected: {_shiftHours},
                onSelectionChanged: _isLoading
                    ? null
                    : (value) => setState(() => _shiftHours = value.first),
              ),
              const SizedBox(height: 12),
              Card(
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 16),
                      child: Text('عدد الأيام'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isLoading || _daysCount <= 1
                          ? null
                          : () => setState(() => _daysCount--),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_daysCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _isLoading || _daysCount >= 30
                          ? null
                          : () => setState(() => _daysCount++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('تاريخ البداية'),
                      subtitle: Text(DateFormat.yMMMMd('ar').format(_selectedDate)),
                      leading: const Icon(Icons.calendar_today_outlined),
                      onTap: _isLoading ? null : _pickDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('وقت البداية'),
                      subtitle: Text(_formatTime(_selectedTime)),
                      leading: const Icon(Icons.access_time_outlined),
                      onTap: _isLoading ? null : _pickTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('مكان الرعاية', Icons.location_on_outlined),
              DropdownButtonFormField<String>(
                value: _selectedGovernorate,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: _governorates
                    .map((governorate) => DropdownMenuItem(
                          value: governorate,
                          child: Text(governorate),
                        ))
                    .toList(),
                onChanged: _isLoading ? null : (value) {
                  if (value != null) setState(() => _selectedGovernorate = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'المنطقة / المركز',
                  hintText: 'مثال: شبين الكوم، مدينة نصر، 6 أكتوبر',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'المنطقة مطلوبة'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'العنوان بالتفصيل',
                  prefixIcon: Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'العنوان مطلوب'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية (اختياري)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: Text(_isLoading ? 'جاري نشر الطلب...' : 'نشر طلب الرعاية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now()) ? DateTime.now() : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null && mounted) setState(() => _selectedTime = time);
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
