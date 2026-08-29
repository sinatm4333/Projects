-- botName = update_crm
-- version = v01

-- =========================================
-- Load Config
-- =========================================
local config = teamyar.get_config()
local config_data = {}
teamyar.write_log('**************************************')
local c_tocken = ""
local c_f_id_api = ""
local c_url_api_id = ""
local c_cat_id = 0
local c_id_parent = ""
local CRM_USER_TYPE_NATURAL = 3
local CRM_USER_TYPE_LEGAL = 4

if config ~= nil and config.data ~= nil then
  config_data   = config.data
  c_tocken     = config_data.tocken or ""
  c_f_id_api   = config_data.f_id_api or ""
  c_url_api_id = config_data.url_api_id or ""
  c_cat_id     = tonumber(config_data.cat_id) or 0
  c_id_parent  = config_data.id_parent or ""
else
  teamyar.write_result("پیکربندی این بات انجام نشده است</br>")
  return
end


-- =========================================
-- Helpers
-- =========================================
local function is_null(x)
  return (x == nil) or (x == json.null) or (json.encode(x) == "null")
end

local function safe_str(x, default)
  if is_null(x) then return default or "" end
  return tostring(x)
end

local function safe_num(x, default)
  if is_null(x) then return default or 0 end
  local n = tonumber(x)
  if n == nil then return default or 0 end
  return n
end

local function normalize_site_id(saite_id)
  local site_id_int = safe_num(saite_id, 0)
  site_id_int = math.floor(site_id_int)
  return site_id_int, tostring(site_id_int)
end

local function gender_to_flag(g)
  if is_null(g) then return 0 end
  if not is_null(g.display) and tostring(g.display) == "مرد" then
    return 1
  end
  return 0
end

