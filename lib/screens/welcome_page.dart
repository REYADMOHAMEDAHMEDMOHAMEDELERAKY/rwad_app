import 'package:flutter/material.dart';
import '../widgets/feature_tile.dart';
import '../widgets/ui_styles.dart';
import 'driver_login_page.dart';
import 'manager_login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('FleetTracker'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'نظام إدارة وتتبع السيارات',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'مرحباً بك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),

                // Features
                const Text(
                  'المميزات الرئيسية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    FeatureTile(icon: Icons.camera_alt, label: 'التقاط الصور'),
                    FeatureTile(icon: Icons.gps_fixed, label: 'تتبع الموقع'),
                    FeatureTile(icon: Icons.access_time, label: 'تسجيل الوقت'),
                    FeatureTile(icon: Icons.note, label: 'الملاحظات'),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'اختر نوع حسابك للمتابعة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Driver Button
                Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('تم الضغط على زر السائق');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DriverLoginPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions_car, size: 24),
                    label: const Text(
                      'واجهة السائق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                // Manager Button
                Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('تم الضغط على زر المدير');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ManagerLoginPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts, size: 24),
                    label: const Text(
                      'واجهة المدير',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // small footer
                const Text(
                  'FleetTracker — نسخة تجريبية',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
