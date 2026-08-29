-- local query = teamyar.query(context,[[{"query":"with recursive CTE_Account AS (SELECT ID as SourceAccount,ID as AccountID, CODE AS AccountCode, PARENT , ORG_ID AS ORG_ID FROM pa_account WHERE ORG_ID = 2 UNION SELECT  CTE_Account.SourceAccount as SourceAccount,pa.ID as AccountID, pa.CODE AS AccountCode, pa.PARENT , pa.ORG_ID AS ORG_ID FROM CTE_Account INNER JOIN pa_account as pa ON CTE_Account.AccountID = pa.PARENT and CTE_Account.ORG_ID = pa.ORG_ID), CTE_DateRangePerYear as (select min(JNDATE) as MinJndate,max(JNDATE) as MaxJndate,min(DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) as sdate,  max(DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) edate, JYEAR FROM REPORT_DIMDATE where (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) <= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) >= 133553537990000000)) OR (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) >= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) <= 133553537990000000)) OR (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) >= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) <= 133553537990000000)) OR (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) <= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) >= 133553537990000000)) group by JYEAR), CTE_VoucherRecords as  (select cte_DateRangePerYear.MaxJndate as Jndate,cte_DateRangePerYear.JYEAR,pv.ORG_ID,pvr.ACCOUNT_ID,SUM(COALESCE(pvr.CRD, 0) - COALESCE(pvr.DEB, 0)) as remain,TAG_ID from cte_DateRangePerYear inner join pa_voucher as pv on pv.RUN_DATE >= sdate and pv.RUN_DATE <= edate inner join pa_voucher_record as pvr on pv.ID = pvr.VOUCHER_ID and pv.ORG_ID = pvr.ORG_ID INNER JOIN PA_VOUCHER_RECORD_TAG vrt ON vrt.VOUCHER_RECORD_ID = pvr.ID and vrt.ORG_ID = pvr.ORG_ID  where pv.ORG_ID = 2 and (pv.RUN_DATE >=132922818000000000 and pv.RUN_DATE <= 133552800000000000) /* and pv.type in (1,4,5) and pv.status in(2,4,5,6)*/ and pv.deleted = 0 and pvr.deleted = 0 group by MaxJndate,JYEAR,pv.ORG_ID,pvr.ACCOUNT_ID,vrt.TAG_ID) , CTE_MinDateRange AS (SELECT min(MinJndate) as MinJndate,min(JYEAR) JYEAR,min(sdate) sdate ,min(edate) edate FROM cte_DateRangePerYear),CTE_AccountsVouchers AS (select CTE_Account.SourceAccount,CTE_Account.ORG_ID,sum(CTE_VoucherRecords.remain) as remain,CTE_VoucherRecords.Jndate,CTE_VoucherRecords.JYEAR,TAG_ID from CTE_Account INNER JOIN CTE_VoucherRecords on CTE_Account.AccountID=CTE_VoucherRecords.ACCOUNT_ID and CTE_Account.ORG_ID=CTE_VoucherRecords.ORG_ID group by CTE_Account.SourceAccount,CTE_Account.ORG_ID,CTE_VoucherRecords.Jndate,CTE_VoucherRecords.JYEAR,TAG_ID), CTE_RemainAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain,Jndate, JYEAR, 1 as type,TAG_ID from CTE_AccountsVouchers where TAG_ID>=0 group by ORG_ID,Jndate,JYEAR,TAG_ID), cte_DecimalCount as (select ps.ORG_ID,ps.ID,ps.name,ps.DECIMAL_COUNT,ps.FEE_DECIMAL from PA_ORGANIZATIONS as po inner join PA_SYMBOLS as ps on po.BASE_CURRENCY = ps.id and po.ORG_ID = ps.ORG_ID), Cte_RemainAccountsBaseDecimalCount as (select uor.ORG_ID,oi.NAME as OrgName,  COALESCE(uor.remain, 0)/POWER(10, COALESCE(cdc.DECIMAL_COUNT, 0)) as remain , uor.JYEAR,uor.JNDATE, uor.type,uor.TAG_ID  from CTE_RemainAccounts uor left join cte_DecimalCount cdc on uor.ORG_ID = cdc.ORG_ID left join org_info oi on uor.ORG_ID = oi.ID) SELECT JSON_ARRAYAGG(JSON_OBJECT( 'ORG_ID',RA.ORG_ID, 'OrgName',RA.OrgName,'type',RA.type,'JYEAR',RA.JYEAR,'JNDATE',RA.JNDATE,'TAG_ID',RA.TAG_ID,'remain',RA.remain, 'title',PVT.NAME)) as result from Cte_RemainAccountsBaseDecimalCount RA LEFT JOIN pa_voucher_tag PVT ON  RA.ORG_ID = PVT.ORG_ID AND RA.TAG_ID = PVT.ID where RA.JYEAR>=0 order by RA.JYEAR ASC,RA.type;","params":[]}]]);

