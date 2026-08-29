local  input = teamyar.get_input();
local invoice_id = input.invoice_id
local date_replace = input.date_replace
--teamyar.write_log('date_replace------'..date_replace)
if date_replace == nil   then
  date_replace = 0 
end
if invoice_id == nil or #invoice_id == 0  then
  invoice_id = 0 
end
local result_uid = ""
local result_referenceNumber = ""

local invoice_factor_code = input.invoice_factor_code
if invoice_factor_code== nil then 
  invoice_factor_code=""
end 

-- Multiplication table (Damm algorithm)
local _multiplicationTable = {
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
    {1, 2, 3, 4, 0, 6, 7, 8, 9, 5},
    {2, 3, 4, 0, 1, 7, 8, 9, 5, 6},
    {3, 4, 0, 1, 2, 8, 9, 5, 6, 7},
    {4, 0, 1, 2, 3, 9, 5, 6, 7, 8},
    {5, 9, 8, 7, 6, 0, 4, 3, 2, 1},
    {6, 5, 9, 8, 7, 1, 0, 4, 3, 2},
    {7, 6, 5, 9, 8, 2, 1, 0, 4, 3},
    {8, 7, 6, 5, 9, 3, 2, 1, 0, 4},
    {9, 8, 7, 6, 5, 4, 3, 2, 1, 0}
}

-- Permutation table
local _permutationTable = {
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
    {1, 5, 7, 6, 2, 8, 3, 0, 9, 4},
    {5, 8, 0, 3, 7, 9, 6, 1, 4, 2},
    {8, 9, 1, 6, 0, 4, 3, 5, 2, 7},
    {9, 4, 5, 3, 1, 2, 6, 8, 7, 0},
    {4, 2, 8, 6, 5, 7, 3, 9, 0, 1},
    {2, 7, 9, 3, 8, 0, 6, 4, 1, 5},
    {7, 0, 4, 6, 9, 1, 3, 2, 5, 8}
}

-- Inverse table
local _inverseTable = {0, 4, 3, 2, 1, 5, 6, 7, 8, 9}

