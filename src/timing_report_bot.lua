-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30
local myArray = {}

Res_chart = [[
<html dir="rtl" lang="fa">
<h3 style="background-color:#D2E0FB;text-align: center;border:1px dots black;height:120px;weight:100%%;padding-top:5px;shadow;border-radius: 10px;">
<p>گزارش زمان‌بندی فرآیند پذیرش خدمات</p>
<p>این گزارش شامل زمان‌های مختلف فرآیند از پذیرش تا تکمیل می‌باشد</p>
<p>(در صورت وجود هرگونه سوال یا تغییری با شماره 09125632329 تماس حاصل فرمایید)</p>
</h3>
<table>
  <thead>
	  <tr style="background-color:#0073e6;color:white;">
				<th>ردیف</th>
     			<th>شماره پذیرش</th>
				<th>کد کالا</th>
                <th>مدل</th>
                <th>وضعیت پذیرش</th>
                <th>ماه</th>
                <th>ایجاد درخواست</th>
                <th>آماده تحویل</th>
                <th>انجام بر اساس روز</th>
                <th>بازه زمانی انجام</th>
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
 border: 2px solid #7d0000;
 border-radius: 8px;
}

td, th {
  border: 2px solid #dddddd;
  text-align: center;
  padding: 8px;
  text-align: center;
  font-size: 11px;
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

</style>

<script>   
     var data = %s,   
      len = data.length,
      str = '';

for (var i = 0; i < len; i++) {
    str += '<tr>';
    str += '<td>' + (i + 1) + '</td>';

    for (var j = 0; j < data[i].length; j++) {
        if (j == 8) { // ستون بازه زمانی انجام (index 8)
            var timeRange = data[i][j] || '';
            var className = 'normal';

            if (timeRange === 'زیر یک روز') {
                className = 'good';
            } else if (timeRange === '0-5') {
                className = 'good';
            } else if (timeRange === '6-10') {
                className = 'normal';
            } else if (timeRange === '11-15') {
                className = 'warning';
            } else if (timeRange === '16-20') {
                className = 'warning';
            } else if (timeRange === '21-25') {
                className = 'critical';
            } else if (timeRange === '26-30') {
                className = 'critical';
            } else if (timeRange && timeRange.indexOf('+') !== -1) {
                className = 'critical';
            }

            str += '<td class="' + className + '">' + timeRange + '</td>';
        } else {
            str += '<td>' + (data[i][j] || '') + '</td>';
        }
    }

    str += '</tr>';
}

document.getElementById('result').innerHTML = str;
</script>

]]

input = {}
local input = teamyar.get_input()
local startDate = input["startDate"]

-- کوئری اصلی
query = [[
select distinct k.`CODE` as ReceiptNo,k.FULL_CODE,k.Model,ReceiptStatus,LEFT(min(k.CommentDateFa),7) as ReceiptMonth,min(k.CommentDateFa) as ReceiptCreateDate,max(k.CommentDateFa) as ReceiptReadyDate
,DATEDIFF(max(k.CommentDate),min(k.CommentDate)) as DaysDiff
,case 
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) = 0 then 'زیر یک روز'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) between 1 and 5 then '0-5'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) between 6 and 10 then '6-10'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) between 11 and 15 then '11-15'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) between 16 and 20 then '16-20'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) between 21 and 25 then '21-25'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) between 26 and 30 then '26-30'
    when DATEDIFF(max(k.CommentDate),min(k.CommentDate)) > 30 then '30+'
    else 'زیر یک روز'
end as TimeRange
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
order by k.`CODE`
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
    -- 1: ReceiptNo, 2: FULL_CODE, 3: Model, 4: ReceiptStatus, 5: ReceiptMonth
    -- 6: ReceiptCreateDate, 7: ReceiptReadyDate, 8: DaysDiff, 9: TimeRange
    
    local receiptNo = result[1] or ""
    local fullCode = result[2] or ""
    local model = result[3] or ""
    local receiptStatus = result[4] or ""
    local receiptMonth = result[5] or ""
    local receiptCreateDate = result[6] or ""
    local receiptReadyDate = result[7] or ""
    local daysDiff = result[8] or 0
    local timeRange = result[9] or ""
    
    -- فرمت کردن اعداد
    local daysDiffStr = string.format("%d", tonumber(daysDiff) or 0)
    
    -- افزودن به آرایه
    table.insert(myArray, {
        receiptNo,
        fullCode,
        model,
        receiptStatus,
        receiptMonth,
        receiptCreateDate,
        receiptReadyDate,
        daysDiffStr,
        timeRange
    })
  end
  
  if #myArray == 0 then
    teamyar.write_result("هیچ داده‌ای برای بازه زمانی مشخص شده یافت نشد")
  else
    local formattedChart = string.format(Res_chart, json.encode(myArray))
    teamyar.write_result(formattedChart)
  end
  
  db.query_free();
end
