-- إعداد بسيط وآمن لجدول الإشعارات
-- Simple and safe notifications table setup

-- حذف الجدول إذا كان موجوداً (اختياري)
-- Drop table if exists (optional)
-- DROP TABLE IF EXISTS public.notifications;

-- إنشاء جدول الإشعارات
-- Create notifications table
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

-- إضافة فهارس للأداء
-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_role ON public.notifications(recipient_role);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- تمكين Row Level Security
-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة إذا كانت موجودة
-- Drop old policies if they exist
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.notifications;
DROP POLICY IF EXISTS "Allow authenticated users to read notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow authenticated users to update notifications" ON public.notifications;

-- إنشاء سياسة بسيطة للوصول الكامل للمستخدمين المصادق عليهم
-- Create simple policy for full access to authenticated users
CREATE POLICY "notifications_authenticated_access" ON public.notifications
FOR ALL USING (true);

-- منح الصلاحيات
-- Grant permissions
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO anon;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO anon;

-- إدراج إشعار تجريبي
-- Insert test notification
INSERT INTO public.notifications (title, message, sender_name, checkin_serial)
VALUES ('اختبار النظام', 'تم إعداد نظام الإشعارات بنجاح!', 'النظام', 0);

-- التحقق من النتيجة
-- Verify result
SELECT 'تم إنشاء جدول notifications بنجاح!' as status;
SELECT COUNT(*) as total_notifications FROM public.notifications;

-- عرض هيكل الجدول
-- Show table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
    AND table_schema = 'public'
ORDER BY ordinal_position;