-- Convert string to reversed digit array
local function stringToReversedDigits(num)
    local digits = {}
    for i = #num, 1, -1 do
        digits[#digits + 1] = tonumber(num:sub(i, i))
    end
    return digits
end

-- Generate check digit
local function generateCheckDigit(num)
    local c = 0
    local myArray = stringToReversedDigits(num)

    for i = 1, #myArray do
    local    aa=myArray[i] + 1
    local bb=((i) % 8) + 1
    local cc=_permutationTable[bb][ aa] 
    local ff= _multiplicationTable[c + 1]
        c = ff[cc+ 1]
    end

    return tostring(_inverseTable[c + 1])

end

-- Usage
-----------------------------------------------------
local function ValidateCheckDigit(num)
    local c = 0
    local myArray = stringToReversedDigits(num)
    for i = 1, #myArray do
        c = _multiplicationTable[c + 1][_permutationTable[(i - 1) % 8 + 1][myArray[i] + 1] + 1]
   
    end

    return (c == 0)
end

--------------------------------------------------------------
--------------------------------------------------------------
function hex_to_decimal(hex_str)
  local hasLeadingZero = hex_str:sub(1, 1) == "0"
    -- Remove '0x' prefix if present and convert to uppercase
    hex_str = hex_str:gsub("^0x", ""):upper()
    -- Check for valid hexadecimal characters
    if not hex_str:match("^[0-9A-F]+$") then
        return nil, "Invalid hexadecimal string"
    end
    local decimal=0
    local str_decimal = ""
    local length = #hex_str
    
    for i = 1, length do
        local char = hex_str:sub(i, i)
        local value
        
        if char:match("%d") then  -- 0-9
            value =char
        else  -- A-F
            value = string.byte(char) - string.byte('A') + 10
        end
        decimal = decimal+(value * (16 ^ (length - i)))
    end
     if hasLeadingZero then
        str_decimal = "0" ..string.format("%18.0f" ,decimal)
    end
    return str_decimal:gsub("%s+", "")
end

-- Example usage:
local hex_num = "1A3F"
local decimal_num, err = hex_to_decimal(hex_num)

if decimal_num then
    -- Output: Hexadecimal 1A3F = Decimal 6719
else
    teamyar.write_log("Error:", err)
end
----------------------------------------------------------------
function pad_with_zero(num)
    -- Convert number to string
    local num_str = tostring(num)
    
    -- Check if string is already 10 chars or longer
    if #num_str >= 12 then
        return num_str
    end
    
    -- Calculate how many zeros to add
    local zeros_to_add = 12 - #num_str
    
    -- Add leading zeros
  local strig_with_zero= string.rep("0", zeros_to_add) .. num_str
  -- add prefix kind repair/delete


    --return kind_prefix..strig_with_zero
  return strig_with_zero
end

----------------------------------------------------------------------------
function convetUTF8(p1)
  local text=""
  	for i = 1, #p1 do
	  local c = p1:byte(i)
	  if c < 65 then
		text = text .. string.format('%d', c - 48)
	  else
		text = text .. string.format('%d', c)
	  end
	end
  return text
end
--------------------------------------------------------------------
function resutStr(p1,p2,p3)
  local str =convetUTF8(p1)
  local hex2=hex_to_decimal(p2)
  str= str..hex2
  local tt=hex_to_decimal(p3)
  tt= string.format("%18.0f" ,tt)
  tt=pad_with_zero(tonumber(tt))
  str= str..tt
  local num=str:gsub("%s+", "")
  str=p1..p2..p3..generateCheckDigit(num)-- verhoeff_checksum(num)
  return str:gsub("%s+", "")
end
-----------------------------------------------------------
function fileToString(file)
  local str=""
  if file ~= nil and file[1] ~= nil and  file[1].module_id ~= nil and file[1].id ~= nil and file[1].mime ~= nil then
    local file_manager = teamyar.create_file_manager(file[1].module_id);
    str = file_manager:readFile(file[1].id);
    file_manager:release();
  end

  return str
end
------------------------------------get config

local c_url = ""
local c_memory_tax_id = ""
local c_public_key_id = ""
local c_org_id = 0
local c_economic_number = ""
local c_tax_rate_number = 10
local c_kind_refrence = 3
  local config = teamyar.get_config()
local config_data = {}
if config ~= nil then 
  config_data = config.data
end 
local c_count_repair =0
local c_price_repair = 0 
 -- c_kind_refrence = input.kind_refrence
  c_count_repair =input.count_repair
  c_price_repair =input.price_repair

if config_data ~= nil then  
  c_url = config_data.url
  c_tax_rate_number = config_data.tax_rate_number
  c_memory_tax_id = config_data.memory_tax_id
  c_public_key_id = config_data.public_key_id
  c_org_id = config_data.org_id
  c_economic_number = config_data.economic_number
  private_key = fileToString(config_data.private_key)
  certificate = fileToString(config_data.certificate)

end
if c_count_repair == nil then 
  c_count_repair =0 
end 
if c_price_repair == nil then 
  c_price_repair =0 
end
if c_kind_refrence == nil then 
  c_kind_refrence =3
end
---------------------------------------------------------------
function getInvoiceDate(invoice_id)
  local query = [[   with DecimalDigits as( 
 select po.ORG_ID,ps.DECIMAL_COUNT DecimalCount, (CASE WHEN COALESCE(ps.FEE_DECIMAL,0) = 0 THEN COALESCE(ps.DECIMAL_COUNT,0) ELSE COALESCE(ps.FEE_DECIMAL,0) END )DigitFee,ps.SHORT_NAME
 from pa_organizations po join pa_symbols ps on(po.BASE_CURRENCY = ps.ID and po.ORG_ID = ps.ORG_ID)
 )
  							select i.DATE_CREATE,i.RUN_DATE,TYPE,i.CLIENT_ID,
                            ( select CODE from org_info where id=i.org_id)org_code,i.PAYMENT_TYPE,i.bill_type,
                            i.bill_template,(pi.QUANTITY/ POW(10,sc.DECIMAL_NUM))QUANTITY,pi.VALUE_ADDED ,
                            i.REMAINED_AMOUNT,(pi.FEE/POWER(10,COALESCE(dd.DigitFee,0))) fee,
                             TAX+TOLL+VALUE_ADDED value_add_price,
                            pi.DISCOUNT,(pi.TAX/POWER(10,COALESCE(dd.DigitFee,0))+BASE_SYMBOL_TOLL)tax,(pi.toll)/POWER(10,COALESCE(dd.DigitFee,0))toll,p.tx_code ,p.name,0 base_deciaml_fee,
                            (select pm.user_TYPE from profile_user_info pm inner join pa_client c on c.REFFERE_ID=pm.id where c.id =i.client_id and c.ORG_ID=i.ORG_ID  limit 1) buyer_type,
                            (  select nc.NATIONAL_CODE from profile_nationalcode nc inner join pa_client c on c.REFFERE_ID= nc.user_id where c.id=i.client_id and c.ORG_ID=i.ORG_ID  limit 1)client_national_code,
                            (select crm.tin from crm_info crm inner join pa_client c on crm.id=c.REFFERE_ID where c.id=i.client_id  and c.ORG_ID=i.ORG_ID limit 1) tin ,
  							0 symbole_rate,
  							(select POSTAL_CODE from profile_user_address ad inner join pa_client c
  							on c.REFFERE_ID= ad.user_id  where c.id=i.client_id and c.org_id=i.org_id limit 1)postal_code,
                           0 row_price,i.SALES_AGENT,
                             (  select nc.NATIONAL_CODE from profile_nationalcode nc where nc.user_id=i.SALES_AGENT   limit 1)agent_national_code,
  							COALESCE((SELECT sum(PRICEAFTER_DISCOUNT) FROM sales_invoice_settlement where invoice_id=i.id and type<>1 ),0)pay_naghd,dd.SHORT_NAME, SC.id_in_moadiyan 
                            from sales_invoice i inner join sales_invoice_product pi on pi.invoice_id=i.id
                            inner join wh_product p on p.id=pi.product_id left  join DecimalDigits dd on dd.org_id= i.org_id 
                              left join wh_stock_capacity    sc   on p.CAPACITY_ID = sc.ID   
                              where i.ID=]]..invoice_id
  local result = queryResultInvoice(query, {})
  local res = result[1]
  local res_inv_direct ={}
  res_inv_direct , unic_tax_id =  createJson(result)
  return  res_inv_direct , unic_tax_id
end 
--------------------------------------------------
function queryResultInvoice(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, { date_create = record[1],
          date_run = record[2],
        type = record[3],
        client_code = record[4],
        org_code = record[5],
        payment_type = record[6],
        bill_type = record[7],
        bill_template = record[8],
        quantity = record[9],
        value_adde = record[10] ,
        remainded_amount = record[11],
        fee = record[12],
        value_add_price = record[13],
        discount = record[14],
        tax = record[15],
        toll = record[16],
        tx_code = record[17],
        pname = record[18] ,
        base_deciaml_fee = record[19],
        buyer_type = record[20],
        client_national_code = record[21],
        tin = record[22],
        symbole_rate =  record[23],
        client_postal_code = record[24],
        row_price = record[25],
        agent = record[26],
        agent_national_code = record[27],
        price_naghd = record[28],
        short_name = record[29],
        unit_id_in_moadian = record[30]
      });
  end
  db.query_free();
  return res_text;
end
--------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text ~= nil then 
      return res_text[1];
  else
return nil 
  end 
end
------------------------------------------------
function createJson(res)
   local tax_unic_id = ""
    if date_replace~=nil and  tonumber(date_replace)~=nil then --تاریخ جایگزین از بات ارسال گروهی
    -- teamyar.write_log("res---55555555555555555555555555-")
    unix_date_run = time.get_unixtime(string.format("%18.0f", date_replace)) 
    unix_create_date = time.get_unixtime(string.format("%18.0f", date_replace))
  else
    unix_date_run = time.get_unixtime(string.format("%18.0f", res[1].date_run))  
    unix_create_date = time.get_unixtime(string.format("%18.0f", res[1].date_create))
  end

  local pay_price = 0
  local pay_type = 1
  local seller_code = res[1].org_code
  local user_type = 0
  local   buyer_economic_code = 0
  local buyer_postal_code = nil 
  if res[1].buyer_type == 3 then
    buyer_economic_code = "0000"..res[1].client_national_code
    buyer_postal_code = res[1].client_national_code
    user_type = 1
  else 
    buyer_economic_code = res[1].client_national_code -- res[1].tin
    user_type = 2
  end

  local factor_subject_num = 1
  if res[1].type==3 then 
    factor_subject_num = 4
  end 
  
  local meli_ec_code = 0
  local price_by_disc = res[1].remainded_amount
  local sum_bill =  remainded_amount
  local sum_tax = 0
  local sum_before_dic = 0
  local sum_discount = 0
  local sum_tax_toll = 0
  local sum_all = 0 
    local sum_all_pay =0 
  local tbl_body ={}
  for i, v in ipairs(res) do
    if tonumber(c_price_repair) ~= nil and tonumber(c_price_repair) >0 then 
      v.fee=tonumber(c_price_repair)
    end
    if tonumber(c_count_repair)~= nil and tonumber(c_count_repair)>0 then 
      v.quantity =tonumber( c_count_repair)
    end 
    sum_tax = sum_tax + math.floor( (((v.fee * v.quantity) - v.discount)*c_tax_rate_number)/100)
    sum_before_dic = sum_before_dic +( v.fee*v.quantity)
    sum_discount = sum_discount + v.discount
    sum_tax_toll = sum_tax_toll +  math.floor((((v.fee* v.quantity)- v.discount )*c_tax_rate_number)/100 )+ v.toll
    sum_all = sum_all+math.floor((((v.fee* v.quantity)- v.discount )*c_tax_rate_number)/100 ) +((v.fee* v.quantity)- v.discount )
     sum_all_pay = sum_all_pay+ math.floor((((v.fee* v.quantity)- v.discount )*c_tax_rate_number)/100 )+((v.fee* v.quantity)- v.discount )
    table.insert(tbl_body,
        {
      sstid = tostring(v.tx_code),  --شناسه کاال/خدمت
      sstt = v.pname,             --kala name
      mu=tostring(v.unit_id_in_moadian), -- "1627",  -- واحد اندازه گیری
      am = v.quantity,  --تعداد/مقدار
      fee =v.fee,  ---مبلغ واحد
      cfee = nil,  --میزان ارز
      cut = nil,  ---نوع ارز
      exr =nil, -- v.symbole_rate ,  --- نرخ برابری ارز با ریال
     prdis = v.fee*v.quantity ,  ---مبلغ قبل از تخفیف
      dis = v.discount,  --مبلغ تخفیف
     adis = (v.fee*v.quantity) -v.discount ,  -- مبلغ بعد از تخفیف
      vra =tonumber(c_tax_rate_number),  --نرخ مالیات برارزش افزوده
     vam =math.floor( (((v.fee*v.quantity) - v.discount )*c_tax_rate_number)/100), --v.tax,  --مبلغ مالیات بر ارزش افزوده
      odt= nil,  --موضوع سایرمالیات و عوارض
      odr= nil,  --نرخ سایرمالیات و عوارض
      odam= nil,  --مبلغ سایرمالیات و عوارض
      lt= nil,  --موضوع سایر وجوه قانونی
      olr= nil,  -- نرخ سایر وجوه قانونی
      olam= nil,  --مبلغ سایر وجوه قانونی
      consfee= nil,  -- اجرت ساخت
      spro= nil,  --سود فروشنده
      bros= nil,  -- حقالعمل
      tcpbs= nil,  --جمع کل اجرت، حق-العمل و سود
      cop= math.floor( ((((v.fee * v.quantity) - v.discount)*c_tax_rate_number)/100)+ (((v.fee * v.quantity) - v.discount))) ,-- ((v.fee- v.discount) * v.quantity ) ,  --سهم نقدی از پرداخت
      vop=  math.floor(( (((v.fee* v.quantity)- v.discount  )*c_tax_rate_number)/100)),  --سهم ارزش افزوده از پرداخت
      bsrn= nil,  --شناسه یکتای ثبت قرارداد حق العملکاری
      tsstam=--  ((v.fee*v.quantity )- v.discount) 
        math.floor(( (((v.fee* v.quantity)- v.discount  )*c_tax_rate_number)/100) +((v.fee* v.quantity)- v.discount  ))-- tonumber(v.remainded_amount)//v.quantity  --مبلغ کل کاال/خدمت
    }
    )
  end 
  local kind_prefix = "2"
   if c_kind_refrence == 3 then 
    kind_prefix = "3"
  end 
  local sum_riali = res[1].remainded_amount
  local sum_currency = res[1].remainded_amount
  local hex_invoice_id = string.format('%04x', kind_prefix..invoice_id)
if #hex_invoice_id == 1 then
  hex_invoice_id = "000000000"..hex_invoice_id
elseif #hex_invoice_id == 2 then
  hex_invoice_id = "00000000"..hex_invoice_id
elseif #hex_invoice_id == 3 then
  hex_invoice_id ="0000000"..hex_invoice_id
elseif #hex_invoice_id == 4 then
  hex_invoice_id = "000000"..hex_invoice_id
elseif #hex_invoice_id == 5 then
  hex_invoice_id = "00000"..hex_invoice_id
elseif #hex_invoice_id == 6 then
  hex_invoice_id = "0000"..hex_invoice_id
elseif #hex_invoice_id == 7 then
  hex_invoice_id = "000"..hex_invoice_id
elseif #hex_invoice_id == 8 then
  hex_invoice_id = "00"..hex_invoice_id
elseif #hex_invoice_id == 9 then
  hex_invoice_id = "0"..hex_invoice_id
end
  local factor_date_milady = 0
  -- teamyar.write_log('8888888888888888888881')
  if date_replace~=nil and tonumber(date_replace)~=nil then 
    local q_date =  [[ select concat(GYEAR,'/',(select case when LENGTH(GMONTH)>1 
    then GMONTH else concat('0',GMONTH) end) ,'/',(select case when LENGTH(GMDAY)>1 
    then GMDAY else concat('0',GMDAY) end)) from report_dimdate where 
    ]]..date_replace..[[ between datekey and datekey+(60*60*24*10000000)-(60*10000000)]]
    factor_date_milady=queryResult(q_date,{})

  else
    --  teamyar.write_log('84444444444444441')
    local q_date =  [[ select concat(GYEAR,'/',(select case when LENGTH(GMONTH)>1 
    then GMONTH else concat('0',GMONTH) end) ,'/',(select case when LENGTH(GMDAY)>1 
    then GMDAY else concat('0',GMDAY) end)) from report_dimdate where 
    (select RUN_DATE from sales_invoice i  where id= ]]..invoice_id..[[ ) between datekey and datekey+(60*60*24*10000000)-(60*10000000)]]
    factor_date_milady=queryResult(q_date,{})
  end
  	local year, month, day = factor_date_milady:match('(%d+)/(%d+)/(%d+)');
	
	if year == nil or month == nil or day == nil then
	  error('Invalid date format. Expected YYYY/MM/DD');
	end
	
	local unixtime = time.get_unixtime({ year = year, month = month, day = day });
	local days = unixtime / 86400;
	local days_dec = string.format('%.6d', days);
	local days_hex = string.format('%.5X', days);
  tax_unic_id =resutStr(c_memory_tax_id, days_hex, hex_invoice_id)
  local org_code=queryResult([[SELECT CODE FROM  org_info where id =]]..c_org_id)
      local buyer_postal_code=tostring(res[1].client_postal_code)
  if #buyer_postal_code==0 then 
    buyer_postal_code="1111111111"
  end
  teamyar.write_log("invoice_factor_code----"..invoice_factor_code)
  local res_inv_direct ={
    header =
    {
      taxid =tax_unic_id,  --شماره منحصر به فرد مالیاتی 
      indatim =  unix_date_run*1000, --تاریخ صدور -- 1762325770000,--
     indati2m = unix_create_date*1000 , -- 1762325808000--, -- تاریخ ایجاد
      inty= 1,--res[1].bill_type, -- نوع صورتحساب
      inno= hex_invoice_id,  --سریال صورتحساب با طول 10 هگز
      irtaxid= invoice_factor_code, --شماره منحصر به فردمالیاتی صورتحساب مرجع
    inp=1,-- res[1].bill_template,  -- الگوی صورتحساب یک فروش
      ins= tonumber(c_kind_refrence), -- موضوع صورتحساب 1اصلی 2 اصلاحی 3-ابطالی 4-برگشت از فروش
      tins= tostring(c_economic_number),  -- شماره اقتصادی فروشنده
     tob= user_type, --وع شخص خریدار 1حقیقی 2 حقوقی
      bid= tostring(res[1].client_national_code),  --  کد ملی خریدار
      tinb= tostring(buyer_economic_code), --- شماره اقتصادی خریدار
      sbc=nil, --tonumber(org_code),  --کد شعبه فروشنده
     bpc= buyer_postal_code, --tostring(res[1].client_postal_code),  -- کد پستی خریدار
      bbc= nil,  --کد شعبه خریدار
      ft= nil,  --  نوع پرواز
      bpn= nil,  --شماره گذرنامه خریدار
      scln= nil,  -- شماره پروانه گمرکی فروشنده
      scc= nil,  --  کد گمرک محل اظهار
      crn= nil,  --شناسه یکتای ثبت قرارداد فروشنده
      billid= nil, -- شماره اشتراک/ شناسه بهره بردار قبض
      tprdis= sum_before_dic,  --مجموع مبلغ قبل از کسر تخفیف
      tdis= sum_discount,  --مجموع تخفیفات
      tadis= sum_before_dic-sum_discount, ---مجموع مبلغ پس ازکسر تخفیف
      tvam= sum_tax,  --مجموع مالیات بر ارزش افزوده
      todam= 0,  --مجموع سایر مالیات، عوارض و وجوه قانونی
      tbill = math.floor(sum_all), -- sum_riali,  --مجموع صورتحساب
      setm=1, -- res[1].payment_type,  --  روش تسویه 1نقد 2 تسویه 3 نقدنسیه
    cap= math.floor(sum_all_pay),  --مبلغ پرداختی نقدی
   insp= 0, --مبلغ پرداختی نسیه
      tvop= math.floor(sum_tax),  --مجموع سهم مالیات برارزش افزوده از پرداخت
      dpvb= nil,  --عدم پرداخت مالیات برارزش افزوده خریدار
      tax17= nil  --مالیات موضوع ماده 17
    },
    body =tbl_body,
  
 
    payments= {
    {
      iinn= nil,  --شماره سوییچ پرداخت
      acn= nil,  ---شماره پذیرنده فروشگاهی
      trmn= nil, --شماره پایانه
      trn= nil,  --شماره پیگیری
      pcn=nil,  --شماره کارت پرداخت کننده صورتحساب
      pid=  "0"..tostring(res[1].client_national_code),  --شماره/شناسه ملی/کد فراگیر اتباع غیر ایرانی پرداخت کننده صورتحساب
      pdt= unix_date_run*1000, --1762325770000  --تاریخ و زمان پرداخت صورتحساب
    }
    },
    extension= {
    {
      key= nil,  --
      value= nil  --
    }
    }
  }

  teamyar.write_log("res_inv_direct-------------"..json.encode(res_inv_direct))
  return res_inv_direct ,tax_unic_id
end
----------------------------------------------------

function getChallenge()
  local datatocken = {time=1,
    packet= {
uid=nil,
    packetType="GET_TOKEN",
retry= false,
data= {
username= "test-tsp-id-1"
},
encryptionKeyId= "",
symmetricKey= "",
iv= "",
fiscalId= "",
dataSignature=""
  },signature=
[[IiIdkclswu3Krc8ZM7MQvEy7ZWzJmBPSl1CQrI0dhLGdRPRrmomVo+UkbdzRyuth9G4EnbgOjnjz
5WJcfO8MuBVouASTMfv/OCOhAkxTudQtWzUO0d6BU/YiRT5alNwdey0dMsn3T083luLv9iG/lKKz9
ewUem0RwBYOnehD6rJFXHirGDfJPHBOTSHCqHL1vQe0JLZAQwaTTieEE8zNWXwNr53BS2KxRKX8+M
leoUl8LWUn6wZS/zs3auOKSRSO5pgJVq6zZCadd5D7vlhrw1KB/XfO4pv8GexAx2dbRMiGG5eumQG
BcLo1RvJW2mZsGu+dQRm/NwnIpN7CP5qlkg==]]
  }
	local nonce = '';
	local curl = teamyar.create_curl();
	if curl:connect({ domain = c_url, port = 443, ssl = true, secure = false }) then
		local request_params = {
			method = "GET",
      
    --  url = "/req/api/self-tsp/sync/GET_TOKEN?timeToLive=200",
			url = "/requestsmanager/api/v2/nonce?timeToLive=200",
			headers = {

    --   { name = "requestTraceId", value = coding.uuid() },
     -- { name = "Content-Type", value = "application/json" },
       -- name = "timestamp", value = "1655185848687" },
				{ name = "Accept", value = "*/*" },
			},
     -- 	data_str = json.encode(datatocken)
		};

		if curl:sendRequest(request_params) then
			local res = curl:getResponse();
      		teamyar.write_log('challenge 5555 response is: ' .. res);
			if curl:getStatus() == 200 then
				teamyar.write_log('challenge response is: ' .. res);
				nonce = json.decode(res).nonce
			else
				teamyar.write_log('status code error: 4 ' .. curl:getStatus())
			end
		end
		curl:disconnect();
	else
		teamyar.write_log('cannot connect to sandboxrc.tax.gov.ir')
	end
	curl:release();
	return nonce;
