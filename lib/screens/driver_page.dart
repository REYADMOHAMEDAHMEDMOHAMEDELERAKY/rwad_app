import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:typed_data';
import 'welcome_page.dart';
import 'dart:async';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;

  // Location variables
  Position? _currentPosition;
  String _currentLocation = 'جاري تحديد الموقع...';
  String? _country;
  String? _city;
  String? _district;
  String? _street;
  String? _fullAddress;
  bool _locationLoading = false;
  String? _locationError;

  // Image variables
  XFile? _beforeImage;
  XFile? _afterImage;
  bool _isSaving = false;

  // Serial number and time
  int _serialNumber = 1;
  DateTime _now = DateTime.now();

  // Driver information
  String _driverFullName = 'السائق';
  String _driverId = 'driver_001';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
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

    _initializeCamera();
    _getCurrentLocation();
    _loadDriverInfo();

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Start clock timer
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('خطأ في تهيئة الكاميرا: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _locationLoading = true;
        _locationError = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'خدمة الموقع غير مفعلة';
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'تم رفض إذن الموقع';
            _locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'إذن الموقع مرفوض نهائياً';
          _locationLoading = false;
        });
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        setState(() {
          _currentLocation =
              '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
        });

        // Get address from coordinates
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            setState(() {
              _country = place.country;
              _city = place.locality;
              _district = place.subLocality;
              _street = place.thoroughfare;
              _fullAddress =
                  '${place.country}, ${place.administrativeArea}, ${place.locality}, ${place.subLocality}';
            });
          }
        } catch (e) {
          debugPrint('خطأ في جلب العنوان: $e');
        }
      }

      setState(() {
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'خطأ في تحديد الموقع: $e';
        _locationLoading = false;
      });
      debugPrint('خطأ في تحديد الموقع: $e');
    }
  }

  Future<void> _captureBeforeImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _beforeImage = image;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      debugPrint('خطأ في التقاط الصورة: $e');
    }
  }

  Future<void> _captureAfterImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _afterImage = image;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      debugPrint('خطأ في التقاط الصورة: $e');
    }
  }

  Future<void> _onSave() async {
    if (_beforeImage == null || _afterImage == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final client = Supabase.instance.client;

      // Upload images to storage
      final beforeFileName =
          'before_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final afterFileName =
          'after_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final beforeFile = File(_beforeImage!.path);
      final afterFile = File(_afterImage!.path);

      await client.storage.from('checkins').upload(beforeFileName, beforeFile);
      await client.storage.from('checkins').upload(afterFileName, afterFile);

      // Get public URLs
      final beforeUrl = client.storage
          .from('checkins')
          .getPublicUrl(beforeFileName);
      final afterUrl = client.storage
          .from('checkins')
          .getPublicUrl(afterFileName);

      // Save to database with all location details
      await client.from('checkins').insert({
        'driver_id': _driverId,
        'lat': _currentPosition!.latitude,
        'lon': _currentPosition!.longitude,
        'before_path': beforeUrl,
        'after_path': afterUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'serial': _serialNumber,
        'country': _country,
        'city': _city,
        'district': _district,
        'street': _street,
        'full_address': _fullAddress,
        'accuracy': _currentPosition!.accuracy,
        'altitude': _currentPosition!.altitude,
        'speed': _currentPosition!.speed,
        'heading': _currentPosition!.heading,
        'notes': 'تم التقاط الصور مع تحديد الموقع التفصيلي',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ البيانات بنجاح'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Reset images and increment serial number
        setState(() {
          _beforeImage = null;
          _afterImage = null;
          _serialNumber += 1;
        });
      }
    } catch (e) {
      debugPrint('خطأ في حفظ البيانات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ البيانات: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _loadDriverInfo() async {
    try {
      final client = Supabase.instance.client;

      // جلب معلومات السائق من جدول drivers أو managers
      final response = await client
          .from('drivers') // أو 'managers' حسب هيكل قاعدة البيانات
          .select('full_name')
          .eq('id', _driverId)
          .maybeSingle();

      if (response != null && response['full_name'] != null) {
        setState(() {
          _driverFullName = response['full_name'];
        });
      } else {
        // إذا لم يتم العثور على السائق في جدول drivers، جرب جدول managers
        final managerResponse = await client
            .from('managers')
            .select('full_name')
            .eq('id', _driverId)
            .maybeSingle();

        if (managerResponse != null && managerResponse['full_name'] != null) {
          setState(() {
            _driverFullName = managerResponse['full_name'];
          });
        } else {
          // إذا لم يتم العثور على الاسم، استخدم معرف افتراضي
          setState(() {
            _driverFullName = 'السائق $_driverId';
          });
        }
      }

      // جلب آخر رقم تسلسلي من قاعدة البيانات
      await _loadLastSerialNumber();
    } catch (e) {
      debugPrint('خطأ في جلب معلومات السائق: $e');
      setState(() {
        _driverFullName = 'السائق $_driverId';
      });
    }
  }

  Future<void> _loadLastSerialNumber() async {
    try {
      final client = Supabase.instance.client;

      // جلب آخر رقم تسلسلي من جدول checkins
      final response = await client
          .from('checkins')
          .select('serial')
          .order('serial', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['serial'] != null) {
        setState(() {
          _serialNumber = response['serial'] + 1; // الرقم التالي
        });
      } else {
        // إذا لم توجد سجلات سابقة، ابدأ من 1
        setState(() {
          _serialNumber = 1;
        });
      }
    } catch (e) {
      debugPrint('خطأ في جلب الرقم التسلسلي: $e');
      // في حالة الخطأ، استخدم رقم افتراضي
      setState(() {
        _serialNumber = 1;
      });
    }
  }

  void _showProfileMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('قائمة السائق'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.info, color: Colors.blue.shade600),
                title: const Text('معلومات السائق'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDriverInfo();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade600),
                title: const Text('تسجيل الخروج'),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDriverInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('معلومات السائق'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('الرقم التسلسلي', '$_serialNumber'),
                _buildInfoRow(
                  'الوقت الحالي',
                  _now.toLocal().toString().split('.').first,
                ),
                _buildInfoRow(
                  'إحداثيات الموقع',
                  '${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}, ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                ),
                if (_fullAddress != null && _fullAddress!.isNotEmpty)
                  _buildInfoRow('العنوان الكامل', _fullAddress!),
                if (_country != null && _country!.isNotEmpty)
                  _buildInfoRow('الدولة', _country!),
                if (_city != null && _city!.isNotEmpty)
                  _buildInfoRow('المدينة', _city!),
                if (_district != null && _district!.isNotEmpty)
                  _buildInfoRow('الحي', _district!),
                if (_street != null && _street!.isNotEmpty)
                  _buildInfoRow('اسم الشارع', _street!),
                if (_currentPosition != null) ...[
                  _buildInfoRow(
                    'دقة الموقع',
                    '${_currentPosition!.accuracy.toStringAsFixed(2)} متر',
                  ),
                  _buildInfoRow(
                    'الارتفاع',
                    '${_currentPosition!.altitude.toStringAsFixed(2)} متر',
                  ),
                  _buildInfoRow(
                    'السرعة',
                    '${_currentPosition!.speed.toStringAsFixed(2)} م/ث',
                  ),
                  _buildInfoRow(
                    'الاتجاه',
                    '${_currentPosition!.heading.toStringAsFixed(2)} درجة',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _cameraController == null) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تهيئة الكاميرا...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildImageDisplay(
    String title,
    XFile? image,
    VoidCallback onCapture,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
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
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(image.path), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط لالتقاط الصورة',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isCapturing ? null : onCapture,
            icon: Icon(
              _isCapturing ? Icons.hourglass_empty : Icons.camera_alt,
              size: 20,
            ),
            label: Text(
              _isCapturing ? 'جاري التحميل...' : 'التقاط الصورة',
              style: GoogleFonts.cairo(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverUI() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile icon and serial number
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً بك، $_driverFullName',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'الرقم التسلسلي: $_serialNumber',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _now.toLocal().toString().split('.').first,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _showProfileMenu,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Camera Preview - Full width
              _buildCameraPreview(),

              const SizedBox(height: 24),

              // Before and After Images side by side
              Row(
                children: [
                  Expanded(
                    child: _buildImageDisplay(
                      'صورة قبل العمل',
                      _beforeImage,
                      _captureBeforeImage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageDisplay(
                      'صورة بعد العمل',
                      _afterImage,
                      _captureAfterImage,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Location coordinates display
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الموقع: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            '${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الموقع: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            '${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed:
                      (_beforeImage != null &&
                          _afterImage != null &&
                          !_isSaving)
                      ? _onSave
                      : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save, size: 28),
                  label: Text(
                    _isSaving ? 'جاري الحفظ...' : 'حفظ التسجيل',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Current Location Display
              Container(
                width: double.infinity,
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
                        Icon(
                          Icons.location_on,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الموقع الحالي',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _locationLoading
                                ? Icons.hourglass_empty
                                : Icons.refresh,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          onPressed: _locationLoading
                              ? null
                              : _getCurrentLocation,
                          tooltip: 'تحديث الموقع',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_locationLoading)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'جاري تحديد الموقع...',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      )
                    else if (_locationError != null)
                      Text(
                        _locationError!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLocation,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            if (_fullAddress != null &&
                                _fullAddress!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'العنوان: $_fullAddress',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
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
            'واجهة السائق',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: _buildDriverUI(),
      ),
    );
  }
}
