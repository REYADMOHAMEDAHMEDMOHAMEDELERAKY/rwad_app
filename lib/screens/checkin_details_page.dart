import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class CheckinDetailsPage extends StatefulWidget {
  final Map<String, dynamic> checkinData;

  const CheckinDetailsPage({super.key, required this.checkinData});

  @override
  State<CheckinDetailsPage> createState() => _CheckinDetailsPageState();
}

class _CheckinDetailsPageState extends State<CheckinDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final bool _isLoadingImages = false;
  String? _imageError;
  Map<String, dynamic>? _driverInfo;
  bool _loadingDriverInfo = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
    _loadDriverInfo();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverInfo() async {
    setState(() => _loadingDriverInfo = true);
    try {
      final client = Supabase.instance.client;
      final driverId = widget.checkinData['driver_id'];

      if (driverId != null) {
        // جلب بيانات السائق من جدول managers
        final response =
            await client
                .from('managers')
                .select('id, username, full_name, role')
                .eq('id', driverId)
                .maybeSingle();

        if (response != null) {
          setState(() {
            _driverInfo = Map<String, dynamic>.from(response);
          });
        }
      }
    } catch (e) {
      debugPrint('خطأ في جلب بيانات السائق: $e');
    } finally {
      setState(() => _loadingDriverInfo = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    try {
      // الحصول على إحداثيات الموقع
      String? lat, lon;

      if (widget.checkinData['lat'] != null &&
          widget.checkinData['lon'] != null) {
        lat = widget.checkinData['lat'].toString();
        lon = widget.checkinData['lon'].toString();
      } else if (widget.checkinData['latitude'] != null &&
          widget.checkinData['longitude'] != null) {
        lat = widget.checkinData['latitude'].toString();
        lon = widget.checkinData['longitude'].toString();
      }

      if (lat != null && lon != null && lat != 'null' && lon != 'null') {
        // إنشاء رابط Google Maps
        final url = 'https://www.google.com/maps?q=$lat,$lon';

        debugPrint('🗺️ فتح Google Maps للموقع: $lat, $lon');

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('لا يمكن فتح Google Maps', isError: true);
        }
      } else {
        _showSnackBar('إحداثيات الموقع غير متوفرة', isError: true);
      }
    } catch (e) {
      debugPrint('خطأ في فتح Google Maps: $e');
      _showSnackBar('حدث خطأ أثناء فتح الخريطة', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 100,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'فشل في تحميل الصورة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    String title,
    String? imageUrl,
    String placeholder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade100, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child:
              imageUrl != null && imageUrl.isNotEmpty
                  ? GestureDetector(
                    onTap: () => _showFullScreenImage(imageUrl, title),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade600,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'خطأ في تحميل الصورة',
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('إعادة المحاولة'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          // إضافة مؤشر للنقر
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'اضغط للتكبير',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        placeholder,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'تفاصيل الموقع',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.checkinData['country'] != null) ...[
            _buildLocationRow('الدولة', widget.checkinData['country']),
            const SizedBox(height: 8),
          ],
          if (widget.checkinData['city'] != null) ...[
            _buildLocationRow('المدينة', widget.checkinData['city']),
            const SizedBox(height: 8),
          ],
          if (widget.checkinData['district'] != null) ...[
            _buildLocationRow('الحي', widget.checkinData['district']),
            const SizedBox(height: 8),
          ],
          if (widget.checkinData['street'] != null) ...[
            _buildLocationRow('الشارع', widget.checkinData['street']),
            const SizedBox(height: 8),
          ],
          if (widget.checkinData['full_address'] != null) ...[
            _buildLocationRow(
              'العنوان الكامل',
              widget.checkinData['full_address'],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإحداثيات',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${widget.checkinData['lat'] ?? widget.checkinData['latitude'] ?? 'N/A'}, ${widget.checkinData['lon'] ?? widget.checkinData['longitude'] ?? 'N/A'}',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // زر فتح Google Maps
          const SizedBox(height: 16),
          _buildGoogleMapsButton(),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      children: [
        Icon(Icons.circle, color: Colors.blue.shade400, size: 8),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMapsButton() {
    // تحقق من وجود إحداثيات الموقع
    bool hasCoordinates = false;

    if ((widget.checkinData['lat'] != null &&
            widget.checkinData['lon'] != null) ||
        (widget.checkinData['latitude'] != null &&
            widget.checkinData['longitude'] != null)) {
      final lat =
          widget.checkinData['lat']?.toString() ??
          widget.checkinData['latitude']?.toString();
      final lon =
          widget.checkinData['lon']?.toString() ??
          widget.checkinData['longitude']?.toString();

      if (lat != null &&
          lon != null &&
          lat != 'null' &&
          lon != 'null' &&
          lat.isNotEmpty &&
          lon.isNotEmpty) {
        hasCoordinates = true;
      }
    }

    if (!hasCoordinates) {
      return const SizedBox.shrink(); // لا يظهر الزر إذا لم توجد إحداثيات
    }

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openGoogleMaps,
        icon: Icon(Icons.map, size: 20),
        label: Text(
          'فتح في Google Maps',
          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'تفاصيل السجل #${widget.checkinData['serial'] ?? 'N/A'}',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Record Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'تفاصيل السجل',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoCard(
                          'الرقم التسلسلي',
                          '${widget.checkinData['serial'] ?? 'N/A'}',
                          Icons.numbers,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          'آخر تحديث',
                          widget.checkinData['updated_at'] != null
                              ? DateTime.parse(
                                widget.checkinData['updated_at'],
                              ).toLocal().toString().split('.').first
                              : 'N/A',
                          Icons.update,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Driver Information Card (for managers)
                  if (_driverInfo != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'معلومات السائق',
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              if (_loadingDriverInfo) const Spacer(),
                              if (_loadingDriverInfo)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            'اسم المستخدم',
                            _driverInfo!['username'] ?? 'غير محدد',
                            Icons.account_circle,
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            'الاسم الكامل',
                            _driverInfo!['full_name'] ??
                                _driverInfo!['username'] ??
                                'غير محدد',
                            Icons.badge,
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            'الدور',
                            _driverInfo!['role'] ?? 'سائق',
                            Icons.work,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  if (_driverInfo != null) const SizedBox(height: 24),
                  if (_driverInfo == null && _loadingDriverInfo)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(strokeWidth: 2),
                          const SizedBox(width: 16),
                          Text(
                            'جاري تحميل معلومات السائق...',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_driverInfo == null && _loadingDriverInfo)
                    const SizedBox(height: 24),

                  // Images Section
                  _buildImageSection(
                    'صورة قبل العمل',
                    widget.checkinData['before_path'],
                    'لا توجد صورة قبل العمل',
                  ),

                  const SizedBox(height: 24),

                  _buildImageSection(
                    'صورة بعد العمل',
                    widget.checkinData['after_path'],
                    'لا توجد صورة بعد العمل',
                  ),

                  const SizedBox(height: 24),

                  // Location Details
                  _buildLocationCard(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
