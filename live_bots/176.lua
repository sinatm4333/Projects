-- local query = teamyar.query(context,[[{"query":"with recursive CTE_Account AS (SELECT ID as SourceAccount,ID as AccountID, CODE AS AccountCode, PARENT , ORG_ID AS ORG_ID FROM pa_account WHERE ORG_ID = 2 UNION SELECT  CTE_Account.SourceAccount as SourceAccount,pa.ID as AccountID, pa.CODE AS AccountCode, pa.PARENT , pa.ORG_ID AS ORG_ID FROM CTE_Account INNER JOIN pa_account as pa ON CTE_Account.AccountID = pa.PARENT and CTE_Account.ORG_ID = pa.ORG_ID), cte_DateRangePerYear as (select min(DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) as sdate,  max(DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) edate, JYEAR FROM REPORT_DIMDATE where (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) <= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) >= 133553537990000000)) OR (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) >= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) <= 133553537990000000)) OR (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) >= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) <= 133553537990000000)) OR (((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000)) <= 132922818000000000) AND ((DATEKEY - MOD( 126000000000+ DATEKEY ,864000000000) +828000000000+35400000000+590000000) >= 133553537990000000)) group by JYEAR), CTE_VoucherRecords as  (select cte_DateRangePerYear.JYEAR,pv.ORG_ID,pvr.ACCOUNT_ID,SUM(COALESCE(pvr.CRD, 0) - COALESCE(pvr.DEB, 0)) as remain from cte_DateRangePerYear inner join pa_voucher as pv on pv.RUN_DATE >= sdate and pv.RUN_DATE <= edate inner join pa_voucher_record as pvr on pv.ID = pvr.VOUCHER_ID and pv.ORG_ID = pvr.ORG_ID where pv.ORG_ID = 2 and (pv.RUN_DATE >=132922818000000000 and pv.RUN_DATE <= 133552800000000000) and pv.type in (1,4,5) and pv.status in(2,4,5,6) and pv.deleted = 0 and pvr.deleted = 0 group by cte_DateRangePerYear.JYEAR,pv.ORG_ID,pvr.ACCOUNT_ID) ,CTE_AccountsVouchersInfo AS (select CTE_Account.SourceAccount,CTE_Account.ORG_ID,sum(CTE_VoucherRecords.remain) as remain,CTE_VoucherRecords.JYEAR from CTE_Account left join CTE_VoucherRecords on CTE_Account.AccountID=CTE_VoucherRecords.ACCOUNT_ID and CTE_Account.ORG_ID=CTE_VoucherRecords.ORG_ID group by CTE_Account.SourceAccount,CTE_Account.ORG_ID,CTE_VoucherRecords.JYEAR), CTE_OPIncomeAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2368,1648) group by ORG_ID,JYEAR), CTE_TCOPIncomeAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(1648)  group by ORG_ID,JYEAR) ,CTE_GeneralCostAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(1646)  group by ORG_ID,JYEAR), CTE_DecValCostsAccounts as(select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2053,2084,2413,2493)  group by ORG_ID,JYEAR), CTE_OtherIncAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2052)  group by ORG_ID,JYEAR), CTE_OtherCostsAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2050)  group by ORG_ID,JYEAR), CTE_FinCostsAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2104,2645)  group by ORG_ID,JYEAR), CTE_OtherNonOPAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2057)  group by ORG_ID,JYEAR ), CTE_TaxCostsAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2054,2055,2209,2489)  group by ORG_ID,JYEAR), CTE_StopOPAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 0 as type from CTE_AccountsVouchersInfo where SourceAccount in(2319)  group by ORG_ID,JYEAR), CTE_SurplusRevTangibleAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 2 as type from CTE_AccountsVouchersInfo where SourceAccount in(2605)  group by ORG_ID,JYEAR), CTE_DiffExchangeRateAccounts as (select ORG_ID, sum(COALESCE(remain,0)) as remain, JYEAR, 5 as type from CTE_AccountsVouchersInfo where SourceAccount in(2304,2305,2048)  group by ORG_ID,JYEAR), cte_UnionRemainAccounts AS (SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_OPIncomeAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_TCOPIncomeAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_GeneralCostAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_DecValCostsAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_OtherIncAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_OtherCostsAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_FinCostsAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_OtherNonOPAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_TaxCostsAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_StopOPAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_SurplusRevTangibleAccounts UNION All SELECT ORG_ID, remain , JYEAR, TYPE FROM CTE_DiffExchangeRateAccounts), CTE_PureProfit as (select  ORG_ID, sum(remain) as remain, JYEAR, 1 as type from cte_UnionRemainAccounts where type= 0 group by ORG_ID, JYEAR), CTE_SurplusRevTangibleTax as (select  ORG_ID, (SUM(COALESCE(remain,0))/COALESCE(4 , 1)) * 0.09 as remain, JYEAR, 3 as type from cte_UnionRemainAccounts where type= 2 group by ORG_ID, JYEAR), CTE_SurplusRevTangibleTaxSum as (select  ORG_ID, (SUM(COALESCE(remain,0))/COALESCE(4 , 1)) + ((SUM(COALESCE(remain,0))/COALESCE(4 , 1)) * 0.09) as remain, JYEAR, 4 as type from cte_UnionRemainAccounts where type= 2 group by ORG_ID, JYEAR), CTE_DiffExchangeRateTax as (select  ORG_ID, (SUM(COALESCE(remain,0))/COALESCE(4 , 1)) * 0.09 as remain, JYEAR, 6 as type from cte_UnionRemainAccounts where type= 6 group by ORG_ID, JYEAR), CTE_DiffExchangeRateTaxSum as (select  ORG_ID, (SUM(COALESCE(remain,0))/COALESCE(4 , 1)) + (SUM(COALESCE(remain,0))/COALESCE(4 , 1) * 0.09) as remain, JYEAR, 7 as type from cte_UnionRemainAccounts where type= 5 group by ORG_ID, JYEAR), CTE_CompYearProfit  as (select  ORG_ID, (SUM(COALESCE(remain,0))/COALESCE(4 , 1)) + ((SUM(COALESCE(remain,0))/COALESCE(4 , 1)) * 0.09) as remain, JYEAR, 8 as type from cte_UnionRemainAccounts where type in(2,5) group by ORG_ID, JYEAR), cte_DecimalCount as (select ps.ORG_ID,ps.ID,ps.name,ps.DECIMAL_COUNT,ps.FEE_DECIMAL from PA_ORGANIZATIONS as po inner join PA_SYMBOLS as ps on po.BASE_CURRENCY = ps.id and po.ORG_ID = ps.ORG_ID), Cte_RemainAccounts as(SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_SurplusRevTangibleAccounts UNION All SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_DiffExchangeRateAccounts UNION All  SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_PureProfit UNION All SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_SurplusRevTangibleTax UNION All SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_SurplusRevTangibleTaxSum UNION All SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_DiffExchangeRateTax UNION All SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_DiffExchangeRateTaxSum UNION All SELECT  ORG_ID, remain , JYEAR, TYPE FROM CTE_CompYearProfit), Cte_RemainAccountsBaseDecimalCount as (select cra.ORG_ID,oi.NAME as OrgName,  COALESCE(cra.remain, 0)/POWER(10, COALESCE(cdc.DECIMAL_COUNT, 0)) as remain , cra.JYEAR, cra.type  from Cte_RemainAccounts cra left join cte_DecimalCount cdc on cra.ORG_ID = cdc.ORG_ID left join org_info oi on cra.ORG_ID = oi.ID) select JSON_ARRAYAGG(JSON_OBJECT( 'ORG_ID',ORG_ID,'OrgName',OrgName,'type',type,'JYEAR',JYEAR,'YEAR',IF(JYEAR =0,'',concat('سال',' ',JYEAR)), 'remain',remain, 'title',CASE COALESCE(type,0)  WHEN 1 THEN 'سود  خالص' WHEN 2 THEN 'مازاد تجدید ارزیابی دارایی های ثابت مشهود' WHEN 3 THEN 'مالیات بر درآمد اقلام فوق' WHEN 4 THEN 'مالیات مربوط به سایر اقلام سود و زیان جامع' WHEN 5 THEN '.........' WHEN 6 THEN 'مالیات بر درآمد اقلام فوق'  WHEN 7 THEN 'سایر اقلام سود و زیان جامع پس از کسر مالیات' WHEN 8 THEN 'سود جامع سال'  ELSE '--'  END)) as result from Cte_RemainAccountsBaseDecimalCount  where JYEAR>=0 order by JYEAR ASC,type;","params":[]}]]);

