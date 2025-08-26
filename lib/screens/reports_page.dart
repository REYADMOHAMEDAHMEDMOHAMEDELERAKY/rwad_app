import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'checkin_details_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedReportType = 'cars'; // cars, drivers, all
  List<Map<String, dynamic>> _reportData = [];
  List<Map<String, dynamic>> _allDetailedRecords = []; // For PDF generation
  bool _isLoading = false;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    // Set default date range (last 7 days)
    _toDate = DateTime.now();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
  }

  Future<void> _selectFromDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            _fromDate ?? DateTime.now().subtract(const Duration(days: 7)),
        firstDate: DateTime(2020),
        lastDate: _toDate ?? DateTime.now(),
        locale: const Locale('ar'),
      );
      if (picked != null && picked != _fromDate) {
        setState(() {
          _fromDate = picked;
          // If toDate is before fromDate, reset toDate
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في اختيار التاريخ: $e',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectToDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _toDate ?? DateTime.now(),
        firstDate: _fromDate ?? DateTime(2020),
        lastDate: DateTime.now(),
        locale: const Locale('ar'),
      );
      if (picked != null && picked != _toDate) {
        setState(() {
          _toDate = picked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في اختيار التاريخ: $e',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateReport() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار تاريخ البداية والنهاية',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasData = false;
    });

    try {
      final client = Supabase.instance.client;

      // Format dates for database query
      final fromDateString = _fromDate!.toIso8601String().split('T')[0];
      final toDateString = _toDate!
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];

      List<Map<String, dynamic>> data = [];

      if (_selectedReportType == 'cars' || _selectedReportType == 'all') {
        // Get cars data with check-ins count
        final carsResponse = await client
            .from('checkins')
            .select('*')
            .gte('created_at', fromDateString)
            .lt('created_at', toDateString)
            .order('created_at', ascending: false);

        debugPrint('🔍 Retrieved ${carsResponse.length} checkin records');

        // Get all driver names first for better mapping
        final driversResponse = await client
            .from('managers')
            .select('username, full_name, id');

        debugPrint(
          '👥 Retrieved ${driversResponse.length} drivers from managers table',
        );

        // Create mapping for driver names (both username and id)
        final Map<String, String?> driverNamesMap = {};
        final Map<String, String?> driverIdToNameMap = {};

        for (var driver in driversResponse) {
          // Map username to full_name
          if (driver['username'] != null) {
            driverNamesMap[driver['username']] = driver['full_name'];
          }
          // Map id to full_name as well
          if (driver['id'] != null) {
            driverIdToNameMap[driver['id'].toString()] = driver['full_name'];
          }
          debugPrint(
            '💾 Driver mapping: username=${driver['username']}, id=${driver['id']}, full_name=${driver['full_name']}',
          );
        }

        // Group by driver and count
        Map<String, Map<String, dynamic>> carsData = {};
        List<Map<String, dynamic>> allRecords =
            []; // Store all detailed records

        for (var record in carsResponse) {
          final driverId = record['driver_id']?.toString() ?? 'unknown';

          // Find driver name using both mapping approaches
          String? driverFullName;

          // Try username mapping first
          driverFullName = driverNamesMap[driverId];

          // If not found, try id mapping
          if ((driverFullName == null || driverFullName.isEmpty) &&
              driverId != 'unknown') {
            driverFullName = driverIdToNameMap[driverId];
          }

          // Use a default if still not found
          if (driverFullName == null || driverFullName.isEmpty) {
            driverFullName = driverId != 'unknown'
                ? 'سائق غير معرّف ($driverId)'
                : 'سائق غير محدد';
          }

          debugPrint('🎯 Driver ID: $driverId -> Full Name: $driverFullName');

          // Add to detailed records for PDF
          allRecords.add({...record, 'driver_full_name': driverFullName});

          if (!carsData.containsKey(driverId)) {
            carsData[driverId] = {
              'driver_id': driverId,
              'driver_name': driverFullName,
              'total_checkins': 0,
              'type': 'car',
              'detailed_records':
                  <Map<String, dynamic>>[], // Store detailed records
            };
          }
          carsData[driverId]!['total_checkins']++;
          carsData[driverId]!['detailed_records'].add({
            ...record,
            'driver_full_name': driverFullName,
          });
        }

        data.addAll(carsData.values);

        // Store all records for PDF generation
        setState(() {
          _allDetailedRecords = allRecords;
        });
      }

      setState(() {
        _reportData = data;
        _hasData = data.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل التقرير: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePDF() async {
    if (_allDetailedRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد بيانات لإنشاء التقرير',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تقرير سجلات السائقين',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'الفترة: ${_fromDate != null ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}' : ''} - ${_toDate != null ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}' : ''}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'تاريخ الإنشاء: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'اسم السائق',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'معرف السائق',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'الرقم التسلسلي',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'تاريخ التسجيل',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'الحالة',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    // Data rows
                    ..._allDetailedRecords.map((record) {
                      final createdAt = record['created_at'];
                      String formattedDate = 'غير محدد';
                      if (createdAt != null) {
                        try {
                          final date = DateTime.parse(createdAt.toString());
                          formattedDate =
                              '${date.day}/${date.month}/${date.year}';
                        } catch (e) {
                          formattedDate = createdAt.toString();
                        }
                      }

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              record['driver_full_name'] ?? 'غير محدد',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              record['driver_id']?.toString() ?? 'غير محدد',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              record['serial']?.toString() ?? 'غير محدد',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(formattedDate),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              record['status']?.toString() ?? 'مكتمل',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                // Footer
                pw.Spacer(),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Divider(),
                      pw.Text(
                        'إجمالي السجلات: ${_allDetailedRecords.length}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'عدد السائقين: ${_reportData.length}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Print or save the PDF with proper error handling
      try {
        if (kIsWeb) {
          // For web platform, use download
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name: 'تقرير_السائقين_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        } else {
          // For mobile/desktop, try printing first, fallback to saving
          try {
            await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdf.save(),
            );
          } catch (printError) {
            debugPrint('Printing failed, saving to file instead: $printError');
            // Fallback: Save to device storage
            await _savePdfToDevice(pdf, 'تقرير_السائقين');
          }
        }
      } catch (e) {
        debugPrint('PDF generation failed: $e');
        // Final fallback: Save to device storage
        await _savePdfToDevice(pdf, 'تقرير_السائقين');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء التقرير: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewDriverRecords(Map<String, dynamic> driverData) {
    final records =
        driverData['detailed_records'] as List<Map<String, dynamic>>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجلات السائق',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            driverData['driver_name'] ?? 'غير محدد',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        '${records.length} سجل',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00C9A7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Records list
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد سجلات لهذا السائق',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _buildDetailedRecordCard(record, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedRecordCard(Map<String, dynamic> record, int index) {
    final createdAt = record['created_at'];
    String formattedDate = 'غير محدد';
    String formattedTime = 'غير محدد';

    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = '${date.day}/${date.month}/${date.year}';
        formattedTime =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdAt.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFF4F46E5).withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4F46E5).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CheckinDetailsPage(checkinData: record),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${record['serial']?.toString() ?? (index + 1).toString()}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['driver_full_name'] ?? 'غير محدد',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'معرف السائق: ${record['driver_id'] ?? 'غير محدد'}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        record['status']?.toString() ?? 'مكتمل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00C9A7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: const Color(0xFF4F46E5).withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'اضغط للتفاصيل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: const Color(0xFF4F46E5).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePdfToDevice(pw.Document pdf, String fileName) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      // Always show file saved message with manual open option
      // Don't claim automatic success as it's often unreliable
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التقرير بنجاح!', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'فتح الملف',
            textColor: Colors.white,
            onPressed: () async {
              await _tryOpenFile(file.path);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ التقرير: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _tryOpenFile(String filePath) async {
    bool openAttempted = false;
    String statusMessage = '';

    try {
      if (Platform.isAndroid) {
        // For Android, try multiple approaches
        try {
          // Method 1: Standard approach
          final uri = Uri.file(filePath);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          openAttempted = true;
          statusMessage =
              'تم محاولة فتح الملف. إذا لم يتم فتحه، تحقق من مجلد التحميلات.';
        } catch (e) {
          // Method 2: Try with file:// protocol
          try {
            final uri = Uri.parse('file://$filePath');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            openAttempted = true;
            statusMessage =
                'تم محاولة فتح الملف. إذا لم يتم فتحه، تحقق من مجلد التحميلات.';
          } catch (e2) {
            statusMessage =
                'لا يمكن فتح الملف تلقائياً. يمكنك العثور عليه في: $filePath';
          }
        }
      } else if (Platform.isIOS) {
        try {
          final uri = Uri.file(filePath);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          openAttempted = true;
          statusMessage =
              'تم محاولة فتح الملف. إذا لم يتم فتحه، تحقق من تطبيق الملفات.';
        } catch (e) {
          statusMessage =
              'لا يمكن فتح الملف تلقائياً. يمكنك العثور عليه في: $filePath';
        }
      } else if (Platform.isWindows) {
        try {
          // For Windows, try normalized path
          final normalizedPath = filePath.replaceAll('\\', '/');
          final uri = Uri.parse('file:///$normalizedPath');
          await launchUrl(uri);
          openAttempted = true;
          statusMessage =
              'تم محاولة فتح الملف. إذا لم يتم فتحه، تحقق من مجلد المستندات.';
        } catch (e) {
          try {
            final uri = Uri.file(filePath);
            await launchUrl(uri);
            openAttempted = true;
            statusMessage =
                'تم محاولة فتح الملف. إذا لم يتم فتحه، تحقق من مجلد المستندات.';
          } catch (e2) {
            statusMessage =
                'لا يمكن فتح الملف تلقائياً. يمكنك العثور عليه في: $filePath';
          }
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        try {
          final uri = Uri.file(filePath);
          await launchUrl(uri);
          openAttempted = true;
          statusMessage =
              'تم محاولة فتح الملف. إذا لم يتم فتحه، تحقق من مجلد المستندات.';
        } catch (e) {
          statusMessage =
              'لا يمكن فتح الملف تلقائياً. يمكنك العثور عليه في: $filePath';
        }
      }

      // Show status message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage, style: GoogleFonts.cairo()),
          backgroundColor: openAttempted ? Colors.blue : Colors.amber,
          duration: Duration(seconds: openAttempted ? 6 : 10),
          action: !openAttempted
              ? SnackBarAction(
                  label: 'نسخ المسار',
                  textColor: Colors.white,
                  onPressed: () {
                    // Copy path to clipboard would be implemented here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('مسار الملف: $filePath'),
                        duration: const Duration(seconds: 8),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح الملف: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          title: Text(
            'التقارير',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4F46E5),
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
                // Date Range Selection Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                              Icons.date_range,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'اختيار الفترة الزمنية',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'من تاريخ',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectFromDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4F46E5,
                                        ).withOpacity(0.2),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: const Color(0xFF4F46E5),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fromDate != null
                                              ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                                              : 'اختر التاريخ',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: _fromDate != null
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إلى تاريخ',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectToDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4F46E5,
                                        ).withOpacity(0.2),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: const Color(0xFF4F46E5),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _toDate != null
                                              ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                                              : 'اختر التاريخ',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: _toDate != null
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.analytics),
                          label: Text(
                            _isLoading
                                ? 'جاري إنشاء التقرير...'
                                : 'إنشاء التقرير',
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

                const SizedBox(height: 20),

                // Report Results
                if (_hasData)
                  Container(
                    padding: const EdgeInsets.all(20),
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
                                Icons.assessment,
                                color: Color(0xFF00C9A7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'نتائج التقرير',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
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
                                '${_reportData.length} عنصر',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF00C9A7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Print PDF button
                            IconButton(
                              onPressed: _generatePDF,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.print,
                                  color: Color(0xFFFF6B6B),
                                  size: 20,
                                ),
                              ),
                              tooltip: 'طباعة التقرير',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._reportData.map((item) => _buildReportItem(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with driver info and actions
            Row(
              children: [
                // Driver avatar with gradient
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Driver info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver name
                      Text(
                        item['driver_name'] ?? 'غير محدد',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      // Driver ID with icon
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'معرف: ${item['driver_id']}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Records count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C9A7), Color(0xFF2BE7C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9A7).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['total_checkins']}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  // View records button
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _viewDriverRecords(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4F46E5).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.visibility_rounded,
                                color: Color(0xFF4F46E5),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'عرض',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4F46E5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Print button
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _generateDriverPDF(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF6B6B).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.print_rounded,
                                color: Color(0xFFFF6B6B),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'PDF',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF6B6B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Quick info
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: const Color(0xFF4F46E5).withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'اضغط "عرض" لمشاهدة التفاصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF4F46E5).withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateDriverPDF(Map<String, dynamic> driverData) async {
    final records =
        driverData['detailed_records'] as List<Map<String, dynamic>>? ?? [];

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد سجلات لهذا السائق',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تقرير سجلات السائق: ${driverData['driver_name'] ?? 'غير محدد'}',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'معرف السائق: ${driverData['driver_id']}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'الفترة: ${_fromDate != null ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}' : ''} - ${_toDate != null ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}' : ''}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'تاريخ الإنشاء: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'الرقم التسلسلي',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'تاريخ التسجيل',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'وقت التسجيل',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'الحالة',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    // Data rows
                    ...records.map((record) {
                      final createdAt = record['created_at'];
                      String formattedDate = 'غير محدد';
                      String formattedTime = 'غير محدد';
                      if (createdAt != null) {
                        try {
                          final date = DateTime.parse(createdAt.toString());
                          formattedDate =
                              '${date.day}/${date.month}/${date.year}';
                          formattedTime =
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        } catch (e) {
                          formattedDate = createdAt.toString();
                        }
                      }

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              record['serial']?.toString() ?? 'غير محدد',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(formattedDate),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(formattedTime),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              record['status']?.toString() ?? 'مكتمل',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                // Footer
                pw.Spacer(),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Divider(),
                      pw.Text(
                        'إجمالي سجلات السائق: ${records.length}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Print or save the PDF with proper error handling
      try {
        if (kIsWeb) {
          // For web platform, use download
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name:
                'تقرير_السائق_${driverData['driver_name']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        } else {
          // For mobile/desktop, try printing first, fallback to saving
          try {
            await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdf.save(),
            );
          } catch (printError) {
            debugPrint('Printing failed, saving to file instead: $printError');
            // Fallback: Save to device storage
            await _savePdfToDevice(
              pdf,
              'تقرير_السائق_${driverData['driver_name']}',
            );
          }
        }
      } catch (e) {
        debugPrint('PDF generation failed: $e');
        // Final fallback: Save to device storage
        await _savePdfToDevice(
          pdf,
          'تقرير_السائق_${driverData['driver_name']}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في إنشاء تقرير السائق: $e',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
