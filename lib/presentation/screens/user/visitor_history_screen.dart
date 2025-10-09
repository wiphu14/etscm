import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  final _searchController = TextEditingController();
  
  final bool _isLoading = false;
  String _selectedFilter = 'all';
  DateTime _selectedDate = DateTime.now();

  // Mock history data
  final List<Map<String, dynamic>> _historyData = [
    {
      'id': 1,
      'visitor_name': 'นายสมชาย ใจดี',
      'phone': '081-111-2222',
      'license_plate': 'กข-1234',
      'house_number': '123/45',
      'resident_name': 'นายสมหมาย รักดี',
      'entry_time': DateTime.now().subtract(const Duration(hours: 5)),
      'exit_time': DateTime.now().subtract(const Duration(hours: 3)),
      'purpose': 'มาเยี่ยมบ้าน',
      'status': 'completed',
    },
    {
      'id': 2,
      'visitor_name': 'นางสมหญิง รักงาน',
      'phone': '081-333-4444',
      'license_plate': 'คค-5678',
      'house_number': '234/56',
      'resident_name': 'นางสาวสมใจ ใจงาม',
      'entry_time': DateTime.now().subtract(const Duration(hours: 2)),
      'exit_time': null,
      'purpose': 'ส่งของ',
      'status': 'inside',
    },
    {
      'id': 3,
      'visitor_name': 'นายประยุทธ สุขสม',
      'phone': '081-555-6666',
      'license_plate': 'งง-9012',
      'house_number': '345/67',
      'resident_name': 'นายสมศักดิ์ มั่นคง',
      'entry_time': DateTime.now().subtract(const Duration(hours: 6)),
      'exit_time': DateTime.now().subtract(const Duration(hours: 4)),
      'purpose': 'ติดต่อธุระ',
      'status': 'completed',
    },
  ];

  List<Map<String, dynamic>> get filteredHistory {
    var filtered = _historyData;

    // Filter by status
    if (_selectedFilter == 'entry') {
      filtered = filtered.where((h) => h['status'] == 'inside').toList();
    } else if (_selectedFilter == 'exit') {
      filtered = filtered.where((h) => h['status'] == 'completed').toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((h) {
        return h['visitor_name'].toLowerCase().contains(query) ||
            h['license_plate'].toLowerCase().contains(query) ||
            h['house_number'].toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadDataForSelectedDate();
    }
  }

  /// Load history data for the selected date
  /// Replace mock data with actual API call when backend is ready
  void _loadDataForSelectedDate() {
    // Mock implementation - replace with actual database query
    // Example: final data = await _visitRepository.getHistoryByDate(_selectedDate);
    // setState(() => _historyData = data);
  }

  /// Export history data to Excel file
  /// Uses ExcelHelper to generate and save the file
  void _exportToExcel() {
    // Mock implementation - replace with actual Excel export
    // Example: await ExcelHelper.exportEntryExitReport(
    //   data: filteredHistory,
    //   villageName: 'หมู่บ้านตัวอย่าง',
    //   startDate: _selectedDate,
    //   endDate: _selectedDate,
    // );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์ Export Excel จะพร้อมใช้งานเร็วๆ นี้'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการเข้าออก', style: AppTextStyles.appBarTitle),
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
            icon: Icon(Icons.file_download_rounded, color: Colors.white),
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.background,
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text(
                      DateFormat('วันEEEที่ d MMMM yyyy', 'th').format(_selectedDate),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: CustomTextField(
              controller: _searchController,
              hint: 'ค้นหาด้วย ชื่อ, ทะเบียน, บ้านเลขที่',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) => setState(() {}),
            ),
          ),

          SizedBox(height: 12.h),

          // Filter Tabs
          _buildFilterTabs(),

          SizedBox(height: 8.h),

          // History List
          Expanded(
            child: _isLoading
                ? LoadingWidget(message: 'กำลังโหลดข้อมูล...')
                : filteredHistory.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.history_rounded,
                        title: 'ไม่พบข้อมูล',
                        subtitle: 'ไม่มีประวัติการเข้าออกในวันที่เลือก',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final history = filteredHistory[index];
                          return _buildHistoryCard(history);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildFilterChip('ทั้งหมด', 'all', _historyData.length),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'อยู่ภายใน',
            'entry',
            _historyData.where((h) => h['status'] == 'inside').length,
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            'ออกแล้ว',
            'exit',
            _historyData.where((h) => h['status'] == 'completed').length,
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
                style: AppTextStyles.bodySmall.copyWith(
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

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    final isInside = history['status'] == 'inside';
    final statusColor = isInside ? AppColors.entry : AppColors.success;

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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: statusColor,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history['visitor_name'],
                      style: AppTextStyles.cardTitle,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      history['license_plate'],
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isInside ? 'อยู่ภายใน' : 'ออกแล้ว',
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: AppColors.divider),
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.home_rounded,
            'บ้าน ${history['house_number']} (${history['resident_name']})',
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Icons.comment_rounded,
            history['purpose'],
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Icons.login_rounded,
            'เข้า: ${DateFormat('HH:mm น.').format(history['entry_time'])}',
            color: AppColors.entry,
          ),
          if (history['exit_time'] != null) ...[
            SizedBox(height: 8.h),
            _buildInfoRow(
              Icons.logout_rounded,
              'ออก: ${DateFormat('HH:mm น.').format(history['exit_time'])}',
              color: AppColors.exit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color ?? AppColors.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}