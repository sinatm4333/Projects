-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30
-- Receipt 313997: تمام status + comments

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

-- Get current receipt info
local info_rows = fetch_rows([[
SELECT ID, CODE, FINAL_STATUS FROM pm_service_request WHERE ID = 313997
]], {})

-- Get status history
local status_rows = fetch_rows([[
SELECT
  NEW_ID,
  FROM_UNIXTIME(COALESCE(CREATION_DATE, 0) / 10000000 - 11644473600) as date,
  COALESCE((SELECT FULLNAME FROM profile_main p WHERE p.ID = psc.AUTHOR_ID), 'نامشخص') as author
FROM pm_service_request_content psc
WHERE SERVICE_REQUEST_ID = 313997 AND TYPE = 11
ORDER BY CREATION_DATE DESC
]], {})

local html = "<h2>Receipt 313997 - Status & History</h2>"

if info_rows and #info_rows > 0 then
    html = html .. "<h3>Current Status</h3><pre>"
    html = html .. "ID: " .. tostring(info_rows[1][1]) .. "\n"
    html = html .. "CODE: " .. tostring(info_rows[1][2]) .. "\n"
    html = html .. "FINAL_STATUS: " .. tostring(info_rows[1][3]) .. "\n"
    html = html .. "</pre>"
end

html = html .. "<h3>Status Changes History</h3><pre>"
html = html .. string.format("%-10s %-25s %s\n", "NEW_ID", "Date", "Author")
html = html .. string.rep("-", 70) .. "\n"

if status_rows then
    for _, r in ipairs(status_rows) do
        html = html .. string.format("%-10s %-25s %s\n",
            tostring(r[1] or ""), tostring(r[2] or ""), tostring(r[3] or ""))
    end
end
html = html .. "</pre>"

return { ok = true, result = html }
