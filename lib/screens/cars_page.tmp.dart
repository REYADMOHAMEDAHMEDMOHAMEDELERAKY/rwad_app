import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      debugPrint('cars: requesting from supabase...');
      final res = await client
          .from('cars')
          .select('id,plate,model,notes')
          .order('id', ascending: true);
      debugPrint('cars: raw response type=${res.runtimeType}');
      debugPrint('cars: raw response=${jsonEncode(res)}');
      try {
        final list = List<Map<String, dynamic>>.from(
          (res as Iterable).map((e) => Map<String, dynamic>.from(e)),
        );
        setState(() => _cars = list);
        debugPrint('cars: parsed ${_cars.length} rows');
      } catch (err) {
        debugPrint('cars: parsing error: $err');
        setState(() => _cars = []);
      }
    } catch (e) {
      debugPrint('loadCars error: $e');
      debugPrintStack();
    }
    setState(() => _loading = false);
  }

  Future<void> _createCar() async {
    final plate = _plateController.text.trim();
    final model = _modelController.text.trim();
    final notes = _notesController.text.trim();
    if (plate.isEmpty) return;
    setState(() => _creating = true);
    try {
      final client = Supabase.instance.client;
      final payload = {'plate': plate, 'model': model, 'notes': notes};
      debugPrint('createCar: payload=${jsonEncode(payload)}');
      final res = await client.from('cars').insert(payload).select();
      debugPrint('createCar: raw response=${jsonEncode(res)}');
      if ((res as List).isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنشاء السيارة: استجابة غير متوقعة من السيرفر'),
          ),
        );
        return;
      }
      _plateController.clear();
      _modelController.clear();
      _notesController.clear();
      await _loadCars();
      if (!mounted) return;
      await _showSavedModal(
        title: 'تم الحفظ',
        message: 'تمت إضافة السيارة بنجاح.',
      );
    } catch (e, st) {
      debugPrint('createCar error: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إنشاء السيارة: ${(e is PostgrestException) ? e.message : e.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deleteCar(int id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('cars').delete().eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف السيارة')));
      await _loadCars();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
    }
  }

  Future<void> _confirmDelete(int id) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذه السيارة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
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
          title: Text('تقرير السيارة: ${car['plate']}'),
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

  Future<void> _editCar(Map<String, dynamic> car) async {
    final plateCtl = TextEditingController(text: car['plate']?.toString());
    final modelCtl = TextEditingController(text: car['model']?.toString());
    final notesCtl = TextEditingController(text: car['notes']?.toString());
    if (!mounted) return;
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withAlpha(200),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تعديل بيانات السيارة',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: plateCtl,
                    decoration: InputDecoration(
                      labelText: 'لوحة السيارة',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: modelCtl,
                    decoration: InputDecoration(
                      labelText: 'الموديل',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final client = Supabase.instance.client;
                            await client
                                .from('cars')
                                .update({
                                  'plate': plateCtl.text.trim(),
                                  'model': modelCtl.text.trim(),
                                  'notes': notesCtl.text.trim(),
                                })
                                .eq('id', car['id']);
                            if (!mounted) return;
                            Navigator.of(context).pop(true);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل التحديث: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('حفظ'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (saved == true) await _loadCars();
    } finally {
      plateCtl.dispose();
      modelCtl.dispose();
      notesCtl.dispose();
    }
  }

  Future<void> _showSavedModal({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withAlpha(204),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
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
        appBar: AppBar(
          title: const Text('إدارة السيارات'),
          actions: [
            IconButton(onPressed: _loadCars, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _plateController,
                        decoration: InputDecoration(
                          labelText: 'لوحة السيارة',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: 'الموديل',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'الملاحظات',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _creating ? null : _createCar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'إضافة سيارة',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _cars.isEmpty
                    ? const Center(child: Text('لا توجد سيارات بعد'))
                    : ListView.separated(
                        itemCount: _cars.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final car = _cars[i];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${car['plate']} - ${car['model']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            if (car['notes'] != null &&
                                                (car['notes'] as String)
                                                    .isNotEmpty)
                                              Text(
                                                '${car['notes']}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.grey[700],
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _editCar(car),
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'تعديل',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _confirmDelete(car['id']),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        label: const Text('حذف'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _showCarReport(car),
                                        icon: const Icon(
                                          Icons.assessment_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('عرض تقرير'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
