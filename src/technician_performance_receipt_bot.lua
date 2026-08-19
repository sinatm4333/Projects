-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/23 11:20
-- Tab: عملکرد تکنسین روی رسید (تعداد رسید + متوسط روز + قطعات + QC reject)

local input = teamyar.get_input() or {}
local org_id = input["org_id"] or input["orgId"] or "2"

local function escape_html(value)
    if value == nil then return "" end
    local amp_entity = "&" .. "amp;"
    local lt_entity = "&" .. "lt;"
    local gt_entity = "&" .. "gt;"
    local quot_entity = "&" .. "quot;"
    local apos_entity = "&" .. "#39;"
    return tostring(value)
        :gsub("&", amp_entity)
        :gsub("<", lt_entity)
        :gsub(">", gt_entity)
        :gsub('"', quot_entity)
        :gsub("'", apos_entity)
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local s = tostring(math.floor(n + 0.5))
    local grouped = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return grouped
end

local function fmt_decimal(value, decimals)
    local n = tonumber(value)
    if n == nil then return "0.0" end
    decimals = decimals or 1
    return string.format("%." .. decimals .. "f", n)
end

local function fetch_rows(query, params)
    db.use_db("0000000")
    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
    end)
    if not ok then return nil, err end
    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do row[i] = record[i] end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

local function cmp_badge(prev_val, curr_val, increase_is_good)
    if prev_val == nil or prev_val == 0 or curr_val == nil then return "" end
    local diff = curr_val - prev_val
    if diff == 0 then return "" end
    local pct = math.floor((diff / math.abs(prev_val) * 1000) + 0.5) / 10
    if pct == 0 then return "" end
    local sign = pct > 0 and "+" or ""
    local good = (pct > 0) == increase_is_good
    local bg = good and "#dcfce7" or "#fee2e2"
    local fg = good and "#166534" or "#991b1b"
    return '<span class="cmp-badge" style="background:' .. bg .. ';color:' .. fg .. ';">' .. sign .. tostring(pct) .. '%</span>'
end

local function cmp_badge_days(prev_val, curr_val, increase_is_good)
    if prev_val == nil or prev_val == 0 or curr_val == nil then return "" end
    local diff = math.floor((curr_val - prev_val) * 10 + 0.5) / 10
    if diff == 0 then return "" end
    local sign = diff > 0 and "+" or ""
    local good = (diff > 0) == increase_is_good
    local bg = good and "#dcfce7" or "#fee2e2"
    local fg = good and "#166534" or "#991b1b"
    return '<span class="cmp-badge" style="background:' .. bg .. ';color:' .. fg .. ';">' .. sign .. tostring(diff) .. '</span>'
end

-- Fetch technician performance by month
local perf_rows = fetch_rows([[
SELECT
    LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7) AS month,
    COALESCE(pm.FULLNAME, 'نامشخص') AS tech_name,
    COUNT(DISTINCT sr.ID) AS receipt_count,
    AVG(CASE
        WHEN sr.BREAK_DOWN_DATE > 0 AND psc.NEW_ID IN (6,7,8)
        THEN DATEDIFF(
            FROM_UNIXTIME((SELECT MAX(c.CREATION_DATE) FROM pm_service_request_content c
             WHERE c.SERVICE_REQUEST_ID = sr.ID AND c.NEW_ID IN (6,7,8)) / 10000000 - 11644473600),
            FROM_UNIXTIME(sr.BREAK_DOWN_DATE / 10000000 - 11644473600)
        )
    END) AS avg_days_to_qc,
    SUM(rpd.QUANTITY_DEMAND) AS total_parts,
    COUNT(DISTINCT CASE WHEN psc.NEW_ID = 2 THEN psc.ID END) AS qc_reject_count
FROM pm_service_request sr
LEFT JOIN pm_service_request_content psc ON psc.SERVICE_REQUEST_ID = sr.ID AND psc.TYPE = 11
LEFT JOIN profile_main pm ON pm.ID = psc.AUTHOR_ID
LEFT JOIN wh_req_product rp ON rp.REF_ID = sr.ID AND rp.DELETED = 0 AND rp.REQUEST_TYPE = 5 AND rp.STATUS = 1
LEFT JOIN wh_req_product_details rpd ON rp.ID = rpd.REQUEST_ID
WHERE REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') >= '1405-01-01'
  AND REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') <= '1405-12-29'
GROUP BY month, pm.FULLNAME
ORDER BY month ASC, tech_name ASC
]], {})

