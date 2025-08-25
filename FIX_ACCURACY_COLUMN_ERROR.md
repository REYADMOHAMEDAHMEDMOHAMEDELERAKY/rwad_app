# 🔧 **إصلاح خطأ عمود accuracy**

## ❌ **المشكلة:**
```
خطأ في حفظ البيانات
PostgrestException(message: Could not find the 'accuracy' column of 'checkins' in the schema cache, code: PGRST204, details: Bad Request, hint: null)
```

## 🔍 **سبب المشكلة:**
التطبيق يحاول حفظ بيانات في أعمدة غير موجودة في جدول `checkins`:
- `accuracy` - دقة الموقع
- `altitude` - الارتفاع
- `speed` - السرعة
- `heading` - الاتجاه
- `driver_id` - معرف السائق
- `notes` - الملاحظات

## ✅ **الحل:**

### **الخطوة 1: تشغيل SQL في Supabase**
اذهب إلى **Supabase Dashboard** → **SQL Editor** وقم بتشغيل الملف:
```
supabase/fix_checkins_table_complete.sql
```

### **الخطوة 2: التحقق من التحديث**
بعد تشغيل SQL، تأكد من أن جميع الأعمدة تم إضافتها:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'checkins' 
ORDER BY ordinal_position;
```

### **الخطوة 3: اختبار التطبيق**
أعد تشغيل التطبيق وجرب التقاط الصور مرة أخرى.

## 📋 **الأعمدة التي سيتم إضافتها:**

| العمود | النوع | الوصف |
|--------|-------|--------|
| `driver_id` | TEXT | معرف السائق |
| `accuracy` | DOUBLE PRECISION | دقة الموقع |
| `altitude` | DOUBLE PRECISION | الارتفاع |
| `speed` | DOUBLE PRECISION | السرعة |
| `heading` | DOUBLE PRECISION | الاتجاه |
| `notes` | TEXT | الملاحظات |
| `created_at` | TIMESTAMPTZ | تاريخ الإنشاء |
| `updated_at` | TIMESTAMPTZ | تاريخ التحديث |
| `status` | TEXT | الحالة |
| `country` | TEXT | الدولة |
| `city` | TEXT | المدينة |
| `district` | TEXT | الحي |
| `street` | TEXT | الشارع |
| `full_address` | TEXT | العنوان الكامل |
| `latitude` | TEXT | خط العرض |
| `longitude` | TEXT | خط الطول |

## 🚀 **بعد الإصلاح:**
- ✅ لن تظهر رسالة الخطأ
- ✅ سيتم حفظ البيانات بنجاح
- ✅ ستظهر رسالة "تم حفظ البيانات بنجاح"
- ✅ سيتم عرض دقة الموقع في الواجهة

## 📱 **ملاحظات:**
- جميع الأعمدة الجديدة تسمح بـ `NULL` كقيمة افتراضية
- البيانات الموجودة ستحتفظ بقيمها الحالية
- سيتم إنشاء فهارس للبحث السريع

---

**🎯 المشكلة في قاعدة البيانات وليس في كود Flutter. بعد تشغيل SQL سيتم حل المشكلة بالكامل.**
