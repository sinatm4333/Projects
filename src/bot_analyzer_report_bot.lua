local input = teamyar.get_input() or {}

local days = tonumber(input["days"]) or 30
if days < 1 then
    days = 1
elseif days > 365 then
    days = 365
end

local limit = tonumber(input["limit"]) or 20
if limit < 1 then
    limit = 1
elseif limit > 100 then
    limit = 100
end

local include_disabled = input["include_disabled"] == true
    or input["include_disabled"] == 1
    or input["include_disabled"] == "1"
    or input["includeDisabled"] == true
    or input["includeDisabled"] == 1
    or input["includeDisabled"] == "1"

local function append_unique_bot_id(ids, seen, value)
    local id = tonumber(value)
    if id == nil or id <= 0 or seen[id] then
        return
    end
    seen[id] = true
    table.insert(ids, id)
end

local function collect_bot_ids(raw, ids, seen)
    if raw == nil then
        return
    end

    local value_type = type(raw)
    if value_type == "number" then
        append_unique_bot_id(ids, seen, raw)
        return
    end

    if value_type == "string" then
        local trimmed = raw:match("^%s*(.-)%s*$")
        if trimmed == "" then
            return
        end
        if trimmed:sub(1, 1) == "[" then
            local ok, decoded = pcall(json.decode, trimmed)
            if ok and decoded ~= nil then
                collect_bot_ids(decoded, ids, seen)
                return
            end
        end
        for part in trimmed:gmatch("[^,;]+") do
            append_unique_bot_id(ids, seen, part:match("^%s*(.-)%s*$"))
        end
        return
    end

    if value_type == "table" then
        for key, item in pairs(raw) do
            if type(item) == "table" then
                collect_bot_ids(
                    item.id or item.ID or item.bot_id or item.botId
                        or item.command_id or item.commandId,
                    ids,
                    seen
                )
            elseif type(key) == "number" then
                collect_bot_ids(item, ids, seen)
            else
                collect_bot_ids(item, ids, seen)
            end
        end
    end
end

local function parse_bot_ids(source)
    local ids = {}
    local seen = {}
    collect_bot_ids(source["bot_ids"] or source["botIds"], ids, seen)
    collect_bot_ids(source["command_ids"] or source["commandIds"], ids, seen)
    collect_bot_ids(source["bot_id"] or source["botId"], ids, seen)
    collect_bot_ids(source["command_id"] or source["commandId"], ids, seen)
    table.sort(ids)
    return ids
end

local function make_action_type_key(workflow_id, topic_id)
    return tostring(tonumber(workflow_id) or workflow_id)
        .. ":"
        .. tostring(tonumber(topic_id) or 0)
end

local function append_unique_action_type_key(keys, seen, workflow_id, topic_id)
    local wf_id = tonumber(workflow_id)
    if wf_id == nil or wf_id <= 0 then
        return
    end
    local key = make_action_type_key(wf_id, topic_id)
    if seen[key] then
        return
    end
    seen[key] = true
    table.insert(keys, key)
end

local function collect_action_type_keys(raw, keys, seen)
    if raw == nil then
        return
    end

    local value_type = type(raw)
    if value_type == "number" then
        append_unique_action_type_key(keys, seen, raw, 0)
        return
    end

    if value_type == "string" then
        local trimmed = raw:match("^%s*(.-)%s*$")
        if trimmed == "" then
            return
        end
        if trimmed:sub(1, 1) == "[" then
            local ok, decoded = pcall(json.decode, trimmed)
            if ok and decoded ~= nil then
                collect_action_type_keys(decoded, keys, seen)
                return
            end
        end
        for part in trimmed:gmatch("[^,;]+") do
            local token = part:match("^%s*(.-)%s*$")
            local wf_part, topic_part = token:match("^(%d+)%s*:%s*(%d+)$")
            if wf_part then
                append_unique_action_type_key(keys, seen, wf_part, topic_part)
            else
                append_unique_action_type_key(keys, seen, token, 0)
            end
        end
        return
    end

    if value_type == "table" then
        for key, item in pairs(raw) do
            if type(item) == "table" then
                if item.workflow_id or item.workflowId or item.work_flow_id or item.workFlowId then
                    append_unique_action_type_key(
                        keys,
                        seen,
                        item.workflow_id or item.workflowId or item.work_flow_id or item.workFlowId,
                        item.topic_id or item.topicId or 0
                    )
                else
                    local token = tostring(item.id or item.ID or item.key or item.action_type_id or item.actionTypeId or "")
                    local wf_part, topic_part = token:match("^(%d+)%s*:%s*(%d+)$")
                    if wf_part then
                        append_unique_action_type_key(keys, seen, wf_part, topic_part)
                    else
                        append_unique_action_type_key(keys, seen, token, 0)
                    end
                end
            elseif type(key) == "number" then
                collect_action_type_keys(item, keys, seen)
            else
                collect_action_type_keys(item, keys, seen)
            end
        end
    end
end

local function collect_workflow_ids(raw, keys, seen)
    if raw == nil then
        return
    end

    local value_type = type(raw)
    if value_type == "number" then
        append_unique_action_type_key(keys, seen, raw, 0)
        return
    end

    if value_type == "string" then
        local trimmed = raw:match("^%s*(.-)%s*$")
        if trimmed == "" then
            return
        end
        if trimmed:sub(1, 1) == "[" then
            local ok, decoded = pcall(json.decode, trimmed)
            if ok and decoded ~= nil then
                collect_workflow_ids(decoded, keys, seen)
                return
            end
        end
        for part in trimmed:gmatch("[^,;]+") do
            append_unique_action_type_key(keys, seen, part:match("^%s*(.-)%s*$"), 0)
        end
        return
    end

    if value_type == "table" then
        for key, item in pairs(raw) do
            if type(item) == "table" then
                append_unique_action_type_key(
                    keys,
                    seen,
                    item.id or item.ID or item.workflow_id or item.workflowId,
                    item.topic_id or item.topicId or 0
                )
            elseif type(key) == "number" then
                collect_workflow_ids(item, keys, seen)
            else
                collect_workflow_ids(item, keys, seen)
            end
        end
    end
end

local function parse_action_type_keys(source)
    local keys = {}
    local seen = {}
    collect_action_type_keys(source["action_type_ids"] or source["actionTypeIds"], keys, seen)
    collect_workflow_ids(source["workflow_ids"] or source["workflowIds"], keys, seen)
    collect_workflow_ids(source["workflow_id"] or source["workflowId"], keys, seen)
    table.sort(keys)
    return keys
