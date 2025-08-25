import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailsPage({super.key, required this.user});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _selectedRole = 'driver';
  String? _selectedCarId;
  List<Map<String, dynamic>> _availableCars = [];
  bool _loadingCars = false;
  bool _isSuspended = false;
  bool _loading = false;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAvailableCars();
    _loadUserCar();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    _usernameController.text = widget.user['username'] ?? '';
    _fullNameController.text = widget.user['full_name'] ?? '';
    _selectedRole = widget.user['role'] ?? 'driver';
    _isSuspended = widget.user['is_suspended'] == true;
  }

  Future<void> _loadAvailableCars() async {
    setState(() => _loadingCars = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('cars')
          .select('id, plate, model, notes')
          .order('plate', ascending: true);

      setState(() {
        _availableCars = List<Map<String, dynamic>>.from(response as List);
      });
        } catch (e) {
      debugPrint('Error loading cars: $e');
      setState(() {
        _availableCars = [];
      });
    } finally {
      setState(() => _loadingCars = false);
    }
  }

  Future<void> _loadUserCar() async {
    if (_selectedRole != 'driver') return;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('car_drivers')
          .select('car_id')
          .eq('driver_username', widget.user['username'])
          .maybeSingle();

      if (response != null && response['car_id'] != null) {
        setState(() {
          _selectedCarId = response['car_id'].toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading user car: $e');
    }
  }

  Future<void> _updateUser() async {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _updating = true);
    try {
      final client = Supabase.instance.client;
      final updateData = {
        'username': username,
        'full_name': fullName.isNotEmpty ? fullName : null,
        'role': _selectedRole,
        'is_suspended': _isSuspended,
      };

      // تحديث كلمة المرور فقط إذا تم إدخالها
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text.trim();
      }

      await client
          .from('managers')
          .update(updateData)
          .eq('id', widget.user['id']);

      // Handle car assignment for drivers
      if (_selectedRole == 'driver') {
        // First, remove any existing car assignment
        await client
            .from('car_drivers')
            .delete()
            .eq('driver_username', username);

        // Then, add new car assignment if one is selected
        if (_selectedCarId != null && _selectedCarId!.isNotEmpty) {
          await client.from('car_drivers').insert({
            'car_id': int.parse(_selectedCarId!),
            'driver_username': username,
          });
        }
      } else {
        // If changing from driver to admin, remove car assignment
        await client
            .from('car_drivers')
            .delete()
            .eq('driver_username', username);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات المستخدم')));

      // تحديث البيانات في الصفحة السابقة
      Navigator.of(context).pop({
        'action': 'update',
        'user': {...widget.user, ...updateData},
      });
    } catch (e) {
      debugPrint('updateUser error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تحديث المستخدم: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _updating = false);
    }
  }

  Future<void> _deleteUser() async {
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

    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      await client.from('managers').delete().eq('id', widget.user['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المستخدم')));

      Navigator.of(
        context,
      ).pop({'action': 'delete', 'userId': widget.user['id']});
    } catch (e) {
      debugPrint('deleteUser error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل حذف المستخدم: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user['role'] == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('تفاصيل المستخدم'),
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
              // User info header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAdmin
                        ? [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
                        : [const Color(0xFF00C9A7), const Color(0xFF2BE7C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isAdmin
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF00C9A7))
                              .withOpacity(0.3),
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
                      child: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.directions_car,
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
                            widget.user['full_name'] ??
                                widget.user['username'] ??
                                '',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${widget.user['username'] ?? ''}',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAdmin ? 'مدير' : 'سائق',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          if (_isSuspended) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'معلق النشاط',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Edit form
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
                              Icons.edit,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تعديل بيانات المستخدم',
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
                        controller: _fullNameController,
                        label: 'الاسم الكامل',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور الجديدة (اختياري)',
                        icon: Icons.lock_outline,
                        isPassword: true,
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
                            if (_selectedRole == 'admin') {
                              _selectedCarId = null;
                            } else {
                              _loadUserCar();
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
                      _SuspensionToggle(
                        value: _isSuspended,
                        onChanged: (value) =>
                            setState(() => _isSuspended = value),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _updating ? null : _updateUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _updating
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
                                  'حفظ التغييرات',
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

              // Danger zone
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    width: 2,
                  ),
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
                              color: const Color(0xFFFF6B6B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: Color(0xFFFF6B6B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'منطقة الخطر',
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
                        'هذه الإجراءات لا يمكن التراجع عنها. كن حذراً عند استخدامها.',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _deleteUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
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
                                  'حذف المستخدم',
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
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: Icon(Icons.security, color: Color(0xFF64748B)),
        ),
        style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontSize: 14),
        dropdownColor: Colors.white,
      ),
    );
  }
}

class _SuspensionToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SuspensionToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.block, color: Color(0xFFFF6B6B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعليق النشاط',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value
                      ? 'المستخدم معلق ولا يمكنه تسجيل الدخول'
                      : 'المستخدم نشط ويمكنه تسجيل الدخول',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF6B6B),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Color(0xFF64748B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اختيار المركبة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4F46E5),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    color: const Color(0xFF64748B),
                  ),
              ],
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('جاري تحميل المركبات...')),
            )
          else if (availableCars.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'لا توجد مركبات متاحة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'إعادة المحاولة',
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DropdownButtonFormField<String>(
                initialValue: selectedCarId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: GoogleFonts.cairo(
                  color: const Color(0xFF1E293B),
                  fontSize: 14,
                ),
                dropdownColor: Colors.white,
                hint: Text(
                  'اختر مركبة...',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'لا توجد مركبة مخصصة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ...availableCars.map((car) {
                    final plate = car['plate'] ?? '';
                    final model = car['model'] ?? '';
                    final notes = car['notes'] ?? '';

                    String displayText = plate;
                    if (model.isNotEmpty) {
                      displayText += ' - $model';
                    }
                    if (notes.isNotEmpty && displayText.length < 30) {
                      displayText += ' ($notes)';
                    }

                    return DropdownMenuItem<String>(
                      value: car['id'].toString(),
                      child: Text(
                        displayText,
                        style: GoogleFonts.cairo(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                onChanged: onChanged,
              ),
            ),

          // Selected car confirmation
          if (selectedCarId != null && selectedCarId!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00C9A7).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00C9A7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم اختيار المركبة: ${_getSelectedCarDisplay()}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF00C9A7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSelectedCarDisplay() {
    if (selectedCarId == null || availableCars.isEmpty) return '';

    final selectedCar = availableCars.firstWhere(
      (car) => car['id'].toString() == selectedCarId,
      orElse: () => {},
    );

    if (selectedCar.isEmpty) return '';

    final plate = selectedCar['plate'] ?? '';
    final model = selectedCar['model'] ?? '';

    return model.isNotEmpty ? '$plate - $model' : plate;
  }
}
