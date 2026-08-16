-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30
-- Test: Check NEW_ID + FINAL_STATUS for receipts 313141 (منتظر QC) و 313970 (مرجوع QC)

local function fetch_rows(query, params)
    db.use_db("0000000")
    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
    end)
    if not ok then
        return nil, err
    end
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

local rows, err = fetch_rows([[
SELECT
  sr.ID as receipt_id,
  sr.CODE as receipt_code,
  sr.FINAL_STATUS,
  psc.NEW_ID,
  psc.TYPE,
  FROM_UNIXTIME(COALESCE(psc.CREATION_DATE, 0) / 10000000 - 11644473600) as created_at,
  COALESCE(pm.FULLNAME, 'نامشخص') as author
FROM pm_service_request sr
LEFT JOIN pm_service_request_content psc ON psc.SERVICE_REQUEST_ID = sr.ID
LEFT JOIN profile_main pm ON pm.ID = psc.AUTHOR_ID
WHERE sr.ID IN (313141, 313970)
ORDER BY sr.ID DESC, psc.CREATION_DATE DESC
]], {})

if not rows then
    return { ok = false, error = "Query failed: " .. (err or "unknown") }
end

local result = "<pre>"
result = result .. string.format("%-15s %-12s %-15s %-10s %-6s %-20s %s\n",
    "Receipt_ID", "Code", "FINAL_STATUS", "NEW_ID", "TYPE", "Created_At", "Author")
result = result .. string.rep("-", 110) .. "\n"

for _, r in ipairs(rows) do
    local receipt_id = r[1] or ""
    local code = r[2] or ""
    local final_status = r[3] or ""
    local new_id = r[4] or ""
    local type_val = r[5] or ""
    local created_at = r[6] or ""
    local author = r[7] or ""

    result = result .. string.format("%-15s %-12s %-15s %-10s %-6s %-20s %s\n",
        tostring(receipt_id), tostring(code), tostring(final_status),
        tostring(new_id), tostring(type_val), tostring(created_at), tostring(author))
end
result = result .. "</pre>"

return { ok = true, result = result }