end

local selected_bot_ids = parse_bot_ids(input)
local selected_action_type_keys = parse_action_type_keys(input)
local has_bot_selection = #selected_bot_ids > 0
local has_action_type_selection = #selected_action_type_keys > 0
local display_limit = has_bot_selection and math.min(#selected_bot_ids, 100) or limit

local function fmt_jalali_datetime(col)
    return [[
CASE
    WHEN ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = 0 THEN NULL
    ELSE CONCAT(
        REPORT_FN_JDATE(]] .. col .. [[, '-'),
        ' ',
        DATE_FORMAT(FROM_UNIXTIME(]] .. col .. [[ / 10000000 - 11644473600), '%H:%i:%s')
    )
END]]
end

local function format_duration(filetime_diff)
    local diff = tonumber(filetime_diff)
    if diff == nil or diff <= 0 then
        return nil
    end

    local total_sec = math.floor(diff / 10000000)
    local days_part = math.floor(total_sec / 86400)
    local hours = math.floor((total_sec % 86400) / 3600)
    local mins = math.floor((total_sec % 3600) / 60)
    local secs = total_sec % 60

    local parts = {}
    if days_part > 0 then
        table.insert(parts, days_part .. " روز")
    end
    if hours > 0 then
        table.insert(parts, hours .. " ساعت")
    end
    if mins > 0 then
        table.insert(parts, mins .. " دقیقه")
    end
    if secs > 0 or #parts == 0 then
        table.insert(parts, secs .. " ثانیه")
    end

    return table.concat(parts, " و ")
end

local function escape_html(value)
    if value == nil then
        return ""
    end
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

local function fmt_num(value)
    return tostring(tonumber(value) or 0)
end

local function performance_class(avg_running_time)
    local avg = tonumber(avg_running_time)
    if avg == nil then
        return "perf-neutral"
    end
    local sec = math.floor(avg / 10000000)
    if sec <= 2 then
        return "perf-good"
    elseif sec <= 10 then
        return "perf-normal"
    elseif sec <= 30 then
        return "perf-warning"
    end
    return "perf-critical"
end

local function status_badge(disabled)
    if disabled then
        return '<span class="badge badge-disabled">غیرفعال</span>'
    end
    return '<span class="badge badge-active">فعال</span>'
end

local function fetch_current_jalali_datetime()
    local record = {}
    local ok = pcall(function()
        db.query({
            query = [[
SELECT CONCAT(
    REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'),
    ' ',
    DATE_FORMAT(NOW(), '%H:%i:%s')
) AS generated_at
]],
            params = {}
        })
    end)
    if ok and db.query_fetch(record) and record[1] ~= nil then
        db.query_free()
        return tostring(record[1])
    end
    db.query_free()
    return "—"
end

local period_params = { days, days }

local query = [[
SELECT
    bc.ID,
    bc.NAME,
    bc.DISABLED,
    COALESCE(bcr.RUN_COUNT, 0) AS run_count,
    SUM(CASE
        WHEN bh.DATE_CREATE >= ((UNIX_TIMESTAMP() - (? * 86400)) + 11644473600) * 10000000 THEN 1
        ELSE 0
    END) AS runs_in_period,
    AVG(CASE
        WHEN bh.DATE_CREATE >= ((UNIX_TIMESTAMP() - (? * 86400)) + 11644473600) * 10000000
         AND bh.running_time IS NOT NULL AND bh.running_time > 0
        THEN bh.running_time
    END) AS avg_running_time,
    MAX(bh.DATE_CREATE) AS last_run_raw
FROM bot_command bc
LEFT JOIN bot_command_run bcr
    ON bcr.COMMAND_ID = bc.ID
LEFT JOIN bot_history bh
    ON bh.command_id = bc.ID
GROUP BY
    bc.ID,
    bc.NAME,
    bc.DISABLED,
    bc.MODIFY_DATE,
    bcr.RUN_COUNT
ORDER BY run_count DESC, bc.ID DESC
]]

local ok = pcall(function()
    db.query({
        query = query,
        params = period_params
    })
end)

if not ok then
    teamyar.write_result([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:tahoma;padding:2rem;text-align:center;">
<h2 style="color:#b42318;">خطا در دریافت تحلیل بات‌ها</h2>
</body></html>
]])
    return
end

local all_bots = {}
local record = {}

while db.query_fetch(record) do
    local avg_raw = tonumber(record[6])
    table.insert(all_bots, {
        id = tonumber(record[1]) or record[1],
        name = record[2],
        disabled = tonumber(record[3]) == 1,
        run_count = tonumber(record[4]) or 0,
        runs_in_period = tonumber(record[5]) or 0,
        avg_running_time = avg_raw,
        avg_running_time_label = avg_raw and format_duration(avg_raw) or "—",
        last_run = record[8] or "—",
        modify_date = record[9] or "—"
    })
end

db.query_free()

