-- التحقق من البيانات المحفوظة في جدول checkins
-- Check saved data in checkins table

-- عرض هيكل الجدول
SELECT 
    'هيكل الجدول' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'checkins' 
ORDER BY ordinal_position;

-- عرض آخر 10 تسجيلات
SELECT 
    'آخر 10 تسجيلات' as info,
    id,
    serial,
    driver_id,
    timestamp,
    lat,
    lon,
    before_path,
    after_path,
    notes
FROM checkins 
ORDER BY created_at DESC 
LIMIT 10;

-- البحث عن تسجيلات سائق معين (استبدل 'ahmed' باسم السائق)
SELECT 
    'تسجيلات السائق ahmed' as info,
    id,
    serial,
    timestamp,
    lat,
    lon,
    before_path,
    after_path,
    notes
FROM checkins 
WHERE driver_id = 'ahmed'
ORDER BY created_at DESC;

-- إحصائيات عامة
SELECT 
    'إحصائيات عامة' as info,
    COUNT(*) as total_records,
    COUNT(DISTINCT driver_id) as unique_drivers,
    MIN(created_at) as first_record,
    MAX(created_at) as last_record
FROM checkins;

-- التحقق من وجود عمود notes
SELECT 
    'التحقق من عمود notes' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'checkins' AND column_name = 'notes'
        ) THEN 'عمود notes موجود'
        ELSE 'عمود notes غير موجود'
    END as notes_status;

-- عرض البيانات مع تفاصيل الموقع
SELECT 
    'تفاصيل الموقع' as info,
    id,
    driver_id,
    serial,
    timestamp,
    lat,
    lon,
    CASE 
        WHEN notes IS NOT NULL AND notes != '' THEN notes
        ELSE 'لا توجد ملاحظات'
    END as location_details
FROM checkins 
WHERE lat IS NOT NULL OR lon IS NOT NULL
ORDER BY created_at DESC 
LIMIT 5;
