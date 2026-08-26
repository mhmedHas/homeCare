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
  State<CreateCareRequestScreen> createState() =>
      _CreateCareRequestScreenState();
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
  int _shiftHours = 8;
  int _daysCount = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _careTypes = [
    'elderly',
    'post_surgery',
    'chronic_disease',
    'disability',
    'maternity',
    'general'
  ];
  final List<String> _careTypeLabels = [
    'رعاية كبار السن',
    'رعاية ما بعد العمليات',
    'أمراض مزمنة',
    'ذوي الاحتياجات الخاصة',
    'رعاية الأمومة',
    'عام'
  ];
  final List<String> _governorates = [
    'القاهرة',
    'الإسكندرية',
    'الجيزة',
    'القليوبية',
    'الشرقية',
    'الدقهلية',
    'المنوفية',
    'الغربية'
  ];
  final List<String> _areas = [
    'مدينة نصر',
    'مصر الجديدة',
    'الزمالك',
    'الدقي',
    'المهندسين',
    'مصر القديمة'
  ];
  final List<String> _allServices = [
    'متابعة الحالة',
    'إعطاء الأدوية',
    'قياس الضغط',
    'قياس السكر',
    'تغيير الجروح',
    'مساعدة الحركة',
    'رعاية كبار السن',
    'رعاية ما بعد العمليات'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
          _isLoading = false;
        });
        return;
      }

      final request = CareRequest(
        id: '',
        clientId: user.uid,
        patientName: _patientNameController.text.trim(),
        patientAge: int.parse(_patientAgeController.text.trim()),
        patientGender: _selectedGender!,
        careType: _selectedCareType!,
        services: _selectedServices,
        shiftHours: _shiftHours,
        daysCount: _daysCount,
        startDate: _selectedDate,
        startTime: _selectedTime,
        governorate: _selectedGovernorate!,
        area: _selectedArea!,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final requestId = await CareRequestService().createRequest(request);
      if (mounted) {
        context.go('/client/request-details/$requestId');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء إنشاء الطلب';
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب رعاية جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Patient Name
                TextFormField(
                  controller: _patientNameController,
                  decoration: const InputDecoration(
                      labelText: 'اسم الحالة', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Age
                TextFormField(
                  controller: _patientAgeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'العمر', prefixIcon: Icon(Icons.numbers)),
                  validator: (v) => v!.isEmpty ? 'العمر مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Gender
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                      labelText: 'الجنس', prefixIcon: Icon(Icons.people)),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('ذكر')),
                    DropdownMenuItem(value: 'female', child: Text('أنثى')),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 12),

                // Care Type
                DropdownButtonFormField<String>(
                  value: _selectedCareType,
                  decoration: const InputDecoration(
                      labelText: 'نوع الرعاية',
                      prefixIcon: Icon(Icons.medical_services)),
                  items: _careTypes.asMap().entries.map((e) {
                    return DropdownMenuItem(
                        value: e.value, child: Text(_careTypeLabels[e.key]));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCareType = v),
                ),
                const SizedBox(height: 12),

                // Services (Multi-select chips)
                const Text('الخدمات المطلوبة',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _allServices.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Shift Hours
                Row(
                  children: [
                    const Text('عدد الساعات: '),
                    Expanded(
                      child: Slider(
                        min: 4,
                        max: 24,
                        divisions: 10,
                        value: _shiftHours.toDouble(),
                        onChanged: (v) =>
                            setState(() => _shiftHours = v.round()),
                      ),
                    ),
                    Text('$_shiftHours ساعة'),
                  ],
                ),
                const SizedBox(height: 12),

                // Days Count
                Row(
                  children: [
                    const Text('عدد الأيام: '),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 30,
                        divisions: 29,
                        value: _daysCount.toDouble(),
                        onChanged: (v) =>
                            setState(() => _daysCount = v.round()),
                      ),
                    ),
                    Text('$_daysCount يوم'),
                  ],
                ),
                const SizedBox(height: 12),

                // Start Date
                ListTile(
                  title: const Text('تاريخ البداية'),
                  subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
                const SizedBox(height: 12),

                // Start Time
                ListTile(
                  title: const Text('وقت البداية'),
                  subtitle: Text(_formatTime(_selectedTime)),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) setState(() => _selectedTime = time);
                  },
                ),
                const SizedBox(height: 12),

                // Governorate
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      prefixIcon: Icon(Icons.location_city)),
                  items: _governorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGovernorate = v),
                ),
                const SizedBox(height: 12),

                // Area
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                      labelText: 'المنطقة',
                      prefixIcon: Icon(Icons.location_on)),
                  items: _areas
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedArea = v),
                ),
                const SizedBox(height: 12),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                      labelText: 'العنوان بالتفصيل',
                      prefixIcon: Icon(Icons.home)),
                  validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'ملاحظات إضافية (اختياري)'),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error)),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('إنشاء الطلب'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
