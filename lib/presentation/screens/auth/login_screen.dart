import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/village_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../user/user_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'user';
  int? _selectedVillageId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VillageProvider>().loadVillages();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'user' && _selectedVillageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกหมู่บ้าน'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      final success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        villageId: _selectedVillageId,
      );

      if (success && mounted) {
        if (_selectedRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบข้อมูล'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  
                  _buildHeader(),
                  
                  SizedBox(height: 40.h),
                  
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32.r),
                        topRight: Radius.circular(32.r),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8.h),
                            
                            Text(
                              'เข้าสู่ระบบ',
                              style: AppTextStyles.h3,
                            ),
                            
                            SizedBox(height: 24.h),
                            
                            _buildRoleSelector(),
                            
                            SizedBox(height: 20.h),
                            
                            if (_selectedRole == 'user')
                              _buildVillageSelector(),
                            
                            if (_selectedRole == 'user')
                              SizedBox(height: 20.h),
                            
                            CustomTextField(
                              controller: _usernameController,
                              label: 'ชื่อผู้ใช้',
                              hint: 'กรอกชื่อผู้ใช้',
                              prefixIcon: Icons.person_rounded,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกชื่อผู้ใช้';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            CustomTextField(
                              controller: _passwordController,
                              label: 'รหัสผ่าน',
                              hint: 'กรอกรหัสผ่าน',
                              prefixIcon: Icons.lock_rounded,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่าน';
                                }
                                if (value.length < 6) {
                                  return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 32.h),
                            
                            CustomButton(
                              text: 'เข้าสู่ระบบ',
                              onPressed: _handleLogin,
                              isFullWidth: true,
                              isLoading: _isLoading,
                              icon: Icons.login_rounded,
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            _buildDemoInfo(),
                            
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: Icon(
            Icons.home_work_rounded,
            size: 50.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'ระบบเข้าออกหมู่บ้าน',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Village Entry System',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('เลือกประเภทผู้ใช้', style: AppTextStyles.label),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: 'admin',
                icon: Icons.admin_panel_settings_rounded,
                title: 'ผู้ดูแลระบบ',
                color: AppColors.admin,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildRoleCard(
                role: 'user',
                icon: Icons.people_rounded,
                title: 'เจ้าหน้าที่',
                color: AppColors.user,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVillageSelector() {
    return Consumer<VillageProvider>(
      builder: (context, villageProvider, _) {
        final villages = villageProvider.villages;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลือกหมู่บ้าน', style: AppTextStyles.label),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedVillageId,
                  hint: Text('เลือกหมู่บ้าน', style: AppTextStyles.hint),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items: villages.map((village) {
                    return DropdownMenuItem<int>(
                      value: village['id'],
                      child: Text(
                        village['village_name'],
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedVillageId = value);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDemoInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, size: 16.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                'ข้อมูลทดสอบ',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Admin: username: admin | password: admin123',
            style: AppTextStyles.caption,
          ),
          Text(
            'User: username: user001 | password: admin123',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}