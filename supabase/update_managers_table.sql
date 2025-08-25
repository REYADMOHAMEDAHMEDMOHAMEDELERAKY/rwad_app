-- تحديث جدول managers لإضافة الأعمدة المطلوبة
-- قم بتشغيل هذا الملف في Supabase SQL Editor

-- إضافة عمود role إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'role') THEN
        ALTER TABLE public.managers ADD COLUMN role text DEFAULT 'driver';
        ALTER TABLE public.managers ADD CONSTRAINT managers_role_check 
        CHECK (role IN ('driver', 'admin'));
    END IF;
END $$;

-- إضافة عمود is_suspended إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'is_suspended') THEN
        ALTER TABLE public.managers ADD COLUMN is_suspended boolean DEFAULT false;
    END IF;
END $$;

-- إضافة الأعمدة الجديدة لبيانات المدير الكاملة
DO $$ 
BEGIN
    -- إضافة عمود full_name (الاسم الكامل)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'full_name') THEN
        ALTER TABLE public.managers ADD COLUMN full_name text;
    END IF;
    
    -- إضافة عمود email (البريد الإلكتروني)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'email') THEN
        ALTER TABLE public.managers ADD COLUMN email text;
    END IF;
    
    -- إضافة عمود phone (رقم الهاتف)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'phone') THEN
        ALTER TABLE public.managers ADD COLUMN phone text;
    END IF;
    
    -- إضافة عمود department (القسم/الإدارة)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'department') THEN
        ALTER TABLE public.managers ADD COLUMN department text;
    END IF;
    
    -- إضافة عمود join_date (تاريخ الانضمام)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'join_date') THEN
        ALTER TABLE public.managers ADD COLUMN join_date date DEFAULT CURRENT_DATE;
    END IF;
    
    -- إضافة عمود last_login (آخر تسجيل دخول)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'last_login') THEN
        ALTER TABLE public.managers ADD COLUMN last_login timestamptz;
    END IF;
    
    -- إضافة عمود total_actions (إجمالي الإجراءات)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'total_actions') THEN
        ALTER TABLE public.managers ADD COLUMN total_actions integer DEFAULT 0;
    END IF;
    
    -- إضافة عمود active_sessions (الجلسات النشطة)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'active_sessions') THEN
        ALTER TABLE public.managers ADD COLUMN active_sessions integer DEFAULT 0;
    END IF;
    
    -- إضافة عمود profile_image (صورة البروفايل)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'profile_image') THEN
        ALTER TABLE public.managers ADD COLUMN profile_image text;
    END IF;
END $$;

-- تحديث المستخدمين الموجودين ليكون لديهم دور افتراضي
UPDATE public.managers 
SET role = 'admin' 
WHERE username = 'admin' AND (role IS NULL OR role = '');

UPDATE public.managers 
SET role = 'driver' 
WHERE role IS NULL OR role = '';

-- تعيين is_suspended = false للمستخدمين الموجودين
UPDATE public.managers 
SET is_suspended = false 
WHERE is_suspended IS NULL;

-- تحديث البيانات الافتراضية للمستخدمين التجريبيين
UPDATE public.managers 
SET 
    full_name = 'علاء أحمد',
    email = 'alaa@rwaad.com',
    phone = '+966 50 123 4567',
    department = 'إدارة الأسطول',
    join_date = '2024-01-01',
    last_login = CURRENT_TIMESTAMP,
    total_actions = 156,
    active_sessions = 3
WHERE username = 'alaa';

UPDATE public.managers 
SET 
    full_name = 'أحمد صبري',
    email = 'ahmed@rwaad.com',
    phone = '+966 50 234 5678',
    department = 'إدارة الأسطول',
    join_date = '2024-01-16',
    last_login = CURRENT_TIMESTAMP,
    total_actions = 89,
    active_sessions = 1
WHERE username = 'ahmed_sabry';

UPDATE public.managers 
SET 
    full_name = 'محمد علي',
    email = 'mohammed@rwaad.com',
    phone = '+966 50 345 6789',
    department = 'إدارة الأسطول',
    join_date = '2024-01-17',
    last_login = CURRENT_TIMESTAMP,
    total_actions = 67,
    active_sessions = 0
WHERE username = 'mohammed';

-- عرض هيكل الجدول المحدث
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'managers' 
ORDER BY ordinal_position;

-- عرض البيانات الحالية
SELECT 
    id, 
    username, 
    full_name,
    email,
    phone,
    role, 
    department,
    join_date,
    last_login,
    total_actions,
    active_sessions,
    is_suspended, 
    created_at
FROM public.managers
ORDER BY id;

