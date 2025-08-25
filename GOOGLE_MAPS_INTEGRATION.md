# تكامل Google Maps في صفحة تفاصيل السجل

## 🎯 **ما تم إضافته:**

### **1. زر فتح Google Maps:**
- ✅ **موقع الزر:** أسفل قسم تفاصيل الموقع
- ✅ **التصميم:** زر أزرق أنيق مع أيقونة خريطة
- ✅ **الوظيفة:** فتح Google Maps للموقع المحدد

### **2. استيراد url_launcher:**
```dart
import 'package:url_launcher/url_launcher.dart';
```

## 🔧 **الوظائف الجديدة:**

### **1. دالة `_openGoogleMaps()`:**
```dart
Future<void> _openGoogleMaps() async {
  try {
    // الحصول على إحداثيات الموقع
    String? lat, lon;
    
    if (widget.checkinRecord['lat'] != null && widget.checkinRecord['lon'] != null) {
      lat = widget.checkinRecord['lat'].toString();
      lon = widget.checkinRecord['lon'].toString();
    } else if (widget.checkinRecord['latitude'] != null && widget.checkinRecord['longitude'] != null) {
      lat = widget.checkinRecord['latitude'].toString();
      lon = widget.checkinRecord['longitude'].toString();
    }

    if (lat != null && lon != null) {
      // إنشاء رابط Google Maps
      final url = 'https://www.google.com/maps?q=$lat,$lon';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // رسالة خطأ
      }
    } else {
      // رسالة عدم وجود إحداثيات
    }
  } catch (e) {
    // معالجة الأخطاء
  }
}
```

### **2. منطق عرض الزر:**
```dart
// زر فتح Google Maps
if ((widget.checkinRecord['lat'] != null && widget.checkinRecord['lon'] != null) ||
    (widget.checkinRecord['latitude'] != null && widget.checkinRecord['longitude'] != null)) ...[
  const SizedBox(height: 20),
  Center(
    child: ElevatedButton.icon(
      onPressed: _openGoogleMaps,
      // ... تصميم الزر
    ),
  ),
],
```

## 📱 **واجهة المستخدم:**

### **1. تصميم الزر:**
- **اللون:** أزرق `#4F46E5`
- **النص:** أبيض
- **الأيقونة:** `Icons.map`
- **النص:** "فتح في Google Maps"
- **الشكل:** زوايا دائرية مع ظلال

### **2. موقع الزر:**
- **الموضع:** أسفل تفاصيل الموقع
- **المحاذاة:** في المنتصف
- **المسافة:** 20px من الأعلى

### **3. شروط الظهور:**
- **يظهر فقط** إذا كانت هناك إحداثيات متاحة
- **يدعم** كلا من `lat/lon` و `latitude/longitude`
- **يختفي** إذا لم تكن هناك إحداثيات

## 🗺️ **كيفية عمل Google Maps:**

### **1. إنشاء الرابط:**
```dart
final url = 'https://www.google.com/maps?q=$lat,$lon';
```

### **2. فتح التطبيق:**
```dart
await launchUrl(
  Uri.parse(url),
  mode: LaunchMode.externalApplication,
);
```

### **3. معالجة الأخطاء:**
- **عدم وجود إحداثيات:** رسالة برتقالية
- **خطأ في الفتح:** رسالة حمراء
- **لا يمكن الفتح:** رسالة حمراء

## 📊 **البيانات المدعومة:**

### **من جدول `checkins`:**
```json
{
  "lat": "28.399226",
  "lon": "45.974155",
  "latitude": "28.399226",
  "longitude": "45.974155"
}
```

### **أولوية الإحداثيات:**
1. **الأولوية الأولى:** `lat` و `lon`
2. **الأولوية الثانية:** `latitude` و `longitude`
3. **إذا لم توجد:** لا يظهر الزر

## ⚠️ **متطلبات التطبيق:**

### **1. إضافة url_launcher:**
```yaml
dependencies:
  url_launcher: ^6.1.14
```

### **2. صلاحيات Android:**
```xml
<!-- في android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

### **3. صلاحيات iOS:**
```xml
<!-- في ios/Runner/Info.plist -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
</array>
```

## 🚀 **كيفية الاستخدام:**

### **1. في صفحة تفاصيل السجل:**
- **انتقل** إلى قسم "تفاصيل الموقع"
- **ابحث** عن زر "فتح في Google Maps"
- **اضغط** على الزر
- **انتظر** فتح Google Maps

### **2. في Google Maps:**
- **سيتم فتح** التطبيق أو الموقع
- **سيظهر** الموقع محدداً
- **يمكنك** رؤية الموقع على الخريطة
- **يمكنك** الحصول على الاتجاهات

### **3. العودة للتطبيق:**
- **اضغط** زر العودة
- **ستعود** لصفحة التفاصيل
- **يمكنك** الاستمرار في التصفح

## 🔍 **استكشاف الأخطاء:**

### **إذا لم يظهر الزر:**
1. تحقق من **وجود إحداثيات** في قاعدة البيانات
2. تأكد من **أسماء الأعمدة** صحيحة
3. راجع **قيم البيانات** ليست `NULL`

### **إذا لم يفتح Google Maps:**
1. تحقق من **اتصال الإنترنت**
2. تأكد من **تثبيت Google Maps**
3. راجع **صلاحيات التطبيق**

### **إذا ظهرت رسالة خطأ:**
1. اقرأ **رسالة الخطأ** بعناية
2. تحقق من **Console** للتفاصيل
3. تأكد من **صحة الإحداثيات**

## 🎯 **الخطوات التالية:**

### **1. اختبار التطبيق:**
- افتح صفحة تفاصيل السجل
- تأكد من ظهور زر Google Maps
- اضغط على الزر
- تحقق من فتح الخريطة

### **2. اختبار البيانات:**
- تأكد من وجود إحداثيات صحيحة
- اختبر مع البيانات القديمة والجديدة
- تحقق من معالجة القيم الفارغة

### **3. اختبار الأخطاء:**
- اختبر مع إحداثيات غير صحيحة
- تحقق من رسائل الخطأ
- تأكد من معالجة الاستثناءات

---

**الآن يمكن للمدير فتح Google Maps لأي موقع محدد في سجلات السائقين!** 🗺️

**الميزات الجديدة:**
- ✅ **زر Google Maps** - تصميم أنيق
- ✅ **فتح خارجي** - في التطبيق أو الموقع
- ✅ **معالجة أخطاء** - رسائل واضحة
- ✅ **دعم متعدد** - lat/lon و latitude/longitude
- ✅ **ذكي** - يظهر فقط عند توفر الإحداثيات
- ✅ **سهولة الاستخدام** - نقرة واحدة لفتح الخريطة
