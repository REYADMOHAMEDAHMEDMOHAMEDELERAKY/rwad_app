# 🛠️ **دليل إعداد نظام الإشعارات**
# **Notification System Setup Guide**

## 🚨 **المشكلة / Problem**
لم تصل اشعارات للمديرين ولم يتم انشاء جدول الاشعارات
(Notifications are not reaching managers and the notifications table was not created)

## ✅ **الحل المطلوب / Required Solution**

### **الخطوة 1: إنشاء جدول الإشعارات في Supabase**
**Step 1: Create notifications table in Supabase**

1. **افتح Supabase Dashboard** / Open Supabase Dashboard
2. **اذهب إلى SQL Editor** / Go to SQL Editor  
3. **انسخ والصق هذا الكود** / Copy and paste this code:

```sql
-- إعداد بسيط لجدول الإشعارات
-- Simple notifications table setup

-- Step 1: Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'checkin',
    recipient_role TEXT DEFAULT 'admin',
    sender_id TEXT,
    sender_name TEXT,
    checkin_id INTEGER,
    checkin_serial INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Step 3: Create simple policy
CREATE POLICY "Enable all access for authenticated users" ON public.notifications
FOR ALL USING (auth.role() = 'authenticated');

-- Step 4: Insert test notification
INSERT INTO public.notifications (title, message, sender_name, checkin_serial)
VALUES ('اختبار الإشعارات', 'هذا إشعار تجريبي للتأكد من عمل النظام', 'النظام', 0);

-- Step 5: Verify table creation
SELECT 'تم إنشاء جدول notifications بنجاح!' as result;
```

4. **اضغط Run** / Click Run
5. **تأكد من ظهور رسالة النجاح** / Verify success message appears

### **الخطوة 2: التحقق من إنشاء الجدول**
**Step 2: Verify table creation**

```sql
-- Check if table exists and view structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check test notification
SELECT * FROM public.notifications;
```

### **الخطوة 3: اختبار النظام**
**Step 3: Test the system**

1. **قم بتسجيل الدخول كسائق** / Login as driver
2. **أنشئ تسجيل جديد (التقط الصور واحفظ)** / Create new check-in (take photos and save)
3. **تحقق من Console في Flutter للرسائل التالية** / Check Flutter Console for these messages:
   ```
   🔔 محاولة إرسال إشعار...
   Driver: [اسم السائق], Serial: [رقم], Location: [موقع]
   ✅ تم إرسال إشعار بنجاح: تسجيل جديد من السائق
   📄 Result: [بيانات الإشعار]
   ```

4. **قم بتسجيل الدخول كمدير** / Login as manager
5. **تحقق من وجود رقم أحمر على أيقونة الإشعارات** / Check for red badge on notifications icon
6. **اضغط على أيقونة الإشعارات** / Click notifications icon
7. **تأكد من ظهور الإشعار الجديد** / Verify new notification appears

## 🐛 **تشخيص المشاكل / Troubleshooting**

### **إذا لم يتم إنشاء الجدول / If table is not created:**
```sql
-- Force create table with full permissions
DROP TABLE IF EXISTS public.notifications;

CREATE TABLE public.notifications (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'checkin',
    recipient_role TEXT DEFAULT 'admin',
    sender_id TEXT,
    sender_name TEXT,
    checkin_id INTEGER,
    checkin_serial INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Grant all permissions
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO anon;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO anon;
```

### **إذا كانت الإشعارات لا تُرسل / If notifications are not sending:**

1. **تحقق من Flutter Console** / Check Flutter Console:
   ```
   ❌ خطأ في إرسال الإشعار: [تفاصيل الخطأ]
   📋 Error type: [نوع الخطأ]
   ```

2. **تحقق من البيانات في الجدول** / Check data in table:
   ```sql
   SELECT COUNT(*) as total_notifications FROM public.notifications;
   SELECT * FROM public.notifications ORDER BY created_at DESC LIMIT 5;
   ```

3. **تحقق من صلاحيات الجدول** / Check table permissions:
   ```sql
   SELECT grantee, privilege_type 
   FROM information_schema.role_table_grants 
   WHERE table_name = 'notifications';
   ```

### **إذا كان المدير لا يرى الإشعارات / If manager doesn't see notifications:**

1. **تحقق من وجود إشعارات** / Check if notifications exist:
   ```sql
   SELECT COUNT(*) FROM public.notifications WHERE recipient_role = 'admin';
   ```

2. **تحقق من Flutter Console في صفحة المدير** / Check Flutter Console in manager page:
   ```
   📅 جلب الإشعارات...
   📄 تم جلب [عدد] إشعار
   ```

## 🧪 **اختبار سريع / Quick Test**

### **إدراج إشعار تجريبي / Insert test notification:**
```sql
INSERT INTO public.notifications (
    title, 
    message, 
    type, 
    recipient_role, 
    sender_name, 
    checkin_serial
) VALUES (
    'اختبار الإشعارات',
    'هذا إشعار تجريبي للتأكد من عمل النظام',
    'system',
    'admin',
    'النظام',
    999
);
```

### **التحقق من الإشعار التجريبي / Check test notification:**
```sql
SELECT * FROM public.notifications WHERE checkin_serial = 999;
```

## 📱 **خطوات التشغيل النهائية / Final Steps**

1. **تأكد من تنفيذ SQL بنجاح** / Ensure SQL executed successfully
2. **أعد تشغيل التطبيق** / Restart the app
3. **جرب إنشاء تسجيل جديد** / Try creating new check-in
4. **تحقق من Console للرسائل** / Check Console for messages
5. **تحقق من صفحة الإشعارات** / Check notifications page

## 🎯 **النتيجة المتوقعة / Expected Result**

عند إنشاء تسجيل جديد من السائق:
When driver creates new check-in:

1. **رسالة في Console:** `✅ تم إرسال إشعار بنجاح`
2. **رقم أحمر على أيقونة الإشعارات في صفحة المدير**
3. **إشعار جديد في صفحة الإشعارات**
4. **تفاصيل الإشعار تتضمن: اسم السائق، الرقم التسلسلي، الموقع**

**Console message:** `✅ تم إرسال إشعار بنجاح`
**Red badge on notifications icon in manager page**
**New notification in notifications page**
**Notification details include: driver name, serial number, location**

---

## 🆘 **في حالة استمرار المشكلة / If Problem Persists**

إذا لم تعمل الإشعارات بعد تنفيذ الخطوات أعلاه:
If notifications still don't work after following the steps above:

1. **تحقق من اتصال Supabase** / Check Supabase connection
2. **تأكد من صحة API keys** / Verify API keys are correct  
3. **تحقق من RLS policies** / Check RLS policies
4. **راجع Flutter Console للأخطاء** / Review Flutter Console for errors
5. **تأكد من أن المستخدم مصادق عليه** / Ensure user is authenticated

**📞 إذا كنت بحاجة لمساعدة إضافية، أرسل screenshot من:**
**If you need additional help, send screenshot of:**
- Supabase SQL Editor results
- Flutter Console output
- Manager page (notifications icon)
- Notifications page