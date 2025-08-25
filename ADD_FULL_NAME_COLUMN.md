# 🗃️ **إضافة عمود `full_name` إلى قاعدة البيانات**

## 🎯 **الهدف:**
إضافة عمود `full_name` (الاسم الكامل) إلى جدول `managers` في قاعدة البيانات Supabase.

## 📋 **الأعمدة التي سيتم إضافتها:**

| العمود | النوع | القيمة الافتراضية | الوصف |
|--------|-------|-------------------|--------|
| `role` | `text` | `'driver'` | الدور (سائق/مدير) |
| `is_suspended` | `boolean` | `false` | حالة التعليق |
| `full_name` | `text` | `NULL` | الاسم الكامل |
| `phone` | `text` | `NULL` | رقم الهاتف |
| `join_date` | `date` | `CURRENT_DATE` | تاريخ الانضمام |

## 🔧 **الخطوات:**

### **الخطوة 1: فتح Supabase Dashboard**
1. اذهب إلى [supabase.com](https://supabase.com)
2. سجل دخولك إلى حسابك
3. اختر مشروعك `rwaad_app`

### **الخطوة 2: فتح SQL Editor**
1. من القائمة الجانبية، اضغط على **"SQL Editor"**
2. اضغط على **"New query"** لإنشاء استعلام جديد

### **الخطوة 3: نسخ ولصق الكود**
انسخ الكود التالي والصقه في SQL Editor:

```sql
-- إضافة عمود full_name إلى جدول managers
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

-- إضافة عمود full_name (الاسم الكامل)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'full_name') THEN
        ALTER TABLE public.managers ADD COLUMN full_name text;
        RAISE NOTICE 'تم إضافة عمود full_name بنجاح';
    ELSE
        RAISE NOTICE 'عمود full_name موجود بالفعل';
    END IF;
END $$;

-- إضافة عمود phone (رقم الهاتف)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'phone') THEN
        ALTER TABLE public.managers ADD COLUMN phone text;
        RAISE NOTICE 'تم إضافة عمود phone بنجاح';
    ELSE
        RAISE NOTICE 'عمود phone موجود بالفعل';
    END IF;
END $$;

-- إضافة عمود join_date (تاريخ الانضمام)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'join_date') THEN
        ALTER TABLE public.managers ADD COLUMN join_date date DEFAULT CURRENT_DATE;
        RAISE NOTICE 'تم إضافة عمود join_date بنجاح';
    ELSE
        RAISE NOTICE 'عمود phone موجود بالفعل';
    END IF;
END $$;

-- تحديث المستخدمين الموجودين ليكون لديهم دور افتراضي
UPDATE public.managers 
SET role = 'admin' 
WHERE username = 'admin' AND (role IS NULL OR role = '');

UPDATE public.managers 
SET role = 'driver' 
WHERE role IS NULL OR role = '';

-- تعيين is_suspended = false للمستخدمين الموجودين
UPDATE public.managers 
SET is_suspended = false 
WHERE is_suspended IS NULL;

-- تحديث البيانات الافتراضية للمستخدمين التجريبيين
UPDATE public.managers 
SET 
    full_name = 'علاء أحمد',
    phone = '+966 50 123 4567',
    join_date = '2024-01-01'
WHERE username = 'alaa';

UPDATE public.managers 
SET 
    full_name = 'أحمد صبري',
    phone = '+966 50 234 5678',
    join_date = '2024-01-16'
WHERE username = 'ahmed_sabry';

UPDATE public.managers 
SET 
    full_name = 'محمد علي',
    phone = '+966 50 345 6789',
    join_date = '2024-01-17'
WHERE username = 'mohammed';

-- عرض هيكل الجدول المحدث
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'managers' 
ORDER BY ordinal_position;

-- عرض البيانات الحالية
SELECT 
    id, 
    username, 
    full_name,
    phone,
    role, 
    join_date,
    is_suspended, 
    created_at
FROM public.managers
ORDER BY id;
```

### **الخطوة 4: تشغيل الكود**
1. اضغط على زر **"Run"** (▶️)
2. انتظر حتى يكتمل التنفيذ
3. تحقق من الرسائل في **"Messages"** tab

### **الخطوة 5: التحقق من النتائج**
ستظهر لك رسائل تؤكد إضافة الأعمدة:
- ✅ `تم إضافة عمود full_name بنجاح`
- ✅ `تم إضافة عمود phone بنجاح`
- ✅ `تم إضافة عمود join_date بنجاح`

## 📊 **النتائج المتوقعة:**

### **هيكل الجدول الجديد:**
| العمود | النوع | القيمة الافتراضية | الوصف |
|--------|-------|-------------------|--------|
| `id` | `bigserial` | `auto-increment` | المعرف الفريد |
| `username` | `text` | - | اسم المستخدم |
| `password` | `text` | - | كلمة المرور |
| `role` | `text` | `'driver'` | الدور |
| `is_suspended` | `boolean` | `false` | حالة التعليق |
| `full_name` | `text` | `NULL` | الاسم الكامل |
| `phone` | `text` | `NULL` | رقم الهاتف |
| `join_date` | `date` | `CURRENT_DATE` | تاريخ الانضمام |
| `created_at` | `timestamptz` | `now()` | تاريخ الإنشاء |

### **البيانات المحدثة:**
| المستخدم | الاسم الكامل | رقم الهاتف | الدور | تاريخ الانضمام |
|-----------|--------------|-------------|-------|-----------------|
| `alaa` | علاء أحمد | +966 50 123 4567 | admin | 2024-01-01 |
| `ahmed_sabry` | أحمد صبري | +966 50 234 5678 | driver | 2024-01-16 |
| `mohammed` | محمد علي | +966 50 345 6789 | driver | 2024-01-17 |

## 🔍 **اختبار النجاح:**

### **1. التحقق من الأعمدة:**
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'managers' 
ORDER BY ordinal_position;
```

### **2. التحقق من البيانات:**
```sql
SELECT 
    id, 
    username, 
    full_name,
    phone,
    role, 
    join_date,
    is_suspended, 
    created_at
FROM public.managers
ORDER BY id;
```

### **3. التحقق من وجود عمود full_name:**
```sql
SELECT full_name FROM public.managers WHERE username = 'alaa';
```

## ⚠️ **ملاحظات مهمة:**

1. **الأعمدة الجديدة** تسمح بـ `NULL` كقيمة افتراضية
2. **البيانات الموجودة** ستحتفظ بقيمها الحالية
3. **المستخدمين الجدد** سيحصلون على قيم افتراضية مناسبة
4. **صفحة إدارة المستخدمين** ستعمل بدون أخطاء

## 🚀 **بعد إضافة الأعمدة:**

1. **أعد تشغيل التطبيق** Flutter
2. **جرب إضافة مستخدم جديد** في صفحة إدارة المستخدمين
3. **تحقق من عدم ظهور أخطاء** عند الحفظ
4. **تحقق من عرض البيانات** في قائمة المستخدمين

## 🔧 **استكشاف الأخطاء:**

### **إذا ظهر خطأ:**
- **تحقق من اسم الجدول** - يجب أن يكون `managers`
- **تحقق من الصلاحيات** - يجب أن يكون لديك صلاحيات ALTER
- **تحقق من الاتصال** - تأكد من الاتصال بقاعدة البيانات

### **إذا لم تظهر الأعمدة:**
- **أعد تشغيل الكود** مرة أخرى
- **تحقق من الرسائل** في Messages tab
- **استخدم استعلام التحقق** أعلاه

---

**🎉 بعد إضافة الأعمدة، ستتمكن من حفظ وعرض الأسماء الكاملة وأرقام الهواتف للمستخدمين!**



