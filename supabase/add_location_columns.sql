-- إضافة أعمدة بيانات الموقع إلى جدول driver_records
-- Add location data columns to driver_records table

-- التحقق من وجود الجدول وإنشاؤه إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'driver_records') THEN
        CREATE TABLE driver_records (
            id SERIAL PRIMARY KEY,
            driver_id TEXT NOT NULL,
            before_path TEXT,
            after_path TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            -- أعمدة بيانات الموقع
            latitude TEXT,
            longitude TEXT,
            country TEXT,
            city TEXT,
            district TEXT,
            street TEXT,
            full_address TEXT
        );
        
        RAISE NOTICE 'تم إنشاء جدول driver_records مع أعمدة بيانات الموقع';
    ELSE
        RAISE NOTICE 'جدول driver_records موجود بالفعل';
    END IF;
END $$;

-- إضافة أعمدة بيانات الموقع إذا لم تكن موجودة
DO $$ 
BEGIN
    -- إضافة عمود latitude
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'latitude') THEN
        ALTER TABLE driver_records ADD COLUMN latitude TEXT;
        RAISE NOTICE 'تم إضافة عمود latitude';
    END IF;
    
    -- إضافة عمود longitude
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'longitude') THEN
        ALTER TABLE driver_records ADD COLUMN longitude TEXT;
        RAISE NOTICE 'تم إضافة عمود longitude';
    END IF;
    
    -- إضافة عمود country
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'country') THEN
        ALTER TABLE driver_records ADD COLUMN country TEXT;
        RAISE NOTICE 'تم إضافة عمود country';
    END IF;
    
    -- إضافة عمود city
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'city') THEN
        ALTER TABLE driver_records ADD COLUMN city TEXT;
        RAISE NOTICE 'تم إضافة عمود city';
    END IF;
    
    -- إضافة عمود district
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'district') THEN
        ALTER TABLE driver_records ADD COLUMN district TEXT;
        RAISE NOTICE 'تم إضافة عمود district';
    END IF;
    
    -- إضافة عمود street
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'street') THEN
        ALTER TABLE driver_records ADD COLUMN street TEXT;
        RAISE NOTICE 'تم إضافة عمود street';
    END IF;
    
    -- إضافة عمود full_address
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'driver_records' AND column_name = 'full_address') THEN
        ALTER TABLE driver_records ADD COLUMN full_address TEXT;
        RAISE NOTICE 'تم إضافة عمود full_address';
    END IF;
    
    RAISE NOTICE 'تم التحقق من جميع أعمدة بيانات الموقع';
END $$;

-- عرض هيكل الجدول للتأكد
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_records' 
ORDER BY ordinal_position;
