import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  bool _isLoadingImages = false;
  String? _imageError;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'الرقم التسلسلي',
                                '${widget.checkinData['serial'] ?? 'N/A'}',
                                Icons.numbers,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'معرف السائق',
                                widget.checkinData['driver_id'] ?? 'N/A',
                                Icons.person,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'التاريخ والوقت',
                                widget.checkinData['timestamp'] != null
                                    ? DateTime.parse(
                                        widget.checkinData['timestamp'],
                                      ).toLocal().toString().split('.').first
                                    : 'N/A',
                                Icons.access_time,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'آخر تحديث',
                                widget.checkinData['updated_at'] != null
                                    ? DateTime.parse(
                                        widget.checkinData['updated_at'],
                                      ).toLocal().toString().split('.').first
                                    : 'N/A',
                                Icons.update,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
