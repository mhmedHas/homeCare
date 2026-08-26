import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  bool _isLoading = true;
  String _status = 'not_submitted';
  String? _rejectionReason;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _status = data['verificationStatus'] ?? 'not_submitted';
          _rejectionReason = data['rejectionReason'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حالة التحقق')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadStatus,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Status Icon
                      _buildStatusIcon(),
                      const SizedBox(height: 24),
                      Text(_getStatusLabel(_status),
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(_getStatusDescription(_status),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      if (_rejectionReason != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سبب الرفض:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(_rejectionReason!),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (_status == 'not_submitted' || _status == 'rejected')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/nurse/documents'),
                            child: Text(_status == 'rejected'
                                ? 'تعديل المستندات'
                                : 'رفع المستندات'),
                          ),
                        ),
                      if (_status == 'approved')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/nurse/home'),
                            child: const Text('الذهاب للوحة الرئيسية'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case 'approved':
        return const Icon(Icons.check_circle,
            size: 80, color: AppColors.success);
      case 'pending':
        return const Icon(Icons.hourglass_empty,
            size: 80, color: Colors.orange);
      case 'rejected':
        return const Icon(Icons.cancel, size: 80, color: AppColors.error);
      default:
        return const Icon(Icons.upload_file, size: 80, color: Colors.grey);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'not_submitted':
        return 'لم يتم التقديم';
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تم التحقق ✅';
      case 'rejected':
        return 'مرفوض ❌';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'not_submitted':
        return 'يرجى رفع المستندات المطلوبة للتحقق من حسابك';
      case 'pending':
        return 'نحن نراجع مستنداتك، سيتم إعلامك عند الانتهاء';
      case 'approved':
        return 'تهانينا! حسابك موثق ويمكنك استقبال الطلبات الآن';
      case 'rejected':
        return 'يوجد مشكلة في المستندات، يرجى تعديلها وإعادة الإرسال';
      default:
        return '';
    }
  }
}
