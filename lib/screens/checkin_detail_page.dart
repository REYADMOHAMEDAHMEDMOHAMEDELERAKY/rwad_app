import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckinDetailPage extends StatelessWidget {
  final Map<String, dynamic> checkinData;

  const CheckinDetailPage({super.key, required this.checkinData});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(checkinData['created_at'] ?? '');
    final serialNumber = checkinData['serial']?.toString() ?? 'غير محدد';
    final latitude = checkinData['lat']?.toString() ?? 'غير محدد';
    final longitude = checkinData['lon']?.toString() ?? 'غير محدد';
    final country = checkinData['country'] ?? '';
    final city = checkinData['city'] ?? '';
    final district = checkinData['district'] ?? '';
    final street = checkinData['street'] ?? '';
    final fullAddress = checkinData['full_address'] ?? '';
    final accuracy = checkinData['accuracy']?.toString() ?? '';
    final altitude = checkinData['altitude']?.toString() ?? '';
    final speed = checkinData['speed']?.toString() ?? '';
    final heading = checkinData['heading']?.toString() ?? '';
    final notes = checkinData['notes'] ?? '';

    // تنسيق العنوان
    String displayAddress = '';
    if (fullAddress.isNotEmpty) {
      displayAddress = fullAddress;
    } else if (country.isNotEmpty || city.isNotEmpty || district.isNotEmpty) {
      List<String> addressParts = [];
      if (street.isNotEmpty) addressParts.add(street);
      if (district.isNotEmpty) addressParts.add(district);
      if (city.isNotEmpty) addressParts.add(city);
      if (country.isNotEmpty) addressParts.add(country);
      displayAddress = addressParts.join(', ');
    } else {
      displayAddress = 'الموقع غير محدد';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          title: Text(
            'تفاصيل التسجيل رقم $serialNumber',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card with basic info
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تسجيل رقم $serialNumber',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (createdAt != null)
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} - ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Location Information Card
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
                                color: const Color(0xFF00C9A7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFF00C9A7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'معلومات الموقع',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow(
                          'العنوان الكامل',
                          displayAddress,
                          Icons.location_city,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'خط العرض',
                                latitude,
                                Icons.my_location,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailRow(
                                'خط الطول',
                                longitude,
                                Icons.my_location,
                              ),
                            ),
                          ],
                        ),
                        if (accuracy.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'دقة الموقع',
                            '$accuracy متر',
                            Icons.gps_fixed,
                          ),
                        ],
                        if (altitude.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'الارتفاع',
                            '$altitude متر',
                            Icons.height,
                          ),
                        ],
                        if (speed.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('السرعة', '$speed م/ث', Icons.speed),
                        ],
                        if (heading.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'الاتجاه',
                            '$heading درجة',
                            Icons.navigation,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Images Section
                if (checkinData['before_path'] != null ||
                    checkinData['after_path'] != null) ...[
                  const SizedBox(height: 20),
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
                                  Icons.photo_library,
                                  color: Color(0xFF00C9A7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'الصور المرفقة',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildImagesSection(context),
                        ],
                      ),
                    ),
                  ),
                ],

                // Additional Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                                  Icons.note,
                                  color: Color(0xFF00C9A7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ملاحظات إضافية',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              notes,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
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
            child: Icon(icon, color: const Color(0xFF00C9A7), size: 18),
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

  Widget _buildImagesSection(BuildContext context) {
    final beforeImageUrl = checkinData['before_path'];
    final afterImageUrl = checkinData['after_path'];

    return Column(
      children: [
        if (beforeImageUrl != null) ...[
          _buildImageCard(
            context,
            'صورة قبل العمل',
            beforeImageUrl,
            Colors.blue,
            Icons.camera_alt,
          ),
          const SizedBox(height: 16),
        ],
        if (afterImageUrl != null) ...[
          _buildImageCard(
            context,
            'صورة بعد العمل',
            afterImageUrl,
            Colors.green,
            Icons.camera_alt,
          ),
        ],
      ],
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    String title,
    String imageUrl,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: GestureDetector(
              onTap: () {
                _showFullScreenImage(context, imageUrl, title);
              },
              child: Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade200,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'جاري تحميل الصورة...',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'فشل في تحميل الصورة',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: color.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  'اضغط لعرض الصورة بالحجم الكامل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
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
                    fontSize: 16,
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
}
