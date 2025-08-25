-- حل مشكلة bucket التخزين المفقود
-- هذا الملف يحتوي على جميع الأوامر المطلوبة لحل مشكلة تحميل الصور

-- ========================================
-- 1. إنشاء bucket التخزين
-- ========================================

-- ملاحظة: لا يمكن إنشاء bucket عبر SQL مباشرة
-- يجب إنشاؤه من خلال Supabase Dashboard

/*
الخطوات:
1. اذهب إلى Supabase Dashboard
2. اختر مشروعك
3. اذهب إلى Storage (في القائمة الجانبية)
4. اضغط "New Bucket"
5. أدخل:
   - Name: checkins
   - Public: ✅ (مفعل)
   - File size limit: 50 MB
6. اضغط "Create bucket"
*/

-- ========================================
-- 2. إنشاء RLS Policies للوصول
-- ========================================

-- إنشاء policy للقراءة (مطلوب لتحميل الصور)
CREATE POLICY "Allow public read access to checkins bucket" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'checkins');

-- إنشاء policy للكتابة (مطلوب لحفظ الصور الجديدة)
CREATE POLICY "Allow public upload to checkins bucket" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'checkins');

-- إنشاء policy للتحديث (مطلوب لتعديل الصور)
CREATE POLICY "Allow public update in checkins bucket" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'checkins');

-- إنشاء policy للحذف (اختياري - لحذف الصور)
CREATE POLICY "Allow public delete from checkins bucket" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'checkins');

-- ========================================
-- 3. فحص حالة التخزين
-- ========================================

-- فحص وجود bucket
SELECT name, public, file_size_limit 
FROM storage.buckets 
WHERE name = 'checkins';

-- فحص policies الموجودة
SELECT * 
FROM storage.policies 
WHERE bucket_id = 'checkins';

-- فحص الملفات الموجودة (بعد إنشاء bucket)
SELECT name, size, updated_at 
FROM storage.objects 
WHERE bucket_id = 'checkins';

-- ========================================
-- 4. إضافة بيانات اختبار (اختياري)
-- ========================================

-- إضافة سجل اختبار مع مسارات صور صحيحة
INSERT INTO checkins (
    serial,
    driver_id,
    before_path,
    after_path,
    lat,
    lon,
    country,
    city,
    district,
    street,
    full_address,
    notes,
    status,
    created_at
) VALUES (
    999,
    'test_driver',
    'test_before.jpg',
    'test_after.jpg',
    28.399210,
    45.974156,
    'Saudi Arabia',
    'Hafar Al Batin',
    'Test District',
    'Test Street',
    'Test Full Address',
    'سجل اختبار للصور',
    'active',
    NOW()
);

-- ========================================
-- 5. فحص البيانات المحفوظة
-- ========================================

-- فحص جميع السجلات
SELECT 
    id,
    serial,
    driver_id,
    before_path,
    after_path,
    lat,
    lon,
    country,
    city,
    created_at,
    status
FROM checkins 
ORDER BY created_at DESC 
LIMIT 10;

-- فحص السجلات بدون صور
SELECT 
    id,
    serial,
    driver_id,
    before_path,
    after_path
FROM checkins 
WHERE before_path IS NULL 
   OR after_path IS NULL 
   OR before_path = '' 
   OR after_path = '';

-- ========================================
-- 6. تحديث السجلات الموجودة (اختياري)
-- ========================================

-- تحديث السجلات التي لا تحتوي على مسارات صور
UPDATE checkins 
SET 
    before_path = 'default_before.jpg',
    after_path = 'default_after.jpg'
WHERE before_path IS NULL 
   OR after_path IS NULL 
   OR before_path = '' 
   OR after_path = '';

-- ========================================
-- 7. إنشاء جدول للصور (اختياري)
-- ========================================

-- إنشاء جدول منفصل لتتبع الصور
CREATE TABLE IF NOT EXISTS checkin_images (
    id SERIAL PRIMARY KEY,
    checkin_id INTEGER REFERENCES checkins(id) ON DELETE CASCADE,
    image_type VARCHAR(20) NOT NULL CHECK (image_type IN ('before', 'after')),
    file_path VARCHAR(255) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء index للبحث السريع
CREATE INDEX IF NOT EXISTS idx_checkin_images_checkin_id 
ON checkin_images(checkin_id);

CREATE INDEX IF NOT EXISTS idx_checkin_images_type 
ON checkin_images(image_type);

-- ========================================
-- 8. فحص الأخطاء المحتملة
-- ========================================

-- فحص السجلات مع أخطاء في المسارات
SELECT 
    id,
    serial,
    driver_id,
    before_path,
    after_path,
    CASE 
        WHEN before_path IS NULL OR before_path = '' THEN 'قبل: فارغ'
        WHEN before_path NOT LIKE '%.jpg' AND before_path NOT LIKE '%.png' AND before_path NOT LIKE '%.jpeg' THEN 'قبل: صيغة غير مدعومة'
        ELSE 'قبل: صحيح'
    END as before_status,
    CASE 
        WHEN after_path IS NULL OR after_path = '' THEN 'بعد: فارغ'
        WHEN after_path NOT LIKE '%.jpg' AND after_path NOT LIKE '%.png' AND after_path NOT LIKE '%.jpeg' THEN 'بعد: صيغة غير مدعومة'
        ELSE 'بعد: صحيح'
    END as after_status
FROM checkins 
WHERE before_path IS NULL 
   OR after_path IS NULL 
   OR before_path = '' 
   OR after_path = ''
   OR before_path NOT LIKE '%.jpg' 
   OR before_path NOT LIKE '%.png' 
   OR before_path NOT LIKE '%.jpeg'
   OR after_path NOT LIKE '%.jpg' 
   OR after_path NOT LIKE '%.png' 
   OR after_path NOT LIKE '%.jpeg';

-- ========================================
-- 9. تنظيف البيانات (اختياري)
-- ========================================

-- حذف السجلات التجريبية
DELETE FROM checkins WHERE serial = 999;

-- حذف السجلات بدون صور (إذا كنت متأكداً)
-- DELETE FROM checkins WHERE before_path IS NULL OR after_path IS NULL;

-- ========================================
-- 10. إعادة تعيين التسلسل (إذا لزم الأمر)
-- ========================================

-- إعادة تعيين التسلسل التلقائي
-- SELECT setval('checkins_id_seq', (SELECT MAX(id) FROM checkins));

-- ========================================
-- ملاحظات مهمة:
-- ========================================

/*
1. لا يمكن إنشاء bucket عبر SQL - يجب إنشاؤه من Dashboard
2. تأكد من تفعيل RLS policies بعد إنشاء bucket
3. اختبر الوصول للتخزين قبل رفع الصور
4. احتفظ بنسخة احتياطية من البيانات قبل التحديث
5. اختبر التطبيق بعد كل خطوة
*/

-- ========================================
-- رسالة نجاح
-- ========================================

SELECT 'تم إنشاء جميع الأوامر بنجاح! تأكد من إنشاء bucket من Dashboard أولاً.' as message;