end


---------------------------------------------------------------------
function generateJWT(payload)

	local certificate =fileToString(config_data.certificate) -- teamyar.get_attachment('certificate.txt');
	local private_key =  fileToString(config_data.private_key) -- teamyar.get_attachment('private-key.txt');
	local tYear,tMonth,tDay,tHour,tMinute,tSecond = string.match(time.get_str(time.current()),'(%d+).(%d+).(%d+) (%d+):(%d+):(%d+)');

	local param_jwt = {
		algorithm = "RS256",
		secret = private_key,
		headers =  {
		alg = "RS256",
		sigT= string.format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ',tYear,tMonth,tDay,tHour,tMinute,tSecond),
		crit={"sigT"},
		x5c = {certificate},
		},
		payload = payload
	}
--teamyar.write_log("param_jwt---"..json.encode(param_jwt))
	return coding.jwt(param_jwt);
end
---------------------------------------------------------------
function generateToken(nonce, clientId)
	return generateJWT({
		nonce = nonce,
		clientId = clientId
	});
end
---------------------------------------------------------------
function getServerInfo(token)
	local server_info = '';
	local curl = teamyar.create_curl();
	if curl:connect({ domain = c_url, port = 443, ssl = true, secure = false }) then
		local request_params = {
			method = "GET",
			url = "/requestsmanager/api/v2/server-information",
			headers = {
				{ name = "Authorization", value = "Bearer " .. token},
			},
		};

		if curl:sendRequest(request_params) then
			server_info = curl:getResponse();
			if curl:getStatus() == 200 then
			--	teamyar.write_log('server_info response is: ' .. server_info);
			else
			--	teamyar.write_log('status code error: ' .. curl:getStatus())
			end
		end
		curl:disconnect();
	else
		--teamyar.write_log('cannot connect to '..c_url)
	end
	curl:release();
	return server_info;
