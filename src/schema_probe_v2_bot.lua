-- تحلیل و ایجاد توسط مهدی جهانی 09125632329
-- Last Edit = 1405/05/02 17:00

local input = teamyar.get_input() or {}
local mode = input["mode"] or "cols"
local like = input["table"] or "sales_price%"

local function fetch_rows(query, params)
    if (teamyar.get_input() or {})["nodb"] ~= "1" then
        pcall(function() db.use_db("0000000") end)
    end
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

local function out(o) teamyar.write_result(json.encode(o)) end

if mode == "cols" then
    local cols, err = fetch_rows([[
        SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '0000000' AND TABLE_NAME LIKE ?
        ORDER BY TABLE_NAME, ORDINAL_POSITION
    ]], { like })
    if cols == nil then out({ ok=false, error=tostring(err) }); return end
    local tables = {}
    for _, r in ipairs(cols) do
        local tn = r[1]
        if tables[tn] == nil then tables[tn] = {} end
        table.insert(tables[tn], { column=r[2], type=r[3], key=r[4] })
    end
    out({ ok=true, tables=tables })
    return
end

if mode == "tables" then
    local rows, err = fetch_rows([[
        SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA='0000000' AND TABLE_NAME LIKE ? ORDER BY TABLE_NAME
    ]], { like })
    if rows == nil then out({ ok=false, error=tostring(err) }); return end
    local t = {}
    for _, r in ipairs(rows) do table.insert(t, r[1]) end
    out({ ok=true, tables=t })
    return
end

if mode == "raw" then
    local rows, err = fetch_rows(input["q"], {})
    if rows == nil then out({ ok=false, error=tostring(err) }); return end
    out({ ok=true, rows=rows })
    return
end

-- simulate: دقیقاً همان الگوی action_management_dashboard_report_bot.lua را بازتولید می‌کند
-- (fetch now_raw از DB، محاسبهٔ from_raw با Lua arithmetic، سپس Query با همان دو مقدار به‌عنوان Param)
if mode == "simulate" then
    local now_rows, e0 = fetch_rows("SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS now_raw", {})
    if now_rows == nil then out({ ok=false, step="now_raw", error=tostring(e0) }); return end
    local now_raw = tonumber(now_rows[1][1])

    local DAY_TICKS = 10000000 * 86400
    local from_raw = now_raw - (90 * DAY_TICKS)
    local to_raw = now_raw

    local q = [[
SELECT
    tt.ID,
    tt.AUTHOR_ID,
    COALESCE(pm_a.fullname, 'نامشخص') AS author_name,
    tt.CATEGORY_ID,
    COALESCE(tc.CATEGORY_TITLE, 'بدون رده') AS category_title,
    tc.SECTION_ID,
    COALESCE(ts_sec.SECTION_NAME, 'بدون واحد') AS section_name,
    tt.TOPIC_ID,
    COALESCE(tp.NAME, 'سایر') AS topic_name,
    tt.WORK_FLOW_ID,
    COALESCE(tw.WF_TITLE, 'بدون جریان‌کار') AS wf_title,
    tt.TASK_TITLE,
    tt.STATUS,
    tt.T_START_DATE,
    tt.T_REAL_END_DATE
FROM todo_task tt
LEFT JOIN profile_main pm_a ON pm_a.id = tt.AUTHOR_ID
LEFT JOIN todo_category tc ON tc.ID = tt.CATEGORY_ID
LEFT JOIN todo_section ts_sec ON ts_sec.ID = tc.SECTION_ID
LEFT JOIN todo_topic tp ON tp.ID = tt.TOPIC_ID
LEFT JOIN todo_workflow tw ON tw.ID = tt.WORK_FLOW_ID
WHERE tt.T_START_DATE >= ? AND tt.T_START_DATE <= ?
ORDER BY tt.ID DESC
    ]]
    local rows, err = fetch_rows(q, { from_raw, to_raw })
    if rows == nil then
        out({ ok=false, step="ranged_query", now_raw=now_raw, from_raw=from_raw, to_raw=to_raw, error=tostring(err) })
        return
    end
    out({ ok=true, now_raw=now_raw, from_raw=from_raw, to_raw=to_raw, rows=rows })
    return
end

