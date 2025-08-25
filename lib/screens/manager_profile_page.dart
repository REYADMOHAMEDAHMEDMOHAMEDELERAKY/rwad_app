import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/auth_bloc.dart';
import 'welcome_page.dart';

class ManagerProfilePage extends StatefulWidget {
  const ManagerProfilePage({super.key});

  @override
  State<ManagerProfilePage> createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  // بيانات المدير من قاعدة البيانات
  Map<String, dynamic> managerData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadManagerData();
  }

  Future<void> _loadManagerData() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;

      // قراءة بيانات المدير الحالي (يمكن تحديثها لاحقاً لتدعم تسجيل الدخول)
      final res = await client
          .from('managers')
          .select('*')
          .eq('username', 'alaa') // افتراضياً نقرأ بيانات alaa
          .single();

      if (res != null) {
        setState(() {
          managerData = Map<String, dynamic>.from(res);
        });
      }
    } catch (e) {
      debugPrint('loadManagerData error: $e');
      // استخدام بيانات افتراضية في حالة الخطأ
      managerData = {
        'username': 'alaa',
        'full_name': 'علاء أحمد',
        'email': 'alaa@rwaad.com',
        'phone': '+966 50 123 4567',
        'role': 'مدير النظام',
        'department': 'إدارة الأسطول',
        'join_date': '2024-01-01',
        'last_login': '2024-01-15 08:30',
        'total_actions': 156,
        'active_sessions': 3,
      };
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateLastLogin() async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('managers')
          .update({
            'last_login': DateTime.now().toIso8601String(),
            'active_sessions': (managerData['active_sessions'] ?? 0) + 1,
          })
          .eq('username', managerData['username']);

      // تحديث البيانات المحلية
      await _loadManagerData();
    } catch (e) {
      debugPrint('updateLastLogin error: $e');
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
          title: const Text('تأكيد تسجيل الخروج'),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من النظام؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    try {
      // تحديث آخر تسجيل دخول قبل الخروج
      await _updateLastLogin();

      // تسجيل الخروج من AuthBloc
      final authBloc = context.read<AuthBloc>();
      authBloc.add(LogoutRequested());

      // العودة إلى صفحة الترحيب
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false, // إزالة جميع الصفحات من المكدس
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('بيانات المدير'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4F46E5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل بيانات المدير...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
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
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
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
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            managerData['full_name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            managerData['role'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            managerData['department'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile information section
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
                                      0xFF4F46E5,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF4F46E5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'المعلومات الشخصية',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _ProfileInfoRow(
                              icon: Icons.person_outline,
                              label: 'اسم المستخدم',
                              value: managerData['username'] ?? '',
                            ),
                            const SizedBox(height: 16),
                            _ProfileInfoRow(
                              icon: Icons.email_outlined,
                              label: 'البريد الإلكتروني',
                              value: managerData['email'] ?? '',
                            ),
                            const SizedBox(height: 16),
                            _ProfileInfoRow(
                              icon: Icons.phone_outlined,
                              label: 'رقم الهاتف',
                              value: managerData['phone'] ?? '',
                            ),
                            const SizedBox(height: 16),
                            _ProfileInfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'تاريخ الانضمام',
                              value: managerData['join_date'] ?? '',
                            ),
                            const SizedBox(height: 16),
                            _ProfileInfoRow(
                              icon: Icons.access_time_outlined,
                              label: 'آخر تسجيل دخول',
                              value: managerData['last_login'] ?? '',
                            ),
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
                                    Icons.analytics_outlined,
                                    color: Color(0xFF00C9A7),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'إحصائيات النشاط',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    title: 'إجمالي الإجراءات',
                                    value: '${managerData['total_actions']}',
                                    icon: Icons.touch_app,
                                    color: const Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    title: 'الجلسات النشطة',
                                    value: '${managerData['active_sessions']}',
                                    icon: Icons.people,
                                    color: const Color(0xFF00C9A7),
                                  ),
                                ),
                              ],
                            ),
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
                                const Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'اضغط على الزر أدناه لتسجيل الخروج من النظام والعودة إلى صفحة الترحيب.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
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
                                label: const Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
