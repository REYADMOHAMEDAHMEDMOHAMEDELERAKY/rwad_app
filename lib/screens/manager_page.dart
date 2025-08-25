import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cars_page.dart';
import 'users_page.dart';
import 'manager_profile_page.dart';
import 'checkin_details_page.dart'; // Added import for CheckinDetailsPage

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  List<Map<String, dynamic>> driverRecords = [];
  bool isLoading = true;
  String? errorMessage;

  // إحصائيات حقيقية من قاعدة البيانات
  int totalCheckinsCount = 0;
  int uniqueDriversCount = 0;
  int totalCarsCount = 0;
  int activeTripsCount = 0;
  int todayCheckinsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDriverRecords();
  }

  Future<void> _loadDriverRecords() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final client = Supabase.instance.client;

      // جلب سجلات السائقين من جدول checkins
      final response = await client
          .from('checkins')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        driverRecords = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
      // تحميل الإحصائيات بعد تحميل السجلات
      await _loadFleetData();
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
      debugPrint('خطأ في تحميل سجلات السائقين: $e');
    }
  }

  Future<void> _loadFleetData() async {
    try {
      final client = Supabase.instance.client;

      // جلب إحصائيات الأسطول من قاعدة البيانات
      final checkinsResponse = await client.from('checkins').select('*');

      // حساب عدد التسجيلات الإجمالي
      final totalCheckins = checkinsResponse.length;

      // حساب عدد السائقين الفريدين
      final uniqueDrivers = checkinsResponse
          .map((record) => record['driver_id'])
          .where((driverId) => driverId != null)
          .toSet()
          .length;

      // حساب تسجيلات اليوم
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayCheckins = checkinsResponse.where((record) {
        if (record['created_at'] != null) {
          final recordDate = DateTime.parse(record['created_at']);
          return recordDate.isAfter(todayStart);
        }
        return false;
      }).length;

      // حساب الرحلات النشطة (التي تم إنشاؤها خلال آخر 24 ساعة)
      final last24Hours = DateTime.now().subtract(const Duration(hours: 24));
      final activeTrips = checkinsResponse.where((record) {
        if (record['created_at'] != null) {
          final recordDate = DateTime.parse(record['created_at']);
          return recordDate.isAfter(last24Hours);
        }
        return false;
      }).length;

      // محاولة جلب عدد السيارات من جدول المركبات (إذا كان موجوداً)
      int carsCount = 0;
      try {
        final carsResponse = await client.from('vehicles').select('*');
        carsCount = carsResponse.length;
      } catch (e) {
        // إذا لم يوجد جدول vehicles، استخدم عدد السائقين كتقدير
        carsCount = uniqueDrivers;
      }

      setState(() {
        totalCheckinsCount = totalCheckins;
        uniqueDriversCount = uniqueDrivers;
        totalCarsCount = carsCount > 0 ? carsCount : uniqueDrivers;
        activeTripsCount = activeTrips;
        todayCheckinsCount = todayCheckins;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الأسطول: $e');
      // في حالة الخطأ، استخدم بيانات افتراضية من السجلات المحملة
      setState(() {
        totalCheckinsCount = driverRecords.length;
        uniqueDriversCount = driverRecords
            .map((r) => r['driver_id'])
            .toSet()
            .length;
        totalCarsCount = uniqueDriversCount;
        activeTripsCount = 0;
        todayCheckinsCount = 0;
      });
    }
  }

  // بيانات الأسطول (محدثة بناءً على قاعدة البيانات)
  Map<String, dynamic> get fleetData {
    return {
      'totalCars': totalCarsCount,
      'activeTrips': activeTripsCount,
      'connectedDrivers': uniqueDriversCount,
      'newNotifications': todayCheckinsCount,
      'totalDrivers': uniqueDriversCount,
      'maintenanceDue': 0, // يمكن تحديثها من جدول الصيانة لاحقاً
      'fuelLevel': 85, // يمكن تحديثها من قاعدة البيانات
      'monthlyTrips': totalCheckinsCount,
    };
  }

  int get uniqueDrivers {
    return driverRecords.map((r) => r['driver_id']).toSet().length;
  }

  @override
  Widget build(BuildContext context) {
    void openPage(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    void _openManagerProfile(BuildContext context) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ManagerProfilePage()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('لوحة المدير'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4F46E5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            onPressed: _loadDriverRecords,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: () => _openManagerProfile(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
            ),
            tooltip: 'بيانات المدير',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with logo and title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.directions_car,
                            size: 50,
                            color: const Color(0xFF4F46E5),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'لوحة القيادة الحديثة',
                            style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'إدارة الأسطول والمهام',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stat cards with real data
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _StatCard(
                    title: 'الرحلات النشطة',
                    value: '${fleetData['activeTrips']}',
                    icon: Icons.directions_car,
                    color: const Color(0xFF4F46E5),
                    gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  _StatCard(
                    title: 'السائقون المتصلون',
                    value: '${fleetData['connectedDrivers']}',
                    icon: Icons.person,
                    color: const Color(0xFF00C9A7),
                    gradient: const [Color(0xFF00C9A7), Color(0xFF2BE7C7)],
                  ),
                  _StatCard(
                    title: 'إشعارات جديدة',
                    value: '${fleetData['newNotifications']}',
                    icon: Icons.notifications,
                    color: const Color(0xFFFF6B6B),
                    gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                  ),
                  _StatCard(
                    title: 'مجموع السيارات',
                    value: '${fleetData['totalCars']}',
                    icon: Icons.local_shipping,
                    color: const Color(0xFFFFA726),
                    gradient: const [Color(0xFFFFA726), Color(0xFFFFCC80)],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Additional stats row
              _MiniStatCard(
                title: 'إجمالي السجلات',
                value: '${fleetData['monthlyTrips']}',
                icon: Icons.timeline,
                color: const Color(0xFF9C27B0),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.directions_car_outlined,
                      label: 'إدارة السيارات',
                      onPressed: () => openPage(const CarsPage()),
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.person_outline,
                      label: 'إدارة المستخدمين',
                      onPressed: () => openPage(const UsersPage()),
                      color: const Color(0xFF00C9A7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Driver records section
              _DriverRecordsSection(
                records: driverRecords,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onRetry: _loadDriverRecords,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverRecordsSection extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _DriverRecordsSection({
    required this.records,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'سجلات السائقين اليومية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'لا توجد سجلات للسائقين حالياً',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...records
                  .map((record) => _DriverRecordTile(record: record))
                  .toList(),
          ],
        ),
      ),
    );
  }
}

class _DriverRecordTile extends StatelessWidget {
  final Map<String, dynamic> record;

  const _DriverRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    // تحديد الحالة بناءً على البيانات الحقيقية
    final status = record['status'] ?? 'مكتمل';
    final isActive = status == 'قيد التنفيذ' || status == 'active';

    // تنسيق التاريخ
    final createdAt = record['created_at'] ?? record['timestamp'];
    String formattedDate = 'غير محدد';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        formattedDate = createdAt.toString();
      }
    }

    // تنسيق الوقت
    String formattedTime = 'غير محدد';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedTime =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedTime = 'غير محدد';
      }
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CheckinDetailsPage(checkinData: record),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4F46E5).withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF4F46E5).withOpacity(0.2)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4F46E5)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record['driver_id'] ?? 'سائق غير محدد',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4F46E5)
                              : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record['serial'] ?? 'غير محدد'} • ${record['lat'] != null && record['lon'] != null ? 'تم تحديد الموقع' : 'لم يتم تحديد الموقع'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (record['notes'] != null &&
                      record['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ملاحظات: ${record['notes']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
