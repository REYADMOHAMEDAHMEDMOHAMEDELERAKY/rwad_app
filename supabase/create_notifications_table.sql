-- إنشاء جدول الإشعارات للمديرين
-- Create notifications table for managers

-- إنشاء جدول notifications
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    
    -- معلومات الإشعار الأساسية
    title TEXT NOT NULL,                    -- عنوان الإشعار
    message TEXT NOT NULL,                  -- نص الإشعار
    type TEXT DEFAULT 'checkin',            -- نوع الإشعار (checkin, system, etc.)
    
    -- معلومات المستلم
    recipient_id TEXT,                      -- معرف المستلم (مدير معين أو null للجميع)
    recipient_role TEXT DEFAULT 'admin',   -- دور المستلم (admin, manager, etc.)
    
    -- معلومات المرسل
    sender_id TEXT,                         -- معرف المرسل (السائق)
    sender_name TEXT,                       -- اسم المرسل
    
    -- بيانات إضافية
    checkin_id INTEGER,                     -- معرف السجل المرتبط
    checkin_serial INTEGER,                 -- الرقم التسلسلي للسجل
    
    -- حالة الإشعار
    is_read BOOLEAN DEFAULT FALSE,          -- هل تم قراءة الإشعار
    is_archived BOOLEAN DEFAULT FALSE,      -- هل تم أرشفة الإشعار
    
    -- طوابع زمنية
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء فهارس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_role ON notifications(recipient_role);
CREATE INDEX IF NOT EXISTS idx_notifications_sender_id ON notifications(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);

-- إنشاء فهرس مركب للاستعلامات الشائعة
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread 
ON notifications(recipient_role, is_read, created_at);

-- تمكين RLS (Row Level Security) للجدول
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- سياسة الأمان: السماح للمستخدمين المصادق عليهم بقراءة الإشعارات
CREATE POLICY "Allow authenticated users to read notifications"
ON notifications
FOR SELECT
TO authenticated
USING (true);

-- سياسة الأمان: السماح للمستخدمين المصادق عليهم بإدراج الإشعارات
CREATE POLICY "Allow authenticated users to insert notifications"
ON notifications
FOR INSERT
TO authenticated
WITH CHECK (true);

-- سياسة الأمان: السماح للمستخدمين المصادق عليهم بتحديث الإشعارات
CREATE POLICY "Allow authenticated users to update notifications"
ON notifications
FOR UPDATE
TO authenticated
USING (true);

-- إدراج إشعار تجريبي
INSERT INTO notifications (
    title, 
    message, 
    type, 
    recipient_role, 
    sender_name,
    checkin_serial
) VALUES (
    'مرحباً بك في نظام الإشعارات',
    'تم إعداد نظام الإشعارات بنجاح. ستتلقى إشعارات عند تسجيل السائقين سجلات جديدة.',
    'system',
    'admin',
    'النظام',
    0
);

-- عرض هيكل الجدول للتأكد
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- رسالة تأكيد
SELECT 'تم إنشاء جدول notifications بنجاح!' as message;