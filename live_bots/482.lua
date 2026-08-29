-- =========================================
-- GetcodWithIdHc (UI + API)
-- Run path: /bot/run/443/GetcodWithIdHc
-- Assets:   /bot/run/443/GetcodWithIdHc/*
-- =========================================

local input = teamyar.get_input() or {}
local type_input = tonumber(input.type) or 0

local function is_empty(x)
  return x == nil or x == json.null or tostring(x) == ""
end

local function escape_sql_string(s)
  return tostring(s):gsub("'", "''")
end

local function to_en_digits(s)
  local map = {
    ["۰"]="0",["۱"]="1",["۲"]="2",["۳"]="3",["۴"]="4",["۵"]="5",["۶"]="6",["۷"]="7",["۸"]="8",["۹"]="9",
    ["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9"
  }
  return (tostring(s):gsub("[۰-۹٠-٩]", map))
end

teamyar.write_log("=== GetcodWithIdHc START ===")
teamyar.write_log("type_input=" .. tostring(type_input))
teamyar.write_log("raw_input=" .. json.encode(input))

-- =========================
-- API: type=1
-- =========================
if type_input == 1 then
  db.use_db("0000000")

  local description = input.description
  local limit = tonumber(input.limit) or 50

  if is_empty(description) then
    teamyar.write_result(json.encode({ ok=false, message="شناسه سایت خالی است", count=0, items={} }))
    return
  end

  description = to_en_digits(description)
  description = tostring(description):gsub("^%s+", ""):gsub("%s+$", "")
  local q = escape_sql_string(description)

  local sqlquery =
    "select id, code, full_code, full_name, description " ..
    "from wh_product " ..
    "where description like '%" .. q .. "%' " ..
    "order by id desc " ..
    "limit " .. tostring(limit)

  teamyar.write_log("[SQL] " .. sqlquery)

  db.query({ query = sqlquery, params = {} })

  local items = {}
  local record = {}
  while db.query_fetch(record) do
    table.insert(items, {
      id = record[1],
      code = record[2] and tostring(record[2]) or "",
      full_code = record[3] and tostring(record[3]) or "",
      full_name = record[4] and tostring(record[4]) or "",
      description = record[5] and tostring(record[5]) or ""
    })
  end

  db.query_free()

  teamyar.write_result(json.encode({
    ok = true,
    q = description,
    count = #items,
    items = items
  }))
  return
end

-- =========================
-- UI: type=0
-- =========================
local userinfo = teamyar.get_user_info()
local lang = "English"
if userinfo and userinfo.lang_id == 4 then
  lang = "Persian"
end

local html = [[
<div id="whSearchApp"></div>

<script src="/bot/run/443/GetcodWithIdHc/]]..lang..[[.js?v=1"></script>
<script src="/bot/run/443/GetcodWithIdHc/xlsx.full.min.js?v=1"></script>

<link href="/bot/run/443/GetcodWithIdHc/main.css?v=2" rel="stylesheet" />
<script src="/bot/run/443/GetcodWithIdHc/main.js?v=3"></script>
]]

teamyar.write_result(html)