end
---------------------------------------------------------------
function createInvoiceJWT(payload)
	return generateJWT(payload);
end
---------------------------------------------------------------
function createJWE(invoice_payload, kid)
	local server_public_key = teamyar.get_attachment('server-public-key.txt');
	local invoice_jwt = createInvoiceJWT(invoice_payload);

	local jwe_obj = {
		headers = {
			alg = "RSA-OAEP-256",
			enc = "A256GCM",
			kid = kid
		},
		plain_text = invoice_jwt,
		public_key= server_public_key
	};
	return coding.jwe(jwe_obj);
end
---------------------------------------------------------------
function generate_unique_id(p1, p2, p3)
	local year, month, day = p2:match('(%d+)/(%d+)/(%d+)');
	
	if year == nil or month == nil or day == nil then
	  error('Invalid date format. Expected YYYY/MM/DD');
	end
	
	local unixtime = time.get_unixtime({ year = year, month = month, day = day });
	local days = unixtime / 86400;
	local days_dec = string.format('%.6d', days);
	local days_hex = string.format('%.5X', days);
	local text = '';
  
	for i = 1, #p1 do
	  local c = p1:byte(i)
	  if c < 65 then
		text = text .. string.format('%d', c - 48)
	  else
		text = text .. string.format('%d', c)
	  end
	end
  
	text = text .. days_dec .. string.format('%.12d', tonumber('0x' .. p3:gsub('^[0]+', '')));