local function fetch_action_types_data()
    local action_types_search = {}
    local action_type_details = {}

    local types_query = [[
SELECT DISTINCT
    tw.id AS workflow_id,
    tw.WF_TITLE AS workflow_title,
    tc.CATEGORY_TITLE AS category_title,
    COALESCE(tt.TOPIC_ID, 0) AS topic_id,
    COALESCE(tp.NAME, '') AS topic_name
FROM todo_task tt
JOIN todo_workflow tw
    ON tw.id = tt.WORK_FLOW_ID
JOIN todo_category tc
    ON tc.id = tt.CATEGORY_ID
LEFT JOIN todo_topic tp
    ON tp.id = tt.TOPIC_ID
   AND COALESCE(tt.TOPIC_ID, 0) > 0
WHERE COALESCE(tw.wf_disabled, 0) = 0

UNION

SELECT
    tw.id AS workflow_id,
    tw.WF_TITLE AS workflow_title,
    tc.CATEGORY_TITLE AS category_title,
    0 AS topic_id,
    '' AS topic_name
FROM todo_workflow tw
JOIN todo_category tc
    ON tc.id = tw.CATEGORY_ID
WHERE COALESCE(tw.wf_disabled, 0) = 0
  AND NOT EXISTS (
        SELECT 1
        FROM todo_task tt
        WHERE tt.WORK_FLOW_ID = tw.id
    )

ORDER BY category_title, workflow_title, topic_name
]]

    local types_ok = pcall(function()
        db.query({
            query = types_query,
            params = {}
        })
    end)

    if types_ok then
        local type_record = {}
        while db.query_fetch(type_record) do
            local workflow_id = tonumber(type_record[1]) or type_record[1]
            local topic_id = tonumber(type_record[4]) or 0
            local type_key = make_action_type_key(workflow_id, topic_id)
            if action_type_details[type_key] == nil then
                action_type_details[type_key] = {
                    id = type_key,
                    workflow_id = workflow_id,
                    topic_id = topic_id,
                    category = type_record[3],
                    workflow = type_record[2],
                    topic = type_record[5],
                    open_task_count = 0,
                    tasks = {}
                }
                table.insert(action_types_search, {
                    id = type_key,
                    workflow_id = workflow_id,
                    topic_id = topic_id,
                    category = type_record[3],
                    workflow = type_record[2],
                    topic = type_record[5],
                    open_task_count = 0
                })
            end
        end
        db.query_free()
    else
        db.query_free()
    end

    local tasks_query = [[
SELECT
    tt.id,
    tt.TASK_TITLE,
    COALESCE(tt.AUTHOR_NAME, '') AS author_name,
    tt.WORK_FLOW_ID,
    COALESCE(tt.TOPIC_ID, 0) AS topic_id,
    ts.step_name,
    pm.fullname AS responsible_name,
    CASE
        WHEN tts.STATUS = 0 THEN 'پیش نویس'
        WHEN tts.STATUS = 1 THEN 'تایید شده'
        WHEN tts.STATUS = 2 THEN 'کامل شده'
        WHEN tts.STATUS = 3 THEN 'رد شده'
        ELSE 'نامشخص'
    END AS status,
    ]] .. fmt_jalali_datetime("tts.DATE_CREATE") .. [[ AS date_create,
    ]] .. fmt_jalali_datetime("tts.DATE_MODIFY") .. [[ AS date_modify
FROM todo_task_steps tts
JOIN todo_task tt
    ON tt.id = tts.TASK_ID
JOIN todo_step ts
    ON ts.id = tts.STEP_ID
JOIN profile_main pm
    ON pm.id = tts.RESPONSIBLE_ID
WHERE (tt.t_real_end_date IS NULL OR tt.t_real_end_date = 0)
  AND EXISTS (
        SELECT 1
        FROM todo_task_steps tts_open
        WHERE tts_open.TASK_ID = tt.id
          AND tts_open.STATUS = 0
    )
ORDER BY tt.id DESC, tts.id
]]

    local tasks_ok = pcall(function()
        db.query({
            query = tasks_query,
            params = {}
        })
    end)

    if not tasks_ok then
        db.query_free()
        return action_types_search, action_type_details
    end

    local task_map = {}
    local task_record = {}
    while db.query_fetch(task_record) do
        local task_id = tonumber(task_record[1]) or task_record[1]
        local workflow_id = tonumber(task_record[4]) or task_record[4]
        local topic_id = tonumber(task_record[5]) or 0
        local type_key = make_action_type_key(workflow_id, topic_id)
        local task_key = tostring(task_id)

        if task_map[task_key] == nil then
            task_map[task_key] = {
                task_id = task_id,
                task_title = task_record[2],
                author_name = task_record[3],
                workflow_id = workflow_id,
                type_key = type_key,
                steps = {}
            }
        end

        table.insert(task_map[task_key].steps, {
            step_name = task_record[6],
            responsible_name = task_record[7],
            status = task_record[8],
            date_create = task_record[9],
            date_modify = task_record[10]
        })
    end
    db.query_free()

    for _, task in pairs(task_map) do
        local details = action_type_details[task.type_key]
        if details ~= nil then
            local already_added = false
            for _, existing in ipairs(details.tasks) do
                if existing.task_id == task.task_id then
                    already_added = true
                    break
                end
            end
            if not already_added then
                table.insert(details.tasks, task)
                details.open_task_count = details.open_task_count + 1
            end
        end
    end

    for _, item in ipairs(action_types_search) do
        local details = action_type_details[item.id]
        if details ~= nil then
            item.open_task_count = details.open_task_count
        end
    end

    return action_types_search, action_type_details
end

local action_types_search, action_type_details = fetch_action_types_data()

local selected_bot_lookup = {}
for _, bot_id in ipairs(selected_bot_ids) do
    selected_bot_lookup[tonumber(bot_id)] = true
end

local analytics_bots = {}
for _, bot in ipairs(all_bots) do
    local is_selected = selected_bot_lookup[tonumber(bot.id)] == true
    if (has_bot_selection and is_selected)
        or (not has_bot_selection and (include_disabled or not bot.disabled)) then
        table.insert(analytics_bots, bot)
    end
end

local never_run = {}
local slowest = {}
local active_in_period = 0
local disabled_count = 0
local never_run_count = 0

for _, bot in ipairs(analytics_bots) do
    if bot.disabled then
        disabled_count = disabled_count + 1
    end
    if bot.run_count == 0 then
        never_run_count = never_run_count + 1
        table.insert(never_run, bot)
    end
    if bot.runs_in_period > 0 then
        active_in_period = active_in_period + 1
        if bot.avg_running_time ~= nil then
            table.insert(slowest, bot)
        end
    end
end

table.sort(slowest, function(a, b)
    if a.avg_running_time == b.avg_running_time then
        return (a.id or 0) < (b.id or 0)
    end
    return (a.avg_running_time or 0) > (b.avg_running_time or 0)
end)

local function heat_style(value, min_value, max_value)
    local v = tonumber(value) or 0
    local min_v = tonumber(min_value) or 0
    local max_v = tonumber(max_value) or 0
    if max_v <= min_v or v <= 0 then
        return "background-color:#ffffff;"
    end

    local n = (v - min_v) / (max_v - min_v)
    local r
    local g
    local b
    if n < 0.5 then
        r = math.floor(255 * n * 2)
        g = 255
        b = math.floor(255 * (1 - n * 2))
    else
        r = 255
        g = math.floor(255 * (2 - n * 2))
        b = 0
    end

    return string.format("background-color:rgb(%d,%d,%d);", r, g, b)
end

