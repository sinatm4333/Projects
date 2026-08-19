-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/28 08:15

-- Bot: Call Center Admin Dashboard - Probe
-- Version: v01 (اکتشافی - نتیجه‌اش قبل از ساخت بات نهایی داشبورد بررسی می‌شود، بعداً حذف/آرشیو شود)
--
-- هدف: قبل از نوشتن بات نهایی «داشبورد مدیریتی کال‌سنتر»، چند ابهام واقعی روی دیتای زنده
-- voip_calls را که از خواندن ۹ بات موجود (id های 256..265) به‌تنهایی قابل حل نبود، با یک Query
-- واقعی روشن می‌کند:
--   1) واقعاً چه مقادیری برای DialStatus وجود دارد (بات‌های موجود فقط 3/4/5/6 را فرض کرده‌اند).
--   2) قرارداد Inbound/Outbound بین بات‌ها ناسازگار است — bot 264 می‌گوید Caller کوچک (<100000) +
--      ConnectedLine بزرگ (>10000) یعنی Outbound (اپراتور تماس‌گیرنده)، اما bot 262 برچسب inbound را
--      به «اپراتور روی سمت Caller» می‌دهد که برعکس همان قرارداد است. این پروب با شمارش طول/بازهٔ
--      واقعی CallerNum/ConnectedLineNum وقتی هرکدام به یک profile_main واقعی وصل‌اند، تعیین می‌کند
--      کدام قرارداد درست است.
--   3) آیا اصلاً وضعیت لحظه‌ای/آنلاین کارمند در اسکیما وجود دارد (پاسخ اولیه از DatabaseSchema.md:
--      خیر — فقط voip_calls با TimeEnd خالی/۰ می‌تواند تقریبی از «الان روی خط است» بدهد؛ اینجا
--      اعتبارسنجی می‌شود).
--   4) آیا جدول آرشیو (`0000000_archive`.voip_calls که چند بات UNION می‌زنند) واقعاً وجود دارد.
--   5) نمونهٔ واقعی voip_ty_permission/profile_main برای فهرست «کارمندان زیرمجموعهٔ من».
--
-- خروجی: JSON با یک بخش به‌ازای هر سؤال، هرکدام در pcall جدا (خطای یک Query بقیه را متوقف نکند).

local input = teamyar.get_input() or {}
local user_info = teamyar.get_user_info()
local owner_user = user_info.id

-- بازهٔ پیش‌فرض: ۳۰ روز اخیر (تیک FILETIME، هم‌قرارداد با بات‌های موجود و action_management_dashboard)
local date_to = tonumber(input.date_to) or time.current()
local date_from = tonumber(input.date_from) or (date_to - (30 * time.day))
local sample_limit = tonumber(input.sample_limit) or 20

local function run_query(query, query_params)
    db.query({ query = query, params = query_params or {} })
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

-- هر بخش را در pcall جدا اجرا می‌کند تا خطای یکی بقیهٔ پروب را متوقف نکند
local function safe_section(fn)
    local ok, result_or_err = pcall(fn)
    if ok then
        return { ok = true, data = result_or_err }
    else
        return { ok = false, error = tostring(result_or_err) }
    end
end

local result = { ok = true, date_from = date_from, date_to = date_to }

-- 1) توزیع واقعی DialStatus در بازه
result.dialstatus_distribution = safe_section(function()
    local rows = run_query([[
        SELECT DialStatus, COUNT(*) AS cnt
        FROM voip_calls
        WHERE Date BETWEEN ? AND ?
        GROUP BY DialStatus
        ORDER BY cnt DESC
    ]], { date_from, date_to })
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, { dialstatus = tonumber(r[1]), cnt = tonumber(r[2]) })
    end
    return out
end)

-- 2) نمونهٔ خام ردیف‌ها برای چشمی دیدن الگوی واقعی شماره‌ها/طول‌ها
result.sample_rows = safe_section(function()
    local rows = run_query(string.format([[
        SELECT ID, Date, CallerNum, CallerName, CallerProfileID,
               ConnectedLineNum, ConnectedLineName, ConnectedLineProfileID,
               DialStatus, Duration, TimeStart, TimeEnd, ChannelState, queue
        FROM voip_calls
        WHERE Date BETWEEN ? AND ?
        ORDER BY Date DESC
        LIMIT %d
    ]], sample_limit), { date_from, date_to })
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, {
            id = r[1], date = r[2], caller_num = r[3], caller_name = r[4], caller_profile_id = r[5],
            connected_num = r[6], connected_name = r[7], connected_profile_id = r[8],
            dialstatus = tonumber(r[9]), duration = tonumber(r[10]),
            time_start = r[11], time_end = r[12], channel_state = r[13], queue = r[14]
        })
    end
    return out
end)