-- rawp: مثل raw ولی params را به‌صورت آرایهٔ JSON در input["params"] می‌پذیرد — برای دیباگ Queryهای Parameterized
if mode == "rawp" then
    local params_json = input["params"] or "[]"
    local ok_p, params = pcall(function() return json.decode(params_json) end)
    if not ok_p or params == nil then params = {} end
    local rows, err = fetch_rows(input["q"], params)
    if rows == nil then out({ ok=false, error=tostring(err), params_used=params }); return end
    out({ ok=true, rows=rows, params_used=params })
    return
end

-- findval: scan all bigint columns for a value, over a slice of the candidate list
if mode == "findval" then
    local val = tonumber(input["val"]) or 0
    local off = tonumber(input["off"]) or 0
    local lim = tonumber(input["lim"]) or 250
    local minr = tonumber(input["minr"]) or 100
    local maxr = tonumber(input["maxr"]) or 2000000

    local cols, err = fetch_rows([[
        SELECT c.TABLE_NAME, c.COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS c
        JOIN INFORMATION_SCHEMA.TABLES t
          ON t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME
        WHERE c.TABLE_SCHEMA='0000000' AND c.DATA_TYPE='bigint'
          AND t.TABLE_TYPE='BASE TABLE'
          AND t.TABLE_ROWS BETWEEN ? AND ?
        ORDER BY c.TABLE_NAME, c.COLUMN_NAME
        LIMIT ? OFFSET ?
    ]], { minr, maxr, lim, off })
    if cols == nil then out({ ok=false, error=tostring(err) }); return end

    local hits = {}
    for _, c in ipairs(cols) do
        local q = "SELECT 1 FROM `" .. c[1] .. "` WHERE `" .. c[2] .. "`=" .. val .. " LIMIT 1"
        local r = fetch_rows(q)
        if r ~= nil and #r > 0 then
            table.insert(hits, c[1] .. "." .. c[2])
        end
    end
    out({ ok=true, scanned=#cols, off=off, hits=hits })
    return
end

-- findpair: find a table whose single row contains BOTH values a and b (across its bigint cols)
if mode == "findpair" then
    local a = tonumber(input["a"]) or 0
    local b = tonumber(input["b"]) or 0
    local off = tonumber(input["off"]) or 0
    local lim = tonumber(input["lim"]) or 400
    local minr = tonumber(input["minr"]) or 100
    local maxr = tonumber(input["maxr"]) or 2000000

    local tcols, err = fetch_rows([[
        SELECT c.TABLE_NAME, GROUP_CONCAT(c.COLUMN_NAME)
        FROM INFORMATION_SCHEMA.COLUMNS c
        JOIN INFORMATION_SCHEMA.TABLES t
          ON t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME
        WHERE c.TABLE_SCHEMA='0000000' AND c.DATA_TYPE='bigint'
          AND t.TABLE_TYPE='BASE TABLE'
          AND t.TABLE_ROWS BETWEEN ? AND ?
        GROUP BY c.TABLE_NAME
        HAVING COUNT(*) >= 2
        ORDER BY c.TABLE_NAME
        LIMIT ? OFFSET ?
    ]], { minr, maxr, lim, off })
    if tcols == nil then out({ ok=false, error=tostring(err) }); return end

    local hits = {}
    local scanned = 0
    for _, tc in ipairs(tcols) do
        local tname = tc[1]
        local cols = {}
        for c in tostring(tc[2]):gmatch("[^,]+") do table.insert(cols, c) end
        local a_terms = {}
        local b_terms = {}
        for _, c in ipairs(cols) do
            table.insert(a_terms, "`" .. c .. "`=" .. a)
            table.insert(b_terms, "`" .. c .. "`=" .. b)
        end
        local q = "SELECT 1 FROM `" .. tname .. "` WHERE ("
            .. table.concat(a_terms, " OR ") .. ") AND ("
            .. table.concat(b_terms, " OR ") .. ") LIMIT 1"
        local r = fetch_rows(q)
        scanned = scanned + 1
        if r ~= nil and #r > 0 then
            table.insert(hits, tname)
        end
    end
    out({ ok=true, scanned=scanned, off=off, hits=hits })
    return
end

out({ ok=false, error="unknown mode" })

