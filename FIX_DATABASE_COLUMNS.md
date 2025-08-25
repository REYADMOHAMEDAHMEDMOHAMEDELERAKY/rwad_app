# 🔧 **إصلاح مشكلة الأعمدة غير الموجودة**

## 🚨 **المشكلة:**
عند محاولة حفظ بيانات المستخدم، يظهر خطأ يشير إلى أن هناك أعمدة لا توجد في قاعدة البيانات.

## ✅ **الحل:**

### **الخطوة 1: تشغيل SQL الإصلاح**
قم بتشغيل الملف التالي في **Supabase SQL Editor**:

```sql
-- إصلاح جدول managers - إضافة الأعمدة المطلوبة فقط
-- قم بتشغيل هذا الملف في Supabase SQL Editor

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

-- إضافة الأعمدة الجديدة لبيانات المدير الكاملة
DO $$ 
BEGIN
    -- إضافة عمود full_name (الاسم الكامل)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'full_name') THEN
        ALTER TABLE public.managers ADD COLUMN full_name text;
    END IF;
    
    -- إضافة عمود email (البريد الإلكتروني)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'email') THEN
        ALTER TABLE public.managers ADD COLUMN email text;
    END IF;
    
    -- إضافة عمود phone (رقم الهاتف)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'phone') THEN
        ALTER TABLE public.managers ADD COLUMN phone text;
    END IF;
    
    -- إضافة عمود department (القسم/الإدارة)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'department') THEN
        ALTER TABLE public.managers ADD COLUMN department text;
    END IF;
    
    -- إضافة عمود join_date (تاريخ الانضمام)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'join_date') THEN
        ALTER TABLE public.managers ADD COLUMN join_date date DEFAULT CURRENT_DATE;
    END IF;
END $$;
```

### **الخطوة 2: التحقق من التحديث**
```sql
-- عرض هيكل الجدول
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'managers' 
ORDER BY ordinal_position;
```

### **الخطوة 3: إعادة تشغيل التطبيق**

## 📋 **الأعمدة الموجودة الآن:**

| العمود | النوع | القيمة الافتراضية | الوصف |
|--------|-------|-------------------|--------|
| `id` | `bigserial` | `auto-increment` | المعرف الفريد |
| `username` | `text` | - | اسم المستخدم |
| `password` | `text` | - | كلمة المرور |
| `role` | `text` | `'driver'` | الدور |
| `is_suspended` | `boolean` | `false` | حالة التعليق |
| `full_name` | `text` | `NULL` | الاسم الكامل |
| `email` | `text` | `NULL` | البريد الإلكتروني |
| `phone` | `text` | `NULL` | رقم الهاتف |
| `department` | `text` | `NULL` | القسم |
| `join_date` | `date` | `CURRENT_DATE` | تاريخ الانضمام |
| `created_at` | `timestamptz` | `now()` | تاريخ الإنشاء |

## 🔍 **الأعمدة التي تم إزالتها من الكود:**

تم إزالة الأعمدة التالية من الكود لأنها غير موجودة في قاعدة البيانات:
- ❌ `total_actions` - إجمالي الإجراءات
- ❌ `active_sessions` - الجلسات النشطة
- ❌ `last_login` - آخر تسجيل دخول
- ❌ `profile_image` - صورة البروفايل

## 🎯 **البيانات التي سيتم حفظها:**

عند إضافة مستخدم جديد، سيتم حفظ:
- ✅ **اسم المستخدم**
- ✅ **كلمة المرور**
- ✅ **الدور** (سائق/مدير)
- ✅ **حالة التعليق** (false)
- ✅ **الاسم الكامل**
- ✅ **البريد الإلكتروني**
- ✅ **رقم الهاتف**
- ✅ **القسم**
- ✅ **تاريخ الانضمام**

## 🚀 **الميزات المستقبلية:**

إذا أردت إضافة الأعمدة المحذوفة لاحقاً، يمكنك:
1. **إضافة الأعمدة** في قاعدة البيانات
2. **تحديث الكود** ليشملها
3. **إضافة واجهات** لإدارة هذه البيانات

## ⚠️ **ملاحظات مهمة:**

1. **الأعمدة الجديدة** تسمح بـ `NULL` كقيمة افتراضية
2. **البيانات الموجودة** ستحتفظ بقيمها الحالية
3. **المستخدمين الجدد** سيحصلون على قيم افتراضية مناسبة
4. **صفحة إدارة المستخدمين** ستعمل بدون أخطاء

## 🔍 **اختبار الحل:**

### **الخطوات:**
1. **شغل SQL الإصلاح** في Supabase
2. **أعد تشغيل التطبيق**
3. **جرب إضافة مستخدم جديد**
4. **تحقق من عدم ظهور أخطاء**

### **النتائج المتوقعة:**
- ✅ عدم ظهور أخطاء عند الحفظ
- ✅ حفظ جميع البيانات المطلوبة
- ✅ عرض البيانات بشكل صحيح
- ✅ عمل جميع الميزات

---

**🎉 تم إصلاح المشكلة! الآن صفحة إدارة المستخدمين ستعمل بدون أخطاء.**