local function run_count_range(bots, max_rows)
    local min_value = nil
    local max_value = 0
    for i = 1, math.min(max_rows, #bots) do
        local count = tonumber(bots[i].run_count) or 0
        if min_value == nil or count < min_value then
            min_value = count
        end
        if count > max_value then
            max_value = count
        end
    end
    return min_value or 0, max_value
end

local function build_top_rows(bots, max_rows, with_heatmap)
    local rows = {}
    local min_runs, max_runs = 0, 0
    if with_heatmap then
        min_runs, max_runs = run_count_range(bots, max_rows)
    end

    for i = 1, math.min(max_rows, #bots) do
        local bot = bots[i]
        local run_style = ""
        local period_style = ""
        if with_heatmap then
            run_style = heat_style(bot.run_count, min_runs, max_runs)
            period_style = heat_style(bot.runs_in_period, 0, max_runs)
        end

        table.insert(rows, string.format(
            [[<tr>
                <td>%d</td>
                <td class="mono">%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td style="%s"><strong>%s</strong></td>
                <td style="%s">%s</td>
                <td class="%s">%s</td>
                <td>%s</td>
            </tr>]],
            i,
            escape_html(bot.id),
            escape_html(bot.name),
            status_badge(bot.disabled),
            run_style,
            fmt_num(bot.run_count),
            period_style,
            fmt_num(bot.runs_in_period),
            performance_class(bot.avg_running_time),
            escape_html(bot.avg_running_time_label),
            escape_html(bot.last_run)
        ))
    end
    if #rows == 0 then
        return [[<tr><td colspan="8" class="empty-row">داده‌ای یافت نشد</td></tr>]]
    end
    return table.concat(rows, "\n")
end

local function build_never_run_rows(bots, max_rows)
    local rows = {}
    for i = 1, math.min(max_rows, #bots) do
        local bot = bots[i]
        table.insert(rows, string.format(
            [[<tr>
                <td>%d</td>
                <td class="mono">%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td>%s</td>
            </tr>]],
            i,
            escape_html(bot.id),
            escape_html(bot.name),
            status_badge(bot.disabled),
            escape_html(bot.modify_date)
        ))
    end
    if #rows == 0 then
        return [[<tr><td colspan="5" class="empty-row">همه بات‌ها حداقل یک‌بار اجرا شده‌اند</td></tr>]]
    end
    return table.concat(rows, "\n")
end

local function escape_format(value)
    return (tostring(value):gsub("%%", "%%%%"))
end

local top_by_runs = {}
for i = 1, math.min(display_limit, #analytics_bots) do
    top_by_runs[i] = analytics_bots[i]
end

local slowest_avg = {}
for i = 1, math.min(display_limit, #slowest) do
    slowest_avg[i] = slowest[i]
end

local include_disabled_label = include_disabled and "بله" or "خیر"
local selection_label = has_action_type_selection
    and ("نوع اقدام انتخاب‌شده (" .. #selected_action_type_keys .. ")")
    or has_bot_selection
        and ("بات انتخاب‌شده (" .. #selected_bot_ids .. ")")
        or ("همه بات‌ها (" .. limit .. " پراجرات‌ترین)")
local generated_at = fetch_current_jalali_datetime()

local top_rows_html = escape_format(build_top_rows(top_by_runs, display_limit, true))
local slowest_rows_html = escape_format(build_top_rows(slowest_avg, display_limit, false))
local never_run_rows_html = escape_format(build_never_run_rows(never_run, display_limit))
local report_data_json = escape_format(json.encode({
    bots = all_bots,
    actionTypes = action_types_search,
    actionTypeDetails = action_type_details,
    limit = limit,
    days = days,
    include_disabled = include_disabled,
    selectedActionTypes = selected_action_type_keys,
    selectedBots = selected_bot_ids
}))

local html = string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>گزارش تحلیل بات‌ها</title>
<style>
* { box-sizing: border-box; }
body {
    margin: 0;
    padding: 12px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    background: #f5f7fb;
}
#reportRoot:fullscreen {
    background: #f5f7fb;
    padding: 12px;
    overflow: auto;
}
.toolbar {
    display: flex;
    justify-content: flex-start;
    gap: 8px;
    margin-bottom: 10px;
    flex-wrap: wrap;
}
.filter-panel {
    background: #fff;
    border: 2px solid #0073e6;
    border-radius: 8px;
    padding: 12px;
    margin-bottom: 12px;
}
.filter-panel label {
    display: block;
    margin-bottom: 6px;
    color: #1f3b63;
}
.filter-row {
    display: flex;
    gap: 10px;
    align-items: flex-start;
    flex-wrap: wrap;
}
#botFilter {
    min-width: 320px;
    max-width: 100%%;
    flex: 1 1 320px;
    min-height: 140px;
    border: 1px solid #9eb7d8;
    border-radius: 6px;
    padding: 6px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
}
.search-combo {
    flex: 1 1 360px;
    min-width: 320px;
    max-width: 100%%;
    position: relative;
}
#actionTypeSearch {
    width: 100%%;
    border: 2px solid #9eb7d8;
    border-radius: 8px;
    padding: 10px 12px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    outline: none;
}
#actionTypeSearch:focus {
    border-color: #0073e6;
    box-shadow: 0 0 0 2px rgba(0, 115, 230, 0.15);
}
.search-results {
    margin-top: 6px;
    max-height: 220px;
    overflow: auto;
    border: 1px solid #9eb7d8;
    border-radius: 8px;
    background: #fff;
}
.search-item {
    display: block;
    width: 100%%;
    text-align: right;
    border: 0;
    border-bottom: 1px dashed #e2e8f0;
    background: #fff;
    padding: 8px 10px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
}
.search-item:hover { background: #eef5ff; }
.search-item.selected {
    background: #dbeafe;
    color: #1e3a8a;
}
.search-empty {
    padding: 12px;
    text-align: center;
    color: #666;
    font-size: 11px;
}
.search-hint {
    padding: 8px 10px;
    font-size: 11px;
    color: #666;
    background: #f8fafc;
    border-bottom: 1px dashed #e2e8f0;
}
.selected-chips {
    margin-top: 8px;
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    min-height: 28px;
}
.chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: #e8f1ff;
    color: #1f3b63;
    border: 1px solid #9eb7d8;
    border-radius: 999px;
    padding: 4px 8px 4px 4px;
    font-size: 11px;
}
.chip button {
    border: 0;
    background: #0073e6;
    color: #fff;
    width: 18px;
    height: 18px;
    border-radius: 50%%;
    cursor: pointer;
    font-size: 12px;
    line-height: 1;
    padding: 0;
}
.chip-hint {
    font-size: 11px;
    color: #666;
}
.filter-actions {
    display: flex;
    flex-direction: column;
    gap: 8px;
}
.btn-filter {
    background: #0073e6;
    color: #fff;
    border: 2px solid #005bb5;
    border-radius: 8px;
    padding: 8px 14px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
    white-space: nowrap;
}
.btn-filter.secondary {
    background: #fff;
    color: #0073e6;
}
.btn-filter:hover { filter: brightness(0.95); }
.filter-hint {
    margin-top: 8px;
    font-size: 11px;
    color: #555;
}
#filterStatus {
    font-size: 11px;
    color: #1f3b63;
    margin-top: 6px;
}
.btn-fullscreen {
    background: #0073e6;
    color: #fff;
    border: 2px solid #005bb5;
    border-radius: 8px;
    padding: 8px 16px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
}
.btn-fullscreen:hover { background: #005bb5; }
.report-header {
    background-color: #D2E0FB;
    text-align: center;
    border: 1px dotted #000;
    border-radius: 10px;
    padding: 12px 10px 16px;
    margin-bottom: 12px;
}
.report-header p { margin: 4px 0; }
.meta-line {
    font-size: 11px;
    color: #333;
    margin-top: 8px;
}
.tab-bar {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-bottom: 10px;
}
.tab-btn {
    background: #fff;
    border: 2px solid #0073e6;
    color: #0073e6;
    border-radius: 8px;
    padding: 8px 14px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
}
.tab-btn.active {
    background: #0073e6;
    color: #fff;
}
.tab-panel { display: none; }
.tab-panel.active { display: block; }
.table-wrap {
    overflow: auto;
    max-height: 70vh;
    border: 2px solid #000;
    border-radius: 8px;
    background: #fff;
}
table {
    width: 100%%;
    border-collapse: collapse;
    text-align: center;
}
thead th {
    position: sticky;
    top: 0;
    z-index: 2;
    background-color: #0073e6;
    color: #fff;
    border: 1px dashed #000;
    padding: 10px 8px;
    font-size: 11px;
    white-space: nowrap;
}
tbody td {
    border: 1px dashed #000;
    padding: 8px;
    font-size: 11px;
    vertical-align: middle;
}
tbody tr:nth-child(even) { background-color: #eeeeee; }
tbody tr:hover { filter: brightness(0.97); }
.summary-table {
    width: 100%%;
    border-collapse: collapse;
    margin-bottom: 12px;
    border: 2px solid #000;
    border-radius: 8px;
    overflow: hidden;
}
.summary-table td {
    border: 1px dashed #000;
    padding: 10px 8px;
    text-align: center;
    font-size: 11px;
}
.summary-table .summary-head {
    background: #4472C4;
    color: #fff;
    font-size: 12px;
}
.summary-table .summary-value {
    background: #5B9BD5;
    color: #fff;
    font-size: 16px;
    font-weight: bold;
}
.mono { font-family: Consolas, monospace; }
.name-cell { text-align: right; font-weight: bold; }
.empty-row { padding: 24px !important; color: #666; }
.badge {
    display: inline-block;
    padding: 3px 8px;
    border-radius: 999px;
    font-size: 10px;
}
.badge-active { background: #c6efce; color: #006100; }
.badge-disabled { background: #ffc7ce; color: #9c0006; }
.perf-good { color: #006100; font-weight: bold; }
.perf-normal { color: #0073e6; font-weight: bold; }
.perf-warning { color: #9c6500; font-weight: bold; }
.perf-critical { color: #9c0006; font-weight: bold; }
.perf-neutral { color: #666; }
.footer {
    text-align: center;
    color: #666;
    font-size: 11px;
    margin-top: 10px;
}
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
    </div>

    <div class="filter-panel">
        <label for="actionTypeSearch">جستجو و انتخاب نوع اقدام برای آنالیز (چندتایی)</label>
        <div class="filter-row">
            <div class="search-combo">
                <input type="text" id="actionTypeSearch" placeholder="رده، جریان کار یا موضوع را تایپ کنید..." autocomplete="off" />
                <div id="actionTypeSearchResults" class="search-results"></div>
                <div id="selectedActionTypes" class="selected-chips"></div>
            </div>
            <div class="filter-actions">
                <button type="button" class="btn-filter" onclick="applyActionTypeFilter()">اعمال فیلتر</button>
                <button type="button" class="btn-filter secondary" onclick="resetActionTypeFilter()">پیش‌فرض (%s پراجرات‌ترین بات)</button>
            </div>
        </div>
        <div class="filter-hint">نوع اقدام = رده + جریان کار + موضوع. بدون انتخاب = همان روش قبلی (رتبه‌بندی بات‌ها بر اساس تعداد اجرا).</div>
        <div id="filterStatus">%s</div>
    </div>

    <div class="report-header">
        <p><strong>گزارش تحلیل بات‌ها</strong></p>
        <p>نمای کلی استفاده، بات‌های بدون اجرا و کندترین بات‌ها</p>
        <div class="meta-line" id="metaLine">
            بازه: %s روز | حداکثر ردیف: %s | فیلتر بات: %s | شامل غیرفعال: %s | زمان تولید: %s
        </div>
    </div>

    <table class="summary-table">
        <tr class="summary-head">
            <td>کل بات‌ها</td>
            <td>فعال در بازه</td>
            <td>هرگز اجرا نشده</td>
            <td>غیرفعال</td>
        </tr>
        <tr>
            <td class="summary-value" id="summaryTotal">%s</td>
            <td class="summary-value" id="summaryActive">%s</td>
            <td class="summary-value" id="summaryNever">%s</td>
            <td class="summary-value" id="summaryDisabled">%s</td>
        </tr>
    </table>

    <div class="tab-bar">
        <button type="button" class="tab-btn active" data-tab="tab-top" onclick="switchTab(this)">پراجرات‌ترین</button>
        <button type="button" class="tab-btn" data-tab="tab-slow" onclick="switchTab(this)">کندترین</button>
        <button type="button" class="tab-btn" data-tab="tab-never" onclick="switchTab(this)">بدون اجرا</button>
        <button type="button" class="tab-btn" data-tab="tab-action-types" id="tabActionTypesBtn" onclick="switchTab(this)" style="display:none;">نوع اقدام انتخاب‌شده</button>
    </div>

    <div class="tab-panel active" id="tab-top">
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ردیف</th>
                        <th>شناسه</th>
                        <th>نام بات</th>
                        <th>وضعیت</th>
                        <th>کل اجرا</th>
                        <th>اجرای بازه</th>
                        <th>میانگین زمان</th>
                        <th>آخرین اجرا</th>
                    </tr>
                </thead>
                <tbody id="topRows">%s</tbody>
            </table>
        </div>
    </div>

    <div class="tab-panel" id="tab-slow">
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ردیف</th>
                        <th>شناسه</th>
                        <th>نام بات</th>
                        <th>وضعیت</th>
                        <th>کل اجرا</th>
                        <th>اجرای بازه</th>
                        <th>میانگین زمان</th>
                        <th>آخرین اجرا</th>
                    </tr>
                </thead>
                <tbody id="slowRows">%s</tbody>
            </table>
        </div>
    </div>

    <div class="tab-panel" id="tab-never">
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ردیف</th>
                        <th>شناسه</th>
                        <th>نام بات</th>
                        <th>وضعیت</th>
                        <th>تاریخ ویرایش</th>
                    </tr>
                </thead>
                <tbody id="neverRows">%s</tbody>
            </table>
        </div>
    </div>

    <div class="tab-panel" id="tab-action-types">
        <div id="actionTypeAnalysisContent" class="table-wrap"></div>
    </div>

    <div class="footer">Teamyar Bot Analytics Report</div>
</div>

<script>
var REPORT_DATA = %s;
var selectedActionTypeMap = {};

function normalizeSearchText(text) {
    return String(text || '')
        .toLowerCase()
        .replace(/[يیى]/g, 'ی')
        .replace(/[كک]/g, 'ک')
        .replace(/\s+/g, ' ')
        .trim();
}

function formatActionTypeLabel(item) {
    var parts = [item.category || '—', item.workflow || '—'];
    if (item.topic) {
        parts.push(item.topic);
    }
    return parts.join(' | ');
}

function actionTypeMatchesQuery(item, query) {
    if (!query) {
        return true;
    }
    var haystack = normalizeSearchText(
        (item.category || '') + ' ' +
        (item.workflow || '') + ' ' +
        (item.topic || '') + ' ' +
        String(item.workflow_id || '') + ':' + String(item.topic_id || 0)
    );
    return haystack.indexOf(query) !== -1;
}

function findActionTypeById(typeId) {
    for (var i = 0; i < REPORT_DATA.actionTypes.length; i++) {
        if (String(REPORT_DATA.actionTypes[i].id) === String(typeId)) {
            return REPORT_DATA.actionTypes[i];
        }
    }
    return null;
}

function getSelectedActionTypeIds() {
    var ids = [];
    for (var key in selectedActionTypeMap) {
        if (selectedActionTypeMap.hasOwnProperty(key)) {
            ids.push(String(key));
        }
    }
    ids.sort();
    return ids;
}

function renderSelectedActionTypeChips() {
    var box = document.getElementById('selectedActionTypes');
    var ids = getSelectedActionTypeIds();
    if (!ids.length) {
        box.innerHTML = '<span class="chip-hint">هیچ نوع اقدامی انتخاب نشده — حالت پیش‌فرض فعال است</span>';
        return;
    }
    var html = [];
    for (var i = 0; i < ids.length; i++) {
        var chipId = ids[i];
        var item = selectedActionTypeMap[chipId];
        html.push(
            '<span class="chip">' +
            '<span>' + escapeHtml(formatActionTypeLabel(item)) + '</span>' +
            '<button type="button" onclick="removeActionTypeSelection(\'' + item.id + '\')">×</button>' +
            '</span>'
        );
    }
    box.innerHTML = html.join('');
}

function renderActionTypeSearchResults() {
    var input = document.getElementById('actionTypeSearch');
    var box = document.getElementById('actionTypeSearchResults');
    var query = normalizeSearchText(input.value);
    var matches = [];
    var maxResults = query ? 120 : 40;

    for (var i = 0; i < REPORT_DATA.actionTypes.length; i++) {
        var item = REPORT_DATA.actionTypes[i];
        if (actionTypeMatchesQuery(item, query)) {
            matches.push(item);
            if (matches.length >= maxResults) {
                break;
            }
        }
    }

    if (!matches.length) {
        box.innerHTML = '<div class="search-empty">نوع اقدامی یافت نشد</div>';
        return;
    }

    var html = [];
    if (!query) {
        html.push('<div class="search-hint">برای پیدا کردن سریع‌تر، رده / جریان کار / موضوع را تایپ کنید</div>');
    } else if (matches.length >= maxResults) {
        html.push('<div class="search-hint">فقط ' + maxResults + ' نتیجه اول نمایش داده شد — جستجو را دقیق‌تر کنید</div>');
    }

    for (var j = 0; j < matches.length; j++) {
        var row = matches[j];
        var isSelected = !!selectedActionTypeMap[row.id];
        var countLabel = (row.open_task_count || 0) > 0
            ? ' (' + row.open_task_count + ' اقدام باز)'
            : '';
        html.push(
            '<button type="button" class="search-item' + (isSelected ? ' selected' : '') + '" onclick="toggleActionTypeSelection(\'' + row.id + '\')">' +
            escapeHtml(formatActionTypeLabel(row)) + escapeHtml(countLabel) +
            (isSelected ? ' ✓' : '') +
            '</button>'
        );
    }
    box.innerHTML = html.join('');
}

function toggleActionTypeSelection(typeId) {
    typeId = String(typeId);
    if (selectedActionTypeMap[typeId]) {
        delete selectedActionTypeMap[typeId];
    } else {
        var item = findActionTypeById(typeId);
        if (item) {
            selectedActionTypeMap[typeId] = item;
        }
    }
    renderSelectedActionTypeChips();
    renderActionTypeSearchResults();
}

function removeActionTypeSelection(typeId) {
    delete selectedActionTypeMap[String(typeId)];
    renderSelectedActionTypeChips();
    renderActionTypeSearchResults();
}

function initSelectedActionTypesFromInput() {
    if (!REPORT_DATA.selectedActionTypes || !REPORT_DATA.selectedActionTypes.length) {
        return;
    }
    for (var i = 0; i < REPORT_DATA.selectedActionTypes.length; i++) {
        var selectedId = REPORT_DATA.selectedActionTypes[i];
        var item = findActionTypeById(selectedId);
        if (item) {
            selectedActionTypeMap[item.id] = item;
        }
    }
}

function initActionTypeSearchCombo() {
    var input = document.getElementById('actionTypeSearch');
    input.addEventListener('input', renderActionTypeSearchResults);
    input.addEventListener('focus', renderActionTypeSearchResults);
    initSelectedActionTypesFromInput();
    renderSelectedActionTypeChips();
    renderActionTypeSearchResults();
}

function escapeHtml(value) {
    if (value === null || value === undefined) return '';
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function statusBadge(disabled) {
    return disabled
        ? '<span class="badge badge-disabled">غیرفعال</span>'
        : '<span class="badge badge-active">فعال</span>';
}

function performanceClass(avg) {
    if (avg === null || avg === undefined) return 'perf-neutral';
    var sec = Math.floor(Number(avg) / 10000000);
    if (sec <= 2) return 'perf-good';
    if (sec <= 10) return 'perf-normal';
    if (sec <= 30) return 'perf-warning';
    return 'perf-critical';
}

function heatStyle(value, minValue, maxValue) {
    var v = Number(value) || 0;
    var minV = Number(minValue) || 0;
    var maxV = Number(maxValue) || 0;
    if (maxV <= minV || v <= 0) return 'background-color:#ffffff;';
    var n = (v - minV) / (maxV - minV);
    var r, g, b;
    if (n < 0.5) {
        r = Math.floor(255 * n * 2);
        g = 255;
        b = Math.floor(255 * (1 - n * 2));
    } else {
        r = 255;
        g = Math.floor(255 * (2 - n * 2));
        b = 0;
    }
    return 'background-color:rgb(' + r + ',' + g + ',' + b + ');';
}

function sortByRunCount(bots) {
    return bots.slice().sort(function(a, b) {
        if ((b.run_count || 0) === (a.run_count || 0)) {
            return (a.id || 0) - (b.id || 0);
        }
        return (b.run_count || 0) - (a.run_count || 0);
    });
}

function sortBySlowest(bots) {
    return bots.slice().sort(function(a, b) {
        if ((b.avg_running_time || 0) === (a.avg_running_time || 0)) {
            return (a.id || 0) - (b.id || 0);
        }
        return (b.avg_running_time || 0) - (a.avg_running_time || 0);
    });
}

function filterBotsBySelection(bots, selectedIds) {
    if (!selectedIds.length) {
        var defaultBots = [];
        for (var defaultIndex = 0; defaultIndex < bots.length; defaultIndex++) {
            if (REPORT_DATA.include_disabled || !bots[defaultIndex].disabled) {
                defaultBots.push(bots[defaultIndex]);
            }
        }
        return sortByRunCount(defaultBots).slice(0, REPORT_DATA.limit);
    }
    var map = {};
    for (var i = 0; i < selectedIds.length; i++) {
        var sid = selectedIds[i];
        map[sid] = true;
    }
    var filtered = [];
    for (var j = 0; j < bots.length; j++) {
        if (map[Number(bots[j].id)]) {
            filtered.push(bots[j]);
        }
    }
    return sortByRunCount(filtered);
}

function buildTopRows(bots, withHeatmap) {
    if (!bots.length) {
        return '<tr><td colspan="8" class="empty-row">داده‌ای یافت نشد</td></tr>';
    }
    var minRuns = bots[0].run_count || 0;
    var maxRuns = bots[0].run_count || 0;
    for (var i = 1; i < bots.length; i++) {
        var count = bots[i].run_count || 0;
        if (count < minRuns) minRuns = count;
        if (count > maxRuns) maxRuns = count;
    }
    var html = [];
    for (var row = 0; row < bots.length; row++) {
        var bot = bots[row];
        var runStyle = withHeatmap ? heatStyle(bot.run_count, minRuns, maxRuns) : '';
        var periodStyle = withHeatmap ? heatStyle(bot.runs_in_period, 0, maxRuns) : '';
        html.push(
            '<tr>' +
            '<td>' + (row + 1) + '</td>' +
            '<td class="mono">' + escapeHtml(bot.id) + '</td>' +
            '<td class="name-cell">' + escapeHtml(bot.name) + '</td>' +
            '<td>' + statusBadge(bot.disabled) + '</td>' +
            '<td style="' + runStyle + '"><strong>' + (bot.run_count || 0) + '</strong></td>' +
            '<td style="' + periodStyle + '">' + (bot.runs_in_period || 0) + '</td>' +
            '<td class="' + performanceClass(bot.avg_running_time) + '">' + escapeHtml(bot.avg_running_time_label || '—') + '</td>' +
            '<td>' + escapeHtml(bot.last_run || '—') + '</td>' +
            '</tr>'
        );
    }
    return html.join('');
}

function buildNeverRows(bots) {
    if (!bots.length) {
        return '<tr><td colspan="5" class="empty-row">همه بات‌ها حداقل یک‌بار اجرا شده‌اند</td></tr>';
    }
    var html = [];
    for (var i = 0; i < bots.length; i++) {
        var bot = bots[i];
        html.push(
            '<tr>' +
            '<td>' + (i + 1) + '</td>' +
            '<td class="mono">' + escapeHtml(bot.id) + '</td>' +
            '<td class="name-cell">' + escapeHtml(bot.name) + '</td>' +
            '<td>' + statusBadge(bot.disabled) + '</td>' +
            '<td>' + escapeHtml(bot.modify_date || '—') + '</td>' +
            '</tr>'
        );
    }
    return html.join('');
}

function computeSummary(bots) {
    var active = 0;
    var never = 0;
    var disabled = 0;
    for (var i = 0; i < bots.length; i++) {
        if (bots[i].disabled) disabled++;
        if ((bots[i].run_count || 0) === 0) never++;
        if ((bots[i].runs_in_period || 0) > 0) active++;
    }
    return {
        total: bots.length,
        active: active,
        never: never,
        disabled: disabled
    };
}

function updateSummary(bots) {
    var summary = computeSummary(bots);
    document.getElementById('summaryTotal').innerText = summary.total;
    document.getElementById('summaryActive').innerText = summary.active;
    document.getElementById('summaryNever').innerText = summary.never;
    document.getElementById('summaryDisabled').innerText = summary.disabled;
}

function updateFilterStatus(selectedIds, visibleCount) {
    var status = document.getElementById('filterStatus');
    if (!selectedIds.length) {
        status.innerText = 'حالت پیش‌فرض: ' + REPORT_DATA.limit + ' بات پراجرات‌ترین';
        return;
    }
    status.innerText = 'فیلتر فعال: ' + selectedIds.length + ' نوع اقدام انتخاب‌شده | نمایش: ' + visibleCount + ' نوع';
}

function renderAnalyticsView(selectedIds) {
    var scopedBots = filterBotsBySelection(REPORT_DATA.bots, selectedIds);
    var slowPool = [];
    for (var i = 0; i < scopedBots.length; i++) {
        if ((scopedBots[i].runs_in_period || 0) > 0 && scopedBots[i].avg_running_time) {
            slowPool.push(scopedBots[i]);
        }
    }
    var neverPool = [];
    for (var j = 0; j < scopedBots.length; j++) {
        if ((scopedBots[j].run_count || 0) === 0) {
            neverPool.push(scopedBots[j]);
        }
    }

    document.getElementById('topRows').innerHTML = buildTopRows(scopedBots, true);
    document.getElementById('slowRows').innerHTML = buildTopRows(sortBySlowest(slowPool).slice(0, REPORT_DATA.limit), false);
    document.getElementById('neverRows').innerHTML = buildNeverRows(neverPool.slice(0, REPORT_DATA.limit));
    updateSummary(scopedBots);
    updateFilterStatus(selectedIds, scopedBots.length);
}

function buildActionTypeAnalysis(selectedIds) {
    if (!selectedIds.length) {
        return '';
    }

    var html = [];
    for (var i = 0; i < selectedIds.length; i++) {
        var typeId = String(selectedIds[i]);
        var details = REPORT_DATA.actionTypeDetails[typeId];
        if (!details) {
            continue;
        }

        html.push(
            '<div class="report-header">' +
            '<p><strong>' + escapeHtml(formatActionTypeLabel(details)) + '</strong></p>' +
            '<p>رده: ' + escapeHtml(details.category || '—') +
            ' | جریان کار: ' + escapeHtml(details.workflow || '—') +
            ' | موضوع: ' + escapeHtml(details.topic || '—') +
            ' | اقدامات باز: ' + (details.open_task_count || 0) + '</p>' +
            '</div>'
        );

        if (!details.tasks || !details.tasks.length) {
            html.push('<div class="search-empty">اقدام بازی برای این نوع یافت نشد</div>');
            continue;
        }

        for (var t = 0; t < details.tasks.length; t++) {
            var task = details.tasks[t];
            html.push(
                '<div class="report-header">' +
                '<p><strong>#' + escapeHtml(task.task_id) + ' | ' + escapeHtml(task.task_title) + '</strong></p>' +
                '<p>مؤلف: ' + escapeHtml(task.author_name || '—') + ' | تعداد مراحل: ' + task.steps.length + '</p>' +
                '</div>'
            );
            html.push(
                '<table><thead><tr>' +
                '<th>ردیف</th><th>مرحله</th><th>مسئول</th><th>وضعیت</th><th>تاریخ ایجاد</th><th>آخرین تغییر</th>' +
                '</tr></thead><tbody>'
            );
            for (var j = 0; j < task.steps.length; j++) {
                var step = task.steps[j];
                html.push(
                    '<tr><td>' + (j + 1) + '</td>' +
                    '<td class="name-cell">' + escapeHtml(step.step_name) + '</td>' +
                    '<td>' + escapeHtml(step.responsible_name) + '</td>' +
                    '<td>' + escapeHtml(step.status) + '</td>' +
                    '<td>' + escapeHtml(step.date_create || '—') + '</td>' +
                    '<td>' + escapeHtml(step.date_modify || '—') + '</td></tr>'
                );
            }
            html.push('</tbody></table>');
        }
    }
    return html.join('');
}

function applyActionTypeFilter() {
    var selectedIds = getSelectedActionTypeIds();
    if (!selectedIds.length) {
        resetActionTypeFilter();
        return;
    }

    document.getElementById('actionTypeAnalysisContent').innerHTML = buildActionTypeAnalysis(selectedIds);
    document.getElementById('tabActionTypesBtn').style.display = '';
    updateFilterStatus(selectedIds, selectedIds.length);
    switchTab(document.getElementById('tabActionTypesBtn'));
}

function resetActionTypeFilter() {
    selectedActionTypeMap = {};
    document.getElementById('actionTypeSearch').value = '';
    document.getElementById('actionTypeAnalysisContent').innerHTML = '';
    document.getElementById('tabActionTypesBtn').style.display = 'none';
    renderSelectedActionTypeChips();
    renderActionTypeSearchResults();
    renderAnalyticsView([]);
    switchTab(document.querySelector('[data-tab="tab-top"]'));
}

function switchTab(btn) {
    var tabs = document.getElementsByClassName('tab-btn');
    for (var i = 0; i < tabs.length; i++) {
        tabs[i].classList.remove('active');
    }
    btn.classList.add('active');

    var panels = document.getElementsByClassName('tab-panel');
    for (var j = 0; j < panels.length; j++) {
        panels[j].classList.remove('active');
    }
    document.getElementById(btn.getAttribute('data-tab')).classList.add('active');
}

function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;

    if (!isFull) {
        if (root.requestFullscreen) {
            root.requestFullscreen();
        } else if (root.webkitRequestFullscreen) {
            root.webkitRequestFullscreen();
        } else if (root.msRequestFullscreen) {
            root.msRequestFullscreen();
        }
        btn.innerText = 'خروج از تمام صفحه';
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
        } else if (document.msExitFullscreen) {
            document.msExitFullscreen();
        }
        btn.innerText = 'تمام صفحه';
    }
}

document.addEventListener('fullscreenchange', syncFullscreenButton);
document.addEventListener('webkitfullscreenchange', syncFullscreenButton);

function syncFullscreenButton() {
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    btn.innerText = isFull ? 'خروج از تمام صفحه' : 'تمام صفحه';
}

document.addEventListener('DOMContentLoaded', function() {
    initActionTypeSearchCombo();
    if (REPORT_DATA.selectedActionTypes && REPORT_DATA.selectedActionTypes.length) {
        applyActionTypeFilter();
    } else if (REPORT_DATA.selectedBots && REPORT_DATA.selectedBots.length) {
        renderAnalyticsView(REPORT_DATA.selectedBots);
    } else {
        updateFilterStatus([], Math.min(REPORT_DATA.limit, REPORT_DATA.bots.length));
    }
});
</script>
</body>
</html>
]],
    limit,
    selection_label,
    days,
    display_limit,
    selection_label,
    include_disabled_label,
    generated_at,
    fmt_num(#analytics_bots),
    fmt_num(active_in_period),
    fmt_num(never_run_count),
    fmt_num(disabled_count),
    top_rows_html,
    slowest_rows_html,
    never_run_rows_html,
    report_data_json
)

teamyar.write_result(html)
