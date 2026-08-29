-- =========================================
-- CONFIG
-- =========================================
local config = teamyar.get_config()
if not config or not config.data then
  teamyar.write_result("پیکربندی انجام نشده است")
  return
end

local c_token      = config.data.tocken or ""
local c_domain     = config.data.f_id_api or ""
local c_url        = config.data.url_api_id or ""

local PURCHASE_MODULE_ID = 4

teamyar.write_log("=== START HC BUY SYNC ===")

-- =========================================
-- HELPERS
-- =========================================
local function safe(v)
  if v == nil or v == json.null then return "" end
  return tostring(v)
end

local function escape_sql(s)
  return safe(s):gsub("'", "''")
end

-- =========================================
-- CHECK DUPLICATE TITLE
-- =========================================
local function purchase_invoice_exists(title)

  local q = "select count(id) from purchase_invoice " ..
            "where deleted=0 and title='" .. escape_sql(title) .. "'"

  db.query({query=q, params={}})

  local record = {}
  local exists = false

  if db.query_fetch(record) then
    if tonumber(record[1]) and tonumber(record[1]) > 0 then
      exists = true
    end
  end

  db.query_free()
  return exists
end

-- =========================================
-- GET PRODUCT CODE BY SITE VARIANT ID
-- =========================================
local function get_product_code_by_site_id(site_variant_id)

  local q = "select full_code from wh_product " ..
            "where description like '%" .. escape_sql(site_variant_id) .. "%' " ..
            "limit 1"

  db.query({query=q, params={}})

  local record = {}
  local result = nil

  if db.query_fetch(record) then
    result = record[1]
  end

  db.query_free()

  return result
end

-- =========================================
-- FETCH BUY FACTORS FROM HC
-- =========================================
local function fetch_buyfactor()

  local curl = teamyar.create_curl()

  if not curl:connect({domain=c_domain, port=443, ssl=true}) then
    teamyar.write_log("HC CONNECT FAIL")
    return nil
  end

  local ok = curl:sendRequest({
    method="POST",
    url=c_url,
    data_str=json.encode({page=1, pagesize=5}),
    headers={
      {name="Accept", value="application/json"},
      {name="ApiKey", value=c_token},
      {name="Content-Type", value="application/json"}
    }
  })

  if not ok then
    curl:disconnect()
    curl:release()
    teamyar.write_log("HC REQUEST FAIL")
    return nil
  end

  local res = curl:getResponse()

  curl:disconnect()
  curl:release()

  return json.decode(res)
end

-- =========================================
-- MAIN
-- =========================================
local decoded = fetch_buyfactor()

if not decoded or not decoded.data or not decoded.data.items then
  teamyar.write_log("NO DATA FROM HC")
  return
end

for _, factor in ipairs(decoded.data.items) do

  -- 1️⃣ ساخت title
  local serial = safe(factor.serial)
  local date   = safe(factor.registered):sub(1,10)

  local invoice_title = "سفارش شماره " .. serial ..
                        " - تاریخ ثبت " .. date

  teamyar.write_log("CHECK TITLE: " .. invoice_title)

  -- 2️⃣ چک تکراری
  if purchase_invoice_exists(invoice_title) then
    teamyar.write_log("DUPLICATE FOUND -> SKIP")
  else

    teamyar.write_log("CREATE NEW PURCHASE INVOICE")

    local log_json = json.decode(factor.log)
    local items = log_json.data.items

    local products = {}
    local has_error = false

    for _, item in ipairs(items) do

      -- ساخت site_variant_id
      local site_variant_id = safe(item.variant.product.id) ..
                              "|" ..
                              safe(item.variant.id)

      teamyar.write_log("SITE VARIANT ID: " .. site_variant_id)

      -- گرفتن کد کالا
      local product_code = get_product_code_by_site_id(site_variant_id)

      if not product_code then
        teamyar.write_log("PRODUCT NOT FOUND FOR SITE ID: " .. site_variant_id)
        has_error = true
      else

        -- 3️⃣ تبدیل به ریال
        local rial_fee = math.floor((item.singleAmount or 0) * 10)

        -- 4️⃣ خالص سازی
        local net_fee = math.floor(rial_fee / 1.1)

        table.insert(products, {
          product_code = product_code,
          quantity     = item.quantity,
          fee          = net_fee,
          discount     = 0
        })

        teamyar.write_log("PRODUCT READY: " .. product_code ..
                          " | qty=" .. safe(item.quantity) ..
                          " | fee=" .. net_fee)
      end
    end

    if not has_error then

      local res = teamyar.call_api(PURCHASE_MODULE_ID,
                                   "/api/invoice/create",
                                   {
        invoice = {
          title    = invoice_title,
          type     = 0,
          run_date = os.time()
        },
        products = products
      })

      teamyar.write_log("CREATE RESULT: " .. json.encode(res))

    else
      teamyar.write_log("ERROR IN PRODUCTS -> INVOICE NOT CREATED")
    end
  end
end

teamyar.write_log("=== END HC BUY SYNC ===")
