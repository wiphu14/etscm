import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final bool _isLoading = false;

  // Mock villages data
  final List<Map<String, dynamic>> _mockVillages = [
    {'id': 1, 'village_name': 'หมู่บ้านสวนสยาม 1'},
    {'id': 2, 'village_name': 'หมู่บ้านมัณฑนา'},
    {'id': 3, 'village_name': 'หมู่บ้านเมืองทอง'},
  ];

  // Mock users data
  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'username': 'admin',
      'full_name': 'ผู้ดูแลระบบ',
      'email': 'admin@village.com',
      'phone': '081-234-5678',
      'role': 'admin',
      'village_id': null,
      'is_active': true,
    },
    {
      'id': 2,
      'username': 'user001',
      'full_name': 'สมชาย ใจดี',
      'email': 'somchai@village.com',
      'phone': '081-111-2222',
      'role': 'user',
      'village_id': 1,
      'village_name': 'หมู่บ้านสวนสยาม 1',
      'is_active': true,
    },
    {
      'id': 3,
      'username': 'user002',
      'full_name': 'สมหญิง รักงาน',
      'email': 'somying@village.com',
      'phone': '081-333-4444',
      'role': 'user',
      'village_id': 2,
      'village_name': 'หมู่บ้านมัณฑนา',
      'is_active': true,
    },
  ];

  String _selectedFilter = 'all';

  List<Map<String, dynamic>> get filteredUsers {
    if (_selectedFilter == 'all') return _users;
    return _users.where((user) => user['role'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการผู้ใช้', style: AppTextStyles.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? LoadingWidget(message: 'กำลังโหลดข้อมูล...')
                : filteredUsers.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_rounded,
                        title: 'ยังไม่มีผู้ใช้',
                        subtitle: 'เพิ่มผู้ใช้ใหม่โดยกดปุ่ม + ด้านบน',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.background,
      child: Row(
        children: [
          _buildFilterChip('ทั้งหมด', 'all', _users.length),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'Admin',
            'admin',
            _users.where((u) => u['role'] == 'admin').length,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'User',
            'user',
            _users.where((u) => u['role'] == 'user').length,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final roleColor = isAdmin ? AppColors.admin : AppColors.user;

    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  color: roleColor,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['full_name'],
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : 'User',
                            style: AppTextStyles.caption.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '@${user['username']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20.sp, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        Text('แก้ไข', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                        () => _showAddEditDialog(user: user),
                      );
                    },
                  ),
                  if (!isAdmin)
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded, size: 20.sp, color: AppColors.warning),
                          SizedBox(width: 8.w),
                          Text('ระงับ', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          setState(() {
                            user['is_active'] = !(user['is_active'] ?? true);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(user['is_active'] 
                                    ? 'เปิดใช้งานผู้ใช้แล้ว' 
                                    : 'ระงับผู้ใช้แล้ว'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        });
                      },
                    ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20.sp, color: AppColors.error),
                        SizedBox(width: 8.w),
                        Text('ลบ', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                        () => _showDeleteDialog(user),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: AppColors.divider),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.email_rounded, user['email']),
          SizedBox(height: 8.h),
          _buildInfoRow(Icons.phone_rounded, user['phone']),
          if (!isAdmin && user['village_name'] != null) ...[
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.home_work_rounded, user['village_name']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();

    final usernameController = TextEditingController(text: user?['username']);
    final fullNameController = TextEditingController(text: user?['full_name']);
    final emailController = TextEditingController(text: user?['email']);
    final phoneController = TextEditingController(text: user?['phone']);
    final passwordController = TextEditingController();

    String selectedRole = user?['role'] ?? 'user';
    int? selectedVillageId = user?['village_id'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_rounded : Icons.add_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                isEdit ? 'แก้ไขผู้ใช้' : 'เพิ่มผู้ใช้ใหม่',
                style: AppTextStyles.h4,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: usernameController,
                    label: 'ชื่อผู้ใช้',
                    hint: 'Username',
                    prefixIcon: Icons.person_rounded,
                    validator: (v) => v?.isEmpty ?? true ? 'กรุณากรอก' : null,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    controller: fullNameController,
                    label: 'ชื่อ-นามสกุล',
                    hint: 'Full Name',
                    prefixIcon: Icons.badge_rounded,
                    validator: (v) => v?.isEmpty ?? true ? 'กรุณากรอก' : null,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    controller: emailController,
                    label: 'อีเมล',
                    hint: 'Email',
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    controller: phoneController,
                    label: 'เบอร์โทร',
                    hint: 'Phone',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12.h),
                  if (!isEdit)
                    CustomTextField(
                      controller: passwordController,
                      label: 'รหัสผ่าน',
                      hint: 'Password',
                      prefixIcon: Icons.lock_rounded,
                      obscureText: true,
                      validator: (v) => v?.isEmpty ?? true ? 'กรุณากรอก' : null,
                    ),
                  SizedBox(height: 12.h),
                  
                  // Role Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role', style: AppTextStyles.label),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedRole = 'admin'),
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: selectedRole == 'admin'
                                      ? AppColors.admin.withValues(alpha: 0.1)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: selectedRole == 'admin'
                                        ? AppColors.admin
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  'Admin',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: selectedRole == 'admin'
                                        ? AppColors.admin
                                        : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedRole = 'user'),
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: selectedRole == 'user'
                                      ? AppColors.user.withValues(alpha: 0.1)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: selectedRole == 'user'
                                        ? AppColors.user
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  'User',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: selectedRole == 'user'
                                        ? AppColors.user
                                        : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Village Selection (for User only)
                  if (selectedRole == 'user') ...[
                    SizedBox(height: 12.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('หมู่บ้าน', style: AppTextStyles.label),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedVillageId,
                              hint: Text('เลือกหมู่บ้าน', style: AppTextStyles.hint),
                              isExpanded: true,
                              items: _mockVillages.map((village) {
                                return DropdownMenuItem<int>(
                                  value: village['id'],
                                  child: Text(
                                    village['village_name'] ?? '',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() => selectedVillageId = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              )),
            ),
            CustomButton(
              text: isEdit ? 'บันทึก' : 'เพิ่ม',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มผู้ใช้สำเร็จ'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              type: ButtonType.success,
              height: 45.h,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 8.w),
            Text('ยืนยันการลบ', style: AppTextStyles.h4),
          ],
        ),
        content: Text(
          'คุณต้องการลบผู้ใช้ "${user['full_name']}" ใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          CustomButton(
            text: 'ลบ',
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบผู้ใช้สำเร็จ'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            type: ButtonType.error,
            height: 45.h,
          ),
        ],
      ),
    );
  }
}