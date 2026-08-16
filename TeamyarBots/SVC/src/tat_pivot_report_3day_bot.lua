-- تحلیل و ایجاد توسط مهدی جهانی 09125632329
-- نسخه با بازه‌های ۳ روزه (به‌جای ۵ روز)
local myArray = {}

Res_chart = [[
<html dir="rtl" lang="fa">
<h3 style="background-color:#D2E0FB;text-align: center;border:1px dots black;height:120px;weight:100%%;padding-top:5px;shadow;border-radius: 10px;">
<p>گزارش TAT (Turn Around Time) به تفکیک ماه</p>
<p>"فاصله زمانی بر حسب روز از پذیرش تا آماده تحویل"</p>
<p>(بازه‌های ۳ روزه - در صورت وجود هرگونه سوال یا تغییری با شماره 09125632329 تماس حاصل فرمایید)</p>
</h3>
<table>
  <thead>
	  <tr style="background-color:#0073e6;color:white;">
				<th>بازه زمانی (روز)</th>
     			<th>فروردین 1404</th>
				<th>اردیبهشت 1404</th>
                <th>خرداد 1404</th>
                <th>تیر 1404</th>
                <th>مرداد 1404</th>
                <th>شهریور 1404</th>
                <th>مهر 1404</th>
                <th>آبان 1404</th>
                <th>آذر 1404</th>
                <th>دی 1404</th>
                <th>بهمن 1404</th>
                <th>اسفند 1404</th>
                <th>جمع کل</th>
                <th>درصد از کل</th>
	  </tr>
  </thead>
  <tbody id="result">
  </tbody>
</table>

<style>

body {
  font-family: IRANSansWeb_Light, sans-serif;
  font-size:12px;
font-weight: bold;
}

table {
  font-family: IRANSansWeb_Light, sans-serif;
  border-collapse: collapse;
  width: 100%%;
 text-align: center;
 border: 2px solid #000000;
 border-radius: 8px;
}

td, th {
  border: 1px dashed #000000;
  text-align: center;
  padding: 8px;
  text-align: center;
  font-size: 11px;
}

th {
  padding: 12px 8px;
  height: auto;
}

tr:nth-child(even) {
  background-color: #eeeeee;
 text-align: center;
}

.normal {
  background-color: #ffffff;
}

.warning {
  background-color: #ffeb9c; /* زرد برای هشدار */
}

.critical {
  background-color: #ffc7ce; /* قرمز برای بحرانی */
}

.good {
  background-color: #c6efce; /* سبز برای خوب */
}

.total-row {
  background-color: #d9e1f2;
  font-weight: bold;
}

.total-row-header td {
  padding: 15.6px 8px;
}

th:first-child,
td:first-child {
  font-size: 14.3px;
}

th:last-child,
td:last-child {
  font-size: 14.3px;
}

.hover-darken {
  filter: brightness(0.9);
  transition: filter 0.1s ease;
}

.hover-border {
  border: 3px solid black !important;
}

</style>

<script>   
     var data = %s,   
      len = data.length,
      str = '';

// تابع محاسبه رنگ heat map
function getHeatMapColor(value, min, max) {
    if (max === 0 || value === 0) {
        return '#ffffff'; // سفید برای مقادیر صفر
    }
    
    // Normalize مقدار بین 0 تا 1
    var normalized = (value - min) / (max - min);
    
    // محاسبه رنگ از سبز تا آبی تیره (به‌جای قرمز)
    var red, green, blue;
    
    if (normalized < 0.5) {
        // از سبز تا فیروزه‌ای (0 تا 0.5)
        red = 0;
        green = 255;
        blue = Math.floor(255 * normalized * 2);
    } else {
        // از فیروزه‌ای تا آبی (0.5 تا 1)
        red = 0;
        green = Math.floor(255 * (2 - normalized * 2));
        blue = 255;
    }
    
    return 'rgb(' + red + ',' + green + ',' + blue + ')';
}

// محاسبه مجموع هر ستون و همچنین ماکزیمم و مینیمم برای heat map
var columnSums = [];
var columnMax = [];
var columnMin = [];
if (len > 0) {
    var numColumns = data[0].length;
    for (var col = 0; col < numColumns; col++) {
        columnSums[col] = 0;
        columnMax[col] = 0;
        columnMin[col] = Infinity;
        
        for (var row = 0; row < len; row++) {
            if (col == 0) {
                // ستون اول (TAT) - مجموع نمی‌خواهیم
                columnSums[col] = '';
            } else if (col == numColumns - 1) {
                // ستون آخر (درصد) - مجموع نمی‌خواهیم
                columnSums[col] = '';
            } else if (col == numColumns - 2) {
                // ستون جمع کل - مجموع همه ردیف‌ها
                columnSums[col] += parseInt(data[row][col]) || 0;
            } else {
                // ستون‌های ماه
                var cellValue = parseInt(data[row][col]) || 0;
                columnSums[col] += cellValue;
                if (cellValue > columnMax[col]) {
                    columnMax[col] = cellValue;
                }
                if (cellValue < columnMin[col]) {
                    columnMin[col] = cellValue;
                }
            }
        }
        
        // اگر همه مقادیر صفر بودند
        if (columnMin[col] === Infinity) {
            columnMin[col] = 0;
        }
    }
}

// ساخت ردیف header برای مجموع کل
var rowIndex = 0;
str += '<tr class="total-row-header" style="background-color:#4472C4;color:white;font-weight: bold;">';
for (var col = 0; col < columnSums.length; col++) {
    if (col == 0) {
        str += '<td data-row="' + rowIndex + '" data-col="' + col + '">جمع کل</td>';
    } else if (col == columnSums.length - 1) {
        // ساخت tooltip برای ستون درصد در ردیف جمع کل
        var totalTooltipText = 'مجموع تا این سلول: 100.00%%';
        str += '<td data-row="' + rowIndex + '" data-col="' + col + '" title="' + totalTooltipText + '">100.00%%</td>';
    } else if (col == columnSums.length - 2) {
        str += '<td data-row="' + rowIndex + '" data-col="' + col + '" style="background-color:#5B9BD5;">' + columnSums[col] + '</td>';
    } else {
        // ستون‌های ماه - اعمال heat map
        var sumValue = parseInt(columnSums[col]) || 0;
        var heatMapColor = getHeatMapColor(sumValue, columnMin[col], columnMax[col]);
        // ترکیب رنگ heat map با پس‌زمینه آبی تیره برای حفظ خوانایی
        str += '<td data-row="' + rowIndex + '" data-col="' + col + '" style="background: linear-gradient(135deg, ' + heatMapColor + ' 0%%, #4472C4 100%%);">' + columnSums[col] + '</td>';
    }
}
str += '</tr>';
rowIndex++;

// ساخت ردیف‌های داده
for (var i = 0; i < len; i++) {
    // پیدا کردن ماکزیمم در ستون‌های ماه (ستون‌های 1 تا 12)
    var maxValue = 0;
    var maxIndexes = [];
    for (var monthCol = 1; monthCol <= 12; monthCol++) {
        var monthValue = parseInt(data[i][monthCol]) || 0;
        if (monthValue > maxValue) {
            maxValue = monthValue;
            maxIndexes = [monthCol];
        } else if (monthValue === maxValue && maxValue > 0) {
            maxIndexes.push(monthCol);
        }
    }
    
    str += '<tr>';
    
    // محاسبه مجموع درصدهای بالای این ردیف (از ردیف 0 تا ردیف فعلی i)
    var cumulativePercentSum = 0;
    for (var row = 0; row <= i; row++) {
        var rowPercent = parseFloat(data[row][data[row].length - 1]) || 0;
        cumulativePercentSum += rowPercent;
    }
    
    for (var j = 0; j < data[i].length; j++) {
        if (j == 0) { // ستون اول - بازه زمانی
            var tat = data[i][j];
            var displayText = '';
            if (tat == 0) {
                displayText = 'زیر یک روز';
            } else if (tat == 31) {
                displayText = '30+';
            } else {
                displayText = tat + ' روز';
            }
            str += '<td data-row="' + rowIndex + '" data-col="' + j + '" style="font-weight: bold;">' + displayText + '</td>';
        } else if (j == data[i].length - 1) { // ستون آخر - درصد
            var percent = parseFloat(data[i][j]) || 0;
            // ساخت tooltip با مجموع درصدها
            var tooltipText = 'مجموع تا این سلول: ' + cumulativePercentSum.toFixed(2) + '%%';
            str += '<td data-row="' + rowIndex + '" data-col="' + j + '" style="font-weight: bold;" title="' + tooltipText + '">' + percent.toFixed(2) + '%%</td>';
        } else if (j == data[i].length - 2) { // ستون قبل از آخر - جمع کل
            var total = parseInt(data[i][j]) || 0;
            str += '<td data-row="' + rowIndex + '" data-col="' + j + '" class="total-row" style="font-weight: bold;">' + total + '</td>';
        } else {
            // ستون‌های ماه
            var count = parseInt(data[i][j]) || 0;
            var cellStyle = '';
            
            // محاسبه رنگ heat map
            var heatMapColor = getHeatMapColor(count, columnMin[j], columnMax[j]);
            cellStyle = 'background-color: ' + heatMapColor + ';';
            
            // اگر این ستون ماکزیمم است و مقدار بیشتر از 0 دارد، border قرمز
            if (maxIndexes.indexOf(j) !== -1 && maxValue > 0) {
                cellStyle += ' border: 2px solid #ff0000; font-weight: bold;';
            }
            
            str += '<td data-row="' + rowIndex + '" data-col="' + j + '" style="' + cellStyle + '">' + count + '</td>';
        }
    }

    str += '</tr>';
    rowIndex++;
}

document.getElementById('result').innerHTML = str;

// اضافه کردن افکت hover به سلول‌ها
var cells = document.querySelectorAll('#result td');
var totalCols = 0;
if (cells.length > 0) {
    // پیدا کردن تعداد ستون‌ها
    var firstRowCells = document.querySelectorAll('#result tr:first-child td');
    totalCols = firstRowCells.length;
}

cells.forEach(function(cell) {
    cell.addEventListener('mouseenter', function() {
        var row = parseInt(this.getAttribute('data-row'));
        var col = parseInt(this.getAttribute('data-col'));
        
        // تیره کردن و بوردر سلول‌های سطر از ابتدا تا نقطه تقاطع (این ستون)
        var rowCells = document.querySelectorAll('#result td[data-row="' + row + '"]');
        for (var i = 0; i < rowCells.length; i++) {
            var cellCol = parseInt(rowCells[i].getAttribute('data-col'));
            if (cellCol <= col) {
                rowCells[i].classList.add('hover-darken');
                rowCells[i].classList.add('hover-border');
            }
        }
        
        // تیره کردن و بوردر سلول‌های ستون از ابتدا تا نقطه تقاطع (این سطر)
        var colCells = document.querySelectorAll('#result td[data-col="' + col + '"]');
        for (var i = 0; i < colCells.length; i++) {
            var cellRow = parseInt(colCells[i].getAttribute('data-row'));
            if (cellRow <= row) {
                colCells[i].classList.add('hover-darken');
                colCells[i].classList.add('hover-border');
            }
        }
        
        // ستون بازه زمانی از ابتدا تا این سطر
        var timeColCells = document.querySelectorAll('#result td[data-col="0"]');
        for (var i = 0; i < timeColCells.length; i++) {
            var cellRow = parseInt(timeColCells[i].getAttribute('data-row'));
            if (cellRow <= row) {
                timeColCells[i].classList.add('hover-darken');
                timeColCells[i].classList.add('hover-border');
            }
        }
        
        // ستون درصد از ابتدا تا این سطر
        var percentCol = totalCols - 1;
        var percentColCells = document.querySelectorAll('#result td[data-col="' + percentCol + '"]');
        for (var i = 0; i < percentColCells.length; i++) {
            var cellRow = parseInt(percentColCells[i].getAttribute('data-row'));
            if (cellRow <= row) {
                percentColCells[i].classList.add('hover-darken');
                percentColCells[i].classList.add('hover-border');
            }
        }
    });
    
    cell.addEventListener('mouseleave', function() {
        var allCells = document.querySelectorAll('#result td');
        allCells.forEach(function(c) {
            c.classList.remove('hover-darken');
            c.classList.remove('hover-border');
        });
    });
});
</script>

<br><br>

<h3 style="background-color:#D2E0FB;text-align: center;border:1px dots black;height:80px;weight:100%%;padding-top:5px;shadow;border-radius: 10px;">
<p>گزارش آماری TAT بر اساس رسید‌های در دست انجام</p>
</h3>

<table id="summaryTable">
  <thead>
	  <tr style="background-color:#0073e6;color:white;">
				<th>بازه زمانی (روز)</th>
     			<th>تعداد رسید</th>
                <th>درصد از کل</th>
	  </tr>
  </thead>
  <tbody id="summaryResult">
  </tbody>
</table>

<script>
     var summaryData = %s;
     var summaryLen = summaryData.length;
     var summaryStr = '';
     
     if (summaryLen > 0) {
         // محاسبه ماکزیمم و مینیمم برای heat map
         var summaryMax = 0;
         var summaryMin = Infinity;
         var summaryTotal = 0;
         
         for (var i = 0; i < summaryLen; i++) {
             var count = parseInt(summaryData[i][1]) || 0;
             summaryTotal += count;
             if (count > summaryMax) {
                 summaryMax = count;
             }
             if (count < summaryMin) {
                 summaryMin = count;
             }
         }
         
         if (summaryMin === Infinity) {
             summaryMin = 0;
         }
         
         // ساخت ردیف‌ها
         var cumulativeCount = 0;
         var cumulativePercent = 0;
         for (var i = 0; i < summaryLen; i++) {
             var tatLabel = summaryData[i][0];
             var count = parseInt(summaryData[i][1]) || 0;
             cumulativeCount += count;
             cumulativePercent = summaryTotal > 0 ? ((cumulativeCount / summaryTotal) * 100) : 0;
             var percent = summaryTotal > 0 ? ((count / summaryTotal) * 100).toFixed(2) : '0.00';
             
             // محاسبه رنگ heat map
             var heatMapColor = getHeatMapColor(count, summaryMin, summaryMax);
             
             // تولتیپ: مجموع سلول‌های بالای سر تا این سلول
             var tooltipText = 'مجموع تا این سلول: ' + cumulativeCount + ' عدد (' + cumulativePercent.toFixed(2) + '%%)';
             
             summaryStr += '<tr>';
             summaryStr += '<td style="font-weight: bold;">' + tatLabel + '</td>';
             summaryStr += '<td style="background-color: ' + heatMapColor + '; font-weight: bold;" title="' + tooltipText + '">' + count + '</td>';
             summaryStr += '<td style="font-weight: bold;" title="' + tooltipText + '">' + percent + '%%</td>';
             summaryStr += '</tr>';
         }
         
         // ردیف جمع کل
         var totalTooltipText = 'مجموع تا این سلول: ' + summaryTotal + ' عدد (100.00%%)';
         summaryStr += '<tr class="total-row-header" style="background-color:#4472C4;color:white;font-weight: bold;">';
         summaryStr += '<td>جمع کل</td>';
         summaryStr += '<td style="background-color:#5B9BD5;" title="' + totalTooltipText + '">' + summaryTotal + '</td>';
         summaryStr += '<td title="' + totalTooltipText + '">100.00%%</td>';
         summaryStr += '</tr>';
     }
     
     document.getElementById('summaryResult').innerHTML = summaryStr;
</script>

]]

input = {}
local input = teamyar.get_input()
local startDate = input["startDate"]

-- کوئری اصلی (بازه‌های ۳ روزه: 0، 3، 6، 9، 12، 15، 18، 21، 24، 27، 30، 31+)
query = [[
SELECT 
    kk.TAT,
    SUM(CASE WHEN ماه = '1404-01' THEN 1 ELSE 0 END) AS Month01,
    SUM(CASE WHEN ماه = '1404-02' THEN 1 ELSE 0 END) AS Month02,
    SUM(CASE WHEN ماه = '1404-03' THEN 1 ELSE 0 END) AS Month03,
    SUM(CASE WHEN ماه = '1404-04' THEN 1 ELSE 0 END) AS Month04,
    SUM(CASE WHEN ماه = '1404-05' THEN 1 ELSE 0 END) AS Month05,
    SUM(CASE WHEN ماه = '1404-06' THEN 1 ELSE 0 END) AS Month06,
    SUM(CASE WHEN ماه = '1404-07' THEN 1 ELSE 0 END) AS Month07,
    SUM(CASE WHEN ماه = '1404-08' THEN 1 ELSE 0 END) AS Month08,
    SUM(CASE WHEN ماه = '1404-09' THEN 1 ELSE 0 END) AS Month09,
    SUM(CASE WHEN ماه = '1404-10' THEN 1 ELSE 0 END) AS Month10,
    SUM(CASE WHEN ماه = '1404-11' THEN 1 ELSE 0 END) AS Month11,
    SUM(CASE WHEN ماه = '1404-12' THEN 1 ELSE 0 END) AS Month12,
    COUNT(*) AS GrandTotal,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER () * 100 , 2
    ) AS GrandTotalPercent
  from (
  select distinct k.`CODE` as ReceiptNo,k.FULL_CODE,k.Model,ReceiptStatus,LEFT(min(k.CommentDateFa),7) as 'ماه',min(k.CommentDateFa) as 'ایجاد درخواست',max(k.CommentDateFa) as 'آماده تحویل'
,DATEDIFF(max(k.CommentDate),min(k.CommentDate)) as 'انجام بر اساس روز' 
,case 
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) = 0 then 0
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 0 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 4 then 3
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 3 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 7 then 6
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 6 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 10 then 9
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 9 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 13 then 12
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 12 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 16 then 15
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 15 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 19 then 18
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 18 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 22 then 21
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 21 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 25 then 24
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 24 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 28 then 27
when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 27 and DATEDIFF(max(k.CommentDate),min(k.CommentDate)) < 31 then 30
else 31 end as TAT
from (
select SERVICE_REQUEST_ID,sr.`CODE`
,wh_product.FULL_CODE,wh_product.full_name as Model
,pm.FULLNAME as Technician
,(select REPORT_FN_GDATE(c.CREATION_DATE, '-')) as CommentDate
,(select REPORT_FN_JDATE(c.CREATION_DATE, '-')) as CommentDateFa
,c.type
,old_id
,new_id 
,case when sr.FINAL_STATUS = 0 then 'پیش پذیرش' 
      when sr.FINAL_STATUS = 1 then 'بررسی' 
      when sr.FINAL_STATUS = 2 then 'اجرا' 
			when sr.FINAL_STATUS = 3 then 'کامل (تعمبرشده)' 
      when sr.FINAL_STATUS = 4 then 'کامل (رد هزینه)'
      when sr.FINAL_STATUS = 5 then 'باطل'
      WHEN sr.FINAL_STATUS = 6 then 'آماده تحویل (تعمیر شده)'
      when sr.FINAL_STATUS = 7 then 'آماده تحویل (رد هزینه)'
      when sr.FINAL_STATUS = 8 then 'آماده تحویل (تعویض شده)'
      when sr.FINAL_STATUS = 9 then 'کامل (تعویض شده)'
      else '' end as ReceiptStatus
FROM pm_service_request_content as C left join pm_service_request as sr on c.SERVICE_REQUEST_ID = sr.ID 
LEFT JOIN profile_main pm ON c.AUTHOR_ID = pm.ID
left join wh_product on sr.PRODUCT_ID = wh_product.id
where (c.TYPE = 11 or new_id in (6,8))
and  sr.BREAK_DOWN_DATE>=?
and sr.FINAL_STATUS in (3,6,8,9)
ORDER by SERVICE_REQUEST_ID desc, c.id
) as k
group by ReceiptNo,k.FULL_CODE,k.Model,ReceiptStatus
  ) as kk
  GROUP BY TAT
