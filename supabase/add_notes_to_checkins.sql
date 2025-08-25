-- إضافة عمود notes إلى جدول checkins
-- Add notes column to existing checkins table

-- التحقق من وجود الجدول
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'checkins') THEN
        RAISE NOTICE 'جدول checkins موجود';
        
        -- إضافة عمود notes إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'notes') THEN
            ALTER TABLE checkins ADD COLUMN notes TEXT;
            RAISE NOTICE 'تم إضافة عمود notes إلى جدول checkins';
        ELSE
            RAISE NOTICE 'عمود notes موجود بالفعل في جدول checkins';
        END IF;
        
        -- إضافة عمود location_details إذا لم يكن موجوداً (اختياري)
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'location_details') THEN
            ALTER TABLE checkins ADD COLUMN location_details JSONB;
            RAISE NOTICE 'تم إضافة عمود location_details (JSONB) إلى جدول checkins';
        ELSE
            RAISE NOTICE 'عمود location_details موجود بالفعل في جدول checkins';
        END IF;
        
    ELSE
        RAISE NOTICE 'جدول checkins غير موجود';
    END IF;
END $$;

-- عرض هيكل الجدول بعد التعديل
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'checkins' 
ORDER BY ordinal_position;

-- رسالة تأكيد
SELECT 'تم تحديث جدول checkins بنجاح!' as message;
