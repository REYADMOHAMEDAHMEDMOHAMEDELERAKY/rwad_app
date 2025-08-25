import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/ui_styles.dart';

// Clean CarsPage implementation (RTL Arabic) with keyboard-aware edit dialog

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _cars = [];
  bool _loading = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('cars')
          .select('id,plate,model,notes')
          .order('id', ascending: true);
      final list = List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e)),
      );
      if (mounted) setState(() => _cars = list);
    } catch (e) {
      debugPrint('loadCars error: $e');
      if (mounted) {
        setState(() {
          _cars = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createCar() async {
    final plate = _plateController.text.trim();
    final model = _modelController.text.trim();
    final notes = _notesController.text.trim();
    if (plate.isEmpty && model.isEmpty) return;
    setState(() => _creating = true);
    try {
      final client = Supabase.instance.client;
      await client.from('cars').insert({
        'plate': plate,
        'model': model,
        'notes': notes,
      }).select();
      await _loadCars();
      _plateController.clear();
      _modelController.clear();
      _notesController.clear();
      await _showSavedModal();
    } catch (e) {
      debugPrint('createCar error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء السيارة: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _updateCar(int id) async {
    final plate = _plateController.text.trim();
    final model = _modelController.text.trim();
    final notes = _notesController.text.trim();
    try {
      final client = Supabase.instance.client;
      await client
          .from('cars')
          .update({'plate': plate, 'model': model, 'notes': notes})
          .eq('id', id)
          .select();
      await _loadCars();
      await _showSavedModal();
    } catch (e) {
      debugPrint('updateCar error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: ${e.toString()}')));
      }
    }
  }

  Future<void> _deleteCar(int id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('cars').delete().eq('id', id);
      await _loadCars();
    } catch (e) {
      debugPrint('deleteCar error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الحذف: ${e.toString()}')));
      }
    }
  }

  Future<void> _showSavedModal() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تم الحفظ'),
          content: const Text('تم حفظ البيانات بنجاح.'),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog({Map<String, dynamic>? car}) async {
    final isEditing = car != null;
    _plateController.text = car != null ? (car['plate'] ?? '') as String : '';
    _modelController.text = car != null ? (car['model'] ?? '') as String : '';
    _notesController.text = car != null ? (car['notes'] ?? '') as String : '';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              isEditing ? 'تعديل السيارة' : 'إضافة سيارة',
              textAlign: TextAlign.center,
            ),
            contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottom),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _plateController,
                    decoration: appInputDecoration('اللوحة'),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _modelController,
                    decoration: appInputDecoration('الموديل'),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: appInputDecoration('ملاحظات'),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        if (isEditing) {
                          final id = car['id'] as int;
                          await _updateCar(id);
                        } else {
                          await _createCar();
                        }
                      },
                      child: const Text('حفظ'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> car) async {
    final id = car['id'] as int;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه السيارة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _deleteCar(id);
  }

  Future<void> _showCarReport(Map<String, dynamic> car) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تقرير السيارة: ${car['plate'] ?? '-'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الموديل: ${car['model'] ?? '-'}'),
              const SizedBox(height: 8),
              Text('الملاحظات: ${car['notes'] ?? '-'}'),
              const SizedBox(height: 12),
              const Text('تقرير تفصيلي: (قريباً)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المركبات'), centerTitle: true),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadCars,
                  child: _cars.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('لا توجد مركبات')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _cars.length,
                          itemBuilder: (ctx, i) {
                            final car = _cars[i];
                            final plate = car['plate'] ?? '';
                            final model = car['model'] ?? '';
                            final notes = car['notes'] ?? '';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      '$plate — $model',
                                      textDirection: TextDirection.rtl,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (notes != null &&
                                        (notes as String).isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        notes,
                                        textDirection: TextDirection.rtl,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[700]),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _showEditDialog(car: car),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'تعديل',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: primaryButtonStyle(context),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _confirmDelete(car),
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'حذف',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: dangerButtonStyle(),
                                        ),
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _showCarReport(car),
                                          icon: const Icon(
                                            Icons.assessment_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('عرض تقرير'),
                                          style: outlinedActionStyle(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEditDialog(),
          label: _creating ? const Text('جارٍ...') : const Text('إضافة'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
