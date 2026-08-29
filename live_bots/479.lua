local sqlquery = "select id,full_name,description from wh_product"

local function is_null(x)
  return (x == nil) or (x == json.null) or (json.encode(x) == "null")
end

local function html_escape(s)
  if s == nil then return "" end
  s = tostring(s)
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  s = s:gsub("'", "&#39;")
  return s
end

-- فقط توکن‌های هگزِ دقیقاً 64 کاراکتری (SHA256) را حذف کن
local function strip_sha256_tokens(s)
  if is_null(s) then return "" end
  s = tostring(s)
  s = s:gsub("(%x+)", function(tok)
    if #tok == 64 then return "" end
    return tok
  end)
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", "")
  s = s:gsub("%s+$", "")
  return s
end

local function csv_escape(s)
  if s == nil then s = "" end
  s = tostring(s)
  s = s:gsub('"', '""')
  return '"' .. s .. '"'
end

-- Base64 encoder (pure lua)
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64_encode(data)
  data = tostring(data or "")
  local out = {}
  local i = 1
  local len = #data

  while i <= len do
    local b1 = data:byte(i) or 0
    local b2 = data:byte(i+1)
    local b3 = data:byte(i+2)

    local n = b1 * 65536 + (b2 or 0) * 256 + (b3 or 0)

    local c1 = math.floor(n / 262144) % 64 + 1
    local c2 = math.floor(n / 4096) % 64 + 1
    local c3 = math.floor(n / 64) % 64 + 1
    local c4 = n % 64 + 1

    out[#out+1] = b64chars:sub(c1, c1)
    out[#out+1] = b64chars:sub(c2, c2)

    if b2 == nil then
      out[#out+1] = "="
      out[#out+1] = "="
    elseif b3 == nil then
      out[#out+1] = b64chars:sub(c3, c3)
      out[#out+1] = "="
    else
      out[#out+1] = b64chars:sub(c3, c3)
      out[#out+1] = b64chars:sub(c4, c4)
    end

    i = i + 3
  end

  return table.concat(out)
end

-- اجرا
db.query({ query = sqlquery, param = {} })

local record = {}
local row_index = 0

-- جدول نمایش داخل بات
local html_table = "<table border='1' style='border-collapse:collapse;width:100%;direction:rtl;font-family:tahoma'>"
html_table = html_table .. "<tr><th>ردیف</th><th>نام کالا</th><th>کد کالا در تیم یار</th><th>توضیحات</th></tr>"

-- CSV با BOM برای اکسل + sep=, برای جداکننده
local BOM = string.char(239,187,191)
local csv = BOM .. "sep=,\r\n"
csv = csv .. "ردیف,نام کالا,کد کالا در تیم یار,توضیحات\r\n"

while db.query_fetch(record) do
  row_index = row_index + 1

  local id          = record[1] or ""
  local full_name   = record[2] or ""
  local description = record[3] or ""

  description = strip_sha256_tokens(description)

  html_table = html_table .. "<tr>"
  html_table = html_table .. "<td>" .. tostring(row_index) .. "</td>"
  html_table = html_table .. "<td>" .. html_escape(full_name) .. "</td>"
  html_table = html_table .. "<td>" .. html_escape(id) .. "</td>"
  html_table = html_table .. "<td>" .. html_escape(description) .. "</td>"
  html_table = html_table .. "</tr>"

  csv = csv
    .. tostring(row_index) .. ","
    .. csv_escape(full_name) .. ","
    .. csv_escape(id) .. ","
    .. csv_escape(description) .. "\r\n"
end

db.query_free()
html_table = html_table .. "</table>"

-- لینک دانلود CSV به صورت Base64 (رفع مشکل فونت/encoding و کاهش خطای unsupported)
local file_name = "wh_product.csv"
local href = "data:text/csv;base64," .. base64_encode(csv)

local out = "<div style='direction:rtl;font-family:tahoma;margin:10px 0'>"
out = out .. "<b>تعداد نتایج:</b> " .. tostring(row_index) .. " | "
out = out .. "<a download='"..file_name.."' href='"..href.."'>دانلود اکسل (CSV)</a>"
out = out .. "</div>"
out = out .. html_table

teamyar.write_result(out)
