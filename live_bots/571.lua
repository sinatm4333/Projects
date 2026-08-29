--edit fact
local uinfo=teamyar.get_user_info()
teamyar.write_log("uinfo----"..json.encode(uinfo))
local timezone=uinfo.timezone
local  input = teamyar.get_input();
local intype = input.type
local org_id_input = input.org_id or ""
teamyar.write_log("in----"..json.encode(input))
if intype == nil then 
  intype = 0
end 
local result_uid = ""
local result_referenceNumber = ""
local invoice_factor_code = input.invoice_factor_code
if invoice_factor_code == nil then 
  invoice_factor_code = ""
end 

local function check_last_inquired()
  local last = queryResult([[SELECT inquired FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..(input.invoice_id or 0)..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
  return tonumber(last) == 1
end

local function do_inquiry_first()
  if check_last_inquired() then return end
  local inv_id = input.invoice_id or 0
  teamyar.write_log("edit fact: invoice "..tostring(inv_id).." last operation not inquired, doing inquiry first")
  local last_hid = queryResult([[SELECT id FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..inv_id..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
  local last_ref = queryResult([[SELECT TRIM(ref_id) FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..inv_id..[[ AND ref_id!='' ORDER BY id DESC LIMIT 1]], {}) or ""
  local last_unic = queryResult([[SELECT TRIM(unic_id) FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..inv_id..[[ AND unic_id!='' ORDER BY id DESC LIMIT 1]], {}) or ""
  pcall(function()
    local res_bot = teamyar.run_command("2/inquery_invoice_taxpayer_m/", {
      referenceNumber = last_ref, invoice_id = tostring(inv_id), org_id = org_id_input, unic_id = last_unic
    })
    local res_status = teamyar.run_command("2/fact_st_m", { invoice_id = tostring(inv_id), org_id = org_id_input })
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

local function get_active_edit_unic_id()
  local inv_id = input.invoice_id or 0
  local uid = queryResult([[SELECT TRIM(h1.unic_id) FROM `0000000_bot`.moadianz_fact_history h1
    WHERE h1.invoice_id=]]..inv_id..[[ AND h1.type=3 AND h1.ref_id!=''
    AND h1.id = (
      SELECT MAX(h2.id) FROM `0000000_bot`.moadianz_fact_history h2
      WHERE h2.invoice_id=]]..inv_id..[[ AND h2.type=3 AND h2.ref_id!=''
    )
    AND NOT EXISTS (
      SELECT 1 FROM `0000000_bot`.moadianz_fact_history h3
      WHERE h3.invoice_id=]]..inv_id..[[ AND h3.type IN (1,2,3) AND h3.ref_id!=''
      AND h3.type != 3
      AND h3.id > h1.id
    )
    ORDER BY h1.id DESC LIMIT 1]], {})
  return uid or ""
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
    local aa = myArray[i] + 1
    local bb = ((i) % 8) + 1
    local cc = _permutationTable[bb][ aa] 
    local ff = _multiplicationTable[c + 1]
    c = ff[cc+ 1]
  end

  return tostring(_inverseTable[c + 1])

end
-- Usage
---------------------------------------------
function queryResultAcl(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    local tmp = record;
    table.insert(res_text, {id = record[1], name = record[2], type = 1});
  end
  db.query_free();
  return res_text;
end
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
function hex_to_decimal(hex_str)
  local hasLeadingZero = hex_str:sub(1, 1) == "0"
  -- Remove '0x' prefix if present and convert to uppercase
  hex_str = hex_str:gsub("^0x", ""):upper()
  -- Check for valid hexadecimal characters
  if not hex_str:match("^[0-9A-F]+$") then
    return nil, "Invalid hexadecimal string"
  end
  local decimal = 0
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
    decimal = decimal + (value * (16 ^ (length - i)))
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
  local str = convetUTF8(p1)
  local hex2 = hex_to_decimal(p2)
  str = str..hex2
  local tt = hex_to_decimal(p3)
  tt = string.format("%18.0f" ,tt)
  tt = pad_with_zero(tonumber(tt))
  str = str..tt
  local num = str:gsub("%s+", "")
  str=p1..p2..p3..generateCheckDigit(num)-- verhoeff_checksum(num)
  return str:gsub("%s+", "")
end
-----------------------------------------------------------
function fileToString(file)
  local str = ""
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
local c_kind_refrence = 2
local config = teamyar.get_config()
local config_data = {}
if config ~= nil then 
  config_data = config.data
end 
local c_count_repair =0
local c_price_repair = 0 
c_kind_refrence = input.kind_refrence
c_count_repair = input.count_repair
c_price_repair = input.price_repair

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
  c_count_repair = 0 
end 
if c_price_repair == nil then 
  c_price_repair = 0 
end
if c_kind_refrence == nil then 
  c_kind_refrence = 2
end
---------------------------------------------------------------
function getInvoiceDate(invoice_id, changes, date_replace, invoice_factor_code)
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
  (case when i.client_id>0  then (select pm.user_TYPE from profile_user_info pm inner join pa_client c on c.REFFERE_ID=pm.id where c.id =i.client_id and c.ORG_ID=i.ORG_ID  limit 1)
else (select pm.user_TYPE from profile_user_info pm  where pm.id= abs(i.client_id)) end ) buyer_type,
  (  select nc.NATIONAL_CODE from profile_nationalcode nc inner join pa_client c on 
  c.REFFERE_ID= nc.user_id where c.id=i.client_id and c.ORG_ID=i.ORG_ID  limit 1)client_national_code,
  (case when i.client_id>0  then (select crm.tin from crm_info crm inner join pa_client c on crm.id=c.REFFERE_ID where
  c.id=i.client_id  and c.ORG_ID=i.ORG_ID limit 1) else (select crm.tin from crm_info crm where crm.id = abs(i.client_id )) end ) tin ,
  0 symbole_rate,
  (case when i.client_id>0  then  (select POSTAL_CODE from profile_user_address ad inner join pa_client c
  on c.REFFERE_ID= ad.user_id  where c.id=i.client_id and c.org_id=i.org_id limit 1) else
  (select POSTAL_CODE from profile_user_address ad where ad.user_id=abs(i.client_id)) end) postal_code,
  0 row_price,i.SALES_AGENT,
  (  select nc.NATIONAL_CODE from profile_nationalcode nc where nc.user_id=i.SALES_AGENT   limit 1)agent_national_code,
  COALESCE((SELECT sum(PRICEAFTER_DISCOUNT) FROM sales_invoice_settlement where invoice_id=i.id and type<>1 ),0)pay_naghd,dd.SHORT_NAME
  , SC.id_in_moadiyan ,i.moadian_status,pi.VALUE_ADDED_TEXT, pi.ID row_id
  ,   (  select nc.branch_code from profile_nationalcode nc inner join pa_client c on 
  c.REFFERE_ID= nc.user_id where c.id=i.client_id and c.ORG_ID=i.ORG_ID  limit 1)branch_code 
  
  
  from sales_invoice i inner join sales_invoice_product pi on pi.invoice_id=i.id
  inner join wh_product p on p.id=pi.product_id left  join DecimalDigits dd on dd.org_id= i.org_id 
  left join wh_stock_capacity    sc   on p.CAPACITY_ID = sc.ID   
  where i.ID=]]..invoice_id
  local result = queryResultInvoice(query, {})
  if result == nil or type(result) ~= "table" or result[1] == nil or type(result[1]) ~= "table" then
    teamyar.write_log("اطلاعات فاکتور یافت نشد یا معتبر نیست")
    return {}, ""
  end
  local res_inv_direct ={}
  res_inv_direct, unic_tax_id = createJson(result, changes, date_replace, invoice_id, invoice_factor_code)
  return  res_inv_direct, unic_tax_id
end 
-------------------------------
function queryResultFactProduct(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, {
        product_id = record[1],
        product = record[2],
        count = record[3],
        price = record[4]
      });
  end
  db.query_free();
  return res_text;
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
        agent=record[26],
        agent_national_code=record[27],
        price_naghd = record[28],
        short_name=record[29],
        unit_id_in_moadian = record[30],
        moadian_status = record[31],
        VALUE_ADDED_TEXT = record[32],
        row_id = record[33],
        branch_code = record[34],
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
function createJson(res, changes, date_replace, invoice_id, invoice_factor_code)
  local tax_unic_id = ""
  if res == nil or type(res) ~= "table" or res[1] == nil or type(res[1]) ~= "table" then
    teamyar.write_log("اطلاعات ورودی برای ساخت صورتحساب معتبر نیست")
    return {}, ""
  end
  local unix_date_run =0
  local unix_create_date = 0
  if date_replace~=nil and  tonumber(date_replace)~=nil then
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
  local buyer_postal_code = nil
  local bbc = nil 
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
    buyer_economic_code =res[1].client_national_code or ""
    user_type = 2
  end
  local factor_subject_num = 1
  if tonumber(res[1].type)==3 then
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
  local tbl_body = {}
  for i, v in ipairs(res) do
    local fee = tonumber(v.fee) or 0
    local quantity = tonumber(v.quantity) or 0
    local discount = tonumber(v.discount) or 0
    local toll = tonumber(v.toll) or 0
    local value_add_price = tonumber(v.value_add_price) or 0
    v.fee = fee
    v.quantity = quantity
    v.discount = discount
    v.toll = toll
    v.value_add_price = value_add_price

    -- apply changes by row_id
    if changes ~= nil then
      for x,y in ipairs(changes) do
        if tostring(v.row_id) == tostring(y.row_id) then
          quantity = tonumber(y.new_quantity) or quantity
          fee = tonumber(y.new_fee) or fee
          v.quantity = quantity
          v.fee = fee
        end
      end
    end
    if tonumber(c_price_repair) ~= nil and tonumber(c_price_repair) >0 then
      fee=tonumber(c_price_repair)
    end
    if tonumber(c_count_repair) ~= nil and tonumber(c_count_repair)>0 then
      quantity = tonumber( c_count_repair)
    end

    sum_before_dic = sum_before_dic +( fee*quantity)
    sum_discount = sum_discount + discount

    local after_discount = (fee * quantity) - discount
    -- استخراج نرخ مالیات از VALUE_ADDED_TEXT (مثل "10%")
    local value_added_text = tostring(v.VALUE_ADDED_TEXT or "")
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

    sum_all_pay = sum_all_pay + after_discount + tax_amount
    sum_tax = sum_tax + tax_amount
    sum_tax_toll = sum_tax_toll + tax_amount + toll

    local rate_tax_toll=0
    if fee > 0 and quantity > 0 then
      rate_tax_toll=(value_add_price*100)/(fee*quantity)-discount
    end
    local currency_fee=0
    if tonumber(v.symbole_rate)~= nil and tonumber(v.symbole_rate)>0 then
      currency_fee=fee/tonumber(v.symbole_rate)
    end
    local unit_id_tax=tostring(v.unit_id_in_moadian or "")

    local tcop = after_discount + tax_amount
    local tvop = tax_amount
    local ttsstam = after_discount + tax_amount
    table.insert(tbl_body,
      {
        sstid = tostring(v.tx_code),
        sstt = v.pname,
        mu= unit_id_tax,
        am = v.quantity,
        fee = v.fee,
        cfee = nil,
        cut = nil,
        exr = nil,
        prdis = v.fee*v.quantity,
        dis = v.discount,
        adis = (v.fee*v.quantity)-v.discount,
        vra = vra,
        vam = tax_amount,
        odt= nil,
        odr= nil,
        odam= nil,
        lt= nil,
        olr= nil,
        olam= nil,
        consfee= nil,
        spro= nil,
        bros= nil,
        tcpbs= nil,
        cop= tcop,
        vop= tvop,
        bsrn= nil,
        tsstam = ttsstam
      }
    )
  end
  local sum_riali = res[1].remainded_amount
  local sum_currency = res[1].remainded_amount
  local edit_count = tonumber(queryResult([[SELECT COUNT(*) FROM `0000000_bot`.moadianz_fact_history WHERE invoice_id=]]..invoice_id..[[ AND type=3]], {})) or 0
  teamyar.write_log("edit_count="..tostring(edit_count).." invoice_id="..tostring(invoice_id))
  local hex_invoice_id = string.format('%010X', (tonumber(invoice_id) or 0) + 400000 + edit_count * 1000000)

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
    local active_unic_id = get_active_edit_unic_id()
    if active_unic_id and #active_unic_id > 0 then
      tax_unic_id = active_unic_id
      teamyar.write_log("edit fact: reusing active edit unic_id="..tax_unic_id)
    else
      tax_unic_id =resutStr(c_memory_tax_id, days_hex, hex_invoice_id)
    end
  end

  if c_org_id == nil then
    teamyar.write_log("خطا در پیکربندی شناسه سازمان")
    c_org_id=0
  end
  local org_code=queryResult([[SELECT CODE FROM  org_info where id =]]..c_org_id)

  local inv_pattern= 1
  if tonumber(res[1].bill_template)~= nil and tonumber(res[1].bill_template)>0 then
    inv_pattern = tonumber(res[1].bill_template)
  end
  local inv_ty = 1
  if tonumber(res[1].bill_type)~= nil and tonumber(res[1].bill_type)>0 then
    inv_ty = tonumber(res[1].bill_type)
  end
  local buyer_postal_code=tostring(res[1].client_postal_code or "")
  if #buyer_postal_code==0 then
    buyer_postal_code="1111111111"
  end
  local res_inv_direct ={
    header =
    {
      taxid = tax_unic_id,
      indatim =  unix_date_run*1000,
      indati2m = unix_create_date*1000,
      inty= inv_ty,
      irtaxid= invoice_factor_code,
      inp= inv_pattern,
      ins= tonumber(c_kind_refrence) or 2,
      tins= tostring(c_economic_number),
      tob= user_type,
      bid= tostring(res[1].client_national_code or ""),
      tinb= tostring(buyer_economic_code),
      sbc=nil,
      bpc= buyer_postal_code,
      bbc= bbc,
      ft= nil,
      bpn= nil,
      scln= nil,
      scc= nil,
      crn= nil,
      billid= nil,
      tprdis= sum_before_dic,
      tdis= sum_discount,
      tadis= sum_before_dic-sum_discount,
      tvam= sum_tax,
      todam= 0,
      tbill = math.floor((sum_before_dic - sum_discount) + sum_tax),
      setm= 1,
      cap= math.floor(sum_all_pay),
      insp= 0,
      tvop= math.floor(sum_tax),
      dpvb= nil,
      tax17= nil
    },
    body = tbl_body

    ,
    payments= {
      {
        iinn= nil,
        acn= nil,
        trmn= nil,
        trn= nil,
        pcn=nil,
        pid=  "0"..tostring(res[1].client_national_code or ""),
        pdt= unix_date_run*1000,
      }
    },
    extension= {
      {
        key= nil,
        value= nil
      }
    }
  }

  return res_inv_direct ,tax_unic_id
end
----------------------------------------------------

function getChallenge()
  local datatocken = {time = 1,
    packet = {
      uid = nil,
      packetType = "GET_TOKEN",
      retry = false,
      data = {
        username = "test-tsp-id-1"
      },
      encryptionKeyId = "",
      symmetricKey = "",
      iv = "",
      fiscalId = "",
      dataSignature = ""
    }, signature =
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
      url = "/requestsmanager/api/v2/nonce?timeToLive=200",
      headers = {
        { name = "Accept", value = "*/*" },
      },
    };

    if curl:sendRequest(request_params) then
      local res = curl:getResponse();     
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

  local certificate = fileToString(config_data.certificate) -- teamyar.get_attachment('certificate.txt');
  local private_key = fileToString(config_data.private_key) -- teamyar.get_attachment('private-key.txt');
  local tYear, tMonth, tDay, tHour, tMinute, tSecond = string.match(time.get_str(time.current()),'(%d+).(%d+).(%d+) (%d+):(%d+):(%d+)');

  local param_jwt = {
    algorithm = "RS256",
    secret = private_key,
    headers =  {
      alg = "RS256",
      sigT = string.format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ', tYear, tMonth, tDay, tHour, tMinute, tSecond),
      crit = {"sigT"},
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
    public_key = server_public_key
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
function sendInvoices(clientId, token, invoices, tax_unic_id22)
  local payload = {};
  --teamyar.write_log("tax_unic_id22----"..tax_unic_id22)
  for index, value in ipairs(invoices) do
    table.insert(payload, {header = {requestTraceId = coding.uuid(), fiscalId = tax_unic_id22 }, payload = value});
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
function main(invoice_id, changes, date_replace, invoice_factor_code)
  local nonce = getChallenge();
  local token = generateToken(nonce, c_memory_tax_id);
  local invoice_payload, tax_unic_id22 = getInvoiceDate(invoice_id, changes, date_replace, invoice_factor_code)
  if invoice_payload == nil or type(invoice_payload) ~= "table" or invoice_payload.header == nil or invoice_payload.body == nil then
    return {msg="ساخت اطلاعات فاکتور برای ارسال به سامانه مودیان ناموفق بود", send_txt="", get_txt=""}
  end
  local result_send_txt = json.encode(invoice_payload)
  local invoices = {
    createJWE(invoice_payload, c_public_key_id)
  };
  local sendInvoicesResponse = sendInvoices(  c_memory_tax_id, token, invoices,c_memory_tax_id);
  local result_get_txt = tostring(sendInvoicesResponse or "")
  local out_msg = "خطا در اصلاح فاکتور"
  if sendInvoicesResponse ~= nil and tostring(sendInvoicesResponse) ~= "" then
    local ok, decoded = pcall(json.decode, sendInvoicesResponse)
    if ok and decoded ~= nil and decoded.result ~= nil and decoded.result[1] ~= nil then
      result_uid = decoded.result[1].uid or ""
      result_referenceNumber = decoded.result[1].referenceNumber or ""
      out_msg = "فاکتور در سامانه مودیان اصلاح شد".."<br>result_uid:<br>"..result_uid.."  <br>  ".."result_referenceNumber:<br>"..result_referenceNumber
    end
  end
  return {msg=out_msg, send_txt=result_send_txt, get_txt=result_get_txt, ref_invoce_id=invoice_factor_code, unic_id=tax_unic_id22 or "", ref_id=result_referenceNumber or ""}
end
---------------------------------------------------------------------------------------------------------------------------
function inquery(invoice_id,refrence_id)
  local nonce = getChallenge();
  local ctocken = "Bearer "..generateToken(nonce,   c_memory_tax_id);
  local res_inquery = {}
  local res_status = 0
  local curli = teamyar.create_curl();
  local status = ""
  if curli:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
    local params_inq = {
      method = "GET", 
      url = "/requestsmanager/api/v2/inquiry-by-reference-id?referenceIds="..refrence_id, 
      headers = {
        {name = "Accept", value = "*/*"}, 
        {name = "Authorization", value = ctocken },
      },
    };
    local sended = curli:sendRequest(params_inq)
    if sended then
      res_inquery = curli:getResponse()
      res_status = curli:getStatus() 
      if res_status == 500 then
        status="خطا در دریافت استعلام  "
        return ""
      elseif res_status == 200 then
        status=json.decode(res_inquery)[1].status
      else
        status="خطا در ارسال درخواست استعلام  "
        return ""
      end
    end
    curli:disconnect();
  end
  curli:release();  

  -----log 
  local msg_modian = ""
  if res_inquery ~= nil then 
    if json.decode(res_inquery)[1] ~= nil then 
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
  local mstatus=5 
  if status ~= "FAILED" then 
    mstatus = 6
  end 
  -----update taxpayer status
  local info_update_status = {
    org_id = c_org_id,
    invoice_id = invoice_id,
    moadian_status = mstatus
  }
  local res_update_status = teamyar.call_api(23,  '/api/sales/update_moadian_status', info_update_status);
  local res_inquery_str = ""
  if #json.decode(res_inquery)[1].data ~= nil then
    if #json.decode(res_inquery)[1].data.error > 0  then 
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

function aclFactor(data)
  local query_param = [[select id,concat('#',id,'  ',INVOICE_CODE,'_',TITLE) from sales_invoice where (moadian_status=4 or moadian_status=6) ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  (TITLE like N'%]]..data.search..[[%' or INVOICE_CODE like N'%]]..data.search..[[%' or id=]]..data.search..[[) ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end 
----------------------
if intype == 128 then
  local ginput = teamyar.get_input()
  local changes = ginput.changes or {}
  local date_replace = ginput.date_replace or ""
  local invoice_factor_code = (ginput.unic_id or ginput.referenceNumber or ginput.ref_invoce_id or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local active_ref = queryResult([[SELECT TRIM(h1.unic_id) FROM `0000000_bot`.moadianz_fact_history h1
    WHERE h1.invoice_id=]]..tonumber(input.invoice_id)..[[ AND h1.type IN (1,3) AND h1.ref_id!='' AND h1.unic_id!=''
    AND NOT EXISTS (
      SELECT 1 FROM `0000000_bot`.moadianz_fact_history h2
      WHERE h2.invoice_id=]]..tonumber(input.invoice_id)..[[ AND h2.type=2 AND h2.ref_id!=''
      AND h2.ref_invoce_id=h1.unic_id
    )
    ORDER BY h1.id DESC LIMIT 1]], {})
  if active_ref and #tostring(active_ref) > 0 then
    invoice_factor_code = tostring(active_ref)
  end
  local res = main(input.invoice_id, changes, date_replace, invoice_factor_code)
  -------------------------------history
  local res_change = "<br>"
  for i,v in ipairs(changes) do
    res_change = res_change.." ردیف:"..i.." ---> ".. "   شناسه سطر:"..v.row_id.." تعداد جدید:"..json.encode(v.new_quantity).." مبلغ جدید:"..json.encode(v.new_fee).."<br>"
  end
  local info_log = {
    org_id = c_org_id,
    history = res.msg..res_change,
    invoice_id = input.invoice_id
  }
  local res_log = teamyar.call_api(23, '/api/sales/update_invoice_history', info_log)
  local info_update_status = {
    org_id = c_org_id,
    invoice_id = input.invoice_id,
    moadian_status = 4
  }
  local res_update_status = teamyar.call_api(23, '/api/sales/update_moadian_status', info_update_status)
  teamyar.write_result(json.encode(res))
elseif intype == 4 then 
  local ginput = teamyar.get_input()
  local new_rows = ginput.new_rows
  teamyar.write_log(json.encode(new_rows))
  local res_change = "<br>"
  for i,v in ipairs(new_rows) do     
    res_change = res_change.." ردیف:"..i.." ---> ".. "   شناسه سطر:"..v.code.." مقدار جدید:"..v.rcount.." مبلغ جدید:"..v.rprice.."<br>"
  end 
  local resstr = main(input.invoice_id,new_rows,ginput.date_replace, input.invoice_factor_code or "")
  -------------------------------history
  local info_log =  {
    org_id = c_org_id,
    history = resstr.msg.."<br> ".."result_referenceNumber:<br>"..result_referenceNumber..res_change  ,
    invoice_id = ginput.invoice_id
  }
  local   res_log = teamyar.call_api(23,  '/api/sales/update_invoice_history', info_log);
  -----update taxpayer status
  local info_update_status = {
    org_id = c_org_id,
    invoice_id = ginput.invoice_id,
    moadian_status =4
  }
  local   res_update_status = teamyar.call_api(23,  '/api/sales/update_moadian_status', info_update_status);
  -------------------------------history
  teamyar.write_result(json.encode(resstr))
  -- else
elseif intype == 7 then ---get factor detail
  aclFactor(teamyar.get_input().data)
elseif intype == 5 then ---get inquery
  local iinput = teamyar.get_input()
  local referenceNumber = queryResult([[ select  REPLACE(SUBSTRING_INDEX(NOTE, 'result_referenceNumber:<br>', -1),'</td></tr></table>','') rf from
                                        sales_history where note like '%result_referenceNumber:<br>%' and
                                        INVOICE_ID=]]..iinput.invoice_id..[[ order by id desc limit 1]],{})
  if referenceNumber ~= nil then
    local res_inquery =  inquery(input.invoice_id, referenceNumber)
    teamyar.write_result(json.encode({msg = res_inquery}))
  end 
elseif intype == 3 then ---get factor detail
  local ginput = teamyar.get_input()
  local res_ddata = getInvoiceDate(ginput.invoice_id, nil, nil, nil)
  teamyar.write_result(json.encode(res_ddata))
else
  local userinfo = teamyar.get_user_info();
  local lang = "English";
  if userinfo.lang_id == 4 then
    lang = "Persian";
  end
  local srlang = "<script src='/bot/run/2/tax_gov_edit_factor/"..lang..".js'></script>";
  res_data = [[
              <div id='myDiv'></div>
              ]]..srlang..[[
              <link href='/bot/run/2/tax_gov_edit_factor/main.css' rel='stylesheet' /> 
              <script src='/bot/run/2/tax_gov_edit_factor/main.js'>
              </script>
              ]];
  teamyar.write_result(res_data);
end