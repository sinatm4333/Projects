local input = teamyar.get_input() or {}
local description = input.description
local limit = tonumber(input.limit) or 50

local function is_empty(x)
  return x == nil or tostring(x) == "" or x == json.null
end

local function escape_sql_string(s)
  return tostring(s):gsub("'", "''")
end

local function html_escape(s)
  s = tostring(s or "")
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  return s
end

if is_empty(description) then
  teamyar.write_result("شناسه سایت خالی است")
  return
end

local q = escape_sql_string(description)

local sqlquery =
  "select id, full_code, full_name, description " ..
  "from wh_product " ..
  "where description like '%" .. q .. "%' " ..
  "order by id desc " ..
  "limit " .. tostring(limit)

db.query({ query = sqlquery, params = {} })

local items = {}
local record = {}

while db.query_fetch(record) do
  local full_code = record[2]
  if full_code ~= nil and tostring(full_code) ~= "" then
    table.insert(items, {
      id = record[1],
      full_code = tostring(full_code),
      full_name = record[3],
      description = record[4]
    })
  end
end

db.query_free()

-- =========================
-- ساخت جدول HTML
-- =========================

local html = {}

-- عنوان فارسی (RTL)
table.insert(html, "<div style='direction:rtl;font-family:tahoma;font-size:12px'>")
table.insert(html, "<div style='margin-bottom:8px'><b>تعداد نتایج:</b> " .. #items .. "</div>")
table.insert(html, "</div>")

-- جدول چپ‌چین (LTR)
table.insert(html, "<table style='border-collapse:collapse;width:100%;direction:ltr;text-align:left;font-family:tahoma;font-size:12px'>")

table.insert(html, "<thead>")
table.insert(html, "<tr style='background:#f2f2f2'>")
table.insert(html, "<th style='border:1px solid #ccc;padding:6px'>ID</th>")
table.insert(html, "<th style='border:1px solid #ccc;padding:6px'>Full Code</th>")
table.insert(html, "<th style='border:1px solid #ccc;padding:6px'>نام کالا</th>")
table.insert(html, "<th style='border:1px solid #ccc;padding:6px'>توضیحات</th>")
table.insert(html, "</tr>")
table.insert(html, "</thead>")

table.insert(html, "<tbody>")

for _, item in ipairs(items) do
  table.insert(html, "<tr>")
  table.insert(html, "<td style='border:1px solid #ccc;padding:6px'>" .. item.id .. "</td>")
  table.insert(html, "<td style='border:1px solid #ccc;padding:6px'>" .. html_escape(item.full_code) .. "</td>")
  table.insert(html, "<td style='border:1px solid #ccc;padding:6px'>" .. html_escape(item.full_name) .. "</td>")
  table.insert(html, "<td style='border:1px solid #ccc;padding:6px'>" .. html_escape(item.description) .. "</td>")
  table.insert(html, "</tr>")
end

table.insert(html, "</tbody>")
table.insert(html, "</table>")

teamyar.write_result(table.concat(html))
