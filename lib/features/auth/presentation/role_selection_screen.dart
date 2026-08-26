import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/shared_preferences_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('اختر نوع الحساب'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إنت هنا عشان إيه؟',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('اختر النوع المناسب ليك عشان نبدأ',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: [
                  _buildRoleCard(
                    title: 'أحتاج رعاية',
                    icon: Icons.family_restroom,
                    role: 'client',
                    color: Colors.blue.shade50,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    title: 'أنا ممرض/ممرضة',
                    icon: Icons.medical_services,
                    role: 'nurse',
                    color: Colors.teal.shade50,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _selectedRole == null
                  ? null
                  : () async {
                      await SharedPreferencesService()
                          .setSelectedRole(_selectedRole!);
                      if (mounted) context.go('/register');
                    },
              child: const Text('متابعة'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
      {required String title,
      required IconData icon,
      required String role,
      required Color color}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 40,
                color: isSelected ? AppColors.primary : Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    role == 'client'
                        ? 'أبحث عن ممرض للرعاية'
                        : 'أقدم خدمات التمريض المنزلية',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