-- ✅ تبدیل اعداد فارسی/عربی به انگلیسی
local function to_en_digits(s)
  local map = {
    ["۰"]="0",["۱"]="1",["۲"]="2",["۳"]="3",["۴"]="4",["۵"]="5",["۶"]="6",["۷"]="7",["۸"]="8",["۹"]="9",
    ["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9"
  }
  return (tostring(s):gsub("[۰-۹٠-٩]", map))
end

-- ✅ فقط رقم
local function digits_only(raw)
  if is_null(raw) then return "" end
  local s = tostring(raw)
  s = to_en_digits(s)
  s = s:gsub("%s+", "")
  s = s:gsub("%D+", "")
  return s
end

-- ✅ کد ملی: همیشه رشته، و همیشه 10 رقم (pad left)
local function normalize_national_code_str(raw)
  local s = digits_only(raw)
  if s == "" then return "" end
  if #s < 10 then
    s = string.rep("0", 10 - #s) .. s
  end
  return s
end


-- =========================================
-- استخراج استان/شهر/آدرس/کدپستی از خروجی Customer/Preview
-- =========================================
local function extract_location_fields(v)
  local ostan, shahr, addr_text, postal = "", "", "", ""

  if not is_null(v) and not is_null(v.locations) and not is_null(v.locations.items)
     and v.locations.items[1] ~= nil and v.locations.items[1] ~= json.null then

    local it = v.locations.items[1]

    if not is_null(it.city) then
      if not is_null(it.city.state) and not is_null(it.city.state.display) then
        ostan = safe_str(it.city.state.display, "")
      end
      if not is_null(it.city.display) then
        shahr = safe_str(it.city.display, "")
      end
    end

    if not is_null(it.address) then
      addr_text = safe_str(it.address, "")
    end

    if not is_null(it.postalCode) then
      postal = safe_str(it.postalCode, "")
    end

  elseif not is_null(v) and not is_null(v.city) then

    if not is_null(v.city.state) and not is_null(v.city.state.display) then
      ostan = safe_str(v.city.state.display, "")
    end

    if not is_null(v.city.display) then
      shahr = safe_str(v.city.display, "")
    end

    if not is_null(v.address) then
      addr_text = safe_str(v.address, "")
    end

    if not is_null(v.postalCode) then
      postal = safe_str(v.postalCode, "")
    end
  end

  return ostan, shahr, addr_text, postal
end


-- =========================================
-- DB helper
-- =========================================
local function queryResult(select_query, user_param)
  db.use_db("0000000")

  local params1 = {
    query = select_query,
    params = user_param
  }

  db.query(params1)
  local res_text = db.query_fetch()
  db.query_free()

  if res_text == nil then
    return nil
  end

  return res_text[1]
end


-- =========================================
-- ✅ NEW: Create Account (module 10) for REAL + LEGAL
-- (API خودش اگر موجود باشد دوباره نمی‌سازد)
-- ==================================-- =========================================
-- CREATE ACCOUNT (module 10)
-- dic_id = user_id
-- =========================================
local function create_account_for_client(user_id, full_name)

--  if user_id == nil or tonumber(user_id) <= 0 then
 ----   teamyar.write_log("ACCOUNT SKIP: invalid user_id")
--    return
 -- end

  full_name = safe_str(full_name, "بدون نام")

  local payload = {
    name = full_name,
    note = "profile_id:" .. tostring(user_id),

    dic_id = tonumber(user_id),   
    
    org_id = 8,     
    parent_id = tonumber(c_id_parent),   
    account_type = 1,
    status_account = 1,
    perm_parent_allow = 1
  }

 teamyar.write_log("account_create_payload--8 8-"..json.encode(payload))

  local res = teamyar.call_api(10, "/api/newClient/create", payload)

 teamyar.write_log("account_create_res---"..json.encode(res))

  if res and res.success == true then
    teamyar.write_log("ACCOUNT CREATED SUCCESS | user_id="..tostring(user_id))
  else
    teamyar.write_log("ACCOUNT CREATE FAILED | user_id="..tostring(user_id))
  end
end
-- =========================================
-- CRM Upsert
-- (FIX: national_code رشته 10 رقمی با صفرهای ابتدا)
-- + FIX آدرس: حقیقی => home.address | حقوقی => work.address
-- + FIX نام حقوقی: اگر خالی بود موبایل ننشیند، "شرکت بدون نام"
-- + ✅ NEW: بعد از create/update کلاینت، ساخت حساب هم انجام شود
-- =========================================
local function updateInsertCrm(national_code, mobile, fname, lname, city, state, address_text, zip_code, is_man, email, user_type, saite_id)

  local site_id_int, site_id_str = normalize_site_id(saite_id)

  email        = safe_str(email, "")
  city         = safe_str(city, "")
  state        = safe_str(state, "")
  address_text = safe_str(address_text, "")
  zip_code     = safe_str(zip_code, "")

  local national_code_str = normalize_national_code_str(national_code)
  mobile = safe_str(mobile, "0")

  -- ✅ FIX نام‌ها: حقوقی موبایل جای نام ننشیند
  local fname_s = safe_str(fname, "")
  local lname_s = safe_str(lname, "")

  if tonumber(user_type) == CRM_USER_TYPE_LEGAL then
    -- حقوقی
    if fname_s == "" then fname_s = "شرکت بدون نام" end
  else
    -- حقیقی
    if lname_s == "" then lname_s = "بدون نام" end
    if fname_s == "" then fname_s = mobile end
  end

  fname = fname_s
  lname = lname_s

  if national_code_str == "" or mobile == "0" then
   -- teamyar.write_log("موبایل یا کدملی خالی است | mobile="..json.encode(mobile).." | national_code="..json.encode(national_code_str))
    return nil
  end

  -- پیدا کردن user_id بر اساس national_code
  local user_id = nil

  local national_num = tonumber(national_code_str)
  if national_num ~= nil then
    local q_find_crm_num = [[
      select distinct n.USER_ID
      from profile_nationalcode n
      inner join profile_mobile m on m.user_id = n.user_id
      inner join profile_user_info p on p.id = n.user_id
      where NATIONAL_CODE =
    ]] .. tostring(national_num) .. [[
      and p.USER_TYPE = ]] .. tostring(tonumber(user_type) or 0)
    user_id = queryResult(q_find_crm_num, {})
  end

  if user_id == nil then
    local q_find_crm_str = [[
      select distinct n.USER_ID
      from profile_nationalcode n
      inner join profile_mobile m on m.user_id = n.user_id
      inner join profile_user_info p on p.id = n.user_id
      where NATIONAL_CODE = ']] .. national_code_str .. [['
      and p.USER_TYPE = ]] .. tostring(tonumber(user_type) or 0) .. [[
    ]]
    user_id = queryResult(q_find_crm_str, {})
  end

  -- آدرس‌ها طبق user_type:
  -- حقیقی (1) => home.address
  -- حقوقی (2) => work.address
  local function build_address_block()
    local home = {
      city = "",
      state = "",
      address = "",
      zip_code = "",
      loc_x = 0,
      loc_y = 0,
      country_code = 364
    }
    local work = {
      city = "",
      state = "",
      address = "",
      zip_code = "",
      loc_x = 0,
      loc_y = 0,
      country_code = 364
    }

    if tonumber(user_type) == CRM_USER_TYPE_LEGAL then
      work.city = city
      work.state = state
      work.address = address_text
      work.zip_code = zip_code
    else
      home.city = city
      home.state = state
      home.address = address_text
      home.zip_code = zip_code
    end

    return { home = home, work = work }
  end

  local function build_payload(id_value)
    return {
      id = id_value,
      comment = "شناسه سایت:" .. site_id_str,
      import_id = site_id_int,

      profile = {
        name = fname,
        last_name = lname,
        user_type = user_type,
        gender = is_man,

        email = { { value = email } },
        mobile = { { value = mobile, country = 364 } },
        national_code = { { value = national_code_str, country = 364 } },

        address = build_address_block()
      },

      city_code  = { name = city },
      state_code = { name = state },
      section_id = tonumber(c_cat_id),
    }
  end

 -- teamyar.write_log(
  --  "CRM UPSERT DEBUG | type="..tostring(user_type)..
   -- " | national_sent="..json.encode(national_code_str)..
   -- " | name="..json.encode(fname).." "..json.encode(lname)
 -- )

  if user_id ~= nil and tonumber(user_id) > 0 then
    --  teamyar.write_log('user_id---'..user_id)
      local q=[[select count(*) from hr_personnels where profile_id=]]..user_id
      local is_personnel=queryResult(q,{})
    --  teamyar.write_log('is ***************************************---'..is_personnel)
      if is_personnel ==0 then
          local crm_info = build_payload(tonumber(user_id))
        --  teamyar.write_log("crm_update_payload---"..json.encode(crm_info))
          local res_update = teamyar.call_api(14, "/api/client/update", crm_info)
         -- teamyar.write_log("update_crm_res---"..json.encode(res_update))
      end

      -- ✅ NEW: ساخت حساب بعد از update (برای حقیقی و حقوقی)
      create_account_for_client(user_id, fname .. " " .. lname)

      return user_id
  end

  local info_new_crm = build_payload(0)
--  teamyar.write_log("crm_create_payload---"..json.encode(info_new_crm))

  local res_create_crm = teamyar.call_api(14, "/api/client/create", info_new_crm)
 -- teamyar.write_log("create_crm_res---"..json.encode(res_create_crm))

  if res_create_crm and res_create_crm.success == true then
    user_id = res_create_crm.data and res_create_crm.data.profile_id or nil
    if user_id ~= nil then
      info_new_crm.id = user_id
   --   teamyar.write_log("update_after_create_payload---"..json.encode(info_new_crm))
    --  teamyar.write_log('user_id---'..user_id)
      local q=[[select count(*) from hr_personnels where profile_id=]]..user_id
      local is_personnel=queryResult(q,{})
    --  teamyar.write_log('is ***************************************---'..is_personnel)
      if is_personnel ==0 then
        local res_update_after = teamyar.call_api(14, "/api/client/update", info_new_crm)
    --    teamyar.write_log("update_after_create_res---"..json.encode(res_update_after))
      end

      -- ✅ NEW: ساخت حساب بعد از create (برای حقیقی و حقوقی)
      create_account_for_client(user_id, fname .. " " .. lname)

      return user_id
    end
  end

  return nil
end


-- =========================================
-- رابط: /api/client/contact/add
-- ✅ فقط روی شخص حقوقی رابط می‌زنیم
-- یعنی:
--    id = legal_user_id
--    contact_id = real_user_id
-- =========================================
local function add_contact_link_on_legal(legal_id, real_id, comment_text)
  comment_text = safe_str(comment_text, "")

  if legal_id == nil or tonumber(legal_id) <= 0 then
 --   teamyar.write_log("CONTACT_ADD SKIP: legal_id invalid")
    return
  end
  if real_id == nil or tonumber(real_id) <= 0 then
  --  teamyar.write_log("CONTACT_ADD SKIP: real_id invalid")
    return
  end

  if tonumber(legal_id) == tonumber(real_id) then
  --  teamyar.write_log("CONTACT_ADD SKIP: legal_id == real_id (bad ids) | id="..tostring(legal_id))
    return
  end

  local payload = {
    id = tonumber(legal_id),
    contact = {
      {
        type = 1,
        contact_id = tonumber(real_id),
        contact_comment = comment_text
      }
    }
  }

 -- teamyar.write_log("contact_add_payload---"..json.encode(payload))
  local res = teamyar.call_api(14, "/api/client/contact/add", payload)
 -- teamyar.write_log("contact_add_res---"..json.encode(res))
end


-- =========================================
-- Get Customer Preview (with locations)
-- =========================================
local function getcrm(cid)
  local data = {}
  local curl = teamyar.create_curl()

  if curl:connect({ domain = c_f_id_api, port = 443, ssl = true, secure = false }) then
    local request_params = {
      method = "POST",
      data_str = json.encode({ id = cid, includes = {"locations"} }),
      url = "/Api/Customer/Preview",
      headers = {
        { name = "Accept", value = "application/json" },
        { name = "ApiKey", value = c_tocken },
        { name = "Content-Type", value = "application/json" },
      },
    }

    local ok = curl:sendRequest(request_params)
    if ok then
      local res = curl:getResponse()
      if curl:getStatus() == 200 then
        local decoded = json.decode(res)
        if decoded and decoded.data then
          data = decoded.data
        end
      else
        teamyar.write_log("Customer/Preview status="..tostring(curl:getStatus()).." | cid="..tostring(cid))
      end
    else
     teamyar.write_log("Customer/Preview sendRequest failed | cid="..tostring(cid))
    end
  else
   teamyar.write_log("Customer/Preview cannot connect | domain="..tostring(c_f_id_api))
  end

  curl:disconnect()
  curl:release()
  return data
end


-- =========================================
-- Main Fetch List (c_url_api_id) and Process
-- =========================================
local function fetch_list(page, pagesize)
  local tempbody = { page = page, pagesize = pagesize }
  local curl = teamyar.create_curl()

  if not curl:connect({ domain = c_f_id_api, port = 443, ssl = true, secure = false }) then
    teamyar.write_log("List cannot connect | domain="..tostring(c_f_id_api))
    curl:release()
    return nil
  end

  local request_params = {
    method = "POST",
    data_str = json.encode(tempbody),
    url = c_url_api_id,
    headers = {
      { name = "Accept", value = "application/json" },
      { name = "ApiKey", value = c_tocken },
      { name = "Content-Type", value = "application/json" },
    },
  }

  local ok = curl:sendRequest(request_params)
  if not ok then
    teamyar.write_log("List sendRequest failed")
    curl:disconnect()
    curl:release()
    return nil
  end

  local res = curl:getResponse()
  local status = curl:getStatus()

  curl:disconnect()
  curl:release()

  if status ~= 200 then
    teamyar.write_log("List status code error: "..tostring(status))
    return nil
  end

  local decoded = json.decode(res)
  return decoded
end


-- =========================================
-- Processor for one customer_id
-- =========================================
local function process_customer(customer_id)
  local v = getcrm(customer_id)
  if is_null(v) then
    teamyar.write_log("Empty preview data | customer_id="..tostring(customer_id))
    return
  end

  local has_real  = (not is_null(v.cell)) and (not is_null(v.nationalCode))
  local has_legal = (not is_null(v.legal)) and (not is_null(v.legal.nationalCode))

  if (not has_real) and (not has_legal) then
    teamyar.write_log("No real/legal identifiers | customer_id="..tostring(customer_id))
    return
  end

  local real_user_id  = nil
  local legal_user_id = nil

  local r_state, r_city, r_addr, r_postal = "", "", "", ""
  if has_real then
    r_state, r_city, r_addr, r_postal = extract_location_fields(v)
    local r_is_man = gender_to_flag(v.gender)

    real_user_id = updateInsertCrm(
      v.nationalCode,
      v.cell,
      v.firstname,
      v.lastname,
      r_city,
      r_state,
      r_addr,
      r_postal,
      r_is_man,
      v.email,
      CRM_USER_TYPE_NATURAL,              -- حقیقی
      customer_id
    )
  end

  if has_legal then
    local l = v.legal
    local l_state, l_city, l_addr, l_postal = extract_location_fields(l)
    local l_is_man = gender_to_flag(l.gender)

    if (safe_str(l_addr, "") == "" and safe_str(r_addr, "") ~= "") then l_addr = r_addr end
    if (safe_str(l_postal, "") == "" and safe_str(r_postal, "") ~= "") then l_postal = r_postal end
    if (safe_str(l_city, "") == "" and safe_str(r_city, "") ~= "") then l_city = r_city end
    if (safe_str(l_state, "") == "" and safe_str(r_state, "") ~= "") then l_state = r_state end

    -- ✅ FIX اصلی شما: businessName جای نام شرکت حقوقی
    local businessName = safe_str(l.businessName, "")
    local l_fname = l.firstname
    local l_lname = l.lastname
    if businessName ~= "" then
      l_fname = businessName
      l_lname = ""
    end

    legal_user_id = updateInsertCrm(
      l.nationalCode,
      v.cell,
      l_fname,
      l_lname,
      l_city,
      l_state,
      l_addr,
      l_postal,
      l_is_man,
      l.email,
      CRM_USER_TYPE_LEGAL,              -- حقوقی
      customer_id
    )
  end

  -- ✅ فقط روی شخص حقوقی رابط می‌زنیم: id=legal , contact_id=real
  if legal_user_id ~= nil and tonumber(legal_user_id) > 0
     and real_user_id ~= nil and tonumber(real_user_id) > 0 then
    add_contact_link_on_legal(legal_user_id, real_user_id, "(ثبت‌شده توسط بات)")
  end
end


-- =========================================
-- RUN OPTIONS (یکی را فعال کن)
-- =========================================

-- ===== گزینه 1: تک صفحه
--[[
local page = 1
local pagesize = 10

local decoded = fetch_list(page, pagesize)
if decoded == nil or decoded.data == nil or decoded.data.items == nil then
  teamyar.write_log("List invalid | page="..tostring(page))
  return
end

for i, y in ipairs(decoded.data.items) do
  local customer_id = nil

  if not is_null(y.log) then
    local ok1, j1 = pcall(json.decode, y.log)
    if ok1 and j1 and j1.data and j1.data.customer and j1.data.customer.id then
      customer_id = j1.data.customer.id
    end
  end

  --customer_id=772199
  if customer_id ~= nil then
    process_customer(customer_id)
  else
    teamyar.write_log("Cannot parse customer_id | page=1 | index="..tostring(i))
  end
end
]]
-- ===== گزینه 2: حلقه صفحه به صفحه

local page = 1
local pagesize = 10

while true do
  local decoded = fetch_list(page, pagesize)
  if decoded == nil then
    teamyar.write_log("List response nil | page="..tostring(page))
    break
  end

  if not (decoded.data and decoded.data.items) then
    teamyar.write_log("response JSON did not contain expected data.items | page="..tostring(page))
    break
  end

  local items = decoded.data.items
  if items[1] == nil then
    teamyar.write_log("No more items | page="..tostring(page))
    break
  end

  for i, y in ipairs(items) do
    local customer_id = nil
    if not is_null(y.log) then
      local decoded_log = json.decode(y.log)
      if decoded_log and decoded_log.data and decoded_log.data.customer and decoded_log.data.customer.id then
        customer_id = decoded_log.data.customer.id
      end
    end

    if customer_id ~= nil then
      process_customer(customer_id)
    else
      teamyar.write_log("Cannot parse customer_id from item.log | index="..tostring(i).." | page="..tostring(page))
    end
  end

  page = page + 1
end