-- 3) قرارداد Inbound/Outbound: وقتی سمت Caller یک profile_main واقعی است، CallerNum معمولاً چند رقمی
--    است؟ وقتی سمت ConnectedLine یک profile_main واقعی است، ConnectedLineNum معمولاً چند رقمی است؟
result.inbound_outbound_convention_check = safe_section(function()
    local rows = run_query([[
        SELECT
            SUM(CallerProfileID IN (SELECT ID FROM profile_main)) AS caller_is_known_profile,
            SUM(ConnectedLineProfileID IN (SELECT ID FROM profile_main)) AS connected_is_known_profile,
            AVG(CASE WHEN CallerProfileID IN (SELECT ID FROM profile_main) THEN LENGTH(CallerNum) END) AS avg_len_callernum_when_caller_is_agent,
            AVG(CASE WHEN ConnectedLineProfileID IN (SELECT ID FROM profile_main) THEN LENGTH(ConnectedLineNum) END) AS avg_len_connectednum_when_connected_is_agent,
            SUM(CallerNum > 100000) AS callernum_gt_100000_cnt,
            SUM(ConnectedLineNum > 10000) AS connectednum_gt_10000_cnt,
            SUM(CallerNum < 100000 AND ConnectedLineNum > 10000) AS bot264_outbound_def_cnt,
            SUM(CallerNum > 100000) AS bot264_inbound_def_cnt,
            COUNT(*) AS total_rows
        FROM voip_calls
        WHERE Date BETWEEN ? AND ?
    ]], { date_from, date_to })
    local r = rows[1] or {}
    return {
        caller_is_known_profile = tonumber(r[1]),
        connected_is_known_profile = tonumber(r[2]),
        avg_len_callernum_when_caller_is_agent = tonumber(r[3]),
        avg_len_connectednum_when_connected_is_agent = tonumber(r[4]),
        callernum_gt_100000_cnt = tonumber(r[5]),
        connectednum_gt_10000_cnt = tonumber(r[6]),
        bot264_outbound_def_cnt = tonumber(r[7]),
        bot264_inbound_def_cnt = tonumber(r[8]),
        total_rows = tonumber(r[9])
    }
end)

-- 4) آیا آرشیو وجود دارد؟
result.archive_table_exists = safe_section(function()
    local rows = run_query([[
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME = 'voip_calls' AND TABLE_SCHEMA LIKE '%archive%'
    ]], {})
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, { schema = r[1], table_name = r[2] })
    end
    return out
end)

-- 5) کارمندان زیرمجموعهٔ کاربر جاری (همان الگوی userAclData در بات‌های موجود)
result.visible_agents = safe_section(function()
    local rows = run_query(string.format([[
        SELECT vp.USER_ID, pm.FULLNAME
        FROM voip_TY_PERMISSION vp
        LEFT JOIN profile_main pm ON vp.USER_ID = pm.ID
        WHERE vp.ID = %d AND vp.TYPE = 1 AND vp.PERM IN (2,3) AND vp.RAW_PERM = 0 AND pm.TYPE = 1
        LIMIT %d
    ]], owner_user, sample_limit), {})
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, { user_id = r[1], fullname = r[2] })
    end
    return out
end)

-- 6) تماس‌های «الان در حال انجام» (تقریب وضعیت آنلاین/مشغول از روی TimeEnd خالی)
result.active_calls_now = safe_section(function()
    local rows = run_query(string.format([[
        SELECT ID, CallerNum, CallerProfileID, ConnectedLineNum, ConnectedLineProfileID,
               ChannelState, TimeStart, TimeEnd, Date
        FROM voip_calls
        WHERE (TimeEnd IS NULL OR TimeEnd = 0) AND Date BETWEEN ? AND ?
        ORDER BY Date DESC
        LIMIT %d
    ]], sample_limit), { date_from, date_to })
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, {
            id = r[1], caller_num = r[2], caller_profile_id = r[3],
            connected_num = r[4], connected_profile_id = r[5],
            channel_state = r[6], time_start = r[7], time_end = r[8], date = r[9]
        })
    end
    return out
end)

-- 7) نمونهٔ profile_phone_extension (آیا نگاشت اپراتور<->داخلی برای «کارمندان لاگین/آنلاین» قابل استفاده است)
result.phone_extension_sample = safe_section(function()
    local rows = run_query(string.format([[
        SELECT ID, USER_ID, EXTENSION, type, voip_name
        FROM voip_phone_extension
        LIMIT %d
    ]], sample_limit), {})
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, { id = r[1], user_id = r[2], extension = r[3], type = r[4], voip_name = r[5] })
    end
    return out
end)

-- 8) پیش‌نمایش ۱۰ اپراتور برتر از دو سمت (Caller / ConnectedLine) با آمار خام، برای دیدن کدام سمت
--    واقعاً «اپراتورهای شناخته‌شده» هستند
result.top_agents_by_caller_side = safe_section(function()
    local rows = run_query(string.format([[
        SELECT v.CallerProfileID, pm.FULLNAME, COUNT(*) total, SUM(v.DialStatus = 5) answer,
               SUM(v.Duration) duration_sum
        FROM voip_calls v
        INNER JOIN profile_main pm ON pm.ID = v.CallerProfileID
        WHERE v.Date BETWEEN ? AND ?
        GROUP BY v.CallerProfileID, pm.FULLNAME
        ORDER BY total DESC
        LIMIT %d
    ]], sample_limit), { date_from, date_to })
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, {
            profile_id = r[1], fullname = r[2], total = tonumber(r[3]),
            answer = tonumber(r[4]), duration_sum = tonumber(r[5])
        })
    end
    return out
end)

result.top_agents_by_connected_side = safe_section(function()
    local rows = run_query(string.format([[
        SELECT v.ConnectedLineProfileID, pm.FULLNAME, COUNT(*) total, SUM(v.DialStatus = 5) answer,
               SUM(v.Duration) duration_sum
        FROM voip_calls v
        INNER JOIN profile_main pm ON pm.ID = v.ConnectedLineProfileID
        WHERE v.Date BETWEEN ? AND ?
        GROUP BY v.ConnectedLineProfileID, pm.FULLNAME
        ORDER BY total DESC
        LIMIT %d
    ]], sample_limit), { date_from, date_to })
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, {
            profile_id = r[1], fullname = r[2], total = tonumber(r[3]),
            answer = tonumber(r[4]), duration_sum = tonumber(r[5])
        })
    end
    return out
end)

teamyar.write_result(json.encode(result))
