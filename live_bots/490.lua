local DB_NAME = "0000000"
db.use_db(DB_NAME)

local sql = [[
SELECT ID, TITLE
FROM sales_invoice
WHERE TITLE IS NOT NULL
  AND DELETED = 0
]]

db.query({ query = sql, params = {} })

local rows = {}
local rec = {}
local total_invoices = 0

while db.query_fetch(rec) do
    total_invoices = total_invoices + 1

    local id = rec[1]
    local title = tostring(rec[2] or "")

    -- گرفتن اولین عدد 5 یا 6 رقمی
    local number = string.match(title, "(%d%d%d%d%d+)")

    if number ~= nil then
        rows[#rows+1] = {
            id = id,
            number = tonumber(number)
        }
    end
end

db.query_free()

if #rows == 0 then
    teamyar.write_result("هیچ شماره‌ای استخراج نشد")
    return
end

-- مرتب سازی
table.sort(rows, function(a,b)
    return a.number < b.number
end)

local min_number = rows[1].number
local max_number = rows[#rows].number

-- پیدا کردن گپ
local missing = {}

for i = 2, #rows do
    local prev = rows[i-1].number
    local curr = rows[i].number

    if curr - prev > 1 then
        for n = prev + 1, curr - 1 do
            missing[#missing+1] = n
        end
    end
end

-- تبدیل به بازه
local ranges = {}

if #missing > 0 then
    local start_num = missing[1]
    local prev_num = missing[1]

    for i = 2, #missing do
        if missing[i] == prev_num + 1 then
            prev_num = missing[i]
        else
            ranges[#ranges+1] = {start = start_num, finish = prev_num}
            start_num = missing[i]
            prev_num = missing[i]
        end
    end

    ranges[#ranges+1] = {start = start_num, finish = prev_num}
end

-- UI
local html = "<div style='font-family:tahoma;direction:rtl;padding:15px'>"
html = html .. "<h3>گزارش بررسی سری بودن شماره فاکتور</h3>"

html = html .. "<div>تعداد کل فاکتورهای حذف‌نشده: <b>" .. total_invoices .. "</b></div>"
html = html .. "<div>تعداد فاکتور دارای شماره معتبر: <b>" .. #rows .. "</b></div>"
html = html .. "<div>بازه شماره‌ها: <b>" .. min_number .. " تا " .. max_number .. "</b></div>"
html = html .. "<div>تعداد کل شماره‌های گمشده: <b style='color:red'>" .. #missing .. "</b></div><br>"

if #ranges == 0 then
    html = html .. "<div style='color:green;font-weight:bold'>هیچ گپی در سری شماره‌ها وجود ندارد</div>"
else
    html = html .. "<table style='border-collapse:collapse;width:100%;font-size:13px'>"
    html = html .. "<tr style='background:#f5f5f5'>"
    html = html .. "<th style='border:1px solid #ccc;padding:6px'>ردیف</th>"
    html = html .. "<th style='border:1px solid #ccc;padding:6px'>از شماره</th>"
    html = html .. "<th style='border:1px solid #ccc;padding:6px'>تا شماره</th>"
    html = html .. "<th style='border:1px solid #ccc;padding:6px'>تعداد در بازه</th>"
    html = html .. "</tr>"

    for i=1,#ranges do
        local r = ranges[i]
        local count_range = r.finish - r.start + 1

        html = html .. "<tr>"
        html = html .. "<td style='border:1px solid #ddd;padding:6px;text-align:center'>" .. i .. "</td>"
        html = html .. "<td style='border:1px solid #ddd;padding:6px;text-align:center'>" .. r.start .. "</td>"
        html = html .. "<td style='border:1px solid #ddd;padding:6px;text-align:center'>" .. r.finish .. "</td>"
        html = html .. "<td style='border:1px solid #ddd;padding:6px;text-align:center;color:red'>" .. count_range .. "</td>"
        html = html .. "</tr>"
    end

    html = html .. "<tr style='background:#fafafa;font-weight:bold'>"
    html = html .. "<td colspan='3' style='border:1px solid #ccc;padding:6px;text-align:center'>مجموع کل شماره‌های گمشده</td>"
    html = html .. "<td style='border:1px solid #ccc;padding:6px;text-align:center;color:red'>" .. #missing .. "</td>"
    html = html .. "</tr>"

    html = html .. "</table>"
end

html = html .. "</div>"

teamyar.write_result(html)
