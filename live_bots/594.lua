-- =====================================================================
--  مرکز فرماندهی باتی  |  Bot Command Center
--  A single-file HTML dashboard for the TeamYar Bot module.
--
--  Everything is rendered server-side into one self-contained page:
--  no external fonts, no CDN, no second round-trip. All data is read
--  once from BOT_* tables and embedded as JSON for the client to
--  search, filter, sort and chart instantly.
--
--  result_type must be 1 (HTML).
-- =====================================================================

teamyar.set_http_header("Content-Type", "text/html; charset=utf-8", true)
teamyar.set_http_status(200, "OK")

-- ---------------------------------------------------------------- time
local FT_EPOCH  = 116444736000000000      -- 1970-01-01 in FILETIME ticks
local DAY_T     = 864000000000            -- one day in ticks
local HOUR_T    = 36000000000
local SEC_T     = 10000000
local TZ_TICKS  = 12600 * SEC_T           -- Asia/Tehran, +03:30
local WINDOW    = 30                      -- days of history to load
-- How many bots the page actually renders. The KPI cards always report the
-- true inventory size; this only caps the table/cards/tree. Ordering puts
-- recently-used bots first, so nothing the 30-day panels talk about is cut.
-- Hard ceiling is teamyar.query's 2000-row limit — past that it errors.
local MAX_BOTS  = 600

local JMONTH = { "فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
                 "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند" }
local WDAY   = { [0] = "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه", "شنبه" }

-- FILETIME is UTC; shift before formatting so the user sees Tehran time.
local function shamsi(ft)
  if type(ft) ~= "number" or ft <= 0 then return nil end
  local ok, s = pcall(time.get_shamsi_str, ft + TZ_TICKS)
  if not ok or type(s) ~= "string" then return nil end
  return s
end

-- "1405.05.18 14:05:09" -> y, m, d, "14:05"
local function jsplit(s)
  if type(s) ~= "string" then return nil end
  local y, m, d, hh, mm = s:match("^(%d+)%.(%d+)%.(%d+) (%d+):(%d+):%d+$")
  if not y then return nil end
  return tonumber(y), tonumber(m), tonumber(d), hh .. ":" .. mm
end

local function date_label(ft)                 -- "۱۸ مرداد ۱۴۰۵" style, latin digits
  local y, m, d = jsplit(shamsi(ft))
  if not y then return "" end
  return d .. " " .. (JMONTH[m] or m) .. " " .. y
end

local function short_label(ft)                -- "18 مرداد"
  local _, m, d = jsplit(shamsi(ft))
  if not d then return "" end
  return d .. " " .. (JMONTH[m] or m)
end

local function clock_label(ft)                -- "14:05"
  local _, _, _, hm = jsplit(shamsi(ft))
  return hm or ""
end

-- noon of the local day whose index is `idx` (days since 1970 in Tehran)
local function day_ft(idx)
  return FT_EPOCH + idx * DAY_T + 43200 * SEC_T - TZ_TICKS
end

local function weekday(ft)
  local ok, w = pcall(time.get_day_of_week, ft + TZ_TICKS)
  if not ok or type(w) ~= "number" then return 0 end
  return w % 7
end

-- ---------------------------------------------------------------- query
-- A failed query must not take the page down, but it must not vanish either:
-- an empty {} here silently empties whole panels. Log the reason.
-- Note teamyar.query hard-caps at 2000 rows and *errors* past it, so every
-- LIMIT below stays at 1900.
local function q(sql, params)
  local ok, rows = pcall(teamyar.query, sql, params or {}, 2)
  if not ok or type(rows) ~= "table" then
    teamyar.write_log("bot_command_center query failed: " .. tostring(rows) ..
                      " | sql: " .. tostring(sql):sub(1, 200))
    return {}
  end
  return rows
end

local function num(v, dflt)
  if type(v) == "number" then return v end
  if type(v) == "string" then return tonumber(v) or (dflt or 0) end
  return dflt or 0
end

local function str(v)
  if type(v) == "string" then return v end
  if type(v) == "number" then return tostring(v) end
  return ""
end

