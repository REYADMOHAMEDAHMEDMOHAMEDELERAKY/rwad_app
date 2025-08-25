# 🔧 حل مشكلة عمود `is_suspended` غير الموجود

## 🚨 **المشكلة:**
عند الضغط على "حفظ التغييرات" في صفحة تفاصيل المستخدم، تظهر رسالة خطأ تقول أن عمود `is_suspended` غير موجود في قاعدة البيانات.

## ✅ **الحل:**

### **الخطوة 1: تحديث قاعدة البيانات**
قم بتشغيل الملف التالي في **Supabase SQL Editor**:

```sql
-- إضافة عمود role إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'role') THEN
        ALTER TABLE public.managers ADD COLUMN role text DEFAULT 'driver';
        ALTER TABLE public.managers ADD CONSTRAINT managers_role_check 
        CHECK (role IN ('driver', 'admin'));
    END IF;
END $$;

-- إضافة عمود is_suspended إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'is_suspended') THEN
        ALTER TABLE public.managers ADD COLUMN is_suspended boolean DEFAULT false;
    END IF;
END $$;

-- تحديث المستخدمين الموجودين
UPDATE public.managers SET role = 'admin' WHERE username = 'admin';
UPDATE public.managers SET role = 'driver' WHERE role IS NULL OR role = '';
UPDATE public.managers SET is_suspended = false WHERE is_suspended IS NULL;
```

### **الخطوة 2: التحقق من التحديث**
```sql
-- عرض هيكل الجدول
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'managers' 
ORDER BY ordinal_position;

-- عرض البيانات
SELECT id, username, role, is_suspended, created_at
FROM public.managers
ORDER BY id;
```

### **الخطوة 3: إعادة تشغيل التطبيق**
بعد تحديث قاعدة البيانات، قم بإعادة تشغيل التطبيق.

## 📋 **الأعمدة المطلوبة في جدول `managers`:**

| العمود | النوع | القيمة الافتراضية | الوصف |
|--------|-------|-------------------|--------|
| `id` | `bigserial` | `auto-increment` | المعرف الفريد |
| `username` | `text` | - | اسم المستخدم |
| `password` | `text` | - | كلمة المرور |
| `role` | `text` | `'driver'` | الدور (driver/admin) |
| `is_suspended` | `boolean` | `false` | حالة التعليق |
| `created_at` | `timestamptz` | `now()` | تاريخ الإنشاء |

## 🎯 **كيفية الوصول إلى Supabase SQL Editor:**

1. **افتح Supabase Dashboard**
2. **اختر مشروعك**
3. **اذهب إلى SQL Editor**
4. **انسخ والصق الكود أعلاه**
5. **اضغط Run**

## 🔍 **التحقق من الحل:**

بعد التحديث، يجب أن تعمل صفحة تفاصيل المستخدم بشكل صحيح:
- ✅ تعديل اسم المستخدم
- ✅ تغيير كلمة المرور
- ✅ تغيير الدور
- ✅ تعليق/إلغاء تعليق النشاط
- ✅ حذف المستخدم

## 📱 **البيانات التجريبية المحدثة:**

| المستخدم | كلمة المرور | الدور | الحالة |
|-----------|-------------|-------|--------|
| `alaa` | `alaa123` | مدير | نشط |
| `ahmed_sabry` | `ahmed123` | سائق | نشط |
| `mohammed` | `mohammed123` | سائق | معلق |

## 🆘 **إذا استمرت المشكلة:**

1. **تحقق من اتصال Supabase**
2. **تأكد من تشغيل SQL بنجاح**
3. **أعد تشغيل التطبيق**
4. **تحقق من Console للأخطاء**

---

**ملاحظة:** تأكد من أن لديك صلاحيات كافية في Supabase لتعديل قاعدة البيانات.




