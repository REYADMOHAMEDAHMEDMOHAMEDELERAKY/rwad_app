-- إعداد بسيط لجدول الإشعارات
-- Simple notifications table setup

-- Step 1: Create notifications table
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

-- Step 2: Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Step 3: Create simple policy
CREATE POLICY "Enable all access for authenticated users" ON public.notifications
FOR ALL USING (auth.role() = 'authenticated');

-- Step 4: Insert test notification
INSERT INTO public.notifications (title, message, sender_name, checkin_serial)
VALUES ('اختبار الإشعارات', 'هذا إشعار تجريبي للتأكد من عمل النظام', 'النظام', 0);

-- Step 5: Verify table creation
SELECT 'تم إنشاء جدول notifications بنجاح!' as result;