-- إضافة عمود full_name إلى جدول managers
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

-- إضافة عمود full_name (الاسم الكامل)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'full_name') THEN
        ALTER TABLE public.managers ADD COLUMN full_name text;
        RAISE NOTICE 'تم إضافة عمود full_name بنجاح';
    ELSE
        RAISE NOTICE 'عمود full_name موجود بالفعل';
    END IF;
END $$;

-- إضافة عمود phone (رقم الهاتف)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'phone') THEN
        ALTER TABLE public.managers ADD COLUMN phone text;
        RAISE NOTICE 'تم إضافة عمود phone بنجاح';
    ELSE
        RAISE NOTICE 'عمود phone موجود بالفعل';
    END IF;
END $$;

-- إضافة عمود join_date (تاريخ الانضمام)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'join_date') THEN
        ALTER TABLE public.managers ADD COLUMN join_date date DEFAULT CURRENT_DATE;
        RAISE NOTICE 'تم إضافة عمود join_date بنجاح';
    ELSE
        RAISE NOTICE 'عمود join_date موجود بالفعل';
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
    phone = '+966 50 123 4567',
    join_date = '2024-01-01'
WHERE username = 'alaa';

UPDATE public.managers 
SET 
    full_name = 'أحمد صبري',
    phone = '+966 50 234 5678',
    join_date = '2024-01-16'
WHERE username = 'ahmed_sabry';

UPDATE public.managers 
SET 
    full_name = 'محمد علي',
    phone = '+966 50 345 6789',
    join_date = '2024-01-17'
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
    phone,
    role, 
    join_date,
    is_suspended, 
    created_at
FROM public.managers
ORDER BY id;
