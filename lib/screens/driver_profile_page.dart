import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_page.dart';
import 'checkin_detail_page.dart';

class DriverProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const DriverProfilePage({super.key, this.userInfo});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  // بيانات السائق من قاعدة البيانات
  Map<String, dynamic> driverData = {};
  bool _loading = true;
  int _totalCheckinsCount = 0;
  int _todayCheckinsCount = 0;
  Map<String, dynamic>? _assignedCar;
  List<Map<String, dynamic>> _driverCheckins = [];
  bool _loadingCheckins = false;
  bool _showingAllCheckins = false; // متغير لتتبع حالة عرض جميع التسجيلات

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _loading = true;
      _showingAllCheckins = false; // إعادة تعيين حالة عرض التسجيلات
    });
    try {
      final client = Supabase.instance.client;

      // استخدام معلومات المستخدم المرسلة من صفحة السائق
      if (widget.userInfo != null) {
        setState(() {
          driverData = Map<String, dynamic>.from(widget.userInfo!);
        });
      } else {
        // محاولة جلب بيانات السائق من قاعدة البيانات
        final res = await client
            .from('managers')
            .select('*')
            .eq('role', 'driver')
            .limit(1)
            .maybeSingle();

        if (res != null) {
          setState(() {
            driverData = Map<String, dynamic>.from(res);
          });
        }
      }

      // جلب إحصائيات السائق
      await _loadDriverStats();
      await _loadAssignedCar();
      await _loadDriverCheckins();
    } catch (e) {
      debugPrint('loadDriverData error: $e');
      // استخدام بيانات افتراضية في حالة الخطأ
      setState(() {
        driverData = {
          'username': 'السائق',
          'full_name': 'السائق',
          'role': 'driver',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDriverStats() async {
    try {
      final client = Supabase.instance.client;
      final driverId = driverData['id']?.toString();

      if (driverId != null) {
        // إجمالي التسجيلات
        final totalResponse = await client
            .from('checkins')
            .select('id')
            .eq('driver_id', driverId);

        setState(() {
          _totalCheckinsCount = totalResponse.length;
        });

        // تسجيلات اليوم
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayResponse = await client
            .from('checkins')
            .select('id')
            .eq('driver_id', driverId)
            .gte('created_at', todayStart.toIso8601String());

        setState(() {
          _todayCheckinsCount = todayResponse.length;
        });
      }
    } catch (e) {
      debugPrint('loadDriverStats error: $e');
    }
  }

  Future<void> _loadAssignedCar() async {
    try {
      final client = Supabase.instance.client;
      final username = driverData['username'];

      if (username != null) {
        // البحث عن المركبة المخصصة للسائق
        final carResponse = await client
            .from('car_drivers')
            .select('car_id, cars(id, plate, model, notes)')
            .eq('driver_username', username)
            .maybeSingle();

        if (carResponse != null && carResponse['cars'] != null) {
          setState(() {
            _assignedCar = Map<String, dynamic>.from(carResponse['cars']);
          });
        }
      }
    } catch (e) {
      debugPrint('loadAssignedCar error: $e');
    }
  }

  Future<void> _loadDriverCheckins() async {
    setState(() => _loadingCheckins = true);
    try {
      final client = Supabase.instance.client;
      final driverId = driverData['id']?.toString();

      if (driverId != null) {
        // جلب جميع تسجيلات السائق مرتبة بالتاريخ (الأحدث أولاً)
        final checkinsResponse = await client
            .from('checkins')
            .select('*')
            .eq('driver_id', driverId)
            .order('created_at', ascending: false)
            .limit(50); // تحديد عدد التسجيلات المعروضة

        setState(() {
          _driverCheckins = List<Map<String, dynamic>>.from(checkinsResponse);
        });
      }
    } catch (e) {
      debugPrint('loadDriverCheckins error: $e');
      setState(() {
        _driverCheckins = [];
      });
    } finally {
      setState(() => _loadingCheckins = false);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                'تأكيد تسجيل الخروج',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج من النظام؟',
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    // العودة إلى صفحة الترحيب
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false, // إزالة جميع الصفحات من المكدس
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          title: Text(
            'بيانات السائق',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF00C9A7),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00C9A7)),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تحميل بيانات السائق...',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF64748B),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header section with profile picture
                      Container(
                        padding: const EdgeInsets.all(24),
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
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile picture
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.directions_car,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              driverData['full_name'] ??
                                  driverData['username'] ??
                                  'السائق',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سائق',
                              style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${driverData['username'] ?? ''}',
                              style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Driver information section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00C9A7,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info,
                                      color: Color(0xFF00C9A7),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'معلومات السائق',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInfoCard(
                                'اسم المستخدم',
                                driverData['username'] ?? 'غير محدد',
                                Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                'الاسم الكامل',
                                driverData['full_name'] ?? 'غير محدد',
                                Icons.badge,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                'المعرف',
                                driverData['id']?.toString() ?? 'غير محدد',
                                Icons.tag,
                              ),
                              if (_assignedCar != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'المركبة المخصصة',
                                  '${_assignedCar!['plate']} - ${_assignedCar!['model']}',
                                  Icons.directions_car,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Statistics section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00C9A7,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.analytics,
                                      color: Color(0xFF00C9A7),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'الإحصائيات',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'إجمالي التسجيلات',
                                      value: '$_totalCheckinsCount',
                                      icon: Icons.checklist,
                                      color: const Color(0xFF00C9A7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'تسجيلات اليوم',
                                      value: '$_todayCheckinsCount',
                                      icon: Icons.today,
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Check-ins History section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00C9A7,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.history,
                                      color: Color(0xFF00C9A7),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'سجل التسجيلات',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _loadDriverCheckins,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF00C9A7,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.refresh,
                                        color: Color(0xFF00C9A7),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildCheckinsHistory(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Logout button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF6B6B,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      color: Color(0xFFFF6B6B),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'تسجيل الخروج',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'اضغط على الزر أدناه لتسجيل الخروج من النظام والعودة إلى صفحة الترحيب.',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _logout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B6B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.logout),
                                  label: Text(
                                    'تسجيل الخروج',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00C9A7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinsHistory() {
    if (_loadingCheckins) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircularProgressIndicator(color: Color(0xFF00C9A7)),
              const SizedBox(height: 12),
              Text(
                'جاري تحميل التسجيلات...',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_driverCheckins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'لا توجد تسجيلات',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'لم يتم تسجيل أي تسجيلات حتى الآن',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // عرض إجمالي عدد التسجيلات
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00C9A7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'إجمالي التسجيلات: ${_driverCheckins.length}',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00C9A7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // قائمة التسجيلات
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _showingAllCheckins
              ? _driverCheckins.length
              : (_driverCheckins.length > 10 ? 10 : _driverCheckins.length),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final checkin = _driverCheckins[index];
            return _buildCheckinCard(checkin);
          },
        ),
        if (_driverCheckins.length > 10) ...[
          const SizedBox(height: 16),
          if (!_showingAllCheckins) ...[
            // زر عرض جميع التسجيلات
            Container(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showingAllCheckins = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.expand_more, size: 20),
                label: Text(
                  'عرض جميع التسجيلات (${_driverCheckins.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'يتم عرض أول 10 تسجيلات من أصل ${_driverCheckins.length}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ] else ...[
            // زر إخفاء التسجيلات الإضافية
            Container(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showingAllCheckins = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.expand_less, size: 20),
                label: Text(
                  'عرض أول 10 تسجيلات فقط',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'يتم عرض جميع التسجيلات (${_driverCheckins.length})',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: const Color(0xFF00C9A7),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildCheckinCard(Map<String, dynamic> checkin) {
    final createdAt = DateTime.tryParse(checkin['created_at'] ?? '');
    final serialNumber = checkin['serial']?.toString() ?? 'غير محدد';
    final latitude = checkin['lat']?.toString() ?? 'غير محدد';
    final longitude = checkin['lon']?.toString() ?? 'غير محدد';
    final country = checkin['country'] ?? '';
    final city = checkin['city'] ?? '';
    final district = checkin['district'] ?? '';

    // تنسيق العنوان
    String address = '';
    if (country.isNotEmpty || city.isNotEmpty || district.isNotEmpty) {
      List<String> addressParts = [];
      if (district.isNotEmpty) addressParts.add(district);
      if (city.isNotEmpty) addressParts.add(city);
      if (country.isNotEmpty) addressParts.add(country);
      address = addressParts.join(', ');
    } else {
      address = 'الموقع غير محدد';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CheckinDetailPage(checkinData: checkin),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00C9A7).withOpacity(0.05),
              const Color(0xFF2BE7C7).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00C9A7).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات التسجيل الأساسية
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'رقم $serialNumber',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: const Color(0xFF00C9A7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: const Color(0xFF00C9A7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // الإحداثيات والوقت
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$latitude, $longitude',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // إضافة أيقونات الصور إذا كانت متوفرة
            if (checkin['before_path'] != null ||
                checkin['after_path'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (checkin['before_path'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'قبل',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (checkin['before_path'] != null &&
                      checkin['after_path'] != null)
                    const SizedBox(width: 6),
                  if (checkin['after_path'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'بعد',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            // نص يشير إلى إمكانية النقر
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 14,
                  color: const Color(0xFF00C9A7).withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'اضغط لعرض التفاصيل الكاملة',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: const Color(0xFF00C9A7).withOpacity(0.6),
                    fontStyle: FontStyle.italic,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
