-- Fix notifications table by adding missing columns
-- إصلاح جدول الإشعارات بإضافة الأعمدة المفقودة

-- Add read_at column if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications' AND column_name = 'read_at') THEN
        ALTER TABLE public.notifications ADD COLUMN read_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'تم إضافة عمود read_at بنجاح';
    ELSE
        RAISE NOTICE 'عمود read_at موجود بالفعل';
    END IF;
END $$;

-- Add updated_at column if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications' AND column_name = 'updated_at') THEN
        ALTER TABLE public.notifications ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'تم إضافة عمود updated_at بنجاح';
    ELSE
        RAISE NOTICE 'عمود updated_at موجود بالفعل';
    END IF;
END $$;

-- Add is_archived column if not exists (for future use)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications' AND column_name = 'is_archived') THEN
        ALTER TABLE public.notifications ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'تم إضافة عمود is_archived بنجاح';
    ELSE
        RAISE NOTICE 'عمود is_archived موجود بالفعل';
    END IF;
END $$;

-- Update existing notifications to have updated_at value
UPDATE public.notifications 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- Verification message
SELECT 'تم إصلاح جدول notifications بنجاح! يمكن الآن تعليم الإشعارات كمقروءة.' as message;