-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/08 12:05
--
-- بات زندهٔ 294 «Bot Higher Profit Dealer» (run/2/m_higher_profit) — نام قدیمی‌اش مانده ولی
-- محتوایش ویجت «تردد دورکاری امروز» است (RES-محور: ctype=3 → JSON دادهٔ امروز، در غیر این
-- صورت → قالب ویجت). پیوست‌ها (main.js / main.css / Persian.js / English.js) روی خود بات
-- زنده‌اند و در این ریپو نیستند. قرارداد خروجی JSON (کلیدها و شکل data/last_act = «ردیف اول»
-- نتیجهٔ کوئری) و شناسهٔ قالب res_bot عمداً دست‌نخورده مانده تا main.js موجود بدون تغییر کار کند.

local TZ_OFFSET_TICKS = 126000000000 -- ‏+3:30؛ زمان‌های درون‌روزی HR سه‌ساعت‌ونیم عقب‌تر از زمان محلی ذخیره می‌شوند (تاییدشدهٔ زنده روی بات 624)

local input = teamyar.get_input()
local ctype = tonumber(input and input.type)
local uinfo = teamyar.get_user_info()
local user_id = tonumber(uinfo and uinfo.id) or 0

local now = time.current()
local year = time.get_year(now)
local month = time.get_month(now)
local day = time.get_day(now)
local hour = time.get_hour(now)
local min = time.get_minute(now)
local sec = time.get_second(now)

local currentdate_time = time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month ..
    [[,"day":]] .. day .. [[,"hour":]] .. hour .. [[,"minute":]] .. min .. [[,"second":]] .. sec .. [[}]])
local day_start = time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month ..
    [[,"day":]] .. day .. [[,"hour":0,"minute":0,"second":0}]])

local function get_query_first_row(query, query_params)
    db.use_db("0000000")
    db.query({ query = query, params = query_params })
    local rows = db.query_fetch()
    db.query_free()
    return rows and rows[1] or nil
end

local function shifted_time_sql(column)
    return "CASE WHEN COALESCE(" .. column .. ", 0) = 0 THEN 0 ELSE " ..
        column .. " + " .. TZ_OFFSET_TICKS .. " END"
end

local function write_today_telework_json()
    local telework_query = [[
SELECT COALESCE(
    JSON_ARRAYAGG(JSON_OBJECT('personnel_id', personnel_id, 'timef', timef, 'timet', timet)),
    JSON_ARRAY()
) AS result
FROM (
    SELECT
        p.PERSONNEL_ID AS personnel_id,
        ]] .. shifted_time_sql("e.TIME_FROM") .. [[ AS timef,
        ]] .. shifted_time_sql("e.TIME_TO") .. [[ AS timet
    FROM hr_personnels p
    INNER JOIN hr_ext_time e ON e.PERSONNEL_ID = p.PERSONNEL_ID
    WHERE e.not_telework = 0
      AND p.PROFILE_ID = ?
      AND e.EXT_DATE = ?
    ORDER BY e.TIME_FROM
) tmp
]]
    local session_query =
        "SELECT COALESCE(MAX(s.last_activity), 0) AS last_activity FROM admin_view_session s WHERE s.user_id = ?"

    local telework_row = get_query_first_row(telework_query, { user_id, day_start })
    local session_row = get_query_first_row(session_query, { user_id })

    local listdata = {
        data = telework_row,
        cur_date = currentdate_time,
        last_act = session_row
    }
    teamyar.write_result(json.encode(listdata))
end

local function write_widget_template()
    math.randomseed((currentdate_time % 2147483647) + user_id)
    local random = math.random(1, 1000000)
    local script = teamyar.get_attachment("main.js")
    local css = teamyar.get_attachment("main.css")
    local str_lang
    if uinfo.lang_id == 4 then
        str_lang = teamyar.get_attachment("Persian.js")
    else
        str_lang = teamyar.get_attachment("English.js")
    end
    local template = teamyar.run_command("2/res_bot", {
        id = "most_higher_dealer_profit_chart",
        tpl_name = "html",
        body = "<div id=\\'hdp_holder_body_html_" .. random .. "\\'></div>",
        script = [[
      (function(){
          ]] .. str_lang .. [[
      var holder_id = '#hdp_holder_body_html_]] .. random .. [[';
    var random_id = ]] .. random .. [[;
      ]] .. script .. [[
    })();
      ]],
        css = css
    })
    teamyar.write_result(template)
end

if ctype == 3 then
    local ok, err = pcall(write_today_telework_json)
    if not ok then
        teamyar.write_log("m_higher_profit telework widget error: " .. tostring(err))
        teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت اطلاعات تردد دورکاری امروز" }))
    end
else
    local ok, err = pcall(write_widget_template)
    if not ok then
        teamyar.write_log("m_higher_profit widget template error: " .. tostring(err))
        teamyar.write_result("<div>خطا در بارگذاری ویجت تردد دورکاری</div>")
    end
end
