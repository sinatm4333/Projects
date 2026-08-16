# تحلیل کد Lua - بات Teamyar

## ساختار کلی کد

این کد یک اسکریپت Lua است که برای یک بات (احتمالاً Telegram یا پلتفرم مشابه) نوشته شده و گزارش‌های تحلیلی از دیتابیس تولید می‌کند.

---

## 1. متغیرهای اولیه

```lua
local myArray = {}           -- آرایه اصلی برای داده‌های جدول اصلی
local myArrayParts = {}      -- آرایه برای قطعات مصرفی
```

---

## 2. HTML Templates

### 2.1. `Res_chart` - جدول اصلی با JavaScript
- **ساختار**: HTML کامل با `<table>`, `<style>`, و `<script>`
- **ویژگی خاص**: استفاده از JavaScript برای رندر داینامیک ردیف‌ها
- **نحوه اتصال**: 
  - داده‌ها از طریق `json.encode(myArray)` به JavaScript پاس داده می‌شوند
  - در JavaScript: `var data = %s` که `%s` با JSON جایگزین می‌شود
  - JavaScript ردیف‌ها را در `<tbody id="result">` می‌سازد

```javascript
// در JavaScript:
var data = %s  // %s با json.encode(myArray) جایگزین می‌شود
// سپس ردیف‌ها ساخته می‌شوند و در innerHTML قرار می‌گیرند
document.getElementById('result').innerHTML = str;
```

### 2.2. سایر Templates (String Concatenation)
- `htmlReportedFaultyByCustomer`
- `htmlUsedParts`
- `htmlReturnContract`
- `htmlDoneRepairs`

**نحوه اتصال**: این templates به صورت رشته‌ای (string concatenation) ساخته می‌شوند:
```lua
htmlReportedFaultyByCustomer = htmlReportedFaultyByCustomer .. string.format([[...]], ...)
```

---

## 3. دریافت Input

```lua
local input = teamyar.get_input()
local productcode = input["productcode"]
```

---

## 4. کوئری‌های SQL

### 4.1. `filetimeQuery`
```sql
SELECT REPORT_FN_GDATE_TO_FILETIME(YEAR(NOW()),MONTH(NOW()),DAY(NOW())) as currentfiletime
```
- **هدف**: دریافت filetime فعلی
- **استفاده**: برای مقایسه تاریخ‌ها در کوئری اصلی

### 4.2. `query` - کوئری اصلی
**پیچیدگی**: بسیار پیچیده با چندین subquery

**ساختار**:
- Subquery داخلی (`kk`): گروه‌بندی گارانتی‌ها بر اساس `PRODUCT_ID` و `ATTRIBUTE_ID`
- Subquery میانی (`k`): محاسبه آمار بازگشتی
- Query اصلی: انتخاب فیلدهای نهایی

**فیلدهای خروجی**:
1. `FULL_CODE` - کد کالا
2. `Model` - مدل
3. `Attribute` - ویژگی
4. `CountOFWarranty` - تعداد گارانتی صادره
5. `AllReceipts` - کل پذیرش‌های خدمات
6. `TotalReturnRate` - درصد بازگشتی کل
7. `WarrantyReturnRate` - درصد بازگشتی تحت گارانتی

**پارامتر**: `productcode` (WHERE pr.FULL_CODE = ?)

### 4.3. `queryReportedFaultyByCustomer`
```sql
SELECT prResid.FULL_CODE, prResid.full_name, PM_BREAK_DOWN.NAME AS FaultyReason, 
       COUNT(PM_SR_BD.BREAK_DOWN_MODE_ID) AS Qty 
FROM PM_SR_BD ...
WHERE prResid.FULL_CODE = ?
GROUP BY ...
```
- **هدف**: اشکالات اعلامی توسط مشتریان
- **پارامتر**: `productcode`

### 4.4. `queryusedparts`
**پیچیدگی**: UNION ALL با دو query مشابه

**ساختار**:
- Query اول: `REF_TYPE = 101` (مستقیم از service request)
- Query دوم: `REF_TYPE = 109` (از طریق cost declaration)
- **پارامتر**: `productcode` (دو بار استفاده می‌شود)

### 4.5. `queryDoneRepairs`
```sql
SELECT final.FULL_CODE, final.full_name, final.Tamir, COUNT(final.Tamir) Faravani
FROM (SELECT ... FROM pm_service_request ... WHERE wp.FULL_CODE=?) AS final
GROUP BY ...
```
- **هدف**: تعمیرات انجام شده
- **پارامتر**: `productcode`

### 4.6. `queryContractReturn`
```sql
SELECT k.*, (k.ReturnQty / k.WarrantyQty) * 100 AS ReturnRatePercent
FROM (SELECT LEFT(pm_service_request.PRODUCT_SERIAL, 9) AS Contract, ...) AS k
WHERE k.WarrantyQty >= 100
```
- **هدف**: بازگشتی به تفکیک قرارداد (9 کاراکتر اول سریال)
- **فیلتر**: فقط قراردادهایی با حداقل 100 گارانتی