local tech_map = {}
local all_months = {}
if perf_rows then
    for _, r in ipairs(perf_rows) do
        local mk = r[1] or ""
        local tech = r[2] or "نامشخص"
        if not tech_map[tech] then tech_map[tech] = {} end
        tech_map[tech][mk] = {
            receipts = tonumber(r[3]) or 0,
            avg_days = tonumber(r[4]) or 0,
            parts = tonumber(r[5]) or 0,
            rejects = tonumber(r[6]) or 0,
        }
        if not all_months[mk] then all_months[mk] = true end
    end
end

local months_list = {}
for mk, _ in pairs(all_months) do table.insert(months_list, mk) end
table.sort(months_list)

-- Build table
local html = [[
<style>
  .tech-table { border-collapse: collapse; width: 100%; }
  .tech-table th, .tech-table td { border: 1px solid #ddd; padding: 8px; text-align: right; }
  .tech-table th { background: #16509D; color: white; font-weight: bold; }
  .tech-table tr:nth-child(even) { background: #f5f5f5; }
  .num-cell { text-align: center; }
  .name-cell { text-align: right; }
  .cmp-badge { display: inline-block; padding: 2px 4px; border-radius: 3px; font-size: 11px; margin-left: 4px; }
</style>

<table class="tech-table">
  <thead>
    <tr>
      <th>نام تکنسین</th>
]]

for _, mk in ipairs(months_list) do
    local month_name = string.sub(mk, 6, 7)
    html = html .. '<th colspan="4">' .. month_name .. '</th>'
end
html = html .. '</tr><tr><th></th>'

for _ = 1, #months_list do
    html = html .. '<th>رسید</th><th>روز</th><th>قطعات</th><th>ریجکت</th>'
end
html = html .. '</tr></thead><tbody>'

-- Sort techs
local techs = {}
for tech, _ in pairs(tech_map) do table.insert(techs, tech) end
table.sort(techs)

for _, tech in ipairs(techs) do
    html = html .. '<tr><td class="name-cell"><strong>' .. escape_html(tech) .. '</strong></td>'

    for _, mk in ipairs(months_list) do
        local curr = tech_map[tech][mk] or { receipts=0, avg_days=0, parts=0, rejects=0 }
        local prev_mk = (mk:sub(1,4) == "1405") and (mk:sub(1,4) .. "-" .. string.format("%02d", tonumber(mk:sub(6)) - 1)) or ""
        local prev = (prev_mk ~= "" and tech_map[tech][prev_mk]) or nil

        -- Receipts
        local cmp_r = ""
        if prev and prev.receipts > 0 then
            cmp_r = cmp_badge(prev.receipts, curr.receipts, true)
        end
        html = html .. '<td class="num-cell">' .. fmt_num(curr.receipts) .. ' ' .. cmp_r .. '</td>'

        -- Days
        local cmp_d = ""
        if prev and prev.avg_days > 0 then
            cmp_d = cmp_badge_days(prev.avg_days, curr.avg_days, false)
        end
        html = html .. '<td class="num-cell">' .. fmt_decimal(curr.avg_days, 1) .. ' ' .. cmp_d .. '</td>'

        -- Parts
        local cmp_p = ""
        if prev and prev.parts > 0 then
            cmp_p = cmp_badge(prev.parts, curr.parts, true)
        end
        html = html .. '<td class="num-cell">' .. fmt_num(curr.parts) .. ' ' .. cmp_p .. '</td>'

        -- Rejects
        local cmp_rej = ""
        if prev and prev.rejects > 0 then
            cmp_rej = cmp_badge(prev.rejects, curr.rejects, false)
        end
        html = html .. '<td class="num-cell">' .. fmt_num(curr.rejects) .. ' ' .. cmp_rej .. '</td>'
    end

    html = html .. '</tr>'
end

html = html .. '</tbody></table>'

return { ok = true, result = html }