-- local dec = json.decode(query)

template = [[
<!DOCTYPE html><html dir="rtl" lang="en"> <head> <meta charset="UTF-8" /> <meta http-equiv="X-UA-Compatible" content="IE=edge" /> <meta name="viewport" content="width=device-width, initial-scale=1.0" /> <title>صورت مالی: صورت سود و زیان جامع</title> </head> <style> table { width: 1500px; } table, th, td { border: 1px solid gray; border-collapse: collapse; text-align: center; padding: 10px; height: 30px; overflow: hidden; box-shadow: 0 0 20px rgba(0, 0, 0, 0.1); } tbody tr:nth-child(odd) { background-color: #f0f8ff; } tbody tr:nth-child(2) { background-color: #f0f8ff; } .Right { text-align: right; } .Bold { font-size: large; font-weight: bold; } .Border { border-top: 2px solid black; } .Border2 { border-top: 5px double black; } </style> <body> <table> <tr> <td colspan="9" class="Bold">شرکت کشت و صنعت باورد</td> </tr> <tr> <td colspan="9" class="Bold">صورت سود و زیان جامع</td> </tr> <tr> <td colspan="9" class="Bold">سال مالی: سال ۱۴۰۲</td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td colspan="۳">(مبالغ به میلیون ریال)</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td>(تجدید ارائه شده)</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td>یادداشت</td> <td></td> <td>سال ۱۴۰۲</td> <td></td> <td>سال ۱۴۰۱</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td class="Border"></td> <td></td> <td class="Border">میلیون ریال</td> <td></td> <td class="Border">میلیون ریال</td> <td></td> </tr> <tr> <td></td> <td class="Right Bold">سود خالص</td> <td></td> <td></td> <td></td> <td dir="ltr">۱,۰۰۸,۷۳۹,۷۴۹,۷۱۰</td> <td></td> <td dir="ltr">(۲,۵۰۸,۴۰۹,۷۷۱,۵۴۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right Bold"> سایر اقلام سود و زیان جامع که در دوره های آتی به صورت سود و زیان تجدید طبقه بندی نخواهند شد: </td> <td></td> <td></td> <td></td> <td class="Border"></td> <td></td> <td class="Border"></td> <td></td> </tr> <tr> <td></td> <td class="Right">مازاد تجدید ارزیابی دارایی های ثابت مشهود</td> <td></td> <td>۱۶</td> <td></td> <td dir="ltr">(۸,۸۵۴,۹۵۸,۳۳۰)</td> <td></td> <td dir="ltr">۱۰۸,۰۲۰,۲۵۷,۶۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">مالیات بر درآمد اقلام فوق</td> <td></td> <td></td> <td></td> <td dir="ltr">(۷۹۶,۹۴۶,۲۵۰)</td> <td></td> <td dir="ltr">۹,۷۲۱,۸۲۳,۱۹۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">مالیات مربوط به سایر اقلام سود و زیان جامع</td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۸,۰۵۸,۰۱۲,۰۸۰)</td> <td></td> <td class="Border" dir="ltr">۹۸,۲۹۸,۴۳۴,۴۹۰</td> <td></td> </tr> <tr> <td></td> <td class="Right Bold"> سایر اقلام سود و زیان جامع که در دوره های آتی به صورت سود و زیان تجدید طبقه بندی نخواهند شد: </td> <td></td> <td></td> <td></td> <td class="Border"></td> <td></td> <td class="Border"></td> <td></td> </tr> <tr> <td></td> <td class="Right">....................</td> <td></td> <td></td> <td></td> <td dir="ltr">۱,۰۰۸,۷۳۹,۷۴۹,۷۱۰</td> <td></td> <td dir="ltr">(۲,۵۰۸,۴۰۹,۷۷۱,۵۴۰)</td> <td></td> </tr> <tr> <td></td> <td class="Right">مالیات بر درآمد اقلام فوق</td> <td></td> <td></td> <td></td> <td dir="ltr">(۸,۸۵۴,۹۵۸,۳۳۰)</td> <td></td> <td dir="ltr">۱۰۸,۰۲۰,۲۵۷,۶۸۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">سایر اقلام سود و زیان جامع پس از کسر مالیات</td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۷۹۶,۹۴۶,۲۵۰)</td> <td></td> <td class="Border" dir="ltr">۹,۷۲۱,۸۲۳,۱۹۰</td> <td></td> </tr> <tr> <td></td> <td class="Right">سود جامع سال</td> <td></td> <td></td> <td></td> <td class="Border" dir="ltr">(۲,۴۱۲,۹۷۶,۱۴۰)</td> <td></td> <td class="Border" dir="ltr">۲۹,۴۳۵,۵۲۰,۲۲۰</td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td class="Border2"></td> <td></td> <td class="Border2"></td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> <tr> <td colspan="9" class="Bold"> یادداشت های توضیحی، بخش جدایی ناپذیر صورت های مالی است. </td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> <tr> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> <td></td> </tr> </table> </body></html>
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

-- local res = string.format(template, dec[2]["OrgName"], convertToFarsi(dec[2]["YEAR"]), convertToFarsi(format_num(dec[4]["remain"], -1)), convertToFarsi(format_num(dec[3]["remain"], -1)), convertToFarsi(format_num(dec[2]["remain"], -1)), convertToFarsi(format_num(dec[1]["remain"], -1)), convertToFarsi(format_num(dec[2]["remain"] * 0.09, -1)), convertToFarsi(format_num(dec[1]["remain"] * 0.09, -1)), convertToFarsi(format_num(dec[2]["remain"] - dec[2]["remain"] * 0.09, -1)), convertToFarsi(format_num(dec[1]["remain"] - dec[1]["remain"] * 0.09, -1)), convertToFarsi(format_num(dec[4]["remain"], -1)), convertToFarsi(format_num(dec[3]["remain"], -1)), convertToFarsi(format_num(dec[2]["remain"], -1)), convertToFarsi(format_num(dec[1]["remain"], -1)), convertToFarsi(format_num(dec[2]["remain"] * 0.09, -1)), convertToFarsi(format_num(dec[1]["remain"] * 0.09, -1)), convertToFarsi(format_num(dec[6]["remain"], -1)), convertToFarsi(format_num(dec[5]["remain"], -1)), convertToFarsi(format_num(dec[8]["remain"], -1)), convertToFarsi(format_num(dec[7]["remain"], -1)))

teamyar.write_result(context, template)