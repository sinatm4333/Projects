-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30
-- Receipt 313997: وضعیت + تاریخچهٔ کامل

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
  sr.ID,
  sr.CODE,
  sr.FINAL_STATUS,
  psc.NEW_ID,
  psc.TYPE,
  FROM_UNIXTIME(COALESCE(psc.CREATION_DATE, 0) / 10000000 - 11644473600) as changed_at,
  COALESCE(pm.FULLNAME, 'نامشخص') as changed_by
FROM pm_service_request sr
LEFT JOIN pm_service_request_content psc ON psc.SERVICE_REQUEST_ID = sr.ID
LEFT JOIN profile_main pm ON pm.ID = psc.AUTHOR_ID
WHERE sr.ID = 313997
ORDER BY psc.CREATION_DATE DESC
]], {})

if not rows then
    return { ok = false, error = "Query failed" }
end

local html = "<h3>Receipt 313997 - تاریخچهٔ کامل</h3><pre>"
html = html .. string.format("%-15s %-15s %-10s %-6s %-25s %s\n",
    "FINAL_STATUS", "NEW_ID", "TYPE", "Seq", "Changed_At", "Changed_By")
html = html .. string.rep("-", 100) .. "\n"

local final_status = ""
for _, r in ipairs(rows) do
    local id = r[1] or ""
    local code = r[2] or ""
    local final_status_val = r[3] or ""
    local new_id = r[4] or ""
    local type_val = r[5] or ""
    local changed_at = r[6] or ""
    local changed_by = r[7] or ""

    if final_status == "" then final_status = final_status_val end

    html = html .. string.format("%-15s %-15s %-10s %-6s %-25s %s\n",
        tostring(final_status_val), tostring(new_id), tostring(type_val),
        tostring(type_val), tostring(changed_at), tostring(changed_by))
end

html = html .. "\n\n<strong>FINAL_STATUS فعلی: " .. tostring(final_status) .. "</strong>"
html = html .. "</pre>"

return { ok = true, result = html }
