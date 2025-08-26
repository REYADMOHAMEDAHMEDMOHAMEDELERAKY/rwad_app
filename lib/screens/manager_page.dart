import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cars_page.dart';
import 'users_page.dart';
import 'manager_profile_page.dart';
import 'checkin_details_page.dart'; // Added import for CheckinDetailsPage
import 'notifications_page.dart';
import 'reports_page.dart'; // Added import for ReportsPage
import '../services/notification_service.dart';

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  List<Map<String, dynamic>> driverRecords = [];
  bool isLoading = true;
  String? errorMessage;
  int _unreadNotificationsCount = 0;

  // Pagination variables
  int _currentPage = 1;
  int _itemsPerPage = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  int _totalRecords = 0;

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
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadDriverRecords({bool loadMore = false}) async {
    debugPrint(
      '🚀 Starting _loadDriverRecords function... Page: $_currentPage, LoadMore: $loadMore',
    );
    try {
      if (!loadMore) {
        setState(() {
          isLoading = true;
          errorMessage = null;
          _currentPage = 1;
          driverRecords.clear();
          _hasMoreData = true;
        });
      } else {
        setState(() {
          _isLoadingMore = true;
        });
      }

      final client = Supabase.instance.client;

      // Calculate offset for pagination
      final offset = (_currentPage - 1) * _itemsPerPage;

      // Get total count first (only on initial load)
      if (!loadMore) {
        try {
          final countResponse = await client.from('checkins').select('id');
          _totalRecords = countResponse.length;
          debugPrint('📊 Total records in database: $_totalRecords');
        } catch (e) {
          debugPrint('❌ Error getting count: $e');
          _totalRecords = 0;
        }
      }

      // جلب سجلات السائقين من جدول checkins مع pagination
      final response = await client
          .from('checkins')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + _itemsPerPage - 1);

      debugPrint(
        '📊 تم جلب ${response.length} سجل من جدول checkins (Page $_currentPage)',
      );

      // Check if we have more data
      _hasMoreData = response.length == _itemsPerPage;

      if (response.isEmpty && !loadMore) {
        debugPrint(
          '⚠️ لا توجد سجلات في جدول checkins - قم بإنشاء سجلات تجريبية',
        );
        // Create demo data if no records exist
        final demoData = [
          {
            'id': 1,
            'driver_id': 'ahmed_sabry',
            'serial': 1,
            'created_at': DateTime.now().toIso8601String(),
            'status': 'مكتمل',
            'lat': '24.7136',
            'lon': '46.6753',
            'notes': 'مثال على سجل تجريبي',
          },
          {
            'id': 2,
            'driver_id': 'mohammed',
            'serial': 2,
            'created_at': DateTime.now()
                .subtract(Duration(hours: 2))
                .toIso8601String(),
            'status': 'مكتمل',
            'lat': '24.7136',
            'lon': '46.6753',
            'notes': 'مثال آخر',
          },
        ];
        response.addAll(demoData);
        _totalRecords = demoData.length;
        _hasMoreData = false;
      }

      // جلب جميع المديرين مرة واحدة لتحسين الأداء
      final allDrivers = await client
          .from('managers')
          .select('username, full_name, id');

      debugPrint('👥 تم جلب ${allDrivers.length} مدير/سائق من جدول managers');

      // إنشاء خريطة للبحث السريع بكل من username و id
      final Map<String, String?> driverNamesMap = {};
      final Map<String, String?> driverIdToNameMap = {};

      for (var driver in allDrivers) {
        // ربط username بـ full_name
        if (driver['username'] != null) {
          driverNamesMap[driver['username']] = driver['full_name'];
        }
        // ربط id بـ full_name أيضاً
        if (driver['id'] != null) {
          driverIdToNameMap[driver['id'].toString()] = driver['full_name'];
        }
        debugPrint(
          '💾 تم حفظ السائق: username=${driver['username']}, id=${driver['id']}, full_name=${driver['full_name']}',
        );
      }

      List<Map<String, dynamic>> recordsWithDriverInfo = [];

      // إرفاق بيانات الساعق لكل سجل
      for (var record in response) {
        Map<String, dynamic> recordWithDriver = Map<String, dynamic>.from(
          record,
        );

        debugPrint('🔍 معالجة سجل للسائق: ${record['driver_id']}');

        final driverId = record['driver_id'];
        String? fullName;

        if (driverId != null) {
          // محاولة البحث بـ username أولاً
          fullName = driverNamesMap[driverId];

          // إذا لم نجد، محاولة البحث بـ id
          if (fullName == null || fullName.isEmpty) {
            fullName = driverIdToNameMap[driverId.toString()];
          }

          if (fullName != null && fullName.isNotEmpty) {
            recordWithDriver['driver_full_name'] = fullName;
            recordWithDriver['driver_username'] = driverId;
            debugPrint('✅ تم إضافة الاسم الكامل: $fullName للسائق: $driverId');
          } else {
            debugPrint('❌ لم يتم العثور على السائق $driverId في جدول managers');
            // ربط بقيمة افتراضية إذا لم نجد الاسم
            recordWithDriver['driver_full_name'] = 'سائق غير محدد';
            recordWithDriver['driver_username'] = driverId;
          }
        } else {
          debugPrint('⚠️ driver_id فارغ في هذا السجل');
          recordWithDriver['driver_full_name'] = 'سائق غير محدد';
          recordWithDriver['driver_username'] = null;
        }

        recordsWithDriverInfo.add(recordWithDriver);
      }

      setState(() {
        if (loadMore) {
          driverRecords.addAll(recordsWithDriverInfo);
          _currentPage++;
          _isLoadingMore = false;
        } else {
          driverRecords = recordsWithDriverInfo;
          isLoading = false;
        }
      });

      debugPrint(
        '📊 Final: Set ${driverRecords.length} total driver records in state',
      );

      // تحميل الإحصائيات بعد تحميل السجلات (only on initial load)
      if (!loadMore) {
        await _loadFleetData();
        await _loadUnreadNotificationsCount();
      }
    } catch (e) {
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          errorMessage = 'خطأ في تحميل البيانات: $e';
          isLoading = false;
        }
      });
      debugPrint('خطأ في تحميل سجلات السائقين: $e');
    }
  }

  // Load more records function
  Future<void> _loadMoreRecords() async {
    if (!_hasMoreData || _isLoadingMore) return;
    await _loadDriverRecords(loadMore: true);
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
      'newNotifications':
          _unreadNotificationsCount, // استخدام العدد الفعلي للإشعارات
      'totalDrivers': uniqueDriversCount,
      'todayCheckins': todayCheckinsCount,
      'monthlyTrips': totalCheckinsCount,
      'totalRecords': totalCheckinsCount,
    };
  }

  int get uniqueDrivers {
    return driverRecords.map((r) => r['driver_id']).toSet().length;
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      setState(() {
        _unreadNotificationsCount = count;
      });
    } catch (e) {
      debugPrint('خطأ في جلب عدد الإشعارات غير المقروءة: $e');
    }
  }

  void _openNotifications() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        )
        .then((_) {
          // تحديث عدد الإشعارات غير المقروءة عند العودة
          _loadUnreadNotificationsCount();
        });
  }

  @override
  Widget build(BuildContext context) {
    void openPage(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    void openManagerProfile(BuildContext context) {
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
          // زر الإشعارات
          IconButton(
            onPressed: _openNotifications,
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationsCount > 99
                            ? '99+'
                            : '$_unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'الإشعارات',
          ),
          IconButton(
            onPressed: _loadDriverRecords,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: () => openManagerProfile(context),
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

              // Modern Statistics Cards with real data
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4F46E5).withOpacity(0.05),
                      const Color(0xFF7C3AED).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إحصائيات الأسطول',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'بيانات فورية من قاعدة البيانات',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.green.shade400,
                                  size: 8,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'متصل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Statistics Grid
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        children: [
                          _ModernStatCard(
                            title: 'إجمالي السجلات',
                            value: '${fleetData['totalRecords']}',
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF4F46E5),
                            gradient: const [
                              Color(0xFF4F46E5),
                              Color(0xFF7C3AED),
                            ],
                            subtitle: 'من جميع السائقين',
                          ),
                          _ModernStatCard(
                            title: 'السائقون النشطون',
                            value: '${fleetData['connectedDrivers']}',
                            icon: Icons.people_rounded,
                            color: const Color(0xFF00C9A7),
                            gradient: const [
                              Color(0xFF00C9A7),
                              Color(0xFF2BE7C7),
                            ],
                            subtitle: 'سائق مسجل',
                          ),
                          _ModernStatCard(
                            title: 'إشعارات جديدة',
                            value: '${fleetData['newNotifications']}',
                            icon: Icons.notifications_active_rounded,
                            color: const Color(0xFFFF6B6B),
                            gradient: const [
                              Color(0xFFFF6B6B),
                              Color(0xFFFF8E8E),
                            ],
                            subtitle: 'إشعار غير مقروء',
                          ),
                          _ModernStatCard(
                            title: 'مجموع المركبات',
                            value: '${fleetData['totalCars']}',
                            icon: Icons.local_shipping_rounded,
                            color: const Color(0xFFFFA726),
                            gradient: const [
                              Color(0xFFFFA726),
                              Color(0xFFFFCC80),
                            ],
                            subtitle: 'مركبة مسجلة',
                          ),
                        ],
                      ),
                    ),

                    // Additional Quick Stats
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickStatCard(
                              title: 'تسجيلات اليوم',
                              value: '${fleetData['todayCheckins']}',
                              icon: Icons.today_rounded,
                              color: const Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickStatCard(
                              title: 'الرحلات النشطة',
                              value: '${fleetData['activeTrips']}',
                              icon: Icons.route_rounded,
                              color: const Color(0xFF2DD4BF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

              // Reports Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B4D8).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReportsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'التقارير المتقدمة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'تقارير السيارات والسائقين مع إختيار التاريخ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.date_range,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'اختيار التاريخ من - إلى',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.assessment,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'إحصائيات متقدمة',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Driver records section
              _DriverRecordsSection(
                records: driverRecords,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onRetry: _loadDriverRecords,
                hasMoreData: _hasMoreData,
                isLoadingMore: _isLoadingMore,
                onLoadMore: _loadMoreRecords,
                currentPage: _currentPage,
                totalRecords: _totalRecords,
                itemsPerPage: _itemsPerPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
  final bool hasMoreData;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final int currentPage;
  final int totalRecords;
  final int itemsPerPage;

  const _DriverRecordsSection({
    required this.records,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
    required this.hasMoreData,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.currentPage,
    required this.totalRecords,
    required this.itemsPerPage,
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
                Expanded(
                  child: Text(
                    'سجلات السائقين اليومية',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Pagination info
                if (totalRecords > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${records.length}/$totalRecords',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00C9A7),
                      ),
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
              Column(
                children: [
                  ...records.map((record) => _DriverRecordTile(record: record)),

                  // Load more button or pagination controls
                  if (hasMoreData || isLoadingMore) const SizedBox(height: 16),
                  if (hasMoreData || isLoadingMore)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isLoadingMore)
                            Column(
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFF4F46E5),
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'جاري تحميل المزيد...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            )
                          else if (hasMoreData)
                            ElevatedButton.icon(
                              onPressed: onLoadMore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              label: Text(
                                'تحميل المزيد ($itemsPerPage سجل)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (!hasMoreData && !isLoadingMore && records.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF00C9A7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تم عرض جميع السجلات',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
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
    // Debug: Print what data we have for this record
    debugPrint('🎯 Driver Record Data:');
    debugPrint('   driver_id: ${record['driver_id']}');
    debugPrint('   driver_full_name: ${record['driver_full_name']}');
    debugPrint('   driver_username: ${record['driver_username']}');
    debugPrint('   جميع البيانات: $record');

    // تحديد الحالة بناءً على البيانات الحقيقية
    final status = record['status'] ?? 'مكتمل';

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

    // الحصول على الاسم الكامل للسائق
    String driverFullName;

    // أولوية عرض الاسم الكامل من جدول managers
    if (record['driver_full_name'] != null &&
        record['driver_full_name'].toString().trim().isNotEmpty &&
        record['driver_full_name'].toString().trim() != 'سائق غير محدد') {
      driverFullName = record['driver_full_name'].toString().trim();
    } else {
      // في حالة عدم وجود اسم كامل، عرض رسالة واضحة
      driverFullName = 'سائق غير معرّف';
    }

    // الرقم التسلسلي للرحلة
    final serialNumber = record['serial']?.toString() ?? 'غير محدد';

    // معلومات الموقع
    final hasLocation = record['lat'] != null && record['lon'] != null;
    final locationText = hasLocation
        ? 'تم تحديد الموقع'
        : 'لم يتم تحديد الموقع';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CheckinDetailsPage(checkinData: record),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFF4F46E5).withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with driver info and serial number
              Row(
                children: [
                  // Driver avatar with gradient
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Driver name and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver full name
                        Text(
                          driverFullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Location info with icon
                        Row(
                          children: [
                            Icon(
                              hasLocation
                                  ? Icons.location_on
                                  : Icons.location_off,
                              size: 12,
                              color: hasLocation
                                  ? const Color(0xFF00C9A7)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locationText,
                              style: TextStyle(
                                fontSize: 11,
                                color: hasLocation
                                    ? const Color(0xFF00C9A7)
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Serial number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9A7), Color(0xFF2BE7C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C9A7).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$serialNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status and time info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Status
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: status == 'مكتمل'
                                  ? const Color(0xFF00C9A7).withOpacity(0.1)
                                  : const Color(0xFFFFA726).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              status == 'مكتمل'
                                  ? Icons.check_circle
                                  : Icons.pending,
                              size: 14,
                              color: status == 'مكتمل'
                                  ? const Color(0xFF00C9A7)
                                  : const Color(0xFFFFA726),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: status == 'مكتمل'
                                  ? const Color(0xFF00C9A7)
                                  : const Color(0xFFFFA726),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time info
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
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notes section (if available)
              if (record['notes'] != null &&
                  record['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_alt,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record['notes'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 12,
                        color: const Color(0xFF4F46E5).withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'اضغط لعرض التفاصيل',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF4F46E5).withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