---------------------------------------------------------------  
	function generate_verhoeff(data)
	  -- The multiplication table
	  local verhoeff_d   = {
		{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
		{ 1, 2, 3, 4, 0, 6, 7, 8, 9, 5 },
		{ 2, 3, 4, 0, 1, 7, 8, 9, 5, 6 },
		{ 3, 4, 0, 1, 2, 8, 9, 5, 6, 7 },
		{ 4, 0, 1, 2, 3, 9, 5, 6, 7, 8 },
		{ 5, 9, 8, 7, 6, 0, 4, 3, 2, 1 },
		{ 6, 5, 9, 8, 7, 1, 0, 4, 3, 2 },
		{ 7, 6, 5, 9, 8, 2, 1, 0, 4, 3 },
		{ 8, 7, 6, 5, 9, 3, 2, 1, 0, 4 },
		{ 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
	  };
  
	  -- The permutation table
	  local verhoeff_p   = {
		{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
		{ 1, 5, 7, 6, 2, 8, 3, 0, 9, 4 },
		{ 5, 8, 0, 3, 7, 9, 6, 1, 4, 2 },
		{ 8, 9, 1, 6, 0, 4, 3, 5, 2, 7 },
		{ 9, 4, 5, 3, 1, 2, 6, 8, 7, 0 },
		{ 4, 2, 8, 6, 5, 7, 3, 9, 0, 1 },
		{ 2, 7, 9, 3, 8, 0, 6, 4, 1, 5 },
		{ 7, 0, 4, 6, 9, 1, 3, 2, 5, 8 }
	  };
  
	  --The inverse table
	  local verhoeff_inv = { 0, 4, 3, 2, 1, 5, 6, 7, 8, 9 };
  
	  --For a given number generates a Verhoeff digit
	  local len          = #data;
	  local ch           = 0;
  
	  for i = 1, len do
		ch = verhoeff_d[ch + 1][verhoeff_p[(i % 8) + 1][data:byte(len - i + 1) - 47] + 1];
	  end
  
	  return verhoeff_inv[ch + 1];
	end
  
	return p1 .. days_hex .. p3 .. string.format('%d', generate_verhoeff(text));
end
---------------------------------------------------------------
function sendInvoices(clientId, token, invoices,tax_unic_id22)
	local payload = {};
--teamyar.write_log("tax_unic_id22----"..tax_unic_id22)
	for index, value in ipairs(invoices) do
		table.insert(payload, {header={requestTraceId=coding.uuid(), fiscalId=tax_unic_id22 }, payload=value});
	end
	
	local invoice_response = '';
	local curl = teamyar.create_curl();
	if curl:connect({ domain = c_url, port = 443, ssl = true, secure = false }) then
		local request_params = {
			method = "POST",
			url = "/requestsmanager/api/v2/invoice",
			headers = {
				{ name = "accept", value = "*/*" },
				{ name = "Authorization", value = "Bearer " .. token},
				{ name = "Content-Type", value = "application/json" },
			},
			data_str = json.encode(payload)
		};
--teamyar.write_log("request_params**--.."..json.encode(request_params))
		if curl:sendRequest(request_params) then
			invoice_response = curl:getResponse();
			if curl:getStatus() == 200 then
			--	teamyar.write_log('invoice response is: ' .. invoice_response);
			else
			--	teamyar.write_log('status code error 2: ' .. curl:getStatus())
			end
		end
		curl:disconnect();
	else
	--	teamyar.write_log('cannot connect to '..c_url)
	end
	curl:release();
	return invoice_response;
end
---------------------------------------------------------------
function main()
	local nonce = getChallenge();
	local token = generateToken(nonce,   c_memory_tax_id);
	-- local server_info = getServerInfo(token);

	local invoice_payload,tax_unic_id22 = getInvoiceDate(invoice_id)

	local invoices = {
		createJWE(invoice_payload, c_public_key_id)
	};

	--local sendInvoicesResponse = sendInvoices(  c_memory_tax_id, token, invoices,tax_unic_id22);
  local sendInvoicesResponse = sendInvoices(  c_memory_tax_id, token, invoices,c_memory_tax_id);
  if #sendInvoicesResponse>0 and json.decode(sendInvoicesResponse)~=nil and  json.decode(sendInvoicesResponse).result ~= nil then 
          result_uid = json.decode(sendInvoicesResponse).result[1].uid
      result_referenceNumber = json.decode(sendInvoicesResponse).result[1].referenceNumber
    teamyar.write_log("فاکتور در سامانه مودیان ثبت شد".."<br>result_uid:<br>"..result_uid.."  <br>  ".."result_referenceNumber:<br>"..result_referenceNumber.."    ");
  teamyar.write_result("فاکتور در سامانه مودیان ثبت شد".."<br>result_uid:<br>"..result_uid.."  <br>  ".."result_referenceNumber:<br>"..result_referenceNumber.."    ");
  end 
--	teamyar.write_result(sendInvoicesResponse);
  
end
---------------------------------------------------------------------------------------------------------------------------
function inquery(refrence_id)
      teamyar.write_log("params_inq-d;sf;ldk")
  	local nonce = getChallenge();
	local ctocken ="Bearer "..generateToken(nonce,   c_memory_tax_id);
  local res_inquery ={}
  local res_status=0
  local curli = teamyar.create_curl();
  local status=""
  if curli:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
    local params_inq= {
      method = "GET", 
      url = "/requestsmanager/api/v2/inquiry-by-reference-id?referenceIds="..refrence_id, 
      headers = {
        {name = "Accept", value = "*/*"}, 
        {name = "Authorization", value = ctocken },
      },
    };
  --  teamyar.write_log("params_inq-------"..json.encode(params_inq))
    local sended = curli:sendRequest(params_inq)
    if sended then
      res_inquery= curli:getResponse()
      res_status= curli:getStatus() 
     -- teamyar.write_log("eres status--"..json.encode(res_status))
      teamyar.write_log("res_inquery--"..res_inquery)

      if res_status == 500 then
        status="خطا در دریافت استعلام  "
        return ""
      elseif res_status== 200 then
        if #json.decode(res_inquery)== 0 then
          status="FAILED"
          msg_modian = "استعلام از سامانه دریافت نشد مجدد فاکتور ابطالی را ارسال کنید"
        else
        status=json.decode(res_inquery)[1].status
        end
        teamyar.write_log("status--"..json.encode(status))

      else
        status="خطا در ارسال درخواست استعلام  "
        return ""
      end
    end
    curli:disconnect();
  end
  curli:release();  
  
  -----log 
  local msg_modian= ""
  if res_inquery ~= nil then 
    if #json.decode(res_inquery)>0 and json.decode(res_inquery)[1] ~= nil then 
      if json.decode(res_inquery)[1].data ~= nil then 
        if  json.decode(res_inquery)[1].data.error ~= nil then 
          if  json.decode(res_inquery)[1].data.error[1] ~= nil then 
          msg_modian =  json.decode(res_inquery)[1].data.error[1].message
          end 
        end 
      end 
    end 
  end 
    local info_log =  {
    org_id = c_org_id,
    history = "استعلام فاکتوراز سامانه مودیان".."<br>result_uid:<br>وضعیت:"..status.."  <br>  ".."پیام:<div id='res_inquery'>"..msg_modian.."</div>",
    invoice_id = invoice_id
  }
  local   res_log = teamyar.call_api(23,  '/api/sales/update_invoice_history', info_log);
  teamyar.write_log("res_log---"..json.encode(res_log))

  local mstatus=5 
  if status ~= "FAILED" then 
    mstatus = 6
  end 
  -----update taxpayer status
  local info_update_status ={
    org_id = c_org_id,
    invoice_id = invoice_id,
    moadian_status =mstatus
  }
  local   res_update_status = teamyar.call_api(23,  '/api/sales/update_moadian_status', info_update_status);
  teamyar.write_log("res_update_status---"..json.encode(res_update_status))
  local res_inquery_str=""
  if #json.decode(res_inquery)>0 and #json.decode(res_inquery)[1].data~= nil then
      if #json.decode(res_inquery)[1].data.error>0  then 
        res_inquery_str=json.decode(res_inquery)[1].data.error[1].message.."  وضعیت:"..status

      else
        res_inquery_str="عدم وجود خطا وضعیت : "..status
      end
  else
  res_inquery_str="استعلام انجام شد وضعیت "..status
  end 
  return res_inquery_str
end
---------------------------------------------------------------
local check_sended_invoice=queryResult( [[select moadian_status from sales_invoice where id=]]..invoice_id,{})
local factor_org_id = queryResult([[select org_id  from sales_invoice where id=]]..invoice_id,{})
teamyar.write_log("check_sended_invoice-------"..check_sended_invoice)
if tonumber(factor_org_id)==tonumber(c_org_id) then 
   if check_sended_invoice == 3  or check_sended_invoice == 5 then --تایید یا خطا در ابطال
      main();
    -------------------------------history
        local info_log =  {
          org_id = c_org_id,
          history = "فاکتور در سامانه مودیان ابطال شد".."<br> ".."result_referenceNumber:<br>"..result_referenceNumber  ,
          invoice_id = invoice_id
        }
        local   res_log = teamyar.call_api(23,  '/api/sales/update_invoice_history', info_log);
      teamyar.write_log("res_log---"..json.encode(res_log))
        -----update taxpayer status
        local info_update_status ={
          org_id = c_org_id,
          invoice_id = invoice_id,
          moadian_status =4
        }
        local   res_update_status = teamyar.call_api(23,  '/api/sales/update_moadian_status', info_update_status);
      teamyar.write_log("res_update_status---"..json.encode(res_update_status))
      -------------------------------history


  elseif check_sended_invoice == 4 then 
     local referenceNumber= input.referenceNumber
    if referenceNumber ~= nil then
         local res_inquery =  inquery(referenceNumber)
        teamyar.write_log("res_inquery------"..res_inquery)
        teamyar.write_result(res_inquery)
    end 
  end 
else 
  teamyar.write_result("شناسه سازمان انتخاب شده با سازمانی که در آن فاکتور ثبت شده است متفاوت است  ")
end 