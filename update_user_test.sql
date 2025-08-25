-- تحديث بيانات المستخدم alaa إلى alaasabry
-- تحديث اسم المستخدم
UPDATE managers 
SET username = 'alaasabry' 
WHERE username = 'alaa';

-- تحديث كلمة المرور (في التطبيق الحقيقي يجب تشفيرها)
UPDATE managers 
SET password = 'alaa123' 
WHERE username = 'alaasabry';

-- التحقق من التحديث
SELECT id, username, role, created_at, is_suspended 
FROM managers 
WHERE username IN ('alaa', 'alaasabry');

