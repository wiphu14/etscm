import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/entry_log_repository.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  final _searchController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all'; // all, inside, exited
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _historyLogs = [];
  
  // API Service & Repository
  late ApiService _apiService;
  late EntryLogRepository _entryLogRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _entryLogRepository = EntryLogRepository(_apiService);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🔵 กำลังโหลดประวัติเข้าออก...');
      debugPrint('🔵 Village ID: ${authProvider.villageId}');
      debugPrint('🔵 Date: ${_selectedDate.toIso8601String().split('T')[0]}');
      
      final logs = await _entryLogRepository.getLogsByDate(
        date: _selectedDate,
        villageId: authProvider.villageId,
      );
      
      debugPrint('🟢 พบประวัติ ${logs.length} รายการ');
      
      if (mounted) {
        setState(() {
          _historyLogs = logs.map((log) {
            // แปลง entry_time จาก String เป็น DateTime
            DateTime? entryTime;
            DateTime? exitTime;
            
            if (log['entry_time'] != null) {
              try {
                entryTime = DateTime.parse(log['entry_time'].toString());
              } catch (e) {
                entryTime = DateTime.now();
              }
            }
            
            if (log['exit_time'] != null) {
              try {
                exitTime = DateTime.parse(log['exit_time'].toString());
              } catch (e) {
                exitTime = null;
              }
            }
            
            return {
              ...log,
              'entry_time': entryTime ?? DateTime.now(),
              'exit_time': exitTime,
              'visitor_name': log['visitor_name'] ?? log['full_name'] ?? 'ไม่ระบุ',
              'status': exitTime != null ? 'exited' : 'inside',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('🔴 โหลดประวัติไม่สำเร็จ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดประวัติได้: $e'),
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

  List<Map<String, dynamic>> get filteredLogs {
    var logs = _historyLogs;
    
    // กรองตาม status
    if (_selectedFilter == 'inside') {
      logs = logs.where((log) => log['status'] == 'inside').toList();
    } else if (_selectedFilter == 'exited') {
      logs = logs.where((log) => log['status'] == 'exited').toList();
    }
    
    // กรองตาม search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase().trim();
      logs = logs.where((log) {
        final name = (log['visitor_name'] ?? '').toString().toLowerCase();
        final plate = (log['license_plate'] ?? '').toString().toLowerCase();
        final house = (log['house_number'] ?? '').toString().toLowerCase();
        final code = (log['qr_code'] ?? log['visitor_code'] ?? '').toString().toLowerCase();
        
        return name.contains(query) || 
               plate.contains(query) || 
               house.contains(query) ||
               code.contains(query);
      }).toList();
    }
    
    return logs;
  }

  int get insideCount => _historyLogs.where((log) => log['status'] == 'inside').length;
  int get exitedCount => _historyLogs.where((log) => log['status'] == 'exited').length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการเข้าออก', style: AppTextStyles.h4.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ส่งออกข้อมูล - Coming Soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: InkWell(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text(
                      DateFormat('วันE ที่ d MMMM yyyy', 'th').format(_selectedDate),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
          
          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'ค้นหาด้วย ชื่อ, ทะเบียน, บ้านเลขที่',
                  hintStyle: AppTextStyles.hint,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppColors.textHint),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
            ),
          ),
          
          // Filter Tabs
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    label: 'ทั้งหมด',
                    count: _historyLogs.length,
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildFilterTab(
                    label: 'อยู่ภายใน',
                    count: insideCount,
                    isSelected: _selectedFilter == 'inside',
                    onTap: () => setState(() => _selectedFilter = 'inside'),
                    color: AppColors.entry,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildFilterTab(
                    label: 'ออกแล้ว',
                    count: exitedCount,
                    isSelected: _selectedFilter == 'exited',
                    onTap: () => setState(() => _selectedFilter = 'exited'),
                    color: AppColors.exit,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // History List
          Expanded(
            child: _isLoading
                ? LoadingWidget(message: 'กำลังโหลด...')
                : filteredLogs.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.history_rounded,
                        title: 'ไม่พบประวัติ',
                        subtitle: _searchController.text.isEmpty
                            ? 'ไม่มีประวัติการเข้าออกในวันที่เลือก'
                            : 'ไม่พบผลลัพธ์จากการค้นหา',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return _buildHistoryCard(log);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              count.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final isExited = log['status'] == 'exited';
    final statusColor = isExited ? AppColors.exit : AppColors.entry;
    
    DateTime entryTime = log['entry_time'] is DateTime 
        ? log['entry_time'] 
        : DateTime.now();
    
    DateTime? exitTime = log['exit_time'] is DateTime 
        ? log['exit_time'] 
        : null;
    
    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
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
                        log['visitor_name'] ?? 'ไม่ระบุ',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        log['license_plate'] ?? 'ไม่ระบุทะเบียน',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    isExited ? 'ออกแล้ว' : 'อยู่ภายใน',
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
            
            // House Info
            _buildInfoRow(
              Icons.home_rounded,
              'บ้าน ${log['house_number'] ?? 'ไม่ระบุ'} ${log['resident_name'] != null ? '(${log['resident_name']})' : ''}',
            ),
            SizedBox(height: 8.h),
            
            // Purpose
            if (log['purpose'] != null)
              _buildInfoRow(
                Icons.assignment_rounded,
                log['purpose'],
              ),
            if (log['purpose'] != null) SizedBox(height: 8.h),
            
            // Entry Time
            _buildInfoRow(
              Icons.login_rounded,
              'เข้า: ${DateFormat('HH:mm').format(entryTime)} น.',
              color: AppColors.entry,
            ),
            
            // Exit Time (if exited)
            if (exitTime != null) ...[
              SizedBox(height: 8.h),
              _buildInfoRow(
                Icons.logout_rounded,
                'ออก: ${DateFormat('HH:mm').format(exitTime)} น.',
                color: AppColors.exit,
              ),
            ],
          ],
        ),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