order by tat
]]

-- کوئری دوم: گزارش آماری TAT برای درخواست‌های در دست انجام
query2 = [[
with cteReceipts as (
			select * FROM
			(
					select pm_service_request.id as RID,pm_service_request.PRODUCT_ID,pm_service_request.CODE as RNO
					,pm_service_request.BREAK_DOWN_DATE
				  ,pm_service_request.FINAL_STATUS
					,profile_main.FULLNAME as ReceiptBy
				  from pm_service_request
					left join profile_main on pm_service_request.AUTHOR_ID = profile_main.ID
					where pm_service_request.FINAL_STATUS <=2
			) as k
	),
  
   cteNotDeletedPartRequests as (
  select sr.id as RID,sr.code as ReceiptNo,rp.`STATUS`
	,RP.DATE_REQUEST,rpd.DATE_DEMAND,rpd.DATE_CONFIRM,rpd.PRODUCT_ID,rpd.ID as reqID
	,'Normal' as PartReqStatus
	,0 as IsDeleted
  FROM
	WH_REQ_PRODUCT AS RP
	inner JOIN wh_req_product_details AS rpd ON rp.id = rpd.REQUEST_ID
	left join pm_cost_declaration_detail as cd on cd.ID = RP.REF_ID 
	left join pm_cost_declaration on pm_cost_declaration.ID = cd.COST_DECLARATION_ID
	LEFT JOIN pm_service_request AS sr ON pm_cost_declaration.SERVICE_REQUEST_ID = sr.id 
  WHERE 	rp.DELETED = 0 
	AND REPLACE ( rpd.reason_of_cancellation, ' ', '' ) = '' 
	AND rp.REQUEST_TYPE = 5 
	and rp.REF_TYPE= 109
	and sr.id in (select rid from cteReceipts)
  
	union all
	
	select sr.id as RID,sr.code as ReceiptNo,rp.`STATUS`
	,RP.DATE_REQUEST,rpd.DATE_DEMAND,rpd.DATE_CONFIRM,rpd.PRODUCT_ID,rpd.ID as reqID
	,'Normal' as PartReqStatus
	,0 as IsDeleted
	FROM
	WH_REQ_PRODUCT AS RP
	inner JOIN wh_req_product_details AS rpd ON rp.id = rpd.REQUEST_ID
	LEFT JOIN pm_service_request AS sr ON RP.REF_ID = sr.id 
  WHERE 	rp.DELETED = 0 
	AND REPLACE ( rpd.reason_of_cancellation, ' ', '' ) = '' 
	AND rp.REQUEST_TYPE = 5 
	and rp.REF_TYPE= 101
  and sr.ID in (select rid from cteReceipts)
),

cteDeletedPartRequests as (
  select sr.id as RID,sr.code as ReceiptNo,rp.`STATUS`
	,RP.DATE_REQUEST,rpd.DATE_DEMAND,rpd.DATE_CONFIRM,rpd.PRODUCT_ID,rpd.ID as reqID
	,'Deleted' as PartReqStatus
	,1 as IsDeleted
  FROM
	WH_REQ_PRODUCT AS RP
	LEFT JOIN wh_req_product_details AS rpd ON rp.id = rpd.REQUEST_ID
	left join pm_cost_declaration_detail as cd on cd.ID = RP.REF_ID 
	left join pm_cost_declaration on pm_cost_declaration.ID = cd.COST_DECLARATION_ID
	LEFT JOIN pm_service_request AS sr ON pm_cost_declaration.SERVICE_REQUEST_ID = sr.id 
  WHERE 	rp.DELETED = 0 
	AND REPLACE ( rpd.reason_of_cancellation, ' ', '' ) <> '' 
	AND rp.REQUEST_TYPE = 5 
	and rp.REF_TYPE= 109
		and sr.id in (select rid from cteReceipts)

	union all
	
	select sr.id as RID,sr.code as ReceiptNo,rp.`STATUS`
	,RP.DATE_REQUEST,rpd.DATE_DEMAND,rpd.DATE_CONFIRM,rpd.PRODUCT_ID,rpd.ID as reqID
	,'Deleted' as PartReqStatus
	,1 as IsDeleted
	FROM
	WH_REQ_PRODUCT AS RP
	LEFT JOIN wh_req_product_details AS rpd ON rp.id = rpd.REQUEST_ID
	LEFT JOIN pm_service_request AS sr ON RP.REF_ID = sr.id 
  WHERE 	rp.DELETED = 0 
	AND REPLACE ( rpd.reason_of_cancellation, ' ', '' ) <> '' 
	AND rp.REQUEST_TYPE = 5 
	and rp.REF_TYPE= 101
	and sr.id in (select rid from cteReceipts)
),

cteFullPart as ( 
 select groupby.RID,groupby.ReceiptNo
 ,REPORT_FN_GDATE(MinDate, '-') as MinDateEN
 ,REPORT_FN_GDATE(MaxDate, '-') as MaxDateEN
 ,case when DATEDIFF(REPORT_FN_GDATE(MaxDate, '-'),REPORT_FN_GDATE(MinDate, '-')) is null then 0 else DATEDIFF(REPORT_FN_GDATE(MaxDate, '-'),REPORT_FN_GDATE(MinDate, '-')) end as DiffPart
 ,CountPartReq
 FROM (
   select RID,ReceiptNo ,MIN(DATE_REQUEST) as MinDate,MAX(DATE_CONFIRM) as MaxDate
			,COUNT(RID) as CountPartReq
		 from	(select * from cteNotDeletedPartRequests union all  select * from cteDeletedPartRequests) as k 
		 group by RID,ReceiptNo
    ) as groupby
),

cteCost as (
select resid.id as RID,resid.code as RNO
,CASE
		WHEN pm_cost_declaration.FINAL_STATUS = 0 THEN
		'باطل' 
		WHEN pm_cost_declaration.FINAL_STATUS = 1 THEN
		'در انتظار تایید هزینه' 
		WHEN pm_cost_declaration.FINAL_STATUS = 4 THEN
		'تایید' 
		WHEN pm_cost_declaration.FINAL_STATUS = 5 THEN
		'رد هزینه' ELSE '' 
	END AS CostStatus
	,Min(pm_cost_declaration.CREATION_DATE) as MinCostCREATION_DATE
,DATEDIFF(REPORT_FN_gDATE(MAX(pm_cost_declaration_detail.CONFIRMATION_DATE),'-'),REPORT_FN_gDATE(MIN(pm_cost_declaration.CREATION_DATE),'-')) as DiffCost
FROM pm_cost_declaration_detail left join pm_cost_declaration on pm_cost_declaration_detail.COST_DECLARATION_ID = pm_cost_declaration.ID
LEFT JOIN pm_service_request AS resid ON resid.id = pm_cost_declaration.SERVICE_REQUEST_ID
	where resid.id in (select rid from cteReceipts)
group by resid.id,resid.code,CostStatus
),
	

cteProduct as (select id,full_code,FULL_NAME from wh_product)



SELECT
COUNT(*) AS Total,
SUM(CASE WHEN TAT = 0 THEN 1 ELSE 0 END) AS `0`,
SUM(CASE WHEN TAT BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS `3`,
SUM(CASE WHEN TAT BETWEEN 4 AND 6 THEN 1 ELSE 0 END) AS `6`,
SUM(CASE WHEN TAT BETWEEN 7 AND 9 THEN 1 ELSE 0 END) AS `9`,
SUM(CASE WHEN TAT BETWEEN 10 AND 12 THEN 1 ELSE 0 END) AS `12`,
SUM(CASE WHEN TAT BETWEEN 13 AND 15 THEN 1 ELSE 0 END) AS `15`,
SUM(CASE WHEN TAT BETWEEN 16 AND 18 THEN 1 ELSE 0 END) AS `18`,
SUM(CASE WHEN TAT BETWEEN 19 AND 21 THEN 1 ELSE 0 END) AS `21`,
SUM(CASE WHEN TAT BETWEEN 22 AND 24 THEN 1 ELSE 0 END) AS `24`,
SUM(CASE WHEN TAT BETWEEN 25 AND 27 THEN 1 ELSE 0 END) AS `27`,
SUM(CASE WHEN TAT BETWEEN 28 AND 30 THEN 1 ELSE 0 END) AS `30`,
SUM(CASE WHEN TAT >= 31 THEN 1 ELSE 0 END) AS `31+`

from (select cteReceipts.rno
,CountPartReq
,DiffPart
,DiffCost
,DATEDIFF(NOW(),REPORT_FN_GDATE(cteReceipts.BREAK_DOWN_DATE, '-')) as TAT

			from cteReceipts

			left join cteFullPart on cteFullPart.ReceiptNo = cteReceipts.RNO

			left join cteCost on cteReceipts.RID = cteCost.RID

			left join cteProduct on cteProduct.id = cteReceipts.PRODUCT_ID) as k
      
      order by TAT 
]]

if startDate == nil then 
      teamyar.write_result("تاریخ شروع وارد نشده است")
else 
 db.use_db("0000000")
    local param1 = {
          query=query,
          params={startDate}
    }
    db.query(param1);
  local result = {}
  
  while db.query_fetch(result) do
    -- ترتیب ستون‌ها در خروجی:
    -- 1: TAT, 2-13: Month01-Month12, 14: GrandTotal, 15: GrandTotalPercent
    
    local tat = result[1] or 0
    local month01 = result[2] or 0
    local month02 = result[3] or 0
    local month03 = result[4] or 0
    local month04 = result[5] or 0
    local month05 = result[6] or 0
    local month06 = result[7] or 0
    local month07 = result[8] or 0
    local month08 = result[9] or 0
    local month09 = result[10] or 0
    local month10 = result[11] or 0
    local month11 = result[12] or 0
    local month12 = result[13] or 0
    local grandTotal = result[14] or 0
    local grandTotalPercent = result[15] or 0
    
    -- فرمت کردن اعداد
    local tatStr = string.format("%d", tonumber(tat) or 0)
    local month01Str = string.format("%d", tonumber(month01) or 0)
    local month02Str = string.format("%d", tonumber(month02) or 0)
    local month03Str = string.format("%d", tonumber(month03) or 0)
    local month04Str = string.format("%d", tonumber(month04) or 0)
    local month05Str = string.format("%d", tonumber(month05) or 0)
    local month06Str = string.format("%d", tonumber(month06) or 0)
    local month07Str = string.format("%d", tonumber(month07) or 0)
    local month08Str = string.format("%d", tonumber(month08) or 0)
    local month09Str = string.format("%d", tonumber(month09) or 0)
    local month10Str = string.format("%d", tonumber(month10) or 0)
    local month11Str = string.format("%d", tonumber(month11) or 0)
    local month12Str = string.format("%d", tonumber(month12) or 0)
    local grandTotalStr = string.format("%d", tonumber(grandTotal) or 0)
    local grandTotalPercentStr = string.format("%.2f", tonumber(grandTotalPercent) or 0)
    
    -- افزودن به آرایه
    table.insert(myArray, {
        tatStr,
        month01Str,
        month02Str,
        month03Str,
        month04Str,
        month05Str,
        month06Str,
        month07Str,
        month08Str,
        month09Str,
        month10Str,
        month11Str,
        month12Str,
        grandTotalStr,
        grandTotalPercentStr
    })
  end
  
  -- اجرای کوئری دوم برای گزارش آماری
  local summaryArray = {}
  local param2 = {
    query = query2,
    params = {}
  }
  db.query(param2);
  local result2 = {}
  
  -- خواندن نتایج کوئری دوم (یک ردیف با ستون‌های Total, 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 31+)
  if db.query_fetch(result2) then
    local total = tonumber(result2[1]) or 0
    local count0 = tonumber(result2[2]) or 0
    local count3 = tonumber(result2[3]) or 0
    local count6 = tonumber(result2[4]) or 0
    local count9 = tonumber(result2[5]) or 0
    local count12 = tonumber(result2[6]) or 0
    local count15 = tonumber(result2[7]) or 0
    local count18 = tonumber(result2[8]) or 0
    local count21 = tonumber(result2[9]) or 0
    local count24 = tonumber(result2[10]) or 0
    local count27 = tonumber(result2[11]) or 0
    local count30 = tonumber(result2[12]) or 0
    local count31plus = tonumber(result2[13]) or 0
    
    -- ساخت آرایه برای نمایش (بازه زمانی، تعداد)
    if count0 > 0 then
      table.insert(summaryArray, {"زیر یک روز", tostring(count0)})
    end
    if count3 > 0 then
      table.insert(summaryArray, {"1 تا 3 روز", tostring(count3)})
    end
    if count6 > 0 then
      table.insert(summaryArray, {"4 تا 6 روز", tostring(count6)})
    end
    if count9 > 0 then
      table.insert(summaryArray, {"7 تا 9 روز", tostring(count9)})
    end
    if count12 > 0 then
      table.insert(summaryArray, {"10 تا 12 روز", tostring(count12)})
    end
    if count15 > 0 then
      table.insert(summaryArray,{"13 تا 15 روز", tostring(count15)})
    end
    if count18 > 0 then
      table.insert(summaryArray, {"16 تا 18 روز", tostring(count18)})
    end
    if count21 > 0 then
      table.insert(summaryArray,{"19 تا 21 روز", tostring(count21)})
    end
    if count24 > 0 then
      table.insert(summaryArray,{"22 تا 24 روز", tostring(count24)})
    end
    if count27 > 0 then
      table.insert(summaryArray,{"25 تا 27 روز", tostring(count27)})
    end
    if count30 > 0 then
      table.insert(summaryArray,{"28 تا 30 روز", tostring(count30)})
    end
    if count31plus > 0 then
      table.insert(summaryArray, {"بالای 30 روز", tostring(count31plus)})
    end
  end
  
  db.query_free();
  
  if #myArray == 0 then
    teamyar.write_result("هیچ داده‌ای برای بازه زمانی مشخص شده یافت نشد")
  else
    -- فرمت کردن chart با هر دو آرایه
    local formattedChart = string.format(Res_chart, json.encode(myArray), json.encode(summaryArray))
    teamyar.write_result(formattedChart)
  end
end
