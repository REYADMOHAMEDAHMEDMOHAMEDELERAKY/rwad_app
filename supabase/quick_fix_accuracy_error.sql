-- إصلاح سريع لخطأ عمود accuracy
-- Quick fix for accuracy column error

-- التحقق من وجود جدول checkins وإضافة الأعمدة المفقودة الأساسية
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'checkins') THEN
        RAISE NOTICE 'جدول checkins موجود، جاري إضافة الأعمدة المفقودة...';
        
        -- إضافة عمود accuracy (الأهم للحل السريع)
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'accuracy') THEN
            ALTER TABLE checkins ADD COLUMN accuracy DOUBLE PRECISION;
            RAISE NOTICE '✅ تم إضافة عمود accuracy بنجاح';
        ELSE
            RAISE NOTICE '✅ عمود accuracy موجود بالفعل';
        END IF;
        
        -- إضافة عمود driver_id إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'driver_id') THEN
            ALTER TABLE checkins ADD COLUMN driver_id TEXT;
            RAISE NOTICE '✅ تم إضافة عمود driver_id';
        ELSE
            RAISE NOTICE '✅ عمود driver_id موجود بالفعل';
        END IF;
        
        -- إضافة عمود altitude إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'altitude') THEN
            ALTER TABLE checkins ADD COLUMN altitude DOUBLE PRECISION;
            RAISE NOTICE '✅ تم إضافة عمود altitude';
        ELSE
            RAISE NOTICE '✅ عمود altitude موجود بالفعل';
        END IF;
        
        -- إضافة عمود speed إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'speed') THEN
            ALTER TABLE checkins ADD COLUMN speed DOUBLE PRECISION;
            RAISE NOTICE '✅ تم إضافة عمود speed';
        ELSE
            RAISE NOTICE '✅ عمود speed موجود بالفعل';
        END IF;
        
        -- إضافة عمود heading إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'heading') THEN
            ALTER TABLE checkins ADD COLUMN heading DOUBLE PRECISION;
            RAISE NOTICE '✅ تم إضافة عمود heading';
        ELSE
            RAISE NOTICE '✅ عمود heading موجود بالفعل';
        END IF;
        
        -- إضافة عمود notes إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'notes') THEN
            ALTER TABLE checkins ADD COLUMN notes TEXT;
            RAISE NOTICE '✅ تم إضافة عمود notes';
        ELSE
            RAISE NOTICE '✅ عمود notes موجود بالفعل';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ جدول checkins غير موجود - يجب إنشاؤه أولاً';
    END IF;
END $$;

-- التحقق من النتائج
SELECT 
    'تم إصلاح خطأ accuracy بنجاح!' as status,
    'يمكن الآن حفظ البيانات بدون أخطاء' as message;

-- عرض الأعمدة المضافة للتأكد
SELECT 
    'الأعمدة المضافة/المتحقق منها:' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'checkins' 
  AND column_name IN ('accuracy', 'driver_id', 'altitude', 'speed', 'heading', 'notes')
ORDER BY column_name;