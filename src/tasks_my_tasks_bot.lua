-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/08 11:50
-- بات «کارهای من» (My Tasks) — ویجت RES-پایه (2/res_bot، قالب table)
-- پیوست‌ها: query.txt (کوئری با {box_clause}/{order} و ۴ پارامتر user_id,user_id,from,count)،
-- main.js (رندر سلول‌ها + کمبوی بازهٔ زمانی)، main.css (استایل — scope زیر .bot_holder[id^="tasks_my_tasks"])

local input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(tonumber(user_info.id) or 0);
local cur_time = time.current();

local DEFAULT_PAGE_SIZE = 10;
local MAX_PAGE_SIZE = 100;
local WEEK_DAYS = 7;

-- ورودی پلتفرم می‌تواند به‌جای مقدارِ غایب، userdata از نوع NULL بدهد؛
-- مقایسهٔ مستقیم با nil یا tonumber مستقیم روی آن قابل اتکا نیست.
local function safe_number(value)
    local value_type = type(value);
    if value_type == "number" then return value end
    if value_type == "string" then return tonumber(value) end
    return nil;
end

-- اعداد FILETIME از دقت %.14g پیش‌فرض الحاق رشته بزرگ‌ترند و به‌صورت علمی
-- (1.34e+17) در SQL می‌نشینند؛ همیشه با %.0f درج شوند.
local function sql_int(value)
    return string.format("%.0f", value);
end

-- شروع امروز به وقت محلی کاربر (FILETIME)
local date_from = time.get_filetime([=[{"year":]=] .. math.floor(tonumber(time.get_year(cur_time)))
    .. [=[,"month":]=] .. math.floor(tonumber(time.get_month(cur_time)))
    .. [=[,"day":]=] .. math.floor(tonumber(time.get_day(cur_time)))
    .. [=[,"hour":0,"minute":0,"second":0}]=]) - user_info.timezone;
local date_to = date_from + time.day;

local function build_box_clause(data_type)
    local user_sql = sql_int(user_id);
    local box_clause = "";
    local order = [[ t.id ]];
    if data_type == 1 then
        -- تغییرات یک هفتهٔ اخیر (تا پایان امروز)
        local week_from = date_from - (WEEK_DAYS * time.day);
        box_clause = [[ AND (tts.RESPONSIBLE_ID = ]] .. user_sql ..
            [[ OR t.AUTHOR_ID = ]] .. user_sql ..
            [[) AND (t.LAST_MODIFY_DATE BETWEEN ]] .. sql_int(week_from) ..
            [[ AND ]] .. sql_int(date_to) .. [[) ]];
        order = [[ t.LAST_MODIFY_DATE ]];
    elseif data_type == 2 then
        -- ایجادشده در امروز
        box_clause = [[ AND (tts.RESPONSIBLE_ID = ]] .. user_sql ..
            [[ OR t.AUTHOR_ID = ]] .. user_sql ..
            [[) AND (tts.DATE_CREATE BETWEEN ]] .. sql_int(date_from) ..
            [[ AND ]] .. sql_int(date_to) .. [[) ]];
    elseif data_type == 3 then
        -- در حال انجام
        box_clause = [[ AND tts.RESPONSIBLE_ID = ]] .. user_sql .. [[ AND t.STATE = 2 ]];
    end
    return box_clause, order;
end

local function fetch_tasks(data_type, from, count)
    local result = { ok = true, total = 0, list = {} };
    local query = teamyar.get_attachment("query.txt");
    if query == nil or query == "" then
        error("attachment query.txt is missing or empty");
    end
    local box_clause, order = build_box_clause(data_type);
    query = string.gsub(query, "{box_clause}", box_clause);
    query = string.gsub(query, "{order}", order);

    db.query({ query = query, params = { user_id, user_id, from, count } });
    while true do
        -- جدول تازه برای هر ردیف: ستون NULL نمی‌تواند مقدار ردیف قبلی را نگه دارد
        local record = {};
        if not db.query_fetch(record) then break end
        local title = string.gsub(tostring(record[2] or ""), '"', "");
        table.insert(result.list, {
            id = record[1] or 0,
            title = title,
            progress = record[3] or 0,
            responsibles = record[4] or ""
        });
        result.total = record[5] or result.total;
    end
    db.query_free();
    return result;
end

local function get_query_response(data, from, count)
    local data_type = math.floor(safe_number(data.data_type) or 0);
    local ok, result = pcall(fetch_tasks, data_type, from, count);
    if not ok then
        teamyar.write_log("tasks_my_tasks error: " .. tostring(result));
        pcall(db.query_free);
        return { ok = false, total = 0, list = {}, error = "خطا در دریافت فهرست کارها" };
    end
    return result;
end

local function render_template()
    -- شناسهٔ مشتق از زمان: math.random بدون seed در هر اجرا دنبالهٔ یکسان می‌دهد
    -- و دو نمونهٔ هم‌زمانِ ویجت روی یک صفحه دچار تداخل id می‌شوند.
    local widget_id = math.floor(cur_time % 899999) + 100000;
    local script = teamyar.get_attachment("main.js");
    local css = teamyar.get_attachment("main.css");
    local template = teamyar.run_command("2/res_bot", {
        id = "tasks_my_tasks",
        tpl_name = "table",
        title = "MY_TASKS",
        path = "2/tasks_my_tasks",
        lang = 1,
        data = [[{header:['TITLE','PROGRESS', 'RESPONSIBLES']} ]],
        generatetd = [[
            (row)=>{  return ty__main.generatedTdMyTask(row) }
        ]],
        ajax = [[{url:'bot/run/2/tasks_my_tasks',
            data:()=>{
                var holder_id = ']] .. widget_id .. [[';
                var date_type=$.Teamyar.input.combobox.get('#task_date_combo_'+holder_id,'value');
                return {
                    type:4,
                    data_type: date_type
                }
            }
        }]],
        script = [[
          (function(){
            var holder_id = ']] .. widget_id .. [[';
            ]] .. script .. [[;
            })();
        ]],
        header = "<div id=\\'holder_header_task_" .. widget_id .. "\\'></div>",
        css = css
    });
    teamyar.write_result(template);
end

local req_type = safe_number(input.type);
if req_type == nil then
    render_template();
elseif req_type == 1 then
    if input.data ~= nil and type(input.data) ~= "userdata" then
        teamyar.set_data("data", input.data);
    end
elseif req_type == 4 then
    local data = input;
    if type(input.data) == "table" then
        data = input.data;
    end
    local from = math.floor(safe_number(input.from) or 0);
    if from < 0 then from = 0 end
    local count = math.floor(safe_number(input.count) or DEFAULT_PAGE_SIZE);
    if count < 1 then count = DEFAULT_PAGE_SIZE end
    if count > MAX_PAGE_SIZE then count = MAX_PAGE_SIZE end
    teamyar.write_result(json.encode(get_query_response(data, from, count)));
end
