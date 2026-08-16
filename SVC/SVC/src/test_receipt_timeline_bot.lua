-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30
-- Receipt 313970 timeline: تمام status changes

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

local rows = fetch_rows([[
SELECT
  SERVICE_REQUEST_ID,
  NEW_ID,
  FROM_UNIXTIME(COALESCE(CREATION_DATE, 0) / 10000000 - 11644473600) as date_changed
FROM pm_service_request_content
WHERE SERVICE_REQUEST_ID IN (313141, 313970, 313997)
ORDER BY SERVICE_REQUEST_ID DESC, CREATION_DATE DESC
]], {})

if not rows then
    return { ok = false, error = "Query failed" }
end

local html = "<pre><strong>تاریخچهٔ رسیدها:</strong>\n\n"
html = html .. "Receipt_ID | NEW_ID | Date_Changed\n"
html = html .. string.rep("-", 60) .. "\n"

for _, r in ipairs(rows) do
    html = html .. string.format("%s | %s | %s\n", r[1] or "", r[2] or "", r[3] or "")
end
html = html .. "</pre>"

return { ok = true, result = html }