---

## 5. نحوه اجرای کوئری‌ها

### الگوی کلی:
```lua
db.use_db("0000000")  -- انتخاب دیتابیس
local param = {
    query = query,
    params = {productcode}  -- یا {productcode, productcode} برای queryusedparts
}
db.query(param)  -- اجرای کوئری

local result = {}
while db.query_fetch(result) do
    -- پردازش هر ردیف
    -- result[1], result[2], ... فیلدهای خروجی
end
```

### مثال از کد:
```lua
db.use_db("0000000")
local param1 = {
    query = query,
    params = {productcode}
}
db.query(param1)
local result = {}

while db.query_fetch(result) do
    -- تحلیل بازگشتی
    local returnanalyze = "قابل قبول"
    if tonumber(result[6]) > 3 then returnanalyze = "هشدار" end
    if tonumber(result[6]) >= 7 then returnanalyze = "بحرانی" end
    
    -- افزودن به آرایه
    table.insert(myArray, {
        result[1], result[2], result[3],
        string.format("%d", tonumber(result[4])),
        string.format("%d", tonumber(result[5])),
        string.format("%.1f", tonumber(result[6])),
        string.format("%.1f", tonumber(result[7])),
        returnanalyze
    })
end
```

---

## 6. اتصال داده‌ها به HTML

### روش 1: JavaScript + JSON (برای جدول اصلی)
```lua
local formattedChart = string.format(Res_chart, json.encode(myArray))
teamyar.write_result(formattedChart)
```

**فرآیند**:
1. `myArray` با `json.encode()` به JSON تبدیل می‌شود
2. JSON در جای `%s` در template قرار می‌گیرد
3. JavaScript در مرورگر داده را می‌خواند و جدول را می‌سازد

### روش 2: String Concatenation (برای سایر جداول)
```lua
htmlReportedFaultyByCustomer = htmlReportedFaultyByCustomer .. string.format([[
    <tr>
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
    </tr>
]], resultReportedFaultyByCustomer[1], ...)
```

**فرآیند**:
1. هر ردیف به صورت مستقیم به رشته HTML اضافه می‌شود
2. در پایان، closing tags اضافه می‌شوند
3. کل HTML با `teamyar.write_result()` ارسال می‌شود

---

## 7. منطق تحلیل بازگشتی

```lua
local returnanalyze = "قابل قبول"
if tonumber(result[6]) > 3 then returnanalyze = "هشدار" end
if tonumber(result[6]) >= 7 then returnanalyze = "بحرانی" end
```

**محدوده‌ها**:
- **قابل قبول**: <= 3%
- **هشدار**: > 3% و < 7%
- **بحرانی**: >= 7%

این مقدار در ستون 8 جدول قرار می‌گیرد و JavaScript کلاس CSS مناسب را اعمال می‌کند:
- `acceptable` (آبی روشن)
- `warning` (زرد)
- `critical` (قرمز)

---

## 8. خروجی نهایی

کد 5 گزارش HTML جداگانه تولید می‌کند:
1. **جدول اصلی** (`formattedChart`) - با JavaScript
2. **بازگشتی به تفکیک قرارداد** (`htmlReturnContract`)
3. **اشکالات اعلامی** (`htmlReportedFaultyByCustomer`)
4. **قطعات مصرفی** (`htmlUsedParts`)
5. **تعمیرات انجام شده** (`htmlDoneRepairs`)

هر کدام با `teamyar.write_result()` ارسال می‌شوند.

---

## 9. نکات مهم

### امنیت:
- استفاده از parameterized queries (`params = {productcode}`) - ✅ خوب است
- اما در برخی کوئری‌ها subquery مستقیم استفاده شده که نیاز به بررسی دارد

### کارایی:
- کوئری اصلی بسیار پیچیده با چندین subquery تودرتو
- ممکن است نیاز به بهینه‌سازی داشته باشد

### خطاها:
- بررسی `productcode == nil` انجام شده ✅
- اما خطاهای دیتابیس بررسی نشده

### Cleanup:
- `db.query_free()` در پایان فراخوانی می‌شود ✅

---

## 10. خلاصه جریان اجرا

```
1. دریافت productcode از input
2. بررسی nil بودن productcode
3. دریافت filetime فعلی
4. اجرای query اصلی → پر کردن myArray
5. اجرای queryReportedFaultyByCustomer → ساخت HTML
6. اجرای queryusedparts → ساخت HTML + پر کردن myArrayParts
7. اجرای queryDoneRepairs → ساخت HTML
8. اجرای queryContractReturn → ساخت HTML
9. ساخت formattedChart با json.encode(myArray)
10. ارسال همه گزارش‌ها با teamyar.write_result()
11. آزادسازی منابع با db.query_free()
```
