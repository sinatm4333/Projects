local  input = teamyar.get_input();
local invoice_id = input.invoice_id
local date_replace = input.date_replace
local input_unic_id = (input.unic_id or ""):gsub("^%s+", ""):gsub("%s+$", "")
local org_id_input = input.org_id or ""
--teamyar.write_log("del_fact input_unic_id="..tostring(input_unic_id).." input_keys="..tostring(input.referenceNumber))
local factor_tax_id = ""
if date_replace == nil   then
  date_replace = 0 
end

local function check_last_inquired()
  local last = queryResult([[SELECT inquired FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
  return tonumber(last) == 1
end

local function do_inquiry_first()
  if check_last_inquired() then return end
 -- teamyar.write_log("del fact: invoice "..tostring(invoice_id).." last operation not inquired, doing inquiry first")
  local last_hid = queryResult([[SELECT id FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
  local last_ref = queryResult([[SELECT TRIM(ref_id) FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND ref_id!='' ORDER BY id DESC LIMIT 1]], {}) or ""
  local last_unic = queryResult([[SELECT TRIM(unic_id) FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND unic_id!='' ORDER BY id DESC LIMIT 1]], {}) or ""
  pcall(function()
    local res_bot = teamyar.run_command("2/inquery_invoice_taxpayer_m/", {
      referenceNumber = last_ref, invoice_id = tostring(invoice_id), org_id = org_id_input, unic_id = last_unic
    })
    local res_status = teamyar.run_command("2/fact_st_m", { invoice_id = tostring(invoice_id), org_id = org_id_input })
    local h_err = ""
    local h_comment = ""
    pcall(function()
      local parsed = json.decode(res_bot)
      if parsed and parsed.status then h_comment = tostring(parsed.status) end
      if parsed and parsed.get_txt and parsed.get_txt ~= "" then
        local ok2, inq = pcall(json.decode, parsed.get_txt)
        if ok2 and inq and inq[1] and inq[1].data and inq[1].data.error and inq[1].data.error[1] then
          h_err = inq[1].data.error[1].message or ""
        end
      end
    end)
    local where_clause = "WHERE id="..tonumber(last_hid or 0)
    db.start()
    db.query_immediate({query = [[UPDATE `0000000_bot`.moadianz_fact_history
      SET ststus=']]..sql_escape(res_status or "")..[[', comment=']]..sql_escape(h_comment)..[[',
      err=']]..sql_escape(h_err)..[[', inquired=1 ]]..where_clause})
    db.commit()
    db.query_free()
    db.use_db("0000000")
  end)
end

local function get_active_cancel_unic_id()
  local uid = queryResult([[SELECT TRIM(h1.unic_id) FROM `0000000_bot`.moadianz_fact_history h1
    WHERE h1.invoice_id=]]..invoice_id..[[ AND h1.type=2 AND (h1.ref_id IS NULL OR h1.ref_id='')
    AND h1.id = (
      SELECT MAX(h2.id) FROM `0000000_bot`.moadianz_fact_history h2
      WHERE h2.invoice_id=]]..invoice_id..[[ AND h2.type=2 AND (h2.ref_id IS NULL OR h2.ref_id='')
    )
    AND NOT EXISTS (
      SELECT 1 FROM `0000000_bot`.moadianz_fact_history h3
      WHERE h3.invoice_id=]]..invoice_id..[[ AND h3.type IN (1,2,3) AND h3.ref_id!=''
      AND h3.id > h1.id
    )
    ORDER BY h1.id DESC LIMIT 1]], {})
  return uid or ""
end

if invoice_id == nil or #invoice_id == 0  then
  invoice_id = 0 
end
local result_uid = ""
local result_referenceNumber = ""
local result_send_txt = ""
local result_get_txt = ""
local result_ref_invoice_id = ""

 

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
    local bb=(i  % 8) + 1
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
function safeJsonDecode(value)
  if value == nil or type(value) ~= "string" or value == "" then
    return nil
  end
  local ok, decoded = pcall(json.decode, value)
  if ok and decoded ~= nil then
    return decoded
  end
  return nil
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
  str_decimal = string.format("%18.0f", decimal)
  if hasLeadingZero then
    str_decimal = "0" .. str_decimal
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
  if num == nil then
    return "000000000000"
  end
  local num_str = tostring(num)
  if #num_str >= 12 then
    return num_str
  end
  local zeros_to_add = 12 - #num_str
  local strig_with_zero = string.rep("0", zeros_to_add) .. num_str
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
  local str = convetUTF8(p1)
  local hex2 = hex_to_decimal(p2)
  if hex2 == nil then hex2 = "0" end
  hex2 = string.format('%.6d', tonumber(hex2) or 0)
  str = str .. hex2
  local tt = hex_to_decimal(p3)
  if tt == nil then tt = "0" end
  tt = string.format('%.12d', tonumber(tt) or 0)
  str = str .. tt
  local num = str:gsub("%s+", "")
  str = p1 .. p2 .. p3 .. generateCheckDigit(num)
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
  COALESCE((SELECT sum(PRICEAFTER_DISCOUNT) FROM sales_invoice_settlement where invoice_id=i.id and type<>1 ),0)pay_naghd,dd.SHORT_NAME, SC.id_in_moadiyan,pi.VALUE_ADDED_TEXT,
      (  select nc.branch_code from profile_nationalcode nc inner join pa_client c on 
  c.REFFERE_ID= nc.user_id where c.id=i.client_id and c.ORG_ID=i.ORG_ID  limit 1)branch_code
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
        unit_id_in_moadian = record[30],
        VALUE_ADDED_TEXT = record[31],
        branch_code = record[32]
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
    local q_unix_run = [[ SELECT (]]..date_replace..[[ - 116444736000000000) DIV 10000000 ]]
    unix_date_run = tonumber(queryResult(q_unix_run,{}))
    unix_create_date = unix_date_run
  else
    local q_unix_run = [[ SELECT (RUN_DATE - 116444736000000000) DIV 10000000 FROM sales_invoice WHERE id = ]]..invoice_id
    unix_date_run = tonumber(queryResult(q_unix_run,{}))
    local q_unix_create = [[ SELECT (DATE_CREATE - 116444736000000000) DIV 10000000 FROM sales_invoice WHERE id = ]]..invoice_id
    unix_create_date = tonumber(queryResult(q_unix_create,{}))
  end
  


  local pay_price = 0
  local pay_type = 1
  local seller_code = res[1].org_code
  local user_type = 0
  local   buyer_economic_code = 0
  local bbc= nil
  local buyer_postal_code = nil 
  if tonumber(res[1].buyer_type) == 3 then
    if res[1].tin == nil or #tostring(res[1].tin) == 0 then 
      buyer_economic_code="0000"..res[1].client_national_code
    else
      buyer_economic_code =res[1].tin
    end 
    buyer_postal_code = res[1].client_national_code
    user_type = 1
  else 
        if #tostring(res[1].branch_code) == 1 then
       bbc= "000"..tostring(res[1].branch_code)
    elseif #tostring(res[1].branch_code) == 2 then
         bbc= "00"..tostring(res[1].branch_code)
    elseif #tostring(res[1].branch_code) == 3 then
         bbc= "0"..tostring(res[1].branch_code)
    elseif #tostring(res[1].branch_code) == 4 then
        bbc= tostring(res[1].branch_code)
    end
    buyer_economic_code = res[1].client_national_code -- res[1].tin
    user_type = 2
  end

  local factor_subject_num = 1
  if tonumber(res[1].type)==3 then 
    factor_subject_num = 4
  end 

  local meli_ec_code = 0
  local price_by_disc = res[1].remainded_amount
  local sum_bill = res[1].remainded_amount
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
    local fee = tonumber(v.fee) or 0
    local quantity = tonumber(v.quantity) or 0
    local discount = tonumber(v.discount) or 0
    local toll = tonumber(v.toll) or 0
    v.fee = fee
    v.quantity = quantity
    v.discount = discount
    v.toll = toll
    local after_discount = (fee * quantity) - discount
    -- استخراج نرخ مالیات از VALUE_ADDED_TEXT (مثل "10%")
    local value_added_text = v.VALUE_ADDED_TEXT or ""
    local vra = 0
    if value_added_text ~= "" then
      local rate_str = value_added_text:gsub("%%", "")
      vra = tonumber(rate_str) or 0
    end
    -- محاسبه مالیات با فرمول استاندارد مودیان
    local tax_amount = 0
    if after_discount > 0 and vra > 0 then
      tax_amount = math.floor((after_discount * vra) / 100)
    end
    sum_before_dic = sum_before_dic + (fee * quantity)
    sum_discount = sum_discount + discount
    sum_tax = sum_tax + tax_amount
    sum_tax_toll = sum_tax_toll + tax_amount + toll
    sum_all = sum_all + after_discount + tax_amount
    sum_all_pay = sum_all_pay + after_discount + tax_amount
    local tcop = after_discount + tax_amount  --سهم نقدی از پرداخت (شامل مالیات)
    local tvop = tax_amount  --سهم ارزش افزوده از پرداخت
    local ttsstam = after_discount + tax_amount  --مبلغ کل کالا/خدمت = adis + vam
    table.insert(tbl_body,
      {
        sstid = tostring(v.tx_code),  --شناسه کاال/خدمت
        sstt = v.pname,             --kala name
        mu=tostring(v.unit_id_in_moadian), -- "1627",  -- واحد اندازه گیری
        am = v.quantity,  --تعداد/مقدار
        fee = v.fee,  ---مبلغ واحد
        cfee = nil,  --میزان ارز
        cut = nil,  ---نوع ارز
        exr =nil, -- v.symbole_rate ,  --- نرخ برابری ارز با ریال
        prdis = v.fee*v.quantity,  ---مبلغ قبل از تخفیف
        dis = v.discount,  --مبلغ تخفیف
        adis = (v.fee*v.quantity) - v.discount,  -- مبلغ بعد از تخفیف
        vra = vra,  --نرخ مالیات برارزش افزوده (محاسبه شده از VALUE_ADDED_TEXT)
        vam = tax_amount,  --مبلغ مالیات بر ارزش افزوده
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
        cop= tcop,  --سهم نقدی از پرداخت (شامل مالیات)
        vop= tvop,  --سهم ارزش افزوده از پرداخت
        bsrn= nil,  --شناسه یکتای ثبت قرارداد حق العملکاری
        tsstam= ttsstam  --مبلغ کل کاال/خدمت
      }
    )
  end 
  local kind_prefix = "2"
  if c_kind_refrence == 3 then 
    kind_prefix = "3"
  end 
  local sum_riali = res[1].remainded_amount
  local sum_currency = res[1].remainded_amount
  local cancel_count = tonumber(queryResult([[SELECT COUNT(*) FROM `0000000_bot`.moadianz_fact_history WHERE invoice_id=]]..invoice_id..[[ AND type=2]], {})) or 0
 -- teamyar.write_log("cancel_count="..tostring(cancel_count).." invoice_id="..tostring(invoice_id))
  local hex_invoice_id = string.format('%010X', (tonumber(invoice_id) or 0) + 800000 + cancel_count * 1000000)
  local hex_invoice_id_10 = string.format('%010X', (tonumber(invoice_id) or 0) + 800000 + cancel_count * 1000000)
  local factor_date_milady = 0

  if date_replace~=nil and tonumber(date_replace)~=nil then 
 local q_date =  [[ SELECT (DATEKEY - 116444736000000000) DIV 864000000000 FROM report_dimdate WHERE 
    ]]..date_replace..[[ between datekey and datekey+(60*60*24*10000000)-(60*10000000)]]
    factor_date_milady=queryResult(q_date,{})

  else
    local q_date =  [[ SELECT (DATEKEY - 116444736000000000) DIV 864000000000 FROM report_dimdate WHERE 
    (select RUN_DATE from sales_invoice i  where id= ]]..invoice_id..[[ ) between datekey and datekey+(60*60*24*10000000)-(60*10000000)]]
    factor_date_milady=queryResult(q_date,{})
  end
  local days = tonumber(factor_date_milady)

  if days == nil then
    error('Invalid date: could not compute days from DATEKEY');
  end

  local days_dec = string.format('%.6d', days);
  local days_hex = string.format('%.5X', days);
  if c_memory_tax_id == nil then 
    teamyar.write_log("خطا در پیکربندی حافظه مالیاتی")
    c_memory_tax_id=0 
  else
    do_inquiry_first()
    local active_unic_id = get_active_cancel_unic_id()
    if active_unic_id and #active_unic_id > 0 then
      tax_unic_id = active_unic_id
      --teamyar.write_log("del fact: reusing active cancel unic_id="..tax_unic_id)
    else
      tax_unic_id =resutStr(c_memory_tax_id, days_hex, hex_invoice_id)
    end
  end
  local org_code=queryResult([[SELECT CODE FROM  org_info where id =]]..c_org_id)
  local buyer_postal_code=tostring(res[1].client_postal_code)
  if #buyer_postal_code==0 then 
    buyer_postal_code="1111111111"
  end
    local inv_pattern= 1
  if tonumber(res[1].bill_template)~= nil and tonumber(res[1].bill_template)>0 then
    inv_pattern = tonumber(res[1].bill_template)
  end
    local inv_ty = 1
  if tonumber(res[1].bill_type)~= nil and tonumber(res[1].bill_type)>0 then
    inv_ty = tonumber(res[1].bill_type)
  end
  local invoice_factor_code = ""
  local qfid =[[SELECT TRIM(h1.unic_id) FROM `0000000_bot`.moadianz_fact_history h1
    WHERE h1.invoice_id=]]..invoice_id..[[ AND h1.type IN (1,3) AND h1.ref_id!='' AND h1.unic_id!=''
    AND NOT EXISTS (
      SELECT 1 FROM `0000000_bot`.moadianz_fact_history h2
      WHERE h2.invoice_id=]]..invoice_id..[[ AND h2.type=2 AND h2.ref_id!=''
      AND h2.ref_invoce_id=h1.unic_id
    )
    ORDER BY h1.id DESC LIMIT 1]]
  --invoice_factor_code = queryResult(qfid,{}) or ""
 -- if invoice_factor_code == "" and input_unic_id and #input_unic_id > 0 then
    invoice_factor_code = input_unic_id
 -- end
  result_ref_invoice_id = invoice_factor_code
   -- teamyar.write_log("qfid-----"..qfid)
 -- teamyar.write_log("tax_unic_id----***-----"..tax_unic_id)
  --teamyar.write_log("invoice_factor_code----***-----"..invoice_factor_code)
  local res_inv_direct ={
    header =
    {
      taxid =tax_unic_id,  --شماره منحصر به فرد مالیاتی 
      indatim =  unix_date_run*1000, --تاریخ صدور -- 1762325770000,--
      indati2m = unix_create_date*1000 , -- 1762325808000--, -- تاریخ ایجاد
      inty= inv_ty, -- نوع صورتحساب
      inno= hex_invoice_id_10,  --سریال صورتحساب با طول 10 هگز
      irtaxid=  invoice_factor_code, --شماره منحصر به فردمالیاتی صورتحساب مرجع
      inp= inv_pattern,  -- الگوی صورتحساب یک فروش
      ins= tonumber(c_kind_refrence), -- موضوع صورتحساب 1اصلی 2 اصلاحی 3-ابطالی 4-برگشت از فروش
      tins= tostring(c_economic_number),  -- شماره اقتصادی فروشنده
      tob= user_type, --وع شخص خریدار 1حقیقی 2 حقوقی
      bid= tostring(res[1].client_national_code),  --  کد ملی خریدار
      tinb= tostring(buyer_economic_code), --- شماره اقتصادی خریدار
      sbc=nil, --tonumber(org_code),  --کد شعبه فروشنده
      bpc= buyer_postal_code, --tostring(res[1].client_postal_code),  -- کد پستی خریدار
      bbc= bbc,  --کد شعبه خریدار
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
      --     data_str = json.encode(datatocken)
    };

    if curl:sendRequest(request_params) then
      local res = curl:getResponse();
    --  teamyar.write_log('challenge 5555 response is: ' .. res);
      if curl:getStatus() == 200 then
        --teamyar.write_log('challenge response is: ' .. res);
        nonce = json.decode(res).nonce
      else
       -- teamyar.write_log('status code error: 4 ' .. curl:getStatus())
      end
    end
    curl:disconnect();
  else
   -- teamyar.write_log('cannot connect to sandboxrc.tax.gov.ir')
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
        --    teamyar.write_log('server_info response is: ' .. server_info);
      else
        --    teamyar.write_log('status code error: ' .. curl:getStatus())
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
  local days = math.floor(unixtime / 86400);
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
      ch = verhoeff_d[ch + 1][verhoeff_p[((i - 1) % 8) + 1][data:byte(len - i + 1) - 47] + 1];
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
        --    teamyar.write_log('invoice response is: ' .. invoice_response);
      else
        --    teamyar.write_log('status code error 2: ' .. curl:getStatus())
      end
    end
    curl:disconnect();
  else
    --    teamyar.write_log('cannot connect to '..c_url)
  end
  curl:release();
  return invoice_response;
end
---------------------------------------------------------------
function main()
  local nonce = getChallenge();
  local token = generateToken(nonce,   c_memory_tax_id);
  local invoice_payload,tax_unic_id22 = getInvoiceDate(invoice_id)
  if invoice_payload == nil or type(invoice_payload) ~= "table" or invoice_payload.header == nil or invoice_payload.body == nil then
    result_send_txt = ""
    result_get_txt = ""
    teamyar.write_result(json.encode({msg="ساخت اطلاعات فاکتور ابطالی برای ارسال به سامانه مودیان ناموفق بود", send_txt="", get_txt=""}))
    return
  end
  factor_tax_id = tax_unic_id22
  result_send_txt = json.encode(invoice_payload)
  local invoices = {
    createJWE(invoice_payload, c_public_key_id)
  };
  local sendInvoicesResponse = sendInvoices(  c_memory_tax_id, token, invoices,c_memory_tax_id);
  result_get_txt = tostring(sendInvoicesResponse or "")
  local decoded_send_response = safeJsonDecode(sendInvoicesResponse)
  if decoded_send_response ~= nil and type(decoded_send_response) == "table" and decoded_send_response.result ~= nil and type(decoded_send_response.result) == "table" and decoded_send_response.result[1] ~= nil and type(decoded_send_response.result[1]) == "table" then
    result_uid = decoded_send_response.result[1].uid or ""
    result_referenceNumber = decoded_send_response.result[1].referenceNumber or ""
  end
end
---------------------------------------------------------------
local check_sended_invoice = queryResult( [[select moadian_status from sales_invoice where id=]]..invoice_id,{})
local factor_org_id = queryResult([[select org_id  from sales_invoice where id=]]..invoice_id,{})

if tonumber(factor_org_id) == tonumber(c_org_id) then
  main();
  local out_msg = ""
  if result_uid ~= "" then
    out_msg = "فاکتور ابطالی در سامانه مودیان ثبت شد - uid: "..result_uid.." - referenceNumber: "..result_referenceNumber
    -------------------------------history
    local info_log =  {
      org_id = c_org_id,
      history = "فاکتور در سامانه مودیان ابطال شد".."<br>factor_tax_id:<br>"..factor_tax_id.." <br> ".."result_referenceNumber:<br>"..result_referenceNumber  ,
      invoice_id = invoice_id
    }
    local   res_log = teamyar.call_api(23,  '/api/sales/update_invoice_history', info_log);
    -----update taxpayer status
    local info_update_status ={
      org_id = c_org_id,
      invoice_id = invoice_id,
      moadian_status =4
    }
    local   res_update_status = teamyar.call_api(23,  '/api/sales/update_moadian_status', info_update_status);
  else
    out_msg = "ارسال فاکتور ابطالی ناموفق بود"
  end
  teamyar.write_result(json.encode({msg=out_msg, send_txt=result_send_txt, get_txt=result_get_txt, ref_invoce_id=result_ref_invoice_id, unic_id=factor_tax_id or "", ref_id=result_referenceNumber or ""}))
else
  teamyar.write_result(json.encode({msg="شناسه سازمان انتخاب شده با سازمانی که در آن فاکتور ثبت شده است متفاوت است", send_txt="", get_txt="", ref_invoce_id=""}))
end