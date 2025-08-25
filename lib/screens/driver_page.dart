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
import 'driver_profile_page.dart';
import 'dart:async';
import '../services/notification_service.dart';

class DriverPage extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const DriverPage({super.key, this.userInfo});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> with TickerProviderStateMixin {
  // Camera variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;

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
  String _driverId = '';
  String _driverUsername = '';

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

  Future<void> _toggleFlashMode() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _flashMode = _flashMode == FlashMode.off
            ? FlashMode.torch
            : FlashMode.off;
      });
      await _cameraController!.setFlashMode(_flashMode);
      debugPrint('Flash mode changed to: $_flashMode');
    } catch (e) {
      debugPrint('خطأ في تغيير وضع الفلاش: $e');
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

      // Set flash mode before taking picture
      await _cameraController!.setFlashMode(_flashMode);
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

      // Set flash mode before taking picture
      await _cameraController!.setFlashMode(_flashMode);
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
      final insertResponse = await client
          .from('checkins')
          .insert({
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
          })
          .select()
          .single();

      // إرسال إشعار للمديرين بالتسجيل الجديد
      try {
        String locationText = '';
        if (_fullAddress != null && _fullAddress!.isNotEmpty) {
          locationText = _fullAddress!;
        } else if (_city != null && _city!.isNotEmpty) {
          locationText = _city!;
        } else {
          locationText = 'موقع غير محدد';
        }

        await NotificationService.sendNewCheckinNotification(
          driverName: _driverFullName,
          driverId: _driverId,
          checkinSerial: _serialNumber,
          checkinId: insertResponse['id'],
          location: locationText,
        );

        debugPrint('✅ تم إرسال إشعار للمديرين بالتسجيل الجديد');
      } catch (notificationError) {
        debugPrint('⚠️ خطأ في إرسال الإشعار: $notificationError');
        // لا نوقف العملية إذا فشل الإشعار
      }

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
      // استخدام معلومات المستخدم المرسلة من صفحة تسجيل الدخول
      if (widget.userInfo != null) {
        setState(() {
          _driverFullName =
              widget.userInfo!['full_name'] ??
              widget.userInfo!['username'] ??
              'السائق';
          _driverId = widget.userInfo!['id']?.toString() ?? '';
          _driverUsername = widget.userInfo!['username'] ?? '';
        });

        debugPrint('تم تحميل معلومات السائق: $_driverFullName');

        // جلب آخر رقم تسلسلي من قاعدة البيانات
        await _loadLastSerialNumber();
        return;
      }

      // في حالة عدم توفر معلومات المستخدم، محاولة الحصول عليها من قاعدة البيانات
      final client = Supabase.instance.client;

      // جلب معلومات السائق من جدول managers
      final response = await client
          .from('managers')
          .select('id, username, full_name')
          .eq('role', 'driver')
          .limit(1)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _driverFullName =
              response['full_name'] ?? response['username'] ?? 'السائق';
          _driverId = response['id']?.toString() ?? '';
          _driverUsername = response['username'] ?? '';
        });
      } else {
        // إذا لم يتم العثور على السائق، استخدم قيم افتراضية
        setState(() {
          _driverFullName = 'السائق';
          _driverId = 'unknown';
          _driverUsername = 'unknown';
        });
      }

      // جلب آخر رقم تسلسلي من قاعدة البيانات
      await _loadLastSerialNumber();
    } catch (e) {
      debugPrint('خطأ في جلب معلومات السائق: $e');
      setState(() {
        _driverFullName = 'السائق';
        _driverId = 'unknown';
        _driverUsername = 'unknown';
      });
    }
  }

  Future<void> _loadLastSerialNumber() async {
    try {
      final client = Supabase.instance.client;

      // جلب عدد السجلات الموجودة في قاعدة البيانات
      final response = await client.from('checkins').select('id');

      // الرقم التسلسلي = عدد السجلات + 1
      final totalRecords = response.length;
      setState(() {
        _serialNumber = totalRecords + 1;
      });

      debugPrint('عدد السجلات الموجودة: $totalRecords');
      debugPrint('الرقم التسلسلي الجديد: $_serialNumber');
    } catch (e) {
      debugPrint('خطأ في جلب عدد السجلات: $e');
      // في حالة الخطأ، استخدم رقم افتراضي
      setState(() {
        _serialNumber = 1;
      });
    }
  }

  void _showProfileMenu() {
    // الانتقال مباشرة إلى صفحة بيانات السائق
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DriverProfilePage(userInfo: widget.userInfo),
      ),
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
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 48,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'جاري تهيئة الكاميرا...',
              style: GoogleFonts.cairo(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Camera Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: CameraPreview(_cameraController!),
            ),
          ),
          // Flash Control Button
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleFlashMode,
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      color: _flashMode == FlashMode.off
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Camera Controls Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCameraButton(
                    'قبل العمل',
                    _beforeImage != null,
                    () => _captureBeforeImage(),
                    const Color(0xFF4CAF50),
                  ),
                  _buildCameraButton(
                    'بعد العمل',
                    _afterImage != null,
                    () => _captureAfterImage(),
                    const Color(0xFF2196F3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton(
    String label,
    bool isCompleted,
    VoidCallback onPressed,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isCapturing ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isCompleted
                    ? color.withOpacity(0.2)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted ? color : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.camera_alt,
                    color: isCompleted ? color : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.cairo(
                        color: isCompleted ? color : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
            color: const Color(0xFF1a1a2e),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: image != null
                ? null
                : LinearGradient(
                    colors: [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: image != null
                  ? const Color(0xFF28a745)
                  : const Color(0xFFDEE2E6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: image != null
                    ? const Color(0xFF28a745).withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: image != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF28a745),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6c757d).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: const Color(0xFF6c757d).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لم يتم التقاط الصورة بعد',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF6c757d),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'استخدم أزرار الكاميرا في الأعلى',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF6c757d).withOpacity(0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Welcome Card - Compact Design
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Welcome Text Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً بك',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _driverFullName,
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'رقم $_serialNumber',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _now
                                        .toLocal()
                                        .toString()
                                        .split(' ')[1]
                                        .split('.')
                                        .first,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Profile Avatar
                      GestureDetector(
                        onTap: _showProfileMenu,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Modern Camera Preview with Built-in Controls
                _buildCameraPreview(),

                const SizedBox(height: 24),

                // Image Display Gallery
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
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: _buildDriverUI(),
      ),
    );
  }
}