-- local dec = json.decode(query)

template = [[
<!DOCTYPE html><html dir="rtl" lang="en"> <head> <meta charset="UTF-8" /> <meta http-equiv="X-UA-Compatible" content="IE=edge" /> <meta name="viewport" content="width=device-width, initial-scale=1.0" /> <title>صورت مالی: صورت جریان های نقدی</title> </head> <style> table { width: 1500px; } table, th, td { border: 1px solid gray; border-collapse: collapse; text-align: center; padding: 10px; height: 30px; overflow: hidden; box-shadow: 0 0 20px rgba(0, 0, 0, 0.1); } tbody tr:nth-child(odd) { background-color: #f0f8ff; } tbody tr:nth-child(2) { background-color: #f0f8ff; } .Right { text-align: right; } .Bold { font-size: large; font-weight: bold; } .Border { border-top: 2px solid black; } .Border2 { border-top: 5px double black; } </style> <body> <table> <tr> <th colspan="9" class="Bold">شرکت کشت و صنعت باورد</th> </tr> <tr> <th colspan="9" class="Bold">صورت جریان های نقدی</th> </tr> <tr> <th colspan="9" class="Bold">سال مالی: سال ۱۴۰۲</th> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td colspan="3">(مبالغ به میلیون ریال)</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td>(تجدید ارائه شده)</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td>یادداشت</td> <td></td> <td>سال ۱۴۰۲</td> <td></td> <td>سال ۱۴۰۱</td> <td></td> </tr> <tr> <td></td> <td class="Right Bold">جریان های نقدی حاصل از فعالیتهای عملیاتی:</td> <td></td> <td class="Border"></td> <td></td> <td class="Border"></td> <td></td> <td class="Border"></td> <td></td> </tr> <tr> <td></td> <td class="Right">نقد حاصل از عملیات</td> <td></td> <td>۴۱</td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۱۷,۰۲۸,۲۶۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداخت های نقدی بابت مالیات بر درآمد</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۱۷,۰۲۸,۲۶۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> جریان خالص ورود (خروج) نقد حاصل از فعالیت های عملیاتی </td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">۰</td> <td></td> <td class="Border" dir="ltr">۴,۵۸۵,۰۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right Bold"> جریان های نقدی حاصل از فعالیتهای سرمایه گذاری: </td> <td></td> <td></td> <td></td> <td class="Border"></td> <td></td> <td class="Border"></td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از فروش دارایی های ثابت مشهود </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۴,۵۸۵,۰۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداخت های نقدی برای خرید دارایی های ثابت مشهود</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۴,۵۸۵,۰۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از فروش دارایی های غیر جاری نگهداری شده برای فروش </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی حاصل از فروش دارایی های نامشهود</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۲۰,۲۴۹,۵۲۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداخت های نقدی برای خرید دارایی های نامشهود</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۲۰,۲۴۹,۵۲۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از فروش سرمایه گذاری های بلند مدت </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۲۰,۲۴۹,۵۲۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right"> پرداخت های نقدی برای تحصیل سرمایه گذاری های بلند مدت </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از فروش سرمایه گذاری در املاک </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداخت های نقدی برای تحصیل سرمایه گذاری در املاک</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از فروش سرمایه گذاری های کوتاه مدت </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۱۴۷,۸۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> پرداخت های نقدی برای تحصیل سرمایه گذاری های کوتاه مدت </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۱۴۷,۸۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداخت های نقدی بابت تسهیلات اعطایی به دیگران</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از استرداد تسهیلات اعطایی به دیگران </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۹۹,۱۳۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> دریافت های نقدی حاصل از سود تسهیلات اعطایی به دیگران </td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۹۹,۱۳۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی حاصل از سود سهام</td> <td></td> <td></td> <td></td> <td dir="ltr">(۱۵,۰۰۰,۰۰۰)</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی حاصل از سود سایر سرمایه گذاری ها</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> جریان خالص ورود (خروج) نقد حاصل از فعالیت های سرمایه گذاری </td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۱۵,۰۰۰,۰۰۰)</td> <td></td> <td class="Border" dir="ltr">(۵۱,۱۸۱,۸۷۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right Bold"> جریان خالص ورود (خروج) نقد قبل از فعالیت های تامین مالی </td> <td></td> <td></td> <td></td> <td class="Border"></td> <td></td> <td class="Border"></td> <td></td> </tr> <tr> <td></td> <td class="Right Bold">جریان های نقدی حاصل از فعالیتهای تامین مالی:</td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی ناشی از افزایش سرمایه</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۱,۱۷۹,۴۵۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی ناشی از صرف سهام</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی ناشی از فروش سهام خزانه</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی برای خرید سهام خزانه</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۴۸,۷۵۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های ناشی از تسهیلات</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت اصل تسهیلات</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۹,۷۰۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت سود تسهیلات</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۹,۷۰۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های ناشی از انتشار اوراق مشارکت</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۱۰۸,۸۳۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت اصل اوراق مشارکت</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">(۹۹,۱۳۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت سود اوراق مشارکت</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">دریافت های نقدی حاصل از انتشار اوراق خرید دین</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت اصل اوراق خرید دین</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت سود اوراق خرید دین</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت اصل اقساط اجاره سرمایه ای</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت سود اجاره سرمایه ای</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">پرداختهای نقدی بابت سود سهام</td> <td></td> <td></td> <td></td> <td dir="ltr">(۲۰۰,۰۰۰,۰۰۰)</td> <td></td> <td dir="ltr">۴,۵۸۵,۰۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right"> جریان خالص ورود (خروج) نقد حاصل از فعالیت های تامین مالی </td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۲۰۰,۰۰۰,۰۰۰)</td> <td></td> <td class="Border" dir="ltr">۵,۵۸۵,۹۰۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">خالص افزایش (کاهش) در موجودی نقد</td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۷۵,۰۰۰,۰۰۰)</td> <td></td> <td class="Border" dir="ltr">۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">مانده موجودی نقد در ابتدای سال</td> <td></td> <td></td> <td></td> <td dir="ltr">۰</td> <td></td> <td dir="ltr">۶۰,۱۴۵,۴۳۵,۰۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">تاثیر تغییرات نرخ ارز</td> <td></td> <td></td> <td></td> <td dir="ltr">(۱۰۰,۰۰۰,۰۰۰)</td> <td></td> <td dir="ltr">۹,۶۰۰,۵۵۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">مانده موجودی نقد در پایان سال</td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۱۷۵,۰۰۰,۰۰۰)</td> <td></td> <td class="Border" dir="ltr">۶۰,۱۵۵,۰۳۵,۶۳۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">معاملات غیر نقدی</td> <td></td> <td>۴۲</td> <td></td> <td class="Border2" dir="ltr">(۷۴,۰۰۰,۰۰۰)</td> <td></td> <td class="Border2" dir="ltr">۵,۰۱۵,۴۸۰</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> <tr> <td colspan="9" class="Bold"> یادداشت های توضیحی، بخش جدایی ناپذیر صورت های مالی است. </td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> </table> </body></html>
]]

function comma_value(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

function format_num(amount, decimal, prefix, neg_prefix)
  local str_amount,  formatted, famount, remain
  decimal = decimal or 2
  neg_prefix = neg_prefix or "-"
  famount = math.abs(round(amount,decimal))
  famount = math.floor(famount)
  remain = round(math.abs(amount) - famount, decimal)
  formatted = comma_value(famount)
  if (decimal > 0) then
    remain = string.sub(tostring(remain),3)
    formatted = formatted .. "." .. remain ..
                string.rep("0", decimal - string.len(remain))
  end
  formatted = (prefix or "") .. formatted 
  if (amount<0) then
    if (neg_prefix=="()") then
      formatted = "("..formatted ..")"
    else
      formatted = neg_prefix .. formatted 
    end
  end
  return formatted
end

local farsiNumbers = {
  [0] = "۰",
  [1] = "۱",
  [2] = "۲",
  [3] = "۳",
  [4] = "۴",
  [5] = "۵",
  [6] = "۶",
  [7] = "۷",
  [8] = "۸",
  [9] = "۹"
}

function convertToFarsi(input)
  local farsiNumber = ""
  local isNegative = false
  if type(input) == "number" then
    if input < 0 then
      isNegative = true
      input = -input
    end
    input = tostring(input)
  elseif type(input) == "string" then
    if input:sub(1, 1) == "-" then
      isNegative = true
      input = input:sub(2)
    end
  else
    return nil
  end
  for i = 1, #input do
    local digit = tonumber(input:sub(i, i))
    if digit ~= nil then
      farsiNumber = farsiNumber .. farsiNumbers[digit]
    else
      farsiNumber = farsiNumber .. input:sub(i, i)
    end
  end
  if isNegative then
    farsiNumber = "(" .. farsiNumber .. ")"
  end
  return farsiNumber
end

-- local sum_01 = dec[43]["remain"] + dec[42]["remain"] + dec[17]["remain"] + dec[35]["remain"] + dec[34]["remain"] + dec[28]["remain"] + dec[27]["remain"] + dec[46]["remain"] + dec[45]["remain"]
-- local sum_02 = dec[39]["remain"] + dec[26]["remain"] + dec[23]["remain"] + dec[22]["remain"] + dec[21]["remain"] + dec[48]["remain"] + dec[41]["remain"]
-- local sum_03 = dec[1]["remain"] + dec[4]["remain"]
-- local sum_04 = dec[40]["remain"] + dec[20]["remain"]

-- local res = string.format(template, dec[2]["OrgName"], convertToFarsi(format_num(dec[32]["remain"], -1)), convertToFarsi(format_num(dec[31]["remain"], -1)), convertToFarsi(format_num(dec[44]["remain"], -1)), convertToFarsi(format_num(dec[43]["remain"], -1)), convertToFarsi(format_num(dec[42]["remain"], -1)), convertToFarsi(format_num(dec[17]["remain"], -1)), convertToFarsi(format_num(dec[35]["remain"], -1)), convertToFarsi(format_num(dec[34]["remain"], -1)), convertToFarsi(format_num(dec[28]["remain"], -1)), convertToFarsi(format_num(dec[27]["remain"], -1)), convertToFarsi(format_num(dec[46]["remain"], -1)), convertToFarsi(format_num(dec[45]["remain"], -1)), convertToFarsi(format_num(dec[2]["remain"], -1)), convertToFarsi(format_num(dec[2]["remain"], -1)), convertToFarsi(format_num(sum_01, -1)), convertToFarsi(format_num(dec[39]["remain"], -1)), convertToFarsi(format_num(dec[26]["remain"], -1)), convertToFarsi(format_num(dec[23]["remain"], -1)), convertToFarsi(format_num(dec[22]["remain"], -1)), convertToFarsi(format_num(dec[21]["remain"], -1)), convertToFarsi(format_num(dec[48]["remain"], -1)), convertToFarsi(format_num(dec[3]["remain"], -1)), convertToFarsi(format_num(dec[41]["remain"], -1)), convertToFarsi(format_num(dec[3]["remain"], -1)), convertToFarsi(format_num(sum_02, -1)), convertToFarsi(format_num(dec[1]["remain"], -1)), convertToFarsi(format_num(dec[40]["remain"], -1)), convertToFarsi(format_num(dec[4]["remain"], -1)), convertToFarsi(format_num(dec[20]["remain"], -1)), convertToFarsi(format_num(sum_03, -1)), convertToFarsi(format_num(sum_04, -1)), convertToFarsi(format_num(dec[5]["remain"], -1)), convertToFarsi(format_num(dec[19]["remain"], -1)))

teamyar.write_result(context, template)