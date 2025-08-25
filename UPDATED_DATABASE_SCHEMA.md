# 🗄️ **هيكل قاعدة البيانات المحدث**

## 📋 **جدول `managers` - الهيكل الكامل:**

### **الأعمدة الأساسية:**
| العمود | النوع | القيمة الافتراضية | الوصف |
|--------|-------|-------------------|--------|
| `id` | `bigserial` | `auto-increment` | المعرف الفريد |
| `username` | `text` | - | اسم المستخدم (فريد) |
| `password` | `text` | - | كلمة المرور |
| `created_at` | `timestamptz` | `now()` | تاريخ الإنشاء |

### **الأعمدة الجديدة المضافة:**
| العمود | النوع | القيمة الافتراضية | الوصف |
|--------|-------|-------------------|--------|
| `full_name` | `text` | `NULL` | الاسم الكامل |
| `email` | `text` | `NULL` | البريد الإلكتروني |
| `phone` | `text` | `NULL` | رقم الهاتف |
| `role` | `text` | `'driver'` | الدور (driver/admin) |
| `department` | `text` | `NULL` | القسم/الإدارة |
| `join_date` | `date` | `CURRENT_DATE` | تاريخ الانضمام |
| `last_login` | `timestamptz` | `NULL` | آخر تسجيل دخول |
| `total_actions` | `integer` | `0` | إجمالي الإجراءات |
| `active_sessions` | `integer` | `0` | الجلسات النشطة |
| `profile_image` | `text` | `NULL` | صورة البروفايل |
| `is_suspended` | `boolean` | `false` | حالة التعليق |

## 🔧 **كيفية التحديث:**

### **الخطوة 1: تشغيل SQL في Supabase**
```sql
-- إضافة الأعمدة الجديدة
DO $$ 
BEGIN
    -- إضافة عمود full_name
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'full_name') THEN
        ALTER TABLE public.managers ADD COLUMN full_name text;
    END IF;
    
    -- إضافة عمود email
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'managers' AND column_name = 'email') THEN
        ALTER TABLE public.managers ADD COLUMN email text;
    END IF;
    
    -- إضافة باقي الأعمدة...
END $$;
```

### **الخطوة 2: تحديث البيانات الموجودة**
```sql
-- تحديث بيانات المستخدمين التجريبيين
UPDATE public.managers 
SET 
    full_name = 'علاء أحمد',
    email = 'alaa@rwaad.com',
    phone = '+966 50 123 4567',
    department = 'إدارة النظام',
    join_date = '2024-01-01',
    total_actions = 156,
    active_sessions = 3
WHERE username = 'alaa';
```

## 📱 **البيانات التجريبية المحدثة:**

### **المستخدم `alaa` (مدير):**
- **full_name:** علاء أحمد
- **email:** alaa@rwaad.com
- **phone:** +966 50 123 4567
- **department:** إدارة النظام
- **join_date:** 2024-01-01
- **total_actions:** 156
- **active_sessions:** 3

### **المستخدم `ahmed_sabry` (سائق):**
- **full_name:** أحمد صبري
- **email:** ahmed@rwaad.com
- **phone:** +966 50 234 5678
- **department:** إدارة الأسطول
- **join_date:** 2024-01-16
- **total_actions:** 89
- **active_sessions:** 1

### **المستخدم `mohammed` (سائق معلق):**
- **full_name:** محمد علي
- **email:** mohammed@rwaad.com
- **phone:** +966 50 345 6789
- **department:** إدارة الأسطول
- **join_date:** 2024-01-17
- **total_actions:** 67
- **active_sessions:** 0

## 🎯 **الميزات الجديدة:**

### **1. بيانات شخصية كاملة:**
- ✅ الاسم الكامل
- ✅ البريد الإلكتروني
- ✅ رقم الهاتف
- ✅ القسم/الإدارة

### **2. تتبع النشاط:**
- ✅ تاريخ الانضمام
- ✅ آخر تسجيل دخول
- ✅ إجمالي الإجراءات
- ✅ الجلسات النشطة

### **3. إدارة الحساب:**
- ✅ صورة البروفايل
- ✅ حالة التعليق
- ✅ الدور والصلاحيات

## 🔍 **التحقق من التحديث:**

### **عرض هيكل الجدول:**
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'managers' 
ORDER BY ordinal_position;
```

### **عرض البيانات:**
```sql
SELECT 
    id, username, full_name, email, phone, role, 
    department, join_date, last_login, total_actions, 
    active_sessions, is_suspended, created_at
FROM public.managers
ORDER BY id;
```

## 🚀 **الميزات المستقبلية:**

### **يمكن إضافة:**
- **تعديل البيانات الشخصية**
- **رفع صورة بروفايل**
- **تتبع النشاطات**
- **إعدادات الإشعارات**
- **سجل العمليات**

## ⚠️ **ملاحظات مهمة:**

1. **الأعمدة الجديدة** تسمح بـ `NULL` كقيمة افتراضية
2. **البيانات الموجودة** ستحتفظ بقيمها الحالية
3. **المستخدمين الجدد** سيحصلون على قيم افتراضية مناسبة
4. **صفحة بيانات المدير** ستعرض البيانات الحقيقية من قاعدة البيانات

---

**🎉 تم تحديث قاعدة البيانات بنجاح! الآن صفحة بيانات المدير تعرض البيانات الحقيقية من قاعدة البيانات.**



