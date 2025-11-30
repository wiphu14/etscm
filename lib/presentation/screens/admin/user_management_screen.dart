import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/custom_card.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔵 กำลังโหลดรายการผู้ใช้...');
      
      final response = await _apiService.get('/users/index.php');
      final responseData = response.data;
      
      debugPrint('🟢 Users Response: $responseData');

      if (responseData != null && responseData['success'] == true) {
        final users = responseData['data'] as List<dynamic>? ?? [];
        
        debugPrint('🟢 โหลดผู้ใช้สำเร็จ: ${users.length} รายการ');

        if (mounted) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(users);
            _isLoading = false;
          });
        }
      } else {
        throw Exception(responseData?['message'] ?? 'โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      debugPrint('🔴 โหลดผู้ใช้ไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'จัดการผู้ใช้',
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.accent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: AppColors.accent,
        child: Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text('กำลังโหลดข้อมูล...', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text('เกิดข้อผิดพลาด', style: AppTextStyles.h4),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: Icon(Icons.refresh_rounded),
              label: Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text('ไม่พบข้อมูลผู้ใช้', style: AppTextStyles.h4),
            SizedBox(height: 8.h),
            Text(
              'กดปุ่ม + เพื่อเพิ่มผู้ใช้ใหม่',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] == true || user['status'] == 'active';
    final role = user['role'] ?? 'user';
    
    Color roleColor;
    String roleText;
    IconData roleIcon;
    
    switch (role) {
      case 'admin':
        roleColor = AppColors.error;
        roleText = 'ผู้ดูแลระบบ';
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case 'manager':
        roleColor = AppColors.warning;
        roleText = 'ผู้จัดการ';
        roleIcon = Icons.manage_accounts_rounded;
        break;
      case 'guard':
        roleColor = AppColors.info;
        roleText = 'รปภ.';
        roleIcon = Icons.security_rounded;
        break;
      default:
        roleColor = AppColors.success;
        roleText = 'ผู้ใช้งาน';
        roleIcon = Icons.person_rounded;
    }
    
    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  roleIcon,
                  color: roleColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['full_name'] ?? user['username'] ?? 'ไม่ระบุ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            roleText,
                            style: AppTextStyles.caption.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '@${user['username'] ?? '-'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isActive ? 'ใช้งาน' : 'ปิดใช้งาน',
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.home_work_outlined,
                  label: 'หมู่บ้าน',
                  value: user['village_name'] ?? '-',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.email_outlined,
                  label: 'อีเมล',
                  value: user['email'] ?? '-',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.phone_outlined,
                  label: 'โทรศัพท์',
                  value: user['phone'] ?? '-',
                ),
              ),
            ],
          ),
          if (user['last_login'] != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  'เข้าใช้งานล่าสุด: ${_formatDateTime(user['last_login'])}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditUserDialog(user),
                icon: Icon(Icons.edit_rounded, size: 18.sp),
                label: Text('แก้ไข'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
              ),
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmDialog(user),
                icon: Icon(Icons.delete_rounded, size: 18.sp),
                label: Text('ลบ'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.textSecondary),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  void _showAddUserDialog() {
    _showUserFormDialog(null);
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    _showUserFormDialog(user);
  }

  void _showUserFormDialog(Map<String, dynamic>? user) {
    final isEdit = user != null;
    final usernameController = TextEditingController(text: user?['username'] ?? '');
    final fullNameController = TextEditingController(text: user?['full_name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final phoneController = TextEditingController(text: user?['phone'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(isEdit ? 'แก้ไขผู้ใช้' : 'เพิ่มผู้ใช้ใหม่', style: AppTextStyles.h4),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้ *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  enabled: !isEdit, // ไม่ให้แก้ไข username
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ-นามสกุล *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'อีเมล',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'โทรศัพท์',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'บทบาท',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'admin', child: Text('ผู้ดูแลระบบ')),
                    DropdownMenuItem(value: 'manager', child: Text('ผู้จัดการ')),
                    DropdownMenuItem(value: 'guard', child: Text('รปภ.')),
                    DropdownMenuItem(value: 'user', child: Text('ผู้ใช้งาน')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value ?? 'user';
                    });
                  },
                ),
                if (!isEdit) ...[
                  SizedBox(height: 12.h),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement save to API
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มผู้ใช้สำเร็จ'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadUsers();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('ยืนยันการลบ', style: AppTextStyles.h4),
        content: Text(
          'คุณต้องการลบผู้ใช้ "${user['full_name'] ?? user['username']}" ใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ลบผู้ใช้สำเร็จ'),
                  backgroundColor: AppColors.success,
                ),
              );
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }
}