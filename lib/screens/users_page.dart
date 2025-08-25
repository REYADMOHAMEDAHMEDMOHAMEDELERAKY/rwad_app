import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ui_styles.dart';
import 'user_details_page.dart'; // Added import for UserDetailsPage

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  final _phoneController = TextEditingController();
  String _selectedRole = 'driver';
  String? _selectedCarId; // For storing selected car ID
  List<Map<String, dynamic>> _availableCars = []; // For storing available cars
  bool _loadingCars = false;

  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadAvailableCars();
  }

  Future<void> _loadAvailableCars() async {
    debugPrint('=== Starting _loadAvailableCars ===');
    setState(() => _loadingCars = true);
    try {
      final client = Supabase.instance.client;
      debugPrint('Supabase client initialized: ${client.toString()}');
      debugPrint('Loading cars from database...');

      final response = await client
          .from('cars')
          .select('id, plate, model, notes')
          .order('plate', ascending: true);

      debugPrint('Raw cars response type: ${response.runtimeType}');
      debugPrint('Raw cars response: $response');

      if (response != null) {
        setState(() {
          _availableCars = List<Map<String, dynamic>>.from(response as List);
        });
        debugPrint('Successfully loaded ${_availableCars.length} cars');

        // Print each car for debugging
        for (int i = 0; i < _availableCars.length; i++) {
          final car = _availableCars[i];
          debugPrint(
            'Car $i: ID=${car['id']}, Plate=${car['plate']}, Model=${car['model']}, Notes=${car['notes']}',
          );
        }
      } else {
        debugPrint('No cars response received (response is null)');
        setState(() {
          _availableCars = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading cars: $e');
      debugPrintStack();
      // Set empty list on error
      setState(() {
        _availableCars = [];
      });
    } finally {
      setState(() => _loadingCars = false);
      debugPrint(
        '=== Finished _loadAvailableCars, cars count: ${_availableCars.length} ===',
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();

    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('managers')
          .select('id,username,role,created_at,is_suspended,full_name,phone')
          .order('id', ascending: true);

      if (res != null && res.isNotEmpty) {
        _users = List<Map<String, dynamic>>.from(res as List);
      } else {
        // إضافة بيانات تجريبية إذا كانت القائمة فارغة
        _users = [
          {
            'id': 1,
            'username': 'alaa',
            'role': 'admin',
            'created_at': '2024-01-15',
            'is_suspended': false,
            'full_name': 'علاء أحمد',
            'phone': '+966 50 123 4567',
            'join_date': '2024-01-01',
          },
          {
            'id': 2,
            'username': 'ahmed_sabry',
            'role': 'driver',
            'created_at': '2024-01-16',
            'is_suspended': false,
            'full_name': 'أحمد صبري',
            'phone': '+966 50 234 5678',
            'join_date': '2024-01-16',
          },
          {
            'id': 3,
            'username': 'mohammed',
            'role': 'driver',
            'created_at': '2024-01-17',
            'is_suspended': true,
            'full_name': 'محمد علي',
            'phone': '+966 50 345 6789',
            'join_date': '2024-01-17',
          },
        ];

        // محاولة إضافة المستخدمين إلى قاعدة البيانات
        for (final user in _users) {
          try {
            await client.from('managers').upsert({
              'id': user['id'],
              'username': user['username'],
              'password': user['username'] == 'alaa'
                  ? 'alaa123'
                  : user['username'] == 'ahmed_sabry'
                  ? 'ahmed123'
                  : 'mohammed123',
              'role': user['role'],
              'is_suspended': user['is_suspended'],
              'full_name': user['full_name'],

              'phone': user['phone'],
              'join_date': user['join_date'],
            });
          } catch (e) {
            debugPrint('Error adding test user ${user['username']}: $e');
          }
        }
      }

      debugPrint('Loaded ${_users.length} users');
    } catch (e) {
      debugPrint('loadUsers error: $e');
      // استخدام بيانات تجريبية في حالة الخطأ
      _users = [
        {
          'id': 1,
          'username': 'alaa',
          'role': 'admin',
          'created_at': '2024-01-15',
          'is_suspended': false,
          'full_name': 'علاء أحمد',
          'phone': '+966 50 123 4567',
          'join_date': '2024-01-01',
        },
        {
          'id': 2,
          'username': 'ahmed_sabry',
          'role': 'driver',
          'created_at': '2024-01-16',
          'is_suspended': false,
          'full_name': 'أحمد صبري',
          'phone': '+966 50 234 5678',
          'join_date': '2024-01-16',
        },
        {
          'id': 3,
          'username': 'mohammed',
          'role': 'driver',
          'created_at': '2024-01-17',
          'is_suspended': true,
          'full_name': 'محمد علي',
          'phone': '+966 50 345 6789',
          'join_date': '2024-01-17',
        },
      ];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty || password.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى ملء الحقول المطلوبة')));
      return;
    }

    // Check if driver role is selected but no car is chosen
    if (_selectedRole == 'driver' &&
        (_selectedCarId == null || _selectedCarId!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار سيارة للسائق')));
      return;
    }

    setState(() => _creating = true);
    try {
      final client = Supabase.instance.client;

      // Create the user
      final userResponse = await client
          .from('managers')
          .insert({
            'username': username,
            'password': password,
            'role': _selectedRole,
            'is_suspended': false,
            'full_name': fullName,
            'phone': phone.isNotEmpty ? phone : '+966 50 000 0000',
            'join_date': DateTime.now().toIso8601String().split('T')[0],
          })
          .select()
          .single();

      // If the user is a driver and a car is selected, assign the car
      if (_selectedRole == 'driver' && _selectedCarId != null) {
        await client.from('car_drivers').insert({
          'car_id': int.parse(_selectedCarId!),
          'driver_username': username,
        });
      }

      // Clear form fields
      _usernameController.clear();
      _passwordController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      setState(() {
        _selectedRole = 'driver';
        _selectedCarId = null;
      });

      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت إضافة المستخدم')));
    } catch (e) {
      debugPrint('createUser error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل إنشاء المستخدم: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _creating = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا المستخدم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final client = Supabase.instance.client;
      await client.from('managers').delete().eq('id', id);
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الحذف')));
    } catch (e) {
      debugPrint('deleteUser error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
    }
  }

  void _openUserDetails(BuildContext context, Map<String, dynamic> user) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UserDetailsPage(user: user)),
    );

    // معالجة النتائج
    if (result != null && mounted) {
      if (result['action'] == 'update') {
        // تحديث المستخدم في القائمة
        setState(() {
          final index = _users.indexWhere(
            (u) => u['id'] == result['user']['id'],
          );
          if (index != -1) {
            _users[index] = result['user'];
          }
        });
      } else if (result['action'] == 'delete') {
        // حذف المستخدم من القائمة
        setState(() {
          _users.removeWhere((u) => u['id'] == result['userId']);
        });
      }
    }
  }

  Future<void> _debugTestCarConnection() async {
    debugPrint('=== DEBUG: Testing direct car connection ===');
    try {
      final client = Supabase.instance.client;
      debugPrint('Client: $client');

      // Test basic connection
      debugPrint('Testing basic connection...');
      final testResponse = await client.from('cars').select('count');
      debugPrint('Basic connection test result: $testResponse');

      // Test full query
      debugPrint('Testing full query...');
      final fullResponse = await client.from('cars').select('*');
      debugPrint('Full query result: $fullResponse');

      // Test with specific fields
      debugPrint('Testing specific fields query...');
      final specificResponse = await client
          .from('cars')
          .select('id, plate, model, notes');
      debugPrint('Specific fields result: $specificResponse');

      // Force reload
      await _loadAvailableCars();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتهى اختبار الاتصال. تحقق من اللوغ')),
      );
    } catch (e, stackTrace) {
      debugPrint('DEBUG ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    }
  }

  Future<void> _addTestCars() async {
    setState(() => _creating = true);
    try {
      final client = Supabase.instance.client;

      // Add test cars
      final testCars = [
        {'plate': 'ABC-123', 'model': 'Toyota Hiace', 'notes': 'حافلة رقم 1'},
        {'plate': 'XYZ-999', 'model': 'Nissan NV200', 'notes': 'سيارة صغيرة'},
        {
          'plate': 'DEF-456',
          'model': 'Mercedes Sprinter',
          'notes': 'حافلة متوسطة',
        },
        {'plate': 'GHI-789', 'model': 'Ford Transit', 'notes': 'حافلة كبيرة'},
        {'plate': 'JKL-012', 'model': 'Hyundai H1', 'notes': 'مركبة نقل'},
      ];

      for (final car in testCars) {
        try {
          await client.from('cars').upsert(car);
          debugPrint('Added test car: ${car['plate']}');
        } catch (e) {
          debugPrint('Error adding test car ${car['plate']}: $e');
        }
      }

      await _loadAvailableCars();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المركبات التجريبية')),
      );
    } catch (e) {
      debugPrint('addTestCars error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إضافة المركبات التجريبية: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _creating = false);
    }
  }

  Future<void> _addTestUsers() async {
    setState(() => _creating = true);
    try {
      final client = Supabase.instance.client;

      // إضافة مستخدمين تجريبيين
      final testUsers = [
        {
          'username': 'alaa',
          'password': 'alaa123',
          'role': 'admin',
          'is_suspended': false,
          'full_name': 'علاء أحمد',
          'phone': '+966 50 123 4567',
          'join_date': '2024-01-01',
        },
        {
          'username': 'ahmed_sabry',
          'password': 'ahmed123',
          'role': 'driver',
          'is_suspended': false,
          'full_name': 'أحمد صبري',
          'phone': '+966 50 234 5678',
          'join_date': '2024-01-16',
        },
        {
          'username': 'mohammed',
          'password': 'mohammed123',
          'role': 'driver',
          'is_suspended': true,
          'full_name': 'محمد علي',
          'phone': '+966 50 345 6789',
          'join_date': '2024-01-17',
        },
      ];

      for (final user in testUsers) {
        try {
          await client.from('managers').upsert(user);
        } catch (e) {
          debugPrint('Error adding test user ${user['username']}: $e');
        }
      }

      await _loadUsers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المستخدمين التجريبيين')),
      );
    } catch (e) {
      debugPrint('addTestUsers error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إضافة المستخدمين التجريبيين: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4F46E5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            color: const Color(0xFF4F46E5),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة المستخدمين',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'إضافة وإدارة المستخدمين والصلاحيات',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.8),
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

              // Add user form
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
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'إضافة مستخدم جديد',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _StyledTextField(
                        controller: _usernameController,
                        label: 'اسم المستخدم',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _fullNameController,
                        label: 'الاسم الكامل',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),

                      _StyledTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 16),
                      _StyledDropdown(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'driver',
                            child: Text('سائق'),
                          ),
                          DropdownMenuItem(value: 'admin', child: Text('مدير')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedRole = v ?? 'driver';
                            // Clear car selection when role changes to admin
                            if (_selectedRole == 'admin') {
                              _selectedCarId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Car selection dropdown - only visible for drivers
                      if (_selectedRole == 'driver') ...[
                        _CarSelectionDropdown(
                          selectedCarId: _selectedCarId,
                          availableCars: _availableCars,
                          isLoading: _loadingCars,
                          onChanged: (carId) {
                            setState(() {
                              _selectedCarId = carId;
                            });
                          },
                          onRefresh: _loadAvailableCars,
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _creating ? null : _createUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _creating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'إضافة المستخدم',
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

              const SizedBox(height: 20),

              // Users list
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
                              Icons.people_outline,
                              color: Color(0xFF00C9A7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'قائمة المستخدمين',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            )
                          : _users.isEmpty
                          ? Column(
                              children: [
                                _EmptyUsersState(),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3CD),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFFEAA7),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'معلومات التشخيص:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF856404),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'عدد المستخدمين المحملين: ${_users.length}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF856404),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _addTestUsers,
                                        icon: const Icon(Icons.add_circle),
                                        label: const Text(
                                          'إضافة مستخدمين تجريبيين',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF00C9A7,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _users.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return _UserCard(
                                  user: user,
                                  onDelete: () => _deleteUser(user['id']),
                                  onTap: _openUserDetails,
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: GoogleFonts.cairo(
            color: const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: const Icon(Icons.security, color: Color(0xFF64748B)),
          labelStyle: GoogleFonts.cairo(
            color: const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        dropdownColor: Colors.white,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDelete;
  final Function(BuildContext, Map<String, dynamic>) onTap;

  const _UserCard({
    required this.user,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['role'] == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(context, user),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFF4F46E5).withOpacity(0.1)
                        : const Color(0xFF00C9A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.directions_car,
                    color: isAdmin
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF00C9A7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? user['username'] ?? '',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (user['full_name'] != null &&
                          user['full_name'].isNotEmpty &&
                          user['username'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${user['username']}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? const Color(0xFF4F46E5).withOpacity(0.1)
                                  : const Color(0xFF00C9A7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAdmin ? 'مدير' : 'سائق',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isAdmin
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF00C9A7),
                              ),
                            ),
                          ),

                          if (user['is_suspended'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'معلق',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFFF6B6B),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم الإنشاء: ${user['created_at'] ?? ''}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onTap(context, user),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF64748B),
                    size: 16,
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

class _EmptyUsersState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 60,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مستخدمين بعد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة مستخدم جديد لبدء العمل',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CarSelectionDropdown extends StatelessWidget {
  final String? selectedCarId;
  final List<Map<String, dynamic>> availableCars;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRefresh;

  const _CarSelectionDropdown({
    required this.selectedCarId,
    required this.availableCars,
    required this.isLoading,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Building _CarSelectionDropdown with ${availableCars.length} cars, loading: $isLoading',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.directions_car,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'اختيار المركبة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh,
                color: Color(0xFF00C9A7),
                size: 20,
              ),
              tooltip: 'تحديث قائمة المركبات',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: isLoading
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'جارٍ تحميل المركبات...',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : availableCars.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'لا توجد مركبات متاحة. يرجى إضافة مركبات أولاً',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFF59E0B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedCarId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.directions_car,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      hintText: 'اختر مركبة...',
                      hintStyle: GoogleFonts.cairo(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 250,
                    items: availableCars.map((car) {
                      final carId = car['id'].toString();
                      final plate = car['plate'] ?? 'غير محدد';
                      final model = car['model'] ?? '';

                      // Ultra-simple text display
                      String text = plate;
                      if (model.isNotEmpty && model.length < 20) {
                        text += ' ($model)';
                      }
                      // Ensure text never exceeds reasonable length
                      if (text.length > 35) {
                        text = text.substring(0, 32) + '...';
                      }

                      return DropdownMenuItem<String>(
                        value: carId,
                        child: Text(
                          text,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
        ),
        if (selectedCarId != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم اختيار المركبة:',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Display selected car details
                      Builder(
                        builder: (context) {
                          final selectedCar = availableCars.firstWhere(
                            (car) => car['id'].toString() == selectedCarId,
                            orElse: () => {},
                          );
                          if (selectedCar.isNotEmpty) {
                            final plate = selectedCar['plate'] ?? '';
                            final model = selectedCar['model'] ?? '';
                            final displayText =
                                plate + (model.isNotEmpty ? ' - $model' : '');
                            return Container(
                              width: double.infinity,
                              child: Text(
                                displayText,
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF047857),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
