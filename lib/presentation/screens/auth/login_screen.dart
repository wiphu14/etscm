import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
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
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่ม Login...');
      debugPrint('🔵 Username: ${_usernameController.text.trim()}');
      debugPrint('🔵 ========================================');
      
      // ============================================
      // Login โดยไม่ต้องส่ง role และ villageId
      // API จะตรวจสอบ role และ villageId จากฐานข้อมูลเอง
      // ============================================
      final success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      debugPrint('🟡 Login Result: $success');
      debugPrint('🟡 Role from API: ${authProvider.role}');
      debugPrint('🟡 Village ID from API: ${authProvider.villageId}');

      if (success && mounted) {
        // ============================================
        // ใช้ role จาก API response
        // ============================================
        final actualRole = authProvider.role ?? 'user';
        
        debugPrint('🟢 Login สำเร็จ! Navigating to: ${actualRole == 'admin' ? 'AdminDashboard' : 'UserDashboard'}');
        
        if (actualRole == 'admin') {
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
        debugPrint('🔴 Login ไม่สำเร็จ: ${authProvider.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบข้อมูล'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 Login Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  
                  _buildHeader(),
                  
                  SizedBox(height: 40.h),
                  
                  // Login Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Center(
                            child: Text(
                              'เข้าสู่ระบบ',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 8.h),
                          
                          Center(
                            child: Text(
                              'กรุณากรอกข้อมูลเพื่อเข้าใช้งาน',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 32.h),
                          
                          // Username Field
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
                          
                          SizedBox(height: 20.h),
                          
                          // Password Field with toggle visibility
                          _buildPasswordField(),
                          
                          SizedBox(height: 32.h),
                          
                          // Login Button
                          CustomButton(
                            text: 'เข้าสู่ระบบ',
                            onPressed: _handleLogin,
                            isFullWidth: true,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                            type: ButtonType.primary,
                          ),
                          
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Footer
                  Text(
                    '© 2025 Village Entry System',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('รหัสผ่าน', style: AppTextStyles.label),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'กรอกรหัสผ่าน',
            hintStyle: AppTextStyles.hint,
            prefixIcon: Icon(Icons.lock_rounded, color: AppColors.textHint),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword 
                  ? Icons.visibility_off_rounded 
                  : Icons.visibility_rounded,
                color: AppColors.textHint,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกรหัสผ่าน';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.security_rounded,
            size: 50.sp,
            color: AppColors.primary,
          ),
        ),
        
        SizedBox(height: 24.h),
        
        Text(
          'ระบบบันทึกผู้มาติดต่อ',
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 8.h),
        
        Text(
          'Village Entry System',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}