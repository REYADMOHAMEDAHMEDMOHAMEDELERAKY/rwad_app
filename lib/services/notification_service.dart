import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// إرسال إشعار جديد للمديرين عند تسجيل سجل جديد
  static Future<void> sendNewCheckinNotification({
    required String driverName,
    required String driverId,
    required int checkinSerial,
    required int checkinId,
    String? location,
  }) async {
    try {
      print('🔔 محاولة إرسال إشعار...');
      print('Driver: $driverName, Serial: $checkinSerial, Location: $location');

      final title = 'تسجيل جديد من السائق';
      final message =
          location != null
              ? 'سجل السائق $driverName تسجيل جديد رقم $checkinSerial في موقع: $location'
              : 'سجل السائق $driverName تسجيل جديد رقم $checkinSerial';

      // محاولة إدراج الإشعار
      final result =
          await _client.from('notifications').insert({
            'title': title,
            'message': message,
            'type': 'checkin',
            'recipient_role': 'admin', // إرسال لجميع المديرين
            'sender_id': driverId,
            'sender_name': driverName,
            'checkin_id': checkinId,
            'checkin_serial': checkinSerial,
          }).select();

      print('✅ تم إرسال إشعار بنجاح: $title');
      print('📄 Result: $result');
    } catch (e) {
      print('❌ خطأ في إرسال الإشعار: $e');
      print('📋 Error type: ${e.runtimeType}');

      // محاولة إنشاء الجدول إذا لم يكن موجوداً
      if (e.toString().contains('relation "notifications" does not exist') ||
          e.toString().contains('table "notifications" does not exist') ||
          e.toString().contains(
            'relation "public.notifications" does not exist',
          )) {
        print('⚠️ جدول notifications غير موجود، محاولة إنشاؤه...');
        await _createNotificationsTableFallback();

        // إعادة المحاولة
        try {
          await _client.from('notifications').insert({
            'title': 'تسجيل جديد من السائق',
            'message':
                location != null
                    ? 'سجل السائق $driverName تسجيل جديد رقم $checkinSerial في موقع: $location'
                    : 'سجل السائق $driverName تسجيل جديد رقم $checkinSerial',
            'type': 'checkin',
            'recipient_role': 'admin',
            'sender_id': driverId,
            'sender_name': driverName,
            'checkin_id': checkinId,
            'checkin_serial': checkinSerial,
          });
          print('✅ تم إرسال الإشعار بعد إنشاء الجدول');
        } catch (retryError) {
          print('❌ فشل في إرسال الإشعار حتى بعد إنشاء الجدول: $retryError');
        }
      }
    }
  }

  /// إنشاء جدول notifications إذا لم يكن موجوداً
  static Future<void> _createNotificationsTableFallback() async {
    try {
      // محاولة إنشاء الجدول بـ SQL مباشر
      await _client.rpc(
        'exec_sql',
        params: {
          'sql': '''
          CREATE TABLE IF NOT EXISTS public.notifications (
            id BIGSERIAL PRIMARY KEY,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            type TEXT DEFAULT 'checkin',
            recipient_role TEXT DEFAULT 'admin',
            sender_id TEXT,
            sender_name TEXT,
            checkin_id INTEGER,
            checkin_serial INTEGER,
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
        ''',
        },
      );
      print('✅ تم إنشاء جدول notifications');
    } catch (e) {
      print('⚠️ لا يمكن إنشاء الجدول تلقائياً: $e');
      print(
        'ℹ️ يرجى تنفيذ simple_notifications_setup.sql في Supabase SQL Editor',
      );
    }
  }

  /// إرسال إشعار لمدير محدد
  static Future<void> sendNotificationToManager({
    required String managerId,
    required String title,
    required String message,
    String type = 'system',
    String? senderId,
    String? senderName,
  }) async {
    try {
      await _client.from('notifications').insert({
        'title': title,
        'message': message,
        'type': type,
        'recipient_id': managerId,
        'recipient_role': 'admin',
        'sender_id': senderId,
        'sender_name': senderName,
      });

      print('✅ تم إرسال إشعار للمدير $managerId: $title');
    } catch (e) {
      print('❌ خطأ في إرسال الإشعار للمدير: $e');
    }
  }

  /// جلب جميع الإشعارات للمديرين
  static Future<List<Map<String, dynamic>>> getManagerNotifications({
    String? managerId,
    bool onlyUnread = false,
    int limit = 50,
  }) async {
    try {
      print('📅 جلب الإشعارات...');

      var query = _client
          .from('notifications')
          .select('*')
          .eq('recipient_role', 'admin');

      // إذا كان مدير محدد
      if (managerId != null) {
        query = query.or('recipient_id.is.null,recipient_id.eq.$managerId');
      }

      // إذا كان فقط الإشعارات غير المقروءة
      if (onlyUnread) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      print('📄 تم جلب ${response.length} إشعار');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ خطأ في جلب الإشعارات: $e');

      // إذا كان الجدول غير موجود، أعد قائمة فارغة
      if (e.toString().contains('relation "notifications" does not exist') ||
          e.toString().contains('table "notifications" does not exist') ||
          e.toString().contains(
            'relation "public.notifications" does not exist',
          )) {
        print(
          '⚠️ جدول notifications غير موجود، ارجع إلى simple_notifications_setup.sql',
        );
      }

      return [];
    }
  }

  /// تعليم إشعار كمقروء
  static Future<void> markAsRead(int notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            // Note: read_at and updated_at columns will be added later
            // 'read_at': DateTime.now().toIso8601String(),
            // 'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      print('✅ تم تعليم الإشعار $notificationId كمقروء');
    } catch (e) {
      print('❌ خطأ في تعليم الإشعار كمقروء: $e');
    }
  }

  /// تعليم جميع الإشعارات كمقروءة لمدير
  static Future<void> markAllAsRead({String? managerId}) async {
    try {
      var query = _client
          .from('notifications')
          .update({
            'is_read': true,
            // Note: read_at and updated_at columns will be added later
            // 'read_at': DateTime.now().toIso8601String(),
            // 'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_role', 'admin')
          .eq('is_read', false);

      if (managerId != null) {
        query = query.or('recipient_id.is.null,recipient_id.eq.$managerId');
      }

      await query;

      print('✅ تم تعليم جميع الإشعارات كمقروءة');
    } catch (e) {
      print('❌ خطأ في تعليم جميع الإشعارات كمقروءة: $e');
    }
  }

  /// حذف إشعار
  static Future<void> deleteNotification(int notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);

      print('✅ تم حذف الإشعار $notificationId');
    } catch (e) {
      print('❌ خطأ في حذف الإشعار: $e');
    }
  }

  /// حذف جميع الإشعارات المقروءة
  static Future<void> deleteReadNotifications({String? managerId}) async {
    try {
      var query = _client
          .from('notifications')
          .delete()
          .eq('recipient_role', 'admin')
          .eq('is_read', true);

      if (managerId != null) {
        query = query.or('recipient_id.is.null,recipient_id.eq.$managerId');
      }

      await query;

      print('✅ تم حذف جميع الإشعارات المقروءة');
    } catch (e) {
      print('❌ خطأ في حذف الإشعارات المقروءة: $e');
    }
  }

  /// الحصول على عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount({String? managerId}) async {
    try {
      print('🔢 جلب عدد الإشعارات غير المقروءة...');

      var query = _client
          .from('notifications')
          .select('id')
          .eq('recipient_role', 'admin')
          .eq('is_read', false);

      if (managerId != null) {
        query = query.or('recipient_id.is.null,recipient_id.eq.$managerId');
      }

      final response = await query;
      final count = response.length;

      print('🔢 عدد الإشعارات غير المقروءة: $count');
      return count;
    } catch (e) {
      print('❌ خطأ في جلب عدد الإشعارات غير المقروءة: $e');

      // إذا كان الجدول غير موجود، أعد 0
      if (e.toString().contains('relation "notifications" does not exist') ||
          e.toString().contains('table "notifications" does not exist') ||
          e.toString().contains(
            'relation "public.notifications" does not exist',
          )) {
        print('⚠️ جدول notifications غير موجود، إرجاع 0');
      }

      return 0;
    }
  }
}
