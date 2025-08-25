-- إصلاح جدول checkins بالكامل - إضافة جميع الأعمدة المفقودة
-- Complete fix for checkins table - add all missing columns

-- التحقق من وجود الجدول
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'checkins') THEN
        RAISE NOTICE 'جدول checkins موجود، جاري إصلاحه بالكامل...';
        
        -- إضافة عمود driver_id إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'driver_id') THEN
            ALTER TABLE checkins ADD COLUMN driver_id TEXT;
            RAISE NOTICE 'تم إضافة عمود driver_id';
        ELSE
            RAISE NOTICE 'عمود driver_id موجود بالفعل';
        END IF;
        
        -- إضافة عمود accuracy إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'accuracy') THEN
            ALTER TABLE checkins ADD COLUMN accuracy DOUBLE PRECISION;
            RAISE NOTICE 'تم إضافة عمود accuracy';
        ELSE
            RAISE NOTICE 'عمود accuracy موجود بالفعل';
        END IF;
        
        -- إضافة عمود altitude إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'altitude') THEN
            ALTER TABLE checkins ADD COLUMN altitude DOUBLE PRECISION;
            RAISE NOTICE 'تم إضافة عمود altitude';
        ELSE
            RAISE NOTICE 'عمود altitude موجود بالفعل';
        END IF;
        
        -- إضافة عمود speed إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'speed') THEN
            ALTER TABLE checkins ADD COLUMN speed DOUBLE PRECISION;
            RAISE NOTICE 'تم إضافة عمود speed';
        ELSE
            RAISE NOTICE 'عمود speed موجود بالفعل';
        END IF;
        
        -- إضافة عمود heading إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'heading') THEN
            ALTER TABLE checkins ADD COLUMN heading DOUBLE PRECISION;
            RAISE NOTICE 'تم إضافة عمود heading';
        ELSE
            RAISE NOTICE 'عمود heading موجود بالفعل';
        END IF;
        
        -- إضافة عمود notes إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'notes') THEN
            ALTER TABLE checkins ADD COLUMN notes TEXT;
            RAISE NOTICE 'تم إضافة عمود notes';
        ELSE
            RAISE NOTICE 'عمود notes موجود بالفعل';
        END IF;
        
        -- إضافة عمود created_at إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'created_at') THEN
            ALTER TABLE checkins ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            RAISE NOTICE 'تم إضافة عمود created_at';
        ELSE
            RAISE NOTICE 'عمود created_at موجود بالفعل';
        END IF;
        
        -- إضافة عمود updated_at إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'updated_at') THEN
            ALTER TABLE checkins ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            RAISE NOTICE 'تم إضافة عمود updated_at';
        ELSE
            RAISE NOTICE 'عمود updated_at موجود بالفعل';
        END IF;
        
        -- إضافة عمود status إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'status') THEN
            ALTER TABLE checkins ADD COLUMN status TEXT DEFAULT 'active';
            RAISE NOTICE 'تم إضافة عمود status';
        ELSE
            RAISE NOTICE 'عمود status موجود بالفعل';
        END IF;
        
        -- إضافة عمود location_details (JSONB) إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'location_details') THEN
            ALTER TABLE checkins ADD COLUMN location_details JSONB;
            RAISE NOTICE 'تم إضافة عمود location_details (JSONB)';
        ELSE
            RAISE NOTICE 'عمود location_details موجود بالفعل';
        END IF;
        
        -- إضافة عمود country إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'country') THEN
            ALTER TABLE checkins ADD COLUMN country TEXT;
            RAISE NOTICE 'تم إضافة عمود country';
        ELSE
            RAISE NOTICE 'عمود country موجود بالفعل';
        END IF;
        
        -- إضافة عمود city إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'city') THEN
            ALTER TABLE checkins ADD COLUMN city TEXT;
            RAISE NOTICE 'تم إضافة عمود city';
        ELSE
            RAISE NOTICE 'عمود city موجود بالفعل';
        END IF;
        
        -- إضافة عمود district إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'district') THEN
            ALTER TABLE checkins ADD COLUMN district TEXT;
            RAISE NOTICE 'تم إضافة عمود district';
        ELSE
            RAISE NOTICE 'عمود district موجود بالفعل';
        END IF;
        
        -- إضافة عمود street إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'street') THEN
            ALTER TABLE checkins ADD COLUMN street TEXT;
            RAISE NOTICE 'تم إضافة عمود street';
        ELSE
            RAISE NOTICE 'عمود street موجود بالفعل';
        END IF;
        
        -- إضافة عمود full_address إذا لم يكن موجوداً
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'full_address') THEN
            ALTER TABLE checkins ADD COLUMN full_address TEXT;
            RAISE NOTICE 'تم إضافة عمود full_address';
        ELSE
            RAISE NOTICE 'عمود full_address موجود بالفعل';
        END IF;
        
        -- إضافة عمود latitude إذا لم يكن موجوداً (بديل لـ lat)
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'latitude') THEN
            ALTER TABLE checkins ADD COLUMN latitude TEXT;
            RAISE NOTICE 'تم إضافة عمود latitude';
        ELSE
            RAISE NOTICE 'عمود latitude موجود بالفعل';
        END IF;
        
        -- إضافة عمود longitude إذا لم يكن موجوداً (بديل لـ lon)
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'checkins' AND column_name = 'longitude') THEN
            ALTER TABLE checkins ADD COLUMN longitude TEXT;
            RAISE NOTICE 'تم إضافة عمود longitude';
        ELSE
            RAISE NOTICE 'عمود longitude موجود بالفعل';
        END IF;
        
    ELSE
        RAISE NOTICE 'جدول checkins غير موجود';
    END IF;
END $$;

-- إنشاء فهارس للبحث السريع
DO $$ 
BEGIN
    -- فهرس على driver_id
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_checkins_driver_id') THEN
        CREATE INDEX idx_checkins_driver_id ON checkins(driver_id);
        RAISE NOTICE 'تم إنشاء فهرس على driver_id';
    END IF;
    
    -- فهرس على created_at
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_checkins_created_at') THEN
        CREATE INDEX idx_checkins_created_at ON checkins(created_at);
        RAISE NOTICE 'تم إنشاء فهرس على created_at';
    END IF;
    
    -- فهرس على status
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_checkins_status') THEN
        CREATE INDEX idx_checkins_status ON checkins(status);
        RAISE NOTICE 'تم إنشاء فهرس على status';
    END IF;
    
    -- فهرس على serial
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_checkins_serial') THEN
        CREATE INDEX idx_checkins_serial ON checkins(serial);
        RAISE NOTICE 'تم إنشاء فهرس على serial';
    END IF;
END $$;

-- عرض هيكل الجدول بعد التحديث
SELECT 
    'هيكل الجدول المحدث' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'checkins' 
ORDER BY ordinal_position;

-- رسالة تأكيد
SELECT 'تم إصلاح جدول checkins بالكامل وإضافة جميع الأعمدة المطلوبة!' as message;