-- =====================================================================
--  gather
-- =====================================================================
local function collect()
  local now       = time.current()
  local since30   = now - WINDOW * DAY_T
  local since7    = now - 7 * DAY_T
  local since24   = now - DAY_T
  local today_idx = (now - FT_EPOCH + TZ_TICKS) // DAY_T
  local first_idx = today_idx - (WINDOW - 1)

  -- --- the day axis ---------------------------------------------------
  local days, dpos = {}, {}
  for i = 0, WINDOW - 1 do
    local idx = first_idx + i
    local ft  = day_ft(idx)
    dpos[idx] = i + 1
    days[i + 1] = {
      lbl  = short_label(ft),
      full = (WDAY[weekday(ft)] or "") .. " · " .. date_label(ft),
      runs = 0,
      errs = 0,
    }
  end

  -- --- sections & categories ------------------------------------------
  local secs = q([[SELECT ID AS id, REF_ID AS ref, NAME AS name, SORT_ID AS sort
                   FROM BOT_SECTION ORDER BY REF_ID, SORT_ID LIMIT 400]])

  -- --- inventory totals, over EVERY bot, independent of MAX_BOTS ---------
  local totals = q([[SELECT CAST(COUNT(*) AS SIGNED) AS total,
                       CAST(SUM(CASE WHEN c.disabled=1 THEN 1 ELSE 0 END) AS SIGNED) AS disabled,
                       CAST(SUM(CASE WHEN c.public_access=1 THEN 1 ELSE 0 END) AS SIGNED) AS pub,
                       CAST(SUM(CASE WHEN c.PERIOD_TIME>0 THEN 1 ELSE 0 END) AS SIGNED) AS timer,
                       CAST(SUM(CASE WHEN c.show_in_widget=1 THEN 1 ELSE 0 END) AS SIGNED) AS widget,
                       CAST(SUM(CASE WHEN c.show_in_portal_menu=1 THEN 1 ELSE 0 END) AS SIGNED) AS portal,
                       CAST(SUM(CASE WHEN c.RESULT_TYPE=1 THEN 1 ELSE 0 END) AS SIGNED) AS html,
                       CAST(SUM(CASE WHEN c.async_run=1 THEN 1 ELSE 0 END) AS SIGNED) AS async,
                       CAST(SUM(CASE WHEN c.cache_time>0 THEN 1 ELSE 0 END) AS SIGNED) AS cached,
                       CAST(IFNULL(SUM(r.RUN_COUNT),0) AS SIGNED) AS alltime
                     FROM BOT_COMMAND c
                     LEFT JOIN BOT_COMMAND_RUN r ON r.COMMAND_ID = c.ID LIMIT 1]])

  -- --- the bots --------------------------------------------------------
  local raw = q([[SELECT c.ID AS id, c.NAME AS name, c.run_path AS path,
                         LEFT(c.DESCRIPTION,240) AS descr, c.disabled AS disabled,
                         c.public_access AS pub, c.RESULT_TYPE AS rtype,
                         c.PERIOD_TIME AS ptime, c.PERIOD_DAY AS pday,
                         c.MODIFY_DATE AS modt, c.max_version AS maxver,
                         c.show_in_widget AS widget, c.show_in_portal_menu AS portal,
                         c.async_run AS async, c.cache_time AS cache,
                         c.max_execute_time AS maxexec, c.icon AS icon,
                         c.color AS color, c.db_prefix AS dbp,
                         c.MODIFIER AS creator, c.src_domain AS srcdom,
                         cc.CAT_ID AS cat_id, s.NAME AS cat, s.REF_ID AS sec_id,
                         p.NAME AS sec, r.RUN_COUNT AS total_runs
                  FROM BOT_COMMAND c
                  LEFT JOIN BOT_COMMAND_CATEGORIES cc
                         ON cc.COMMAND_ID = c.ID AND cc.IS_DEFAULT = 1
                  LEFT JOIN BOT_SECTION s ON s.ID = cc.CAT_ID
                  LEFT JOIN BOT_SECTION p ON p.ID = s.REF_ID
                  LEFT JOIN BOT_COMMAND_RUN r ON r.COMMAND_ID = c.ID
                  LEFT JOIN (SELECT command_id, COUNT(*) AS n FROM BOT_HISTORY
                             WHERE DATE_CREATE >= ? GROUP BY command_id) h
                         ON h.command_id = c.ID
                  ORDER BY IFNULL(h.n,0) DESC, IFNULL(r.RUN_COUNT,0) DESC,
                           c.ID DESC
                  LIMIT ]] .. MAX_BOTS, { since30 })

  -- --- 30-day aggregates per bot ---------------------------------------
  local stats = q([[SELECT command_id AS id,
                      CAST(SUM(CASE WHEN CONTENT='The command was run.' THEN 1 ELSE 0 END) AS SIGNED) AS runs,
                      CAST(SUM(CASE WHEN CONTENT LIKE 'Error%' THEN 1 ELSE 0 END) AS SIGNED) AS errs,
                      CAST(SUM(CASE WHEN DATE_CREATE >= ? AND CONTENT='The command was run.' THEN 1 ELSE 0 END) AS SIGNED) AS runs24,
                      CAST(SUM(CASE WHEN DATE_CREATE >= ? AND CONTENT LIKE 'Error%' THEN 1 ELSE 0 END) AS SIGNED) AS errs24,
                      MAX(DATE_CREATE) AS last_seen,
                      CAST(ROUND(AVG(CASE WHEN CONTENT='The command was run.' THEN running_time ELSE NULL END)/10000) AS SIGNED) AS avg_ms,
                      CAST(ROUND(MAX(running_time)/10000) AS SIGNED) AS max_ms
                    FROM BOT_HISTORY WHERE DATE_CREATE >= ?
                    GROUP BY command_id LIMIT 1900]],
                  { since24, since24, since30 })

  -- --- per bot, per day -------------------------------------------------
  local daily = q([[SELECT command_id AS id,
                      CAST(FLOOR((DATE_CREATE - 116444736000000000 + 126000000000)/864000000000) AS SIGNED) AS d,
                      CAST(SUM(CASE WHEN CONTENT='The command was run.' THEN 1 ELSE 0 END) AS SIGNED) AS runs,
                      CAST(SUM(CASE WHEN CONTENT LIKE 'Error%' THEN 1 ELSE 0 END) AS SIGNED) AS errs
                    FROM BOT_HISTORY WHERE DATE_CREATE >= ?
                    GROUP BY command_id, d LIMIT 1900]], { since30 })

  -- --- feed ------------------------------------------------------------
  local events = q([[SELECT ID AS id, command_id AS bid, run_type AS rt,
                       DATE_CREATE AS ts, running_time AS rtm,
                       CASE WHEN CONTENT LIKE 'Error%' THEN 1 ELSE 0 END AS iserr,
                       LEFT(CONTENT,200) AS msg
                     FROM BOT_HISTORY
                     WHERE CONTENT = 'The command was run.' OR CONTENT LIKE 'Error%'
                     ORDER BY ID DESC LIMIT 80]])

  local errors = q([[SELECT ID AS id, command_id AS bid, run_type AS rt,
                       DATE_CREATE AS ts, LEFT(CONTENT,260) AS msg
                     FROM BOT_HISTORY
                     WHERE CONTENT LIKE 'Error%' AND DATE_CREATE >= ?
                     ORDER BY ID DESC LIMIT 60]], { since30 })

  -- --- rhythm -----------------------------------------------------------
  local hourly = q([[SELECT CAST(FLOOR(((DATE_CREATE - 116444736000000000 + 126000000000) % 864000000000)/36000000000) AS SIGNED) AS h,
                       CAST(SUM(CASE WHEN CONTENT='The command was run.' THEN 1 ELSE 0 END) AS SIGNED) AS runs
                     FROM BOT_HISTORY WHERE DATE_CREATE >= ?
                     GROUP BY h ORDER BY h LIMIT 30]], { since7 })

  local rtypes = q([[SELECT run_type AS rt, CAST(COUNT(*) AS SIGNED) AS n
                     FROM BOT_HISTORY
                     WHERE DATE_CREATE >= ? AND CONTENT='The command was run.'
                     GROUP BY run_type LIMIT 20]], { since30 })

  local vers = q([[SELECT COMMAND_ID AS id, CAST(COUNT(*) AS SIGNED) AS n
                   FROM BOT_COMMAND_VERSION GROUP BY COMMAND_ID LIMIT 1900]])

  -- --- fold ------------------------------------------------------------
  local stat_by, spark_by, ver_by = {}, {}, {}

  for _, r in ipairs(stats) do stat_by[num(r.id)] = r end
  for _, r in ipairs(vers)  do ver_by[num(r.id)]  = num(r.n) end

  for _, r in ipairs(daily) do
    local slot = dpos[num(r.d)]
    if slot then
      local id = num(r.id)
      local s  = spark_by[id]
      if not s then
        s = { runs = {}, errs = {} }
        for i = 1, WINDOW do s.runs[i] = 0; s.errs[i] = 0 end
        spark_by[id] = s
      end
      s.runs[slot] = s.runs[slot] + num(r.runs)
      s.errs[slot] = s.errs[slot] + num(r.errs)
      days[slot].runs = days[slot].runs + num(r.runs)
      days[slot].errs = days[slot].errs + num(r.errs)
    end
  end

  -- --- shape the bots ----------------------------------------------------
  local bots = {}
  local kpi  = { total = 0, active = 0, disabled = 0, pub = 0, timer = 0,
                 widget = 0, portal = 0, html = 0, async = 0, cached = 0,
                 idle = 0, failing = 0, runs30 = 0, errs30 = 0,
                 runs24 = 0, errs24 = 0, ms_sum = 0, ms_n = 0, alltime = 0 }

  for _, r in ipairs(raw) do
    local id = num(r.id)
    local st = stat_by[id] or {}
    local sp = spark_by[id]

    local runs30 = num(st.runs)
    local errs30 = num(st.errs)
    local last   = num(st.last_seen)

    local b = {
      id      = id,
      name    = str(r.name),
      path    = str(r.path),
      descr   = str(r.descr),
      cat     = str(r.cat),
      sec     = str(r.sec),
      catId   = num(r.cat_id),
      secId   = num(r.sec_id),
      off     = num(r.disabled) == 1,
      pub     = num(r.pub) == 1,
      html    = num(r.rtype) == 1,
      timer   = num(r.ptime) > 0,
      widget  = num(r.widget) == 1,
      portal  = num(r.portal) == 1,
      async   = num(r.async) == 1,
      cache   = num(r.cache),
      maxexec = num(r.maxexec),
      dbp     = str(r.dbp),
      creator = str(r.creator),
      srcdom  = str(r.srcdom),
      ver     = ver_by[id] or 0,
      total   = num(r.total_runs),
      runs    = runs30,
      errs    = errs30,
      runs24  = num(st.runs24),
      errs24  = num(st.errs24),
      avg     = num(st.avg_ms),
      max     = num(st.max_ms),
      mod     = date_label(num(r.modt)),
      modAgo  = num(r.modt) > 0 and ((now - num(r.modt)) // SEC_T) or -1,
      last    = last > 0 and (date_label(last) .. " · " .. clock_label(last)) or "",
      lastAgo = last > 0 and ((now - last) // SEC_T) or -1,
      spark   = sp and sp.runs or nil,
      espark  = sp and sp.errs or nil,
    }

    kpi.total   = kpi.total + 1
    kpi.runs30  = kpi.runs30 + runs30
    kpi.errs30  = kpi.errs30 + errs30
    kpi.runs24  = kpi.runs24 + b.runs24
    kpi.errs24  = kpi.errs24 + b.errs24
    kpi.alltime = kpi.alltime + b.total
    if b.off then kpi.disabled = kpi.disabled + 1 else kpi.active = kpi.active + 1 end
    if b.pub    then kpi.pub    = kpi.pub + 1 end
    if b.timer  then kpi.timer  = kpi.timer + 1 end
    if b.widget then kpi.widget = kpi.widget + 1 end
    if b.portal then kpi.portal = kpi.portal + 1 end
    if b.html   then kpi.html   = kpi.html + 1 end
    if b.async  then kpi.async  = kpi.async + 1 end
    if b.cache > 0 then kpi.cached = kpi.cached + 1 end
    if runs30 == 0 then kpi.idle = kpi.idle + 1 end
    if errs30 > 0  then kpi.failing = kpi.failing + 1 end
    if b.avg > 0 and runs30 > 0 then
      kpi.ms_sum = kpi.ms_sum + b.avg * runs30
      kpi.ms_n   = kpi.ms_n + runs30
    end

    bots[#bots + 1] = b
  end

  -- The loop above only saw the MAX_BOTS rows we render. Replace every count
  -- that describes the inventory with the real figure, so the cards never
  -- report the size of the page instead of the size of the installation.
  kpi.shown = #bots
  local t = totals[1]
  if t then
    local busy   = kpi.shown - kpi.idle      -- bots with 30-day activity
    kpi.total    = num(t.total)
    kpi.disabled = num(t.disabled)
    kpi.active   = kpi.total - kpi.disabled
    kpi.pub      = num(t.pub)
    kpi.timer    = num(t.timer)
    kpi.widget   = num(t.widget)
    kpi.portal   = num(t.portal)
    kpi.html     = num(t.html)
    kpi.async    = num(t.async)
    kpi.cached   = num(t.cached)
    kpi.alltime  = num(t.alltime)
    kpi.idle     = kpi.total - busy
  end

  -- --- feed rows ----------------------------------------------------------
  local feed = {}
  for _, r in ipairs(events) do
    local ts = num(r.ts)
    feed[#feed + 1] = {
      bid = num(r.bid),
      rt  = num(r.rt),
      err = num(r.iserr) == 1,
      ms  = num(r.rtm) // 10000,
      t   = clock_label(ts),
      d   = short_label(ts),
      ago = ts > 0 and ((now - ts) // SEC_T) or -1,
      msg = num(r.iserr) == 1 and str(r.msg) or "",
    }
  end

  local errlist = {}
  for _, r in ipairs(errors) do
    local ts = num(r.ts)
    errlist[#errlist + 1] = {
      bid = num(r.bid),
      rt  = num(r.rt),
      t   = clock_label(ts),
      d   = short_label(ts),
      ago = ts > 0 and ((now - ts) // SEC_T) or -1,
      msg = str(r.msg),
    }
  end

  local hours = {}
  for i = 1, 24 do hours[i] = 0 end
  for _, r in ipairs(hourly) do
    local h = num(r.h)
    if h >= 0 and h <= 23 then hours[h + 1] = num(r.runs) end
  end

  local kinds = {}
  for _, r in ipairs(rtypes) do
    kinds[#kinds + 1] = { rt = num(r.rt), n = num(r.n) }
  end

  local sections = {}
  for _, r in ipairs(secs) do
    sections[#sections + 1] = { id = num(r.id), ref = num(r.ref), name = str(r.name) }
  end

  kpi.avg = kpi.ms_n > 0 and (kpi.ms_sum // kpi.ms_n) or 0
  kpi.ms_sum, kpi.ms_n = nil, nil

  -- --- who can reach which bot -------------------------------------------
  -- Mirrors CBotManager::checkPermCommand: a user reaches a bot if they are a
  -- module admin, or belong to a subject holding a grant on the bot itself
  -- (TYPE=10) or on ANY category the bot sits in (TYPE=2). The grant subject is
  -- a group id; individual people carry a self-membership row in
  -- PROFILE_GROUP_MEMBER, so one join resolves both. PERM is a bitmask of
  -- BOT_ROLE_SETTING ids, not of the detailed flags — each role expands to its
  -- ROLE_FLAGS. public_access and per-bot subsystem grants are separate paths.
  local SUBJECTS_SQL = [[SELECT DISTINCT USER_ID FROM BOT_TY_PERMISSION WHERE TYPE IN (2,10)
                         UNION
                         SELECT DISTINCT USER_ID FROM ADMIN_TY_PERMISSION
                          WHERE TYPE=1 AND ID=26 AND (PERM & 1)>0]]

  local grant_rows = q([[SELECT USER_ID AS sub, ID AS obj, TYPE AS otype, PERM AS perm
                         FROM BOT_TY_PERMISSION
                         WHERE TYPE IN (2,10) AND PERM > 0 LIMIT 1900]])

  local role_rows = q([[SELECT ID AS bit, ROLE_NAME AS name, ROLE_FLAGS AS flags
                        FROM BOT_ROLE_SETTING WHERE STATUS > 0 ORDER BY ID LIMIT 64]])

  local catmap_rows = q([[SELECT COMMAND_ID AS cmd, CAT_ID AS cat
                          FROM BOT_COMMAND_CATEGORIES LIMIT 1900]])

  local admin_rows = q([[SELECT USER_ID AS sub FROM ADMIN_TY_PERMISSION
                         WHERE TYPE=1 AND ID=26 AND (PERM & 1)>0 LIMIT 300]])

  local subject_rows = q([[SELECT s.USER_ID AS id, m.FULLNAME AS name, m.TYPE AS kind
                           FROM (]] .. SUBJECTS_SQL .. [[) s
                           LEFT JOIN PROFILE_MAIN m ON m.ID = s.USER_ID LIMIT 900]])

  local member_rows = q([[SELECT g.GROUP_ID AS gid, g.USER_ID AS uid, u.FULLNAME AS name
                          FROM PROFILE_GROUP_MEMBER g
                          JOIN PROFILE_MAIN u ON u.ID = g.USER_ID AND u.TYPE = 1
                          WHERE g.GROUP_ID IN (]] .. SUBJECTS_SQL .. [[) LIMIT 1900]])

  local access = { roles = {}, subjects = {}, grants = {}, cats = {}, admins = {}, members = {} }

  for _, r in ipairs(role_rows) do
    access.roles[#access.roles + 1] =
      { bit = num(r.bit), name = str(r.name), flags = num(r.flags) }
  end
  for _, r in ipairs(subject_rows) do
    access.subjects[#access.subjects + 1] =
      { id = num(r.id), name = str(r.name), kind = num(r.kind) }   -- kind 1 = person, 2 = group
  end
  for _, r in ipairs(grant_rows) do
    access.grants[#access.grants + 1] =
      { s = num(r.sub), o = num(r.obj), t = num(r.otype), p = num(r.perm) }
  end
  for _, r in ipairs(catmap_rows) do
    access.cats[#access.cats + 1] = { c = num(r.cmd), k = num(r.cat) }
  end
  for _, r in ipairs(admin_rows) do
    access.admins[#access.admins + 1] = num(r.sub)
  end
  for _, r in ipairs(member_rows) do
    access.members[#access.members + 1] =
      { g = num(r.gid), u = num(r.uid), n = str(r.name) }
  end

  local lic = {}
  local okl, info = pcall(teamyar.get_license_info)
  if okl and type(info) == "table" then
    lic.domain = str(info.domain)
    lic.id     = str(info.id)
  end

  local me = ""
  local oku, u = pcall(teamyar.get_user_info)
  if oku and type(u) == "table" then
    me = (str(u.name) .. " " .. str(u.family)):gsub("^%s+", ""):gsub("%s+$", "")
  end

  return {
    bots     = bots,
    days     = days,
    feed     = feed,
    errors   = errlist,
    hours    = hours,
    kinds    = kinds,
    sections = sections,
    access   = access,
    kpi      = kpi,
    window   = WINDOW,
    lic      = lic,
    me       = me,
    genAt    = date_label(now) .. " · " .. clock_label(now),
    genWd    = WDAY[weekday(now)] or "",
  }
end

-- =====================================================================
--  render
-- =====================================================================
local HEAD = [==[<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>مرکز فرماندهی باتی</title>
<style>
:root{
  --bg:#070b16; --bg2:#0c1224; --panel:rgba(255,255,255,.045);
  --panel2:rgba(255,255,255,.025); --line:rgba(255,255,255,.09);
  --line2:rgba(255,255,255,.05);
  --fg:#e8edff; --fg2:#a3b0d4; --fg3:#6d7ba3;
  --brand:#7c5cff; --brand2:#22d3ee;
  --ok:#34d399; --warn:#fbbf24; --err:#fb7185; --info:#60a5fa;
  --shadow:0 18px 48px rgba(0,0,0,.45);
  --r:16px;
}
body.lite{
  --bg:#eef1f8; --bg2:#f7f9fd; --panel:#ffffff; --panel2:#fbfcff;
  --line:#dfe5f2; --line2:#eef1f8;
  --fg:#131a2e; --fg2:#4d5a7a; --fg3:#8c98b6;
  --shadow:0 12px 32px rgba(20,30,70,.10);
}
*{box-sizing:border-box;margin:0;padding:0}
html,body{background:var(--bg);}
body{
  font-family:Vazirmatn,"IRANSans","IRANYekan","Segoe UI",Tahoma,system-ui,sans-serif;
  color:var(--fg); line-height:1.65; min-height:100vh;
  -webkit-font-smoothing:antialiased;
  background:
    radial-gradient(1100px 620px at 82% -12%, rgba(124,92,255,.20), transparent 62%),
    radial-gradient(900px 520px at 6% 4%, rgba(34,211,238,.14), transparent 60%),
    var(--bg);
  transition:background .35s ease,color .25s ease;
}
body.lite{
  background:
    radial-gradient(1100px 620px at 82% -12%, rgba(124,92,255,.13), transparent 62%),
    radial-gradient(900px 520px at 6% 4%, rgba(34,211,238,.12), transparent 60%),
    var(--bg);
}
.num{font-variant-numeric:tabular-nums;font-feature-settings:"tnum";direction:ltr;display:inline-block}
.mono{font-family:ui-monospace,"Cascadia Mono",Consolas,monospace;direction:ltr;unicode-bidi:embed}
.wrap{max-width:1560px;margin:0 auto;padding:18px 20px 56px;position:relative}

/* ---------- panels ---------- */
.panel{
  background:var(--panel); border:1px solid var(--line); border-radius:var(--r);
  backdrop-filter:blur(14px); -webkit-backdrop-filter:blur(14px);
}
.ph{display:flex;align-items:center;gap:10px;padding:13px 16px;border-bottom:1px solid var(--line2)}
.ph h2{font-size:14px;font-weight:700;letter-spacing:.1px}
.ph .sub{font-size:11.5px;color:var(--fg3);font-weight:500}
.ph .grow{flex:1}

/* ---------- topbar ---------- */
.top{display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin-bottom:18px}
.brand{display:flex;align-items:center;gap:12px}
.orb{
  width:42px;height:42px;border-radius:13px;position:relative;flex:none;
  background:linear-gradient(140deg,var(--brand),var(--brand2));
  box-shadow:0 8px 26px rgba(124,92,255,.42);
  display:grid;place-items:center;
}
.orb::after{
  content:"";position:absolute;inset:-5px;border-radius:17px;
  border:1.5px solid rgba(124,92,255,.42);animation:ping 2.6s ease-out infinite;
}
@keyframes ping{0%{transform:scale(.9);opacity:.9}70%{transform:scale(1.18);opacity:0}100%{opacity:0}}
.orb svg{width:22px;height:22px}
.brand h1{font-size:19px;font-weight:800;letter-spacing:-.2px}
.brand .meta{font-size:11.5px;color:var(--fg3)}
.top .grow{flex:1}
.tbtn{
  display:inline-flex;align-items:center;gap:7px;height:36px;padding:0 13px;
  border-radius:11px;border:1px solid var(--line);background:var(--panel);
  color:var(--fg2);font:inherit;font-size:12.5px;font-weight:600;cursor:pointer;
  transition:.16s;
}
.tbtn:hover{color:var(--fg);border-color:var(--brand);transform:translateY(-1px)}
.tbtn svg{width:15px;height:15px}
.clock{
  display:flex;flex-direction:column;align-items:flex-end;line-height:1.25;
  padding:0 13px;border-radius:11px;border:1px solid var(--line);background:var(--panel);
  height:36px;justify-content:center;
}
.clock b{font-size:13px}
.clock span{font-size:10.5px;color:var(--fg3)}
a.tbtn{text-decoration:none}

/* ---------- open-in-module affordance ---------- */
.go{
  width:26px;height:26px;flex:none;display:grid;place-items:center;border-radius:8px;
  border:1px solid var(--line);background:var(--panel2);color:var(--fg3);
  text-decoration:none;opacity:0;transition:.15s
}
.go svg{width:13px;height:13px}
.go:hover{color:#fff;background:var(--brand);border-color:var(--brand)}
.card:hover .go,.ev:hover .go,.nb:hover .go,.go:focus{opacity:1}
@media(hover:none){.go{opacity:.7}}
.tbl a.tlink{color:inherit;text-decoration:none;border-bottom:1px dotted var(--line)}
.tbl a.tlink:hover{color:var(--brand2);border-bottom-color:var(--brand2)}

/* ---------- link-pattern popover ---------- */
.pop{
  position:absolute;top:52px;inset-inline-end:20px;z-index:90;width:min(340px,92vw);
  background:var(--bg2);border:1px solid var(--line);border-radius:14px;padding:14px;
  box-shadow:var(--shadow);display:none
}
.pop.on{display:block}
.pop h4{font-size:12.5px;font-weight:800;margin-bottom:4px}
.pop p{font-size:11px;color:var(--fg3);line-height:1.7;margin-bottom:9px}
.pop label{
  display:flex;align-items:center;gap:8px;padding:7px 9px;border-radius:9px;
  border:1px solid var(--line2);margin-bottom:5px;cursor:pointer;font-size:11.5px;transition:.14s
}
.pop label:hover{border-color:var(--brand)}
.pop label.on{border-color:var(--brand);background:var(--panel)}
.pop label code{font-size:10.5px;color:var(--fg2);direction:ltr}

/* ---------- kpi ---------- */
.kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:12px;margin-bottom:16px}
.kpi{
  position:relative;overflow:hidden;padding:14px 15px 12px;border-radius:var(--r);
  background:var(--panel);border:1px solid var(--line);
}
.kpi::before{content:"";position:absolute;inset:0 auto 0 0;width:3px;background:var(--c,var(--brand))}
.kpi .lbl{font-size:11.5px;color:var(--fg3);font-weight:600;display:flex;align-items:center;gap:6px}
.kpi .val{font-size:30px;font-weight:800;letter-spacing:-1px;line-height:1.2;margin-top:2px}
.kpi .sub{font-size:11px;color:var(--fg2)}
.kpi .viz{position:absolute;inset-inline-end:12px;top:12px;opacity:.95}
.dot{width:7px;height:7px;border-radius:50%;background:var(--c,var(--brand));flex:none}

/* ---------- grid rows ---------- */
.row{display:grid;gap:12px;margin-bottom:16px}
.row.a{grid-template-columns:1fr 340px}
.row.b{grid-template-columns:1fr 380px}

/* ---------- chart ---------- */
.chartbox{padding:8px 14px 14px}
.seg{display:flex;gap:4px;background:var(--panel2);border:1px solid var(--line2);border-radius:10px;padding:3px}
.seg button{
  border:0;background:transparent;color:var(--fg3);font:inherit;font-size:11.5px;font-weight:600;
  padding:4px 11px;border-radius:7px;cursor:pointer;transition:.15s
}
.seg button.on{background:var(--brand);color:#fff}
.tip{
  position:fixed;z-index:60;pointer-events:none;opacity:0;transform:translateY(4px);
  background:var(--bg2);border:1px solid var(--line);border-radius:10px;padding:8px 11px;
  font-size:11.5px;box-shadow:var(--shadow);transition:opacity .12s;min-width:130px;color:var(--fg)
}
.tip.on{opacity:1;transform:none}
.tip b{display:block;font-size:12px;margin-bottom:4px}
.tip i{font-style:normal;color:var(--fg3)}

/* ---------- command bar ---------- */
.cmd{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:12px}
.search{position:relative;flex:1;min-width:240px}
.search input{
  width:100%;height:44px;border-radius:13px;border:1px solid var(--line);
  background:var(--panel);color:var(--fg);font:inherit;font-size:14px;
  padding:0 44px 0 78px;transition:.18s;outline:none
}
.search input:focus{border-color:var(--brand);box-shadow:0 0 0 4px rgba(124,92,255,.16)}
.search .ic{position:absolute;inset-inline-start:15px;top:50%;transform:translateY(-50%);color:var(--fg3)}
.search .ic svg{width:17px;height:17px;display:block}
.search .kbd{
  position:absolute;inset-inline-end:12px;top:50%;transform:translateY(-50%);
  font-size:10.5px;color:var(--fg3);border:1px solid var(--line);border-radius:6px;
  padding:2px 7px;background:var(--panel2)
}
select.sel{
  height:44px;border-radius:13px;border:1px solid var(--line);background:var(--panel);
  color:var(--fg2);font:inherit;font-size:12.5px;font-weight:600;padding:0 12px;cursor:pointer;outline:none
}
.views{display:flex;gap:3px;background:var(--panel);border:1px solid var(--line);border-radius:13px;padding:4px;height:44px}
.views button{
  width:38px;border:0;background:transparent;border-radius:9px;color:var(--fg3);cursor:pointer;
  display:grid;place-items:center;transition:.15s
}
.views button svg{width:17px;height:17px}
.views button.on{background:var(--brand);color:#fff}
.chips{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:14px}
.chip{
  border:1px solid var(--line);background:var(--panel);color:var(--fg2);
  font:inherit;font-size:11.5px;font-weight:600;padding:6px 12px;border-radius:999px;
  cursor:pointer;transition:.15s;display:inline-flex;align-items:center;gap:6px
}
.chip:hover{border-color:var(--brand);color:var(--fg)}
.chip.on{background:var(--brand);border-color:var(--brand);color:#fff}
.chip .n{font-size:10.5px;opacity:.7}
.chip.sec.on{background:var(--brand2);border-color:var(--brand2);color:#04222b}
.count{font-size:12px;color:var(--fg3);font-weight:600;margin-inline-start:auto}

/* ---------- cards ---------- */
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(288px,1fr));gap:12px}
.card{
  position:relative;padding:14px;border-radius:var(--r);background:var(--panel);
  border:1px solid var(--line);cursor:pointer;transition:.18s;overflow:hidden
}
.card:hover{transform:translateY(-3px);border-color:var(--brand);box-shadow:var(--shadow)}
.card.off{opacity:.55}
.card .rail{position:absolute;inset:0 auto 0 0;width:3px;background:var(--h,var(--ok))}
.card h3{font-size:14px;font-weight:700;line-height:1.45;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.card .path{font-size:10.5px;color:var(--fg3);margin-top:1px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.card .spark{height:34px;margin:10px 0 8px}
.card .stats{display:flex;gap:12px;font-size:11px;color:var(--fg2)}
.card .stats b{color:var(--fg);font-weight:700}
.card .tags{display:flex;gap:4px;flex-wrap:wrap;margin-top:9px}
.tag{
  font-size:10px;font-weight:700;padding:2px 7px;border-radius:6px;
  background:var(--panel2);border:1px solid var(--line2);color:var(--fg2)
}
.tag.pub{color:#04222b;background:var(--brand2);border-color:transparent}
.tag.timer{color:#2b1a00;background:var(--warn);border-color:transparent}
.tag.err{color:#320712;background:var(--err);border-color:transparent}
.tag.off{color:#fff;background:var(--fg3);border-color:transparent}
.hpill{
  font-size:10px;font-weight:800;padding:2px 8px;border-radius:999px;flex:none;
  background:var(--panel2);color:var(--h);border:1px solid var(--line);
  background:color-mix(in srgb,var(--h) 18%,transparent);
  border-color:color-mix(in srgb,var(--h) 34%,transparent)
}
mark{background:rgba(124,92,255,.32);color:inherit;border-radius:3px;padding:0 1px}

/* ---------- table ---------- */
.tbl{width:100%;border-collapse:collapse;font-size:12.5px}
.tbl th{
  text-align:right;font-size:11px;color:var(--fg3);font-weight:700;padding:9px 12px;
  border-bottom:1px solid var(--line);cursor:pointer;white-space:nowrap;user-select:none
}
.tbl th:hover{color:var(--fg)}
.tbl td{padding:9px 12px;border-bottom:1px solid var(--line2);white-space:nowrap}
.tbl tr{cursor:pointer}
.tbl tbody tr:hover{background:var(--panel2)}
.tbl .nm{max-width:280px;overflow:hidden;text-overflow:ellipsis}

/* ---------- tree ---------- */
.tree{padding:6px 14px 14px}
.tsec{margin-top:12px}
.tsec>h3{font-size:12.5px;font-weight:800;color:var(--fg2);display:flex;align-items:center;gap:8px;margin-bottom:6px}
.tsec>h3 .ln{flex:1;height:1px;background:var(--line)}
.tcat{border:1px solid var(--line2);border-radius:12px;margin-bottom:6px;overflow:hidden;background:var(--panel2)}
.tcat>button{
  width:100%;display:flex;align-items:center;gap:10px;padding:9px 12px;border:0;
  background:transparent;color:var(--fg);font:inherit;font-size:12.5px;font-weight:600;cursor:pointer;text-align:right
}
.tcat>button:hover{background:var(--panel)}
.tcat .bar{flex:1;height:5px;border-radius:3px;background:var(--line);overflow:hidden;max-width:220px}
.tcat .bar i{display:block;height:100%;background:linear-gradient(90deg,var(--brand),var(--brand2))}
.tcat .n{font-size:11px;color:var(--fg3)}
.tcat .kids{display:none;padding:2px 12px 11px;flex-wrap:wrap;gap:6px}
.tcat.open .kids{display:flex}
.mini{
  border:1px solid var(--line);background:var(--panel);border-radius:9px;padding:5px 10px;
  font-size:11.5px;cursor:pointer;color:var(--fg2);display:inline-flex;align-items:center;gap:6px;transition:.15s
}
.mini:hover{border-color:var(--brand);color:var(--fg)}
.mini .go{width:18px;height:18px;border:0;background:transparent}
.mini .go svg{width:11px;height:11px}
.mini:hover .go{opacity:1}

/* ---------- feed ---------- */
.feed{max-height:430px;overflow:auto;padding:6px 6px 8px}
.ev{display:flex;align-items:flex-start;gap:9px;padding:7px 9px;border-radius:10px;cursor:pointer;transition:.13s}
.ev:hover{background:var(--panel2)}
.ev .bd{width:6px;height:6px;border-radius:50%;margin-top:7px;flex:none;background:var(--ok)}
.ev.bad .bd{background:var(--err)}
.ev .b{flex:1;min-width:0}
.ev .nm{font-size:12px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ev .ms{font-size:10.5px;color:var(--fg3);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ev.bad .ms{color:var(--err)}
.ev .tm{font-size:10.5px;color:var(--fg3);flex:none;text-align:left}
.newlist{padding:6px}
.nb{display:flex;align-items:center;gap:10px;padding:8px 9px;border-radius:10px;cursor:pointer;transition:.13s}
.nb:hover{background:var(--panel2)}
.nb .idx{
  width:24px;height:24px;border-radius:8px;display:grid;place-items:center;flex:none;
  font-size:11px;font-weight:800;background:var(--panel2);border:1px solid var(--line2);color:var(--fg3)
}
.nb:first-child .idx{background:linear-gradient(140deg,var(--brand),var(--brand2));color:#fff;border-color:transparent}
.nb .b{flex:1;min-width:0}
.nb .nm{font-size:12.5px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.nb .mt{font-size:10.5px;color:var(--fg3)}
.scroll::-webkit-scrollbar{width:8px;height:8px}
.scroll::-webkit-scrollbar-thumb{background:var(--line);border-radius:8px}
.scroll::-webkit-scrollbar-track{background:transparent}

/* ---------- drawer ---------- */
.scrim{position:fixed;inset:0;background:rgba(3,6,14,.62);backdrop-filter:blur(3px);opacity:0;pointer-events:none;transition:.25s;z-index:70}
.scrim.on{opacity:1;pointer-events:auto}
.draw{
  position:fixed;top:0;bottom:0;right:0;width:min(520px,94vw);z-index:80;
  background:var(--bg2);border-left:1px solid var(--line);
  transform:translateX(100%);transition:transform .3s cubic-bezier(.2,.8,.2,1);
  display:flex;flex-direction:column;box-shadow:var(--shadow)
}
.draw.on{transform:translateX(0)}
.dh{padding:16px 18px;border-bottom:1px solid var(--line);display:flex;gap:12px;align-items:flex-start}
.dh h2{font-size:16px;font-weight:800;line-height:1.5}
.dh .path{font-size:11px;color:var(--fg3);margin-top:2px}
.dx{border:1px solid var(--line);background:var(--panel);color:var(--fg2);border-radius:10px;width:32px;height:32px;cursor:pointer;font-size:16px;flex:none;line-height:1}
.dx:hover{color:var(--err);border-color:var(--err)}
.db{flex:1;overflow:auto;padding:16px 18px 26px}
.dgrid{display:grid;grid-template-columns:repeat(3,1fr);gap:9px;margin:14px 0}
.dstat{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:10px 12px}
.dstat .l{font-size:10.5px;color:var(--fg3);font-weight:600}
.dstat .v{font-size:19px;font-weight:800;letter-spacing:-.5px}
.dsec{font-size:11.5px;font-weight:800;color:var(--fg3);margin:18px 0 8px;display:flex;align-items:center;gap:8px}
.dsec .ln{flex:1;height:1px;background:var(--line)}
.kv{display:flex;justify-content:space-between;gap:12px;padding:6px 0;border-bottom:1px dashed var(--line2);font-size:12px}
.kv span{color:var(--fg3)}
.kv b{font-weight:600;text-align:left;overflow:hidden;text-overflow:ellipsis}
.acts{display:flex;gap:8px;flex-wrap:wrap;margin-top:14px}
.act{
  flex:1;min-width:120px;height:38px;border-radius:11px;border:1px solid var(--line);
  background:var(--panel);color:var(--fg2);font:inherit;font-size:12px;font-weight:700;cursor:pointer;
  display:inline-flex;align-items:center;justify-content:center;gap:7px;transition:.15s;text-decoration:none
}
.act:hover{border-color:var(--brand);color:var(--fg)}
.act.pri{background:linear-gradient(120deg,var(--brand),var(--brand2));color:#fff;border-color:transparent}
.errline{
  font-size:11px;background:color-mix(in srgb,var(--err) 12%,transparent);
  border:1px solid color-mix(in srgb,var(--err) 26%,transparent);
  border-radius:9px;padding:7px 10px;margin-bottom:6px;color:var(--fg)
}
.errline i{display:block;font-style:normal;color:var(--fg3);font-size:10px;margin-bottom:2px}
.empty{text-align:center;padding:42px 20px;color:var(--fg3);font-size:13px}
.empty svg{width:44px;height:44px;opacity:.4;margin-bottom:10px}
.foot{margin-top:22px;text-align:center;font-size:11px;color:var(--fg3)}

@media(max-width:1240px){
  .kpis{grid-template-columns:repeat(3,1fr)}
  .row.a,.row.b{grid-template-columns:1fr}
}
@media(max-width:640px){
  .wrap{padding:12px 12px 40px}
  .kpis{grid-template-columns:repeat(2,1fr)}
  .cards{grid-template-columns:1fr}
  .kpi .val{font-size:25px}
}
</style>
</head>
<body>
<div class="wrap">

  <div class="top">
    <div class="brand">
      <div class="orb">
        <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">
          <rect x="4" y="8" width="16" height="11" rx="3"/><path d="M12 8V4"/><circle cx="12" cy="3" r="1.2" fill="#fff"/>
          <path d="M9 13h.01M15 13h.01"/><path d="M9.5 16.2h5"/>
        </svg>
      </div>
      <div>
        <h1>مرکز فرماندهی باتی</h1>
        <div class="meta" id="brandMeta"></div>
      </div>
    </div>
    <div class="grow"></div>
    <div class="clock"><b id="ck">—</b><span id="ckd"></span></div>
    <a class="tbtn" href="/bot" target="_blank" rel="noopener" title="صفحه اصلی ماژول باتی">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/></svg>
      ماژول باتی
    </a>
    <button class="tbtn" id="gear" title="الگوی لینک صفحه باتی">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 7.9 19.4a1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H2a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 4.6 7.9a1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 2.7-1.1V2a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H22a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.1 1.2z"/></svg>
      لینک‌ها
    </button>
    <button class="tbtn" id="theme" title="روشن / تاریک">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>
      <span id="themeTxt">روشن</span>
    </button>
    <button class="tbtn" onclick="location.reload()">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 1 1-2.6-6.4"/><path d="M21 3v6h-6"/></svg>
      بروزرسانی
    </button>
  </div>

  <div class="pop" id="pop">
    <h4>لینک «صفحهٔ باتی» کجا برود؟</h4>
    <p>مسیر <b>اجرا</b> و <b>خروجی</b> از راهنمای رسمی گرفته شده و قطعی است. مسیر صفحهٔ ویرایش/منبع در راهنما نیامده بود؛ اگر گزینهٔ فعلی باز نشد، گزینهٔ بعدی را انتخاب کن. انتخابت ذخیره می‌ماند.</p>
    <div id="popOpts"></div>
  </div>

  <div class="kpis" id="kpis"></div>

  <div class="row a">
    <div class="panel">
      <div class="ph">
        <span class="dot" style="--c:var(--brand)"></span>
        <h2>نبض اجرا</h2>
        <span class="sub" id="pulseSub"></span>
        <span class="grow"></span>
        <div class="seg" id="rangeSeg">
          <button data-r="7">۷ روز</button>
          <button data-r="14">۱۴ روز</button>
          <button data-r="30" class="on">۳۰ روز</button>
        </div>
      </div>
      <div class="chartbox"><div id="mainChart"></div></div>
    </div>
    <div style="display:grid;gap:12px;align-content:start">
      <div class="panel">
        <div class="ph"><span class="dot" style="--c:var(--brand2)"></span><h2>ریتم شبانه‌روز</h2><span class="sub">۷ روز اخیر</span></div>
        <div class="chartbox"><div id="hourChart"></div></div>
      </div>
      <div class="panel">
        <div class="ph"><span class="dot" style="--c:var(--info)"></span><h2>از کجا اجرا می‌شوند</h2></div>
        <div class="chartbox" id="kindChart"></div>
      </div>
    </div>
  </div>

  <div class="cmd">
    <div class="search">
      <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/></svg></span>
      <input id="q" type="search" placeholder="جستجو در نام، مسیر، توضیح یا دسته…" autocomplete="off">
      <span class="kbd">/</span>
    </div>
    <select class="sel" id="sort">
      <option value="recent">تازه‌ترین تغییر</option>
      <option value="runs">پراجراترین (۳۰ روز)</option>
      <option value="total">بیشترین اجرای کل</option>
      <option value="errs">پرخطاترین</option>
      <option value="slow">کندترین</option>
      <option value="lastrun">آخرین اجرا</option>
      <option value="name">الفبا</option>
    </select>
    <div class="views" id="views">
      <button data-v="cards" class="on" title="کارت"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></svg></button>
      <button data-v="table" title="جدول"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 5h18M3 12h18M3 19h18"/></svg></button>
      <button data-v="tree" title="دسته‌بندی"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 5h6M4 12h10M4 19h14"/><circle cx="19" cy="5" r="1.6"/></svg></button>
      <button data-v="perm" title="دسترسی‌ها"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 11h-6"/><path d="M19 8v6"/></svg></button>
    </div>
  </div>

  <div class="chips" id="chips"></div>
  <div id="stage"></div>

  <div class="row b" style="margin-top:16px">
    <div class="panel">
      <div class="ph">
        <span class="dot" style="--c:var(--ok)"></span><h2>جریان رویدادها</h2>
        <span class="grow"></span>
        <div class="seg" id="feedSeg">
          <button data-f="all" class="on">همه</button>
          <button data-f="err">فقط خطا</button>
        </div>
      </div>
      <div class="feed scroll" id="feed"></div>
    </div>
    <div class="panel">
      <div class="ph"><span class="dot" style="--c:var(--warn)"></span><h2>تازه‌ترین باتی‌ها</h2><span class="sub">بر اساس آخرین ویرایش</span></div>
      <div class="newlist scroll" id="newest" style="max-height:430px;overflow:auto"></div>
    </div>
  </div>

  <div class="foot" id="foot"></div>
</div>

<div class="tip" id="tip"></div>
<div class="scrim" id="scrim"></div>
<aside class="draw" id="draw">
  <div class="dh">
    <div style="flex:1;min-width:0">
      <h2 id="dName">—</h2>
      <div class="path mono" id="dPath"></div>
    </div>
    <button class="dx" id="dClose">&times;</button>
  </div>
  <div class="db scroll" id="dBody"></div>
</aside>

<script>
window.__BOTS__ = ]==]

local TAIL = [==[;
(function(){
"use strict";
var D = window.__BOTS__ || {};
/* Lua's json.encode turns an empty table into {}, not [] — so never trust a
   list to be a list. Everything below goes through arr(). */
function arr(v){ return Array.isArray(v) ? v : []; }
var BOTS = arr(D.bots), DAYS = arr(D.days), FEED = arr(D.feed),
    ERRS = arr(D.errors), HOURS = arr(D.hours), KINDS = arr(D.kinds),
    SECS = arr(D.sections), K = D.kpi || {}, WIN = D.window || 30;

var RT = {0:"داخلی",1:"API",2:"عمومی",3:"تایمر",4:"دستور",5:"ویجت",6:"ویجت پورتال",7:"منوی پورتال",8:"دیباگ"};

/* --------------------------------------------------------------- links ---
   Verified against BOT_DEVELOPMENT_GUIDE.md:
     run    -> /bot/run/<license_id>/<run_path>      (run_path already carries the prefix)
     export -> /bot/command/export?id=<command_id>
   The module page route is /bot/command (CPageCommand), but the guide never
   spells out the query string for the view screen, so it is a choice the user
   can flip below. Everything derives from BOT_PAGE, so fixing it is one click. */
var PAGE_PATTERNS = [
  { k:"view",  t:"/bot/command/view?id=…",       f:function(b){ return "/bot/command/view?id=" + b.id; } },
  { k:"cmd",   t:"/bot/command?id=…",            f:function(b){ return "/bot/command?id=" + b.id; } },
  { k:"cmdid", t:"/bot/command?command_id=…",    f:function(b){ return "/bot/command?command_id=" + b.id; } },
  { k:"run",   t:"مستقیم اجرا کن (قطعی)",         f:function(b){ return "/bot/run/" + b.path; } }
];
var pageKey = "view";
try { pageKey = localStorage.getItem("bcc.page") || "view"; } catch(x){}
function pat(){
  for (var i=0;i<PAGE_PATTERNS.length;i++) if (PAGE_PATTERNS[i].k===pageKey) return PAGE_PATTERNS[i];
  return PAGE_PATTERNS[0];
}
function botPage(b){ return location.origin + pat().f(b); }
function botRun(b){ return location.origin + "/bot/run/" + b.path; }
function botExport(b){ return location.origin + "/bot/command/export?id=" + b.id; }
function botHistory(b){ return location.origin + "/bot/command/history?id=" + b.id; }
var GO_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/></svg>';
function goLink(b, title){
  return '<a class="go" href="'+esc(botPage(b))+'" target="_blank" rel="noopener" title="'+esc(title||("باز کردن «"+b.name+"» در ماژول باتی"))+'">'+GO_ICON+'</a>';
}
var byId = {}; BOTS.forEach(function(b){ byId[b.id] = b; });
var Z = []; for (var i=0;i<WIN;i++) Z.push(0);

/* ------------------------------------------------------------ helpers */
function esc(s){ return String(s==null?"":s).replace(/[&<>"']/g,function(c){
  return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]; }); }
function nf(n){ n = Number(n)||0; return n.toLocaleString("en-US"); }
function el(h){ var d=document.createElement("div"); d.innerHTML=h.trim(); return d.firstChild; }
function ago(s){
  if (s==null || s<0) return "—";
  if (s<60) return "همین حالا";
  if (s<3600) return Math.floor(s/60)+" دقیقه پیش";
  if (s<86400) return Math.floor(s/3600)+" ساعت پیش";
  var d=Math.floor(s/86400);
  if (d<30) return d+" روز پیش";
  if (d<365) return Math.floor(d/30)+" ماه پیش";
  return Math.floor(d/365)+" سال پیش";
}
function ms(n){ n=Number(n)||0; return n>=1000 ? (n/1000).toFixed(1)+" ثانیه" : n+" م‌ث"; }
function health(b){
  if (b.off) return {c:"var(--fg3)", t:"خاموش", s:-1};
  var r = b.runs||0, e = b.errs||0;
  if (r===0 && e===0) return {c:"var(--fg3)", t:"بی‌حرکت", s:0};
  var rate = e/Math.max(1,r+e);
  if (rate===0) return {c:"var(--ok)", t:"سالم", s:100};
  if (rate<0.05) return {c:"var(--ok)", t:Math.round((1-rate)*100)+"٪", s:Math.round((1-rate)*100)};
  if (rate<0.25) return {c:"var(--warn)", t:Math.round((1-rate)*100)+"٪", s:Math.round((1-rate)*100)};
  return {c:"var(--err)", t:Math.round((1-rate)*100)+"٪", s:Math.round((1-rate)*100)};
}
function hl(text, q){
  var t = esc(text);
  if (!q) return t;
  var i = text.toLowerCase().indexOf(q);
  if (i < 0) return t;
  return esc(text.slice(0,i)) + "<mark>" + esc(text.slice(i,i+q.length)) + "</mark>" + esc(text.slice(i+q.length));
}
function svg(w,h,inner,extra){
  return '<svg viewBox="0 0 '+w+' '+h+'" preserveAspectRatio="none" style="width:100%;height:'+h+'px;display:block'+(extra||"")+'">'+inner+'</svg>';
}

/* ------------------------------------------------------------- tooltip */
var TIP = document.getElementById("tip");
function tipOn(html, ev){
  TIP.innerHTML = html; TIP.classList.add("on");
  var r = TIP.getBoundingClientRect();
  var x = ev.clientX - r.width/2, y = ev.clientY - r.height - 14;
  x = Math.max(8, Math.min(x, innerWidth - r.width - 8));
  if (y < 8) y = ev.clientY + 18;
  TIP.style.left = x+"px"; TIP.style.top = y+"px";
}
function tipOff(){ TIP.classList.remove("on"); }

/* ----------------------------------------------------------------- KPI */
function ring(pct, color, size){
  size = size||42;
  var r = size/2-4, c = 2*Math.PI*r, off = c*(1-Math.max(0,Math.min(100,pct))/100);
  return '<svg width="'+size+'" height="'+size+'" viewBox="0 0 '+size+' '+size+'">'+
    '<circle cx="'+size/2+'" cy="'+size/2+'" r="'+r+'" fill="none" stroke="var(--line)" stroke-width="4"/>'+
    '<circle cx="'+size/2+'" cy="'+size/2+'" r="'+r+'" fill="none" stroke="'+color+'" stroke-width="4" '+
    'stroke-linecap="round" stroke-dasharray="'+c.toFixed(1)+'" stroke-dashoffset="'+off.toFixed(1)+'" '+
    'transform="rotate(-90 '+size/2+' '+size/2+')"/></svg>';
}
function microBars(vals, color){
  var m = Math.max.apply(null, vals.concat([1])), n = vals.length, w = 60, h = 24, bw = w/n;
  var s = "";
  for (var i=0;i<n;i++){
    var bh = Math.max(1.5, vals[i]/m*h);
    s += '<rect x="'+(i*bw).toFixed(2)+'" y="'+(h-bh).toFixed(2)+'" width="'+(bw*0.68).toFixed(2)+'" height="'+bh.toFixed(2)+'" rx="0.8" fill="'+color+'" opacity="'+(0.35+0.65*i/n).toFixed(2)+'"/>';
  }
  return '<svg width="'+w+'" height="'+h+'" viewBox="0 0 '+w+' '+h+'">'+s+'</svg>';
}
function renderKpis(){
  var runsSeries = DAYS.map(function(d){ return d.runs; });
  var errsSeries = DAYS.map(function(d){ return d.errs; });
  var totalR = K.runs30||0, totalE = K.errs30||0;
  var healthPct = totalR+totalE > 0 ? Math.round(totalR/(totalR+totalE)*100) : 100;

  var cards = [
    { c:"var(--brand)", l:"باتی‌های ثبت‌شده", v:nf(K.total),
      s:nf(K.active)+" فعال · "+nf(K.disabled)+" غیرفعال"
        + (K.shown < K.total ? " · نمایش "+nf(K.shown)+" پرکاربرد" : ""),
      viz: ring(K.total? K.active/K.total*100:0, "var(--brand)") },
    { c:"var(--brand2)", l:"اجرا در ۳۰ روز", v:nf(totalR),
      s:nf(K.alltime)+" اجرا از ابتدا",
      viz: microBars(runsSeries, "var(--brand2)") },
    { c:"var(--ok)", l:"اجرا در ۲۴ ساعت", v:nf(K.runs24),
      s: (K.errs24>0 ? nf(K.errs24)+" خطا در همین بازه" : "بدون خطا در این بازه"),
      viz: microBars(runsSeries.slice(-7), "var(--ok)") },
    { c:"var(--err)", l:"خطاها در ۳۰ روز", v:nf(totalE),
      s:nf(K.failing)+" باتی خطا داده‌اند",
      viz: microBars(errsSeries, "var(--err)") },
    { c: healthPct>=98?"var(--ok)":healthPct>=90?"var(--warn)":"var(--err)",
      l:"سلامت کلی", v:healthPct+"٪",
      s: healthPct>=98?"وضعیت پایدار":healthPct>=90?"نیازمند نگاه":"نیازمند رسیدگی",
      viz: ring(healthPct, healthPct>=98?"var(--ok)":healthPct>=90?"var(--warn)":"var(--err)") },
    { c:"var(--warn)", l:"میانگین زمان اجرا", v:nf(K.avg),
      s:"میلی‌ثانیه · وزنی بر تعداد اجرا",
      viz: microBars(HOURS.slice(8,20), "var(--warn)") }
  ];

  document.getElementById("kpis").innerHTML = cards.map(function(k){
    return '<div class="kpi" style="--c:'+k.c+'">'+
      '<div class="viz">'+k.viz+'</div>'+
      '<div class="lbl"><span class="dot" style="--c:'+k.c+'"></span>'+k.l+'</div>'+
      '<div class="val num">'+k.v+'</div>'+
      '<div class="sub">'+k.s+'</div></div>';
  }).join("");

  document.getElementById("pulseSub").textContent =
    nf(totalR)+" اجرا · "+nf(totalE)+" خطا";
}

/* --------------------------------------------------------- main chart */
var range = 30;
function renderMain(){
  var d = DAYS.slice(-range);
  if (!d.length){ document.getElementById("mainChart").innerHTML = '<div class="empty">داده‌ای برای نمایش نیست</div>'; return; }
  var W = 1000, H = 190, PB = 26, PT = 12;
  var maxR = Math.max.apply(null, d.map(function(x){return x.runs;}).concat([1]));
  var maxE = Math.max.apply(null, d.map(function(x){return x.errs;}).concat([1]));
  var n = d.length, bw = W/n, ih = H-PB-PT;
  var bars = "", errs = "", grid = "", labels = "";

  for (var g=1; g<=3; g++){
    var y = PT + ih*(g/4);
    grid += '<line x1="0" y1="'+y.toFixed(1)+'" x2="'+W+'" y2="'+y.toFixed(1)+'" stroke="var(--line2)" stroke-width="1"/>';
  }
  var pts = [];
  for (var i=0;i<n;i++){
    var x = i*bw, bh = d[i].runs/maxR*ih;
    bars += '<rect class="bar" data-i="'+i+'" x="'+(x+bw*0.16).toFixed(2)+'" y="'+(PT+ih-bh).toFixed(2)+
            '" width="'+(bw*0.68).toFixed(2)+'" height="'+Math.max(bh,0.6).toFixed(2)+'" rx="2" fill="url(#gb)"/>';
    var ey = PT + ih - (d[i].errs/maxE*ih*0.55);
    pts.push((x+bw/2).toFixed(1)+","+ey.toFixed(1));
    if (d[i].errs>0)
      errs += '<circle cx="'+(x+bw/2).toFixed(1)+'" cy="'+ey.toFixed(1)+'" r="2.6" fill="var(--err)"/>';
    var step = n>20?5:n>10?2:1;
    if (i%step===0 || i===n-1)
      labels += '<text x="'+(x+bw/2).toFixed(1)+'" y="'+(H-8)+'" text-anchor="middle" font-size="10" fill="var(--fg3)">'+esc(d[i].lbl)+'</text>';
  }
  var line = d.some(function(x){return x.errs>0;})
    ? '<polyline points="'+pts.join(" ")+'" fill="none" stroke="var(--err)" stroke-width="1.4" opacity=".55"/>' : "";

  var html = '<svg viewBox="0 0 '+W+' '+H+'" style="width:100%;height:210px;display:block;overflow:visible">'+
    '<defs><linearGradient id="gb" x1="0" y1="0" x2="0" y2="1">'+
    '<stop offset="0%" stop-color="var(--brand2)"/><stop offset="100%" stop-color="var(--brand)" stop-opacity=".55"/>'+
    '</linearGradient></defs>'+ grid + bars + line + errs + labels +
    '<rect id="hit" x="0" y="0" width="'+W+'" height="'+H+'" fill="transparent"/></svg>';

  var box = document.getElementById("mainChart");
  box.innerHTML = html;
  var sv = box.querySelector("svg");
  sv.addEventListener("mousemove", function(ev){
    var r = sv.getBoundingClientRect();
    var rel = (ev.clientX - r.left) / r.width * W;
    var i = Math.max(0, Math.min(n-1, Math.floor(rel/bw)));
    tipOn('<b>'+esc(d[i].full)+'</b>'+
          '<i>اجرا</i> <span class="num">'+nf(d[i].runs)+'</span><br>'+
          '<i>خطا</i> <span class="num" style="color:var(--err)">'+nf(d[i].errs)+'</span>', ev);
  });
  sv.addEventListener("mouseleave", tipOff);
}

/* ---------------------------------------------------------- hour chart */
function renderHours(){
  var W=340, H=104, n=24, bw=W/n, ih=H-20;
  var m = Math.max.apply(null, HOURS.concat([1])), s="";
  for (var i=0;i<n;i++){
    var bh = Math.max(2, HOURS[i]/m*ih);
    var peak = HOURS[i]===m;
    s += '<rect data-h="'+i+'" x="'+(i*bw+bw*0.14).toFixed(2)+'" y="'+(ih-bh+6).toFixed(2)+'" width="'+(bw*0.72).toFixed(2)+
         '" height="'+bh.toFixed(2)+'" rx="2" fill="'+(peak?"var(--brand2)":"var(--brand)")+'" opacity="'+(peak?1:0.42+0.5*HOURS[i]/m)+'"/>';
    if (i%6===0) s += '<text x="'+(i*bw+bw/2).toFixed(1)+'" y="'+(H-2)+'" text-anchor="middle" font-size="9.5" fill="var(--fg3)">'+i+'</text>';
  }
  var box = document.getElementById("hourChart");
  box.innerHTML = '<svg viewBox="0 0 '+W+' '+H+'" style="width:100%;height:110px;display:block">'+s+'</svg>';
  var sv = box.querySelector("svg");
  sv.addEventListener("mousemove", function(ev){
    var r = sv.getBoundingClientRect();
    var i = Math.max(0, Math.min(23, Math.floor((ev.clientX-r.left)/r.width*24)));
    tipOn('<b>ساعت '+i+':00</b><i>اجرا</i> <span class="num">'+nf(HOURS[i])+'</span>', ev);
  });
  sv.addEventListener("mouseleave", tipOff);
}

/* ---------------------------------------------------------- kind chart */
function renderKinds(){
  var tot = KINDS.reduce(function(a,b){return a+b.n;},0) || 1;
  var sorted = KINDS.slice().sort(function(a,b){return b.n-a.n;});
  var cols = ["var(--brand)","var(--brand2)","var(--ok)","var(--warn)","var(--info)","var(--err)","#a78bfa","#f472b6","#4ade80"];
  document.getElementById("kindChart").innerHTML = sorted.length ? sorted.map(function(k,i){
    var p = k.n/tot*100;
    return '<div style="margin:9px 0 0">'+
      '<div style="display:flex;justify-content:space-between;font-size:11.5px;color:var(--fg2)">'+
        '<span>'+esc(RT[k.rt]||("نوع "+k.rt))+'</span>'+
        '<span class="num">'+nf(k.n)+' · '+p.toFixed(0)+'٪</span></div>'+
      '<div style="height:6px;border-radius:3px;background:var(--line);margin-top:4px;overflow:hidden">'+
        '<i style="display:block;height:100%;width:'+p.toFixed(1)+'%;background:'+cols[i%cols.length]+'"></i></div></div>';
  }).join("") : '<div class="empty">داده‌ای نیست</div>';
}

/* --------------------------------------------------------------- state */
var state = { q:"", view:"cards", sort:"recent", flags:{}, sec:0, sortCol:null, sortDir:1,
              perm:"bot", openAcc:null };

var FLAGS = [
  { k:"active", t:"فعال",    f:function(b){return !b.off;} },
  { k:"off",    t:"غیرفعال", f:function(b){return b.off;} },
  { k:"pub",    t:"عمومی",   f:function(b){return b.pub;} },
  { k:"timer",  t:"تایمردار",f:function(b){return b.timer;} },
  { k:"widget", t:"ویجت",    f:function(b){return b.widget;} },
  { k:"portal", t:"پورتال",  f:function(b){return b.portal;} },
  { k:"html",   t:"HTML",    f:function(b){return b.html;} },
  { k:"live",   t:"فعال ۳۰روز", f:function(b){return (b.runs||0)>0;} },
  { k:"idle",   t:"بی‌حرکت", f:function(b){return (b.runs||0)===0;} },
  { k:"bad",    t:"خطادار",  f:function(b){return (b.errs||0)>0;} }
];

function renderChips(){
  var host = document.getElementById("chips");
  var h = FLAGS.map(function(f){
    var n = BOTS.filter(f.f).length;
    return '<button class="chip'+(state.flags[f.k]?" on":"")+'" data-flag="'+f.k+'">'+esc(f.t)+'<span class="n num">'+n+'</span></button>';
  }).join("");
  var tops = SECS.filter(function(s){ return s.ref===0; });
  if (tops.length){
    h += '<span style="width:1px;height:22px;background:var(--line);margin:0 4px"></span>';
    h += '<button class="chip sec'+(state.sec===0?" on":"")+'" data-sec="0">همه بخش‌ها</button>';
    h += tops.map(function(s){
      var n = BOTS.filter(function(b){ return b.secId===s.id; }).length;
      if (!n) return "";
      return '<button class="chip sec'+(state.sec===s.id?" on":"")+'" data-sec="'+s.id+'">'+esc(s.name)+'<span class="n num">'+n+'</span></button>';
    }).join("");
  }
  host.innerHTML = h;
}

function filtered(){
  var q = state.q.trim().toLowerCase();
  var act = FLAGS.filter(function(f){ return state.flags[f.k]; });
  var out = BOTS.filter(function(b){
    if (state.sec && b.secId !== state.sec) return false;
    for (var i=0;i<act.length;i++) if (!act[i].f(b)) return false;
    if (!q) return true;
    return (b.name+" "+b.path+" "+b.descr+" "+b.cat+" "+b.sec+" "+b.dbp).toLowerCase().indexOf(q) >= 0;
  });
  var s = state.sort;
  out.sort(function(a,b){
    if (s==="name")    return a.name.localeCompare(b.name,"fa");
    if (s==="runs")    return (b.runs||0)-(a.runs||0);
    if (s==="total")   return (b.total||0)-(a.total||0);
    if (s==="errs")    return (b.errs||0)-(a.errs||0);
    if (s==="slow")    return (b.avg||0)-(a.avg||0);
    if (s==="lastrun"){
      var A = a.lastAgo<0?1e12:a.lastAgo, B = b.lastAgo<0?1e12:b.lastAgo; return A-B;
    }
    var X = a.modAgo<0?1e12:a.modAgo, Y = b.modAgo<0?1e12:b.modAgo; return X-Y;
  });
  return out;
}

/* --------------------------------------------------------------- cards */
function sparkline(b){
  var v = b.spark || Z, e = b.espark || Z;
  var W=260, H=34, n=v.length, m=Math.max.apply(null, v.concat([1]));
  var step = W/(n-1||1), pts=[], area=[];
  for (var i=0;i<n;i++){
    var x=(i*step), y=H-2-(v[i]/m)*(H-6);
    pts.push(x.toFixed(1)+","+y.toFixed(1));
  }
  area = "0,"+H+" " + pts.join(" ") + " "+W+","+H;
  var dots = "";
  for (var j=0;j<n;j++) if (e[j]>0){
    dots += '<circle cx="'+(j*step).toFixed(1)+'" cy="'+(H-3)+'" r="2" fill="var(--err)"/>';
  }
  var id = "g"+b.id;
  return '<svg viewBox="0 0 '+W+' '+H+'" preserveAspectRatio="none" style="width:100%;height:34px;display:block">'+
    '<defs><linearGradient id="'+id+'" x1="0" y1="0" x2="0" y2="1">'+
    '<stop offset="0%" stop-color="var(--brand2)" stop-opacity=".45"/>'+
    '<stop offset="100%" stop-color="var(--brand)" stop-opacity="0"/></linearGradient></defs>'+
    '<polygon points="'+area+'" fill="url(#'+id+')"/>'+
    '<polyline points="'+pts.join(" ")+'" fill="none" stroke="var(--brand2)" stroke-width="1.6" stroke-linejoin="round"/>'+
    dots+'</svg>';
}
function tagsOf(b){
  var t = [];
  if (b.off)    t.push('<span class="tag off">غیرفعال</span>');
  if (b.pub)    t.push('<span class="tag pub">عمومی</span>');
  if (b.timer)  t.push('<span class="tag timer">تایمر</span>');
  if (b.errs>0) t.push('<span class="tag err">'+b.errs+' خطا</span>');
  if (b.widget) t.push('<span class="tag">ویجت</span>');
  if (b.portal) t.push('<span class="tag">پورتال</span>');
  if (b.html)   t.push('<span class="tag">HTML</span>');
  if (b.async)  t.push('<span class="tag">ناهمزمان</span>');
  if (b.cache>0)t.push('<span class="tag">کش '+b.cache+'د</span>');
  if (b.ver>0)  t.push('<span class="tag">v'+b.ver+'</span>');
  return t.join("");
}
function renderCards(list, q){
  if (!list.length) return emptyBox();
  return '<div class="cards">' + list.map(function(b){
    var h = health(b);
    return '<article class="card'+(b.off?" off":"")+'" data-id="'+b.id+'" style="--h:'+h.c+'">'+
      '<div class="rail"></div>'+
      '<div style="display:flex;align-items:center;gap:8px">'+
        '<div style="flex:1;min-width:0">'+
          '<h3>'+hl(b.name,q)+'</h3>'+
          '<div class="path mono">'+hl(b.path,q)+'</div>'+
        '</div>'+
        '<span class="hpill">'+h.t+'</span>'+
        goLink(b)+
      '</div>'+
      '<div class="spark">'+sparkline(b)+'</div>'+
      '<div class="stats">'+
        '<span>اجرا <b class="num">'+nf(b.runs)+'</b></span>'+
        '<span>خطا <b class="num" style="color:'+(b.errs>0?"var(--err)":"inherit")+'">'+nf(b.errs)+'</b></span>'+
        '<span>زمان <b class="num">'+nf(b.avg)+'</b>م‌ث</span>'+
      '</div>'+
      '<div class="tags">'+ (b.cat? '<span class="tag">'+esc(b.cat)+'</span>':'') + tagsOf(b) +'</div>'+
    '</article>';
  }).join("") + '</div>';
}

/* --------------------------------------------------------------- table */
var COLS = [
  { k:"name",  t:"نام",        v:function(b,q){ return '<div class="nm"><a class="tlink" href="'+esc(botPage(b))+'" target="_blank" rel="noopener">'+hl(b.name,q)+'</a></div>'; }, s:function(b){return b.name;} },
  { k:"path",  t:"مسیر اجرا",  v:function(b,q){ return '<a class="tlink mono" style="font-size:11px;color:var(--fg3)" href="'+esc(botRun(b))+'" target="_blank" rel="noopener">'+hl(b.path,q)+'</a>'; }, s:function(b){return b.path;} },
  { k:"cat",   t:"دسته",       v:function(b){ return esc(b.cat||"—"); }, s:function(b){return b.cat;} },
  { k:"runs",  t:"اجرا ۳۰روز", v:function(b){ return '<span class="num">'+nf(b.runs)+'</span>'; }, s:function(b){return b.runs;} },
  { k:"total", t:"اجرای کل",   v:function(b){ return '<span class="num">'+nf(b.total)+'</span>'; }, s:function(b){return b.total;} },
  { k:"errs",  t:"خطا",        v:function(b){ return '<span class="num" style="color:'+(b.errs>0?"var(--err)":"var(--fg3)")+'">'+nf(b.errs)+'</span>'; }, s:function(b){return b.errs;} },
  { k:"avg",   t:"میانگین",    v:function(b){ return '<span class="num">'+nf(b.avg)+'</span>'; }, s:function(b){return b.avg;} },
  { k:"last",  t:"آخرین اجرا", v:function(b){ return '<span style="color:var(--fg3);font-size:11.5px">'+esc(ago(b.lastAgo))+'</span>'; }, s:function(b){return b.lastAgo<0?1e12:b.lastAgo;} },
  { k:"mod",   t:"ویرایش",     v:function(b){ return '<span style="color:var(--fg3);font-size:11.5px">'+esc(ago(b.modAgo))+'</span>'; }, s:function(b){return b.modAgo<0?1e12:b.modAgo;} },
  { k:"state", t:"وضعیت",      v:function(b){ var h=health(b); return '<span class="hpill" style="--h:'+h.c+'">'+h.t+'</span>'; }, s:function(b){return health(b).s;} }
];
function renderTable(list, q){
  if (!list.length) return emptyBox();
  var rows = list.slice();
  if (state.sortCol){
    var c = COLS.filter(function(x){return x.k===state.sortCol;})[0];
    if (c) rows.sort(function(a,b){
      var A=c.s(a), B=c.s(b);
      if (typeof A==="string") return state.sortDir*A.localeCompare(B,"fa");
      return state.sortDir*((A||0)-(B||0));
    });
  }
  return '<div class="panel" style="overflow:auto"><table class="tbl"><thead><tr>'+
    COLS.map(function(c){
      var a = state.sortCol===c.k ? (state.sortDir>0?" ▲":" ▼") : "";
      return '<th data-col="'+c.k+'">'+esc(c.t)+a+'</th>';
    }).join("")+'</tr></thead><tbody>'+
    rows.map(function(b){
      return '<tr data-id="'+b.id+'"'+(b.off?' style="opacity:.55"':'')+'>'+
        COLS.map(function(c){ return '<td>'+c.v(b,q)+'</td>'; }).join("")+'</tr>';
    }).join("")+'</tbody></table></div>';
}

/* ---------------------------------------------------------------- tree */
function renderTree(list){
  if (!list.length) return emptyBox();
  var byCat = {}, uncat = [];
  list.forEach(function(b){
    if (!b.catId){ uncat.push(b); return; }
    (byCat[b.catId] = byCat[b.catId] || []).push(b);
  });
  var tops = SECS.filter(function(s){ return s.ref===0; });
  var maxN = Math.max.apply(null, Object.keys(byCat).map(function(k){return byCat[k].length;}).concat([1]));
  var h = '<div class="panel tree">';
  tops.forEach(function(sec){
    var cats = SECS.filter(function(c){ return c.ref===sec.id && byCat[c.id]; });
    if (!cats.length) return;
    var tot = cats.reduce(function(a,c){ return a+byCat[c.id].length; },0);
    h += '<div class="tsec"><h3><span class="dot" style="--c:var(--brand2)"></span>'+esc(sec.name)+
         ' <span style="color:var(--fg3);font-weight:600" class="num">'+tot+'</span><span class="ln"></span></h3>';
    cats.sort(function(a,b){ return byCat[b.id].length - byCat[a.id].length; });
    cats.forEach(function(c){
      var arr = byCat[c.id];
      var runs = arr.reduce(function(a,b){return a+(b.runs||0);},0);
      var errs = arr.reduce(function(a,b){return a+(b.errs||0);},0);
      h += '<div class="tcat"><button data-cat="'+c.id+'">'+
        '<span style="min-width:120px">'+esc(c.name)+'</span>'+
        '<span class="bar"><i style="width:'+(arr.length/maxN*100).toFixed(1)+'%"></i></span>'+
        '<span class="n num">'+arr.length+' باتی · '+nf(runs)+' اجرا'+(errs?' · <span style="color:var(--err)">'+errs+' خطا</span>':'')+'</span>'+
        '</button><div class="kids">'+
        arr.map(function(b){
          var hh = health(b);
          return '<span class="mini" data-id="'+b.id+'"><span class="dot" style="--c:'+hh.c+'"></span>'+esc(b.name)+goLink(b)+'</span>';
        }).join("")+'</div></div>';
    });
    h += '</div>';
  });
  if (uncat.length){
    h += '<div class="tsec"><h3><span class="dot" style="--c:var(--fg3)"></span>بدون دسته‌بندی'+
         ' <span style="color:var(--fg3);font-weight:600" class="num">'+uncat.length+'</span><span class="ln"></span></h3>'+
         '<div class="tcat open"><div class="kids">'+
         uncat.map(function(b){
           var hh = health(b);
           return '<span class="mini" data-id="'+b.id+'"><span class="dot" style="--c:'+hh.c+'"></span>'+esc(b.name)+goLink(b)+'</span>';
         }).join("")+'</div></div></div>';
  }
  return h+'</div>';
}

function emptyBox(){
  return '<div class="panel empty">'+
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/></svg>'+
    '<div>هیچ باتی با این شرط پیدا نشد</div></div>';
}

/* ---------------------------------------------------------------- feed */
var feedMode = "all";
function renderFeed(){
  var rows = feedMode==="err" ? FEED.filter(function(e){return e.err;}) : FEED;
  var host = document.getElementById("feed");
  if (!rows.length){ host.innerHTML = '<div class="empty">رویدادی ثبت نشده</div>'; return; }
  host.innerHTML = rows.map(function(e){
    var b = byId[e.bid];
    return '<div class="ev'+(e.err?" bad":"")+'" data-id="'+e.bid+'">'+
      '<span class="bd"></span>'+
      '<div class="b"><div class="nm">'+esc(b? b.name : ("باتی #"+e.bid))+'</div>'+
      '<div class="ms">'+ (e.err ? esc(e.msg) : (esc(RT[e.rt]||"") + " · " + ms(e.ms))) +'</div></div>'+
      '<div class="tm"><span class="num">'+esc(e.t)+'</span><br>'+esc(e.d)+'</div>'+
      (b ? goLink(b) : '') + '</div>';
  }).join("");
}
function renderNewest(){
  var list = BOTS.slice().sort(function(a,b){
    var A=a.modAgo<0?1e12:a.modAgo, B=b.modAgo<0?1e12:b.modAgo; return A-B;
  }).slice(0,12);
  document.getElementById("newest").innerHTML = list.map(function(b,i){
    return '<div class="nb" data-id="'+b.id+'">'+
      '<div class="idx num">'+(i+1)+'</div>'+
      '<div class="b"><div class="nm">'+esc(b.name)+'</div>'+
      '<div class="mt">'+esc(b.mod||"—")+' · '+esc(ago(b.modAgo))+'</div></div>'+
      '<span class="hpill" style="--h:'+health(b).c+'">'+health(b).t+'</span>'+
      goLink(b)+'</div>';
  }).join("");
}

/* -------------------------------------------------------------- drawer */
var DRAW = document.getElementById("draw"), SCRIM = document.getElementById("scrim"), openId = null;
function openBot(id){
  var b = byId[id]; if (!b) return;
  openId = id;
  var h = health(b);
  document.getElementById("dName").innerHTML =
    '<a class="tlink" href="'+esc(botPage(b))+'" target="_blank" rel="noopener" style="color:inherit;text-decoration:none">'+esc(b.name)+'</a>';
  document.getElementById("dPath").innerHTML =
    '<a class="tlink" href="'+esc(botRun(b))+'" target="_blank" rel="noopener" style="color:inherit">/bot/run/'+esc(b.path)+'</a>';

  var myErrs = ERRS.filter(function(e){ return e.bid===b.id; }).slice(0,8);
  var myFeed = FEED.filter(function(e){ return e.bid===b.id; }).slice(0,10);
  var url = botRun(b);

  var body =
    (b.descr ? '<div style="font-size:12.5px;color:var(--fg2)">'+esc(b.descr)+'</div>' : '') +
    '<div class="tags" style="margin-top:10px">'+ (b.cat? '<span class="tag">'+esc(b.sec)+' › '+esc(b.cat)+'</span>':'') + tagsOf(b) +'</div>'+
    '<div class="acts">'+
      '<a class="act pri" href="'+esc(botPage(b))+'" target="_blank" rel="noopener">'+
        GO_ICON+' صفحهٔ باتی (منبع و تنظیمات)</a>'+
    '</div>'+
    '<div class="acts">'+
      '<a class="act" href="'+esc(url)+'" target="_blank" rel="noopener">'+
        '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="m5 3 14 9-14 9z"/></svg> اجرا</a>'+
      '<a class="act" href="'+esc(botHistory(b))+'" target="_blank" rel="noopener">'+
        '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12a9 9 0 1 1-2.6-6.4"/><path d="M21 3v6h-6"/><path d="M12 7v5l3 2"/></svg> تاریخچه</a>'+
      '<a class="act" href="'+esc(botExport(b))+'" target="_blank" rel="noopener">'+
        '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/></svg> خروجی .tybot</a>'+
    '</div>'+
    '<div class="acts">'+
      '<button class="act" data-copy="'+esc(url)+'">کپی لینک اجرا</button>'+
      '<button class="act" data-copy="'+esc(b.path)+'">کپی مسیر</button>'+
    '</div>'+
    '<div class="dgrid">'+
      '<div class="dstat"><div class="l">اجرا ۳۰ روز</div><div class="v num">'+nf(b.runs)+'</div></div>'+
      '<div class="dstat"><div class="l">خطا ۳۰ روز</div><div class="v num" style="color:'+(b.errs?"var(--err)":"inherit")+'">'+nf(b.errs)+'</div></div>'+
      '<div class="dstat"><div class="l">اجرای کل</div><div class="v num">'+nf(b.total)+'</div></div>'+
      '<div class="dstat"><div class="l">میانگین</div><div class="v num">'+nf(b.avg)+'</div></div>'+
      '<div class="dstat"><div class="l">کندترین</div><div class="v num">'+nf(b.max)+'</div></div>'+
      '<div class="dstat"><div class="l">سلامت</div><div class="v" style="color:'+h.c+'">'+h.t+'</div></div>'+
    '</div>'+
    '<div class="dsec">روند ۳۰ روز<span class="ln"></span></div>'+
    '<div style="background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:12px">'+ botChart(b) +'</div>'+
    '<div class="dsec">مشخصات<span class="ln"></span></div>'+
    kv("آخرین اجرا", b.last ? (b.last+" ("+ago(b.lastAgo)+")") : "—") +
    kv("آخرین ویرایش", (b.mod||"—")+" · "+ago(b.modAgo)) +
    kv("نوع خروجی", b.html ? "HTML" : "JSON / متن") +
    kv("حداکثر زمان اجرا", b.maxexec + " ثانیه") +
    kv("کش", b.cache>0 ? (b.cache+" دقیقه") : "ندارد") +
    kv("نسخه‌ها", b.ver>0 ? b.ver : "بدون نسخه‌بندی") +
    kv("پیشوند دیتابیس", b.dbp || "—") +
    kv("مبدأ", b.srcdom || "بومی") +
    kv("شناسه", "#"+b.id) +
    (myErrs.length ? '<div class="dsec" style="color:var(--err)">خطاهای اخیر<span class="ln"></span></div>'+
      myErrs.map(function(e){
        return '<div class="errline"><i>'+esc(e.d)+' · '+esc(e.t)+' · '+esc(RT[e.rt]||"")+'</i>'+esc(e.msg)+'</div>';
      }).join("") : '') +
    (myFeed.length ? '<div class="dsec">آخرین رویدادها<span class="ln"></span></div>'+
      myFeed.map(function(e){
        return '<div class="ev'+(e.err?" bad":"")+'" style="cursor:default"><span class="bd"></span>'+
          '<div class="b"><div class="nm" style="font-size:11.5px">'+esc(RT[e.rt]||"")+(e.err?" · خطا":" · "+ms(e.ms))+'</div></div>'+
          '<div class="tm"><span class="num">'+esc(e.t)+'</span> '+esc(e.d)+'</div></div>';
      }).join("") : '');

  document.getElementById("dBody").innerHTML = body;
  document.getElementById("dBody").scrollTop = 0;
  DRAW.classList.add("on"); SCRIM.classList.add("on");
}
function kv(k,v){ return '<div class="kv"><span>'+esc(k)+'</span><b>'+esc(v)+'</b></div>'; }
function botChart(b){
  var v = b.spark || Z, e = b.espark || Z;
  var W=440, H=110, n=v.length, m=Math.max.apply(null, v.concat([1])), bw=W/n, ih=H-22, s="";
  for (var i=0;i<n;i++){
    var bh = Math.max(1.5, v[i]/m*ih);
    s += '<rect x="'+(i*bw+bw*0.15).toFixed(2)+'" y="'+(ih-bh+6).toFixed(2)+'" width="'+(bw*0.7).toFixed(2)+
         '" height="'+bh.toFixed(2)+'" rx="1.6" fill="var(--brand)" opacity="'+(0.4+0.6*i/n).toFixed(2)+'"/>';
    if (e[i]>0) s += '<circle cx="'+(i*bw+bw/2).toFixed(1)+'" cy="'+(H-12)+'" r="2.4" fill="var(--err)"/>';
  }
  s += '<text x="2" y="'+(H-1)+'" font-size="9.5" fill="var(--fg3)">'+esc(DAYS[0]?DAYS[0].lbl:"")+'</text>';
  s += '<text x="'+(W-2)+'" y="'+(H-1)+'" text-anchor="end" font-size="9.5" fill="var(--fg3)">'+esc(DAYS[DAYS.length-1]?DAYS[DAYS.length-1].lbl:"")+'</text>';
  return '<svg viewBox="0 0 '+W+' '+H+'" style="width:100%;height:120px;display:block">'+s+'</svg>';
}
function closeDraw(){ DRAW.classList.remove("on"); SCRIM.classList.remove("on"); openId = null; }

/* --------------------------------------------------------------- access ---
   The graph mirrors CBotManager::checkPermCommand. A person reaches a bot when
   they are a module admin, or belong to a subject holding a grant on the bot
   (TYPE=10) or on any category it belongs to (TYPE=2). PERM is a mask of role
   ids; each role expands to its ROLE_FLAGS, which are the detailed abilities. */
var ACC    = D.access || {};
var ROLES  = arr(ACC.roles), SUBJ = arr(ACC.subjects), GRANTS = arr(ACC.grants),
    CATMAP = arr(ACC.cats),  ADMINS = arr(ACC.admins), MEMB = arr(ACC.members);

var PFLAG = ["دیدن","اجرا","افزودن","ویرایش","حذف","درون‌ریزی","برون‌بری","انتساب CRM",
             "دیباگ","افزودن نسخه","حذف نسخه","حذف تاریخچه","تنظیم تایمر","حذف کش",
             "افزودن دسته","ویرایش دسته","حذف دسته","دسترسی دسته","دسترسی بخش",
             "ویرایش بخش","ویرایش پیکربندی","ویرایش دسترسی"];

var subjById = {}, adminSet = {}, catsOf = {}, membOf = {}, subjOf = {},
    userName = {}, gBot = {}, gCat = {}, catName = {};
SUBJ.forEach(function(s){ subjById[s.id] = s; });
ADMINS.forEach(function(id){ adminSet[id] = 1; });
CATMAP.forEach(function(c){ (catsOf[c.c] = catsOf[c.c] || []).push(c.k); });
SECS.forEach(function(s){ catName[s.id] = s.name; });
MEMB.forEach(function(m){
  (membOf[m.g] = membOf[m.g] || []).push(m.u);
  (subjOf[m.u] = subjOf[m.u] || []).push(m.g);
  userName[m.u] = m.n;
});
GRANTS.forEach(function(g){
  var t = (g.t === 10 ? gBot : gCat);
  (t[g.o] = t[g.o] || []).push(g);
});

function roleNames(mask){
  var out = []; ROLES.forEach(function(r){ if (mask & r.bit) out.push(r.name); });
  return out;
}
function roleFlags(mask){
  var f = 0; ROLES.forEach(function(r){ if (mask & r.bit) f |= r.flags; });
  return f;
}
function flagNames(f){
  var out = [];
  for (var i = 0; i < PFLAG.length; i++) if (f & (1 << i)) out.push(PFLAG[i]);
  return out;
}
function subjLabel(id){
  var s = subjById[id];
  if (s && s.name) return s.name;
  return userName[id] || ("شناسه " + id);
}
function isGroup(id){ var s = subjById[id]; return s ? s.kind === 2 : false; }

/* every grant that reaches this bot, direct then inherited from its categories.
   Memoised: the by-person view asks for this once per person per bot. */
var _grantCache = {};
function grantsFor(bot){
  var hit = _grantCache[bot.id];
  if (hit) return hit;
  var out = [];
  (gBot[bot.id] || []).forEach(function(g){ out.push({ g:g, via:"bot", cat:0 }); });
  (catsOf[bot.id] || []).forEach(function(k){
    (gCat[k] || []).forEach(function(g){ out.push({ g:g, via:"cat", cat:k }); });
  });
  _grantCache[bot.id] = out;
  return out;
}
/* distinct people a bot is reachable by, module admins excluded */
function peopleFor(bot){
  var seen = {}, out = [];
  grantsFor(bot).forEach(function(x){
    (membOf[x.g.s] || []).forEach(function(u){
      if (!seen[u]) { seen[u] = 1; out.push(u); }
    });
  });
  return out;
}
/* strongest ability the mask actually confers. "محدود" is not a fallback for
   "nothing" — it means the roles grant something narrow (انتساب CRM, say) but
   neither دیدن nor اجرا, which reads very differently from view-only. */
function accessBadge(mask){
  var f = roleFlags(mask), t;
  if (f & (1<<21) || f & (1<<4)) t = { l:"مدیریت", c:"var(--err)"  };
  else if (f & (1<<3))           t = { l:"ویرایش", c:"var(--warn)" };
  else if (f & (1<<1))           t = { l:"اجرا",   c:"var(--ok)"   };
  else if (f & 1)                t = { l:"دیدن",   c:"var(--fg3)"  };
  else                           t = { l:"محدود",  c:"var(--info)" };
  return '<span class="hpill" style="--h:'+t.c+'">'+t.l+'</span>';
}

var ACC_CAP = 200;   /* rows rendered per access list — disclosed when it bites */

function accSubjRow(x){
  var g = x.g, names = roleNames(g.p), abil = flagNames(roleFlags(g.p));
  var n = (membOf[g.s] || []).length;
  return '<div style="display:flex;gap:8px;align-items:baseline;padding:5px 0;border-top:1px solid var(--line)">'+
    '<span style="min-width:190px">'+
      (isGroup(g.s) ? '<span style="color:var(--fg3);font-size:11px">گروه · </span>' : '')+
      esc(subjLabel(g.s))+
      (n ? '<span style="color:var(--fg3);font-size:11px"> ('+nf(n)+' نفر)</span>' : '')+
    '</span>'+
    accessBadge(g.p)+
    '<span style="color:var(--fg3);font-size:11.5px">'+esc(names.join("، ") || "—")+'</span>'+
    '<span class="grow"></span>'+
    '<span style="color:var(--fg3);font-size:11px">'+
      (x.via === "bot" ? "روی خود باتی" : "از دستهٔ «"+esc(catName[x.cat] || x.cat)+"»")+
    '</span>'+
    '<span style="color:var(--fg3);font-size:11px;max-width:38%;text-align:left">'+esc(abil.join("، "))+'</span>'+
  '</div>';
}

function renderAccessByBot(list){
  var rows = list.slice(0, ACC_CAP).map(function(b){
    var gs = grantsFor(b), ppl = peopleFor(b);
    var direct = gs.filter(function(x){ return x.via === "bot"; }).length;
    var open = state.openAcc === ("b" + b.id);
    var head = '<div class="accrow" data-acc="b'+b.id+'" style="display:flex;gap:10px;align-items:center;padding:9px 2px;cursor:pointer">'+
      '<span style="flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">'+esc(b.name)+'</span>'+
      (b.pub ? '<span class="hpill" style="--h:var(--info)">عمومی</span>' : '')+
      '<span style="color:var(--fg3);font-size:11.5px">'+nf(gs.length)+' دسترسی'+
        (direct ? ' · '+nf(direct)+' مستقیم' : '')+'</span>'+
      '<span style="color:var(--fg);font-size:11.5px;min-width:64px;text-align:left">'+nf(ppl.length)+' نفر</span>'+
    '</div>';
    if (!open) return head;
    var body = gs.length
      ? gs.map(accSubjRow).join("")
      : '<div class="empty" style="padding:10px">هیچ دسترسی صریحی ثبت نشده — فقط مدیران ماژول'+
        (b.pub ? ' و (چون عمومی است) همه' : '')+' می‌توانند به آن برسند.</div>';
    var who = ppl.length
      ? '<div style="padding:8px 0 2px;border-top:1px solid var(--line)">'+
          '<div style="color:var(--fg3);font-size:11px;margin-bottom:4px">افراد نهایی</div>'+
          ppl.slice(0,80).map(function(u){
            return '<span class="mini">'+esc(userName[u] || ("کاربر "+u))+'</span>';
          }).join("")+
          (ppl.length > 80 ? '<span class="mini">+'+nf(ppl.length-80)+' نفر دیگر</span>' : '')+
        '</div>'
      : '';
    return head + '<div style="padding:0 2px 10px">'+body+who+'</div>';
  }).join("");
  return (rows || '<div class="empty">باتی‌ای مطابق جستجو نیست</div>')+
    (list.length > ACC_CAP
      ? '<div class="empty" style="margin-top:8px">'+nf(list.length - ACC_CAP)+
        ' باتی دیگر در این فهرست هست؛ برای دیدنشان جستجو را باریک‌تر کن.</div>'
      : '');
}

/* person -> the bots they reach, with the strongest mask on each */
function botsForUser(uid){
  var subs = subjOf[uid] || [], mine = {}, out = [];
  subs.forEach(function(s){ mine[s] = 1; });
  BOTS.forEach(function(b){
    var mask = 0;
    grantsFor(b).forEach(function(x){ if (mine[x.g.s]) mask |= x.g.p; });
    if (mask) out.push({ b:b, mask:mask });
  });
  return out;
}

function renderAccessByPerson(q){
  var people = Object.keys(userName).map(Number);
  if (q) people = people.filter(function(u){ return (userName[u]||"").toLowerCase().indexOf(q) >= 0; });
  var rows = people.map(function(u){ return { u:u, list:botsForUser(u) }; })
                   .filter(function(r){ return r.list.length || adminSet[r.u]; })
                   .sort(function(a,b){ return b.list.length - a.list.length; });
  if (!rows.length) return '<div class="empty">کسی مطابق جستجو نیست</div>';
  return rows.slice(0, ACC_CAP).map(function(r){
    var open = state.openAcc === ("u" + r.u);
    var head = '<div class="accrow" data-acc="u'+r.u+'" style="display:flex;gap:10px;align-items:center;padding:9px 2px;cursor:pointer">'+
      '<span style="flex:1">'+esc(userName[r.u] || ("کاربر "+r.u))+'</span>'+
      (adminSet[r.u] ? '<span class="hpill" style="--h:var(--err)">مدیر ماژول</span>' : '')+
      '<span style="color:var(--fg);font-size:11.5px;min-width:90px;text-align:left">'+nf(r.list.length)+' باتی</span>'+
    '</div>';
    if (!open) return head;
    if (adminSet[r.u] && !r.list.length)
      return head + '<div class="empty" style="padding:10px">مدیر ماژول باتی است: به همهٔ '+nf(K.total)+' باتی دسترسی کامل دارد.</div>';
    var body = r.list.slice(0,300).map(function(x){
      return '<div style="display:flex;gap:8px;align-items:center;padding:5px 0;border-top:1px solid var(--line)">'+
        '<span style="flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">'+esc(x.b.name)+'</span>'+
        accessBadge(x.mask)+
        '<span style="color:var(--fg3);font-size:11.5px">'+esc(roleNames(x.mask).join("، "))+'</span>'+
        goLink(x.b)+'</div>';
    }).join("");
    return head + '<div style="padding:0 2px 10px">'+body+
      (r.list.length > 300 ? '<div class="empty">+'+nf(r.list.length-300)+' باتی دیگر</div>' : '')+'</div>';
  }).join("");
}

function renderAccess(list, q){
  var admins = ADMINS.map(function(id){
    return '<span class="mini">'+(isGroup(id)?'گروه · ':'')+esc(subjLabel(id))+'</span>';
  }).join("") || '<span class="mini">—</span>';

  var seg = [["bot","بر اساس باتی"],["person","بر اساس شخص"]].map(function(p){
    return '<button data-p="'+p[0]+'"'+(state.perm===p[0]?' class="on"':'')+'>'+p[1]+'</button>';
  }).join("");

  return '<div class="panel" style="margin-bottom:12px">'+
      '<div class="ph"><span class="dot" style="--c:var(--err)"></span><h2>مدیران ماژول باتی</h2>'+
      '<span class="sub">دسترسی کامل به همهٔ باتی‌ها، مستقل از جدول زیر</span></div>'+
      '<div style="padding:2px 0 4px">'+admins+'</div>'+
    '</div>'+
    '<div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">'+
      '<div class="seg" id="permSeg">'+seg+'</div>'+
      '<span class="count">'+(state.perm==="person"
        ? 'افراد از راه عضویت در گروه‌ها دسترسی می‌گیرند'
        : 'هر ردیف را باز کن تا گروه‌ها، سطح و افراد نهایی را ببینی')+'</span>'+
    '</div>'+
    '<div class="panel">'+
      (state.perm === "person" ? renderAccessByPerson(q) : renderAccessByBot(list))+
    '</div>';
}

/* ---------------------------------------------------------------- paint */
function paint(){
  var list = filtered(), q = state.q.trim().toLowerCase();
  var stage = document.getElementById("stage");
  var html = state.view==="table" ? renderTable(list,q)
           : state.view==="tree"  ? renderTree(list)
           : state.view==="perm"  ? renderAccess(list,q)
           : renderCards(list,q);
  if (state.view === "perm"){ stage.innerHTML = html; return; }
  stage.innerHTML =
    '<div style="display:flex;align-items:center;margin-bottom:10px">'+
      '<span class="count">'+ (list.length===BOTS.length
          ? (K.shown < K.total
              ? ('نمایش '+nf(BOTS.length)+' باتی پرکاربرد از '+nf(K.total)+' باتی ثبت‌شده')
              : ('نمایش همه '+nf(list.length)+' باتی'))
          : ('<b style="color:var(--fg)">'+nf(list.length)+'</b> از '+nf(BOTS.length)+' باتی'
             + (K.shown < K.total ? ' (از '+nf(K.total)+' ثبت‌شده)' : ''))) +'</span></div>' + html;
}

/* --------------------------------------------------------------- events */
document.getElementById("q").addEventListener("input", function(e){ state.q = e.target.value; paint(); });
document.getElementById("sort").addEventListener("change", function(e){ state.sort = e.target.value; state.sortCol=null; paint(); });
document.getElementById("views").addEventListener("click", function(e){
  var b = e.target.closest("button[data-v]"); if (!b) return;
  [].forEach.call(this.children, function(x){ x.classList.remove("on"); });
  b.classList.add("on"); state.view = b.dataset.v; paint();
});
/* access view: sub-tab switch and row expand — delegated, the stage is rebuilt */
document.getElementById("stage").addEventListener("click", function(e){
  var p = e.target.closest("#permSeg button[data-p]");
  if (p){ e.stopPropagation(); state.perm = p.dataset.p; state.openAcc = null; paint(); return; }
  var r = e.target.closest(".accrow[data-acc]");
  if (r && !e.target.closest("a[href]")){
    e.stopPropagation();          // keep the document handler from opening a drawer
    state.openAcc = (state.openAcc === r.dataset.acc) ? null : r.dataset.acc;
    paint();
  }
}, true);
document.getElementById("chips").addEventListener("click", function(e){
  var b = e.target.closest("button"); if (!b) return;
  if (b.dataset.flag){ state.flags[b.dataset.flag] = !state.flags[b.dataset.flag]; }
  else if (b.dataset.sec != null){ state.sec = Number(b.dataset.sec); }
  renderChips(); paint();
});
document.getElementById("rangeSeg").addEventListener("click", function(e){
  var b = e.target.closest("button"); if (!b) return;
  [].forEach.call(this.children, function(x){ x.classList.remove("on"); });
  b.classList.add("on"); range = Number(b.dataset.r); renderMain();
});
document.getElementById("feedSeg").addEventListener("click", function(e){
  var b = e.target.closest("button"); if (!b) return;
  [].forEach.call(this.children, function(x){ x.classList.remove("on"); });
  b.classList.add("on"); feedMode = b.dataset.f; renderFeed();
});
document.addEventListener("click", function(e){
  POP.classList.remove("on");                       // any click outside closes it
  // a real link wins over every delegated handler below
  if (e.target.closest("a[href]")) return;
  var cat = e.target.closest("[data-cat]");
  if (cat){ cat.parentNode.classList.toggle("open"); return; }
  var th = e.target.closest("th[data-col]");
  if (th){
    if (state.sortCol===th.dataset.col) state.sortDir = -state.sortDir;
    else { state.sortCol = th.dataset.col; state.sortDir = -1; }
    paint(); return;
  }
  var cp = e.target.closest("[data-copy]");
  if (cp){
    var txt = cp.dataset.copy, done = function(){
      var o = cp.textContent; cp.textContent = "کپی شد ✓";
      setTimeout(function(){ cp.textContent = o; }, 1400);
    };
    if (navigator.clipboard) navigator.clipboard.writeText(txt).then(done, done);
    else {
      var ta=document.createElement("textarea"); ta.value=txt; document.body.appendChild(ta);
      ta.select(); try{document.execCommand("copy");}catch(x){} document.body.removeChild(ta); done();
    }
    return;
  }
  var t = e.target.closest("[data-id]");
  if (t && !e.target.closest(".draw")) openBot(Number(t.dataset.id));
});
document.getElementById("dClose").addEventListener("click", closeDraw);
SCRIM.addEventListener("click", closeDraw);
document.addEventListener("keydown", function(e){
  if (e.key==="Escape"){ closeDraw(); return; }
  if (e.key==="/" && document.activeElement.id!=="q"){
    e.preventDefault(); document.getElementById("q").focus();
  }
});

/* ------------------------------------------------------- link patterns */
var POP = document.getElementById("pop");
function renderPop(){
  document.getElementById("popOpts").innerHTML = PAGE_PATTERNS.map(function(p){
    return '<label class="'+(p.k===pageKey?"on":"")+'" data-pat="'+p.k+'">'+
      '<input type="radio" name="bccpat" '+(p.k===pageKey?"checked":"")+'>'+
      '<code>'+esc(p.t)+'</code></label>';
  }).join("");
}
document.getElementById("gear").addEventListener("click", function(e){
  e.stopPropagation(); renderPop(); POP.classList.toggle("on");
});
POP.addEventListener("click", function(e){
  e.stopPropagation();
  var l = e.target.closest("[data-pat]"); if (!l) return;
  pageKey = l.dataset.pat;
  try { localStorage.setItem("bcc.page", pageKey); } catch(x){}
  renderPop(); paint(); renderFeed(); renderNewest();
  if (openId != null) openBot(openId);              // refresh the open drawer's links
});

/* ---------------------------------------------------------------- theme */
var TH = document.getElementById("theme");
function applyTheme(t){
  document.body.classList.toggle("lite", t==="lite");
  document.getElementById("themeTxt").textContent = t==="lite" ? "تاریک" : "روشن";
  try{ localStorage.setItem("bcc.theme", t); }catch(x){}
}
TH.addEventListener("click", function(){
  applyTheme(document.body.classList.contains("lite") ? "dark" : "lite");
});
try{ applyTheme(localStorage.getItem("bcc.theme")==="lite" ? "lite" : "dark"); }catch(x){ applyTheme("dark"); }

/* ----------------------------------------------------------------- clock */
var t0 = Date.now();
function tick(){
  var s = Math.floor((Date.now()-t0)/1000);
  document.getElementById("ck").textContent = D.genAt || "";
  document.getElementById("ckd").textContent = (D.genWd||"") + (s>60 ? " · داده " + ago(s) : " · هم‌اکنون");
}
setInterval(tick, 15000); tick();

/* ------------------------------------------------------------------ boot */
document.getElementById("brandMeta").textContent =
  (D.lic && D.lic.domain ? D.lic.domain : "TeamYar") +
  (D.me ? " · " + D.me : "") + " · " + nf(K.total) + " باتی" +
  (K.shown < K.total ? " (نمایش " + nf(K.shown) + ")" : "");
document.getElementById("foot").textContent =
  "داده‌ها از BOT_COMMAND و BOT_HISTORY · پنجره " + WIN + " روزه · ساخته‌شده در " + (D.genAt||"");

renderKpis(); renderMain(); renderHours(); renderKinds();
renderChips(); paint(); renderFeed(); renderNewest(); renderPop();
})();
</script>
</body>
</html>]==]

-- =====================================================================
--  entry
-- =====================================================================
local function main()
  local data = collect()
  local ok, encoded = pcall(json.encode, data)
  if not ok or type(encoded) ~= "string" then
    encoded = '{"bots":[],"days":[],"feed":[],"errors":[],"hours":[],"kinds":[],"sections":[],"kpi":{}}'
  end
  -- keep the JSON inert inside <script>: < > & become \u escapes
  encoded = encoded:gsub("<", "\\u003C"):gsub(">", "\\u003E"):gsub("&", "\\u0026")
  return HEAD .. encoded .. TAIL
end

local ok, page = pcall(main)
if not ok then
  teamyar.write_log("bot_command_center failed: " .. tostring(page))
  page = [==[<!DOCTYPE html><html lang="fa" dir="rtl"><head><meta charset="utf-8">
<title>مرکز فرماندهی باتی</title></head>
<body style="font-family:Tahoma,sans-serif;background:#0b1020;color:#e8edff;padding:40px;text-align:center">
<h1 style="font-size:20px">داشبورد در دسترس نیست</h1>
<p style="color:#8b97b8;font-size:13px">خطا در خواندن داده‌ها ثبت شد. لاگ باتی را ببینید.</p>
</body></html>]==]
end

teamyar.write_result(page)
