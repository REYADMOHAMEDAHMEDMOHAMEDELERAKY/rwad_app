-- إنشاء جدول driver_records لبيانات السائقين
-- Create driver_records table for driver data

-- إنشاء الجدول
CREATE TABLE IF NOT EXISTS driver_records (
    id SERIAL PRIMARY KEY,
    driver_id TEXT NOT NULL,
    before_path TEXT,
    after_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- بيانات الموقع
    latitude TEXT,
    longitude TEXT,
    country TEXT,
    city TEXT,
    district TEXT,
    street TEXT,
    full_address TEXT
);

-- إنشاء فهرس على driver_id للبحث السريع
CREATE INDEX IF NOT EXISTS idx_driver_records_driver_id ON driver_records(driver_id);

-- إنشاء فهرس على created_at للترتيب الزمني
CREATE INDEX IF NOT EXISTS idx_driver_records_created_at ON driver_records(created_at);

-- عرض هيكل الجدول
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_records' 
ORDER BY ordinal_position;

-- رسالة تأكيد
SELECT 'تم إنشاء جدول driver_records بنجاح!' as message;
