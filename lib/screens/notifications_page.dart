import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import 'checkin_details_page.dart';

class NotificationsPage extends StatefulWidget {
  final String? managerId;

  const NotificationsPage({super.key, this.managerId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  bool _showOnlyUnread = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final notifications = await NotificationService.getManagerNotifications(
        managerId: widget.managerId,
        onlyUnread: _showOnlyUnread,
        limit: 100,
      );
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      debugPrint('خطأ في جلب الإشعارات: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount(
        managerId: widget.managerId,
      );
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      debugPrint('خطأ في جلب عدد الإشعارات غير المقروءة: $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    await NotificationService.markAsRead(notificationId);
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead(managerId: widget.managerId);
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _deleteNotification(int notificationId) async {
    await NotificationService.deleteNotification(notificationId);
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _deleteAllRead() async {
    await NotificationService.deleteReadNotifications(
      managerId: widget.managerId,
    );
    _loadNotifications();
    _loadUnreadCount();
  }

  void _navigateToCheckin(Map<String, dynamic> notification) async {
    // Mark as read first
    if (!notification['is_read']) {
      await _markAsRead(notification['id']);
    }

    // Navigate to check-in details if available
    if (notification['checkin_id'] != null) {
      try {
        // جلب بيانات التسجيل من قاعدة البيانات
        final client = Supabase.instance.client;
        final checkinData = await client
            .from('checkins')
            .select('*')
            .eq('id', notification['checkin_id'])
            .maybeSingle();

        if (checkinData != null && mounted) {
          // الانتقال إلى صفحة تفاصيل التسجيل
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CheckinDetailsPage(checkinData: checkinData),
            ),
          );
        } else if (mounted) {
          // إذا لم يتم العثور على بيانات التسجيل
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لم يتم العثور على تفاصيل التسجيل رقم ${notification['checkin_serial']}',
              ),
              backgroundColor: Colors.orange.shade600,
            ),
          );
        }
      } catch (e) {
        // في حالة حدوث خطأ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في فتح تفاصيل التسجيل: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        debugPrint('خطأ في جلب بيانات التسجيل: $e');
      }
    } else {
      // إذا لم يكن هناك معرف تسجيل مرتبط
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('هذا الإشعار غير مرتبط بتسجيل محدد'),
            backgroundColor: Colors.grey.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                'الإشعارات',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
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
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4F46E5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read, size: 20),
                      const SizedBox(width: 8),
                      Text('تعليم الكل كمقروء', style: GoogleFonts.cairo()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete_read',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_sweep,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'حذف المقروء',
                        style: GoogleFonts.cairo(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 20),
                      const SizedBox(width: 8),
                      Text('تحديث', style: GoogleFonts.cairo()),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead();
                    break;
                  case 'delete_read':
                    _deleteAllRead();
                    break;
                  case 'refresh':
                    _loadNotifications();
                    _loadUnreadCount();
                    break;
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Filter toggle
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showOnlyUnread = false);
                          _loadNotifications();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_showOnlyUnread
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !_showOnlyUnread
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'جميع الإشعارات',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              color: !_showOnlyUnread
                                  ? const Color(0xFF4F46E5)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showOnlyUnread = true);
                          _loadNotifications();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _showOnlyUnread
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _showOnlyUnread
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'غير المقروء',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              color: _showOnlyUnread
                                  ? const Color(0xFF4F46E5)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notifications list
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        ),
                      )
                    : _notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadNotifications();
                          await _loadUnreadCount();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyUnread ? Icons.mark_email_read : Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnread ? 'لا توجد إشعارات غير مقروءة' : 'لا توجد إشعارات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread
                ? 'جميع الإشعارات تم قراءتها'
                : 'ستظهر الإشعارات هنا عند توفرها',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = !notification['is_read'];
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '');
    final type = notification['type'] ?? 'system';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? Colors.blue.shade200 : Colors.grey.shade200,
          width: isUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToCheckin(notification),
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
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification['title'] ?? 'إشعار',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      itemBuilder: (context) => [
                        if (isUnread)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                const Icon(Icons.mark_email_read, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'تعليم كمقروء',
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'حذف',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'mark_read':
                            _markAsRead(notification['id']);
                            break;
                          case 'delete':
                            _deleteNotification(notification['id']);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification['message'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                if (notification['sender_name'] != null ||
                    notification['checkin_serial'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (notification['sender_name'] != null) ...[
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification['sender_name'],
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (notification['sender_name'] != null &&
                          notification['checkin_serial'] != null)
                        Text(
                          ' • ',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      if (notification['checkin_serial'] != null) ...[
                        Icon(
                          Icons.assignment,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'رقم ${notification['checkin_serial']}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(createdAt),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
                // إضافة مؤشر للنقر إذا كان الإشعار مرتبط بتسجيل
                if (notification['checkin_id'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'اضغط لعرض تفاصيل التسجيل',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'checkin':
        return Colors.green.shade600;
      case 'system':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'checkin':
        return Icons.assignment_turned_in;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
