-- =========================================
-- WH Product Search Bot (UI + API) - RUN ID: 443
-- Endpoint: /bot/run/443/wh_product_search
-- =========================================

local DEV_NAME     = "سینا تقوی مقدم"
local PRODUCT_INFO = "WH Product Search | جستجوی کالا بر اساس description (شناسه/کد سایت) + خروجی اکسل"
local DB_NAME      = "0000000"

local input = teamyar.get_input() or {}
local type_input = tonumber(input.type) or 0

-- =========================
-- Helpers
-- =========================
local function is_empty(x)
  return x == nil or x == json.null or tostring(x) == ""
end

local function escape_sql_string(s)
  return tostring(s):gsub("'", "''")
end

local function to_en_digits(s)
  local map = {
    ["۰"]="0",["۱"]="1",["۲"]="2",["۳"]="3",["۴"]="4",["۵"]="5",["۶"]="6",["۷"]="7",["۸"]="8",["۹"]="9",
    ["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9"
  }
  return (tostring(s):gsub("[۰-۹٠-٩]", map))
end

local function esc_html(s)
  if s == nil then return "" end
  s = tostring(s)
  s = s:gsub("&","&amp;")
       :gsub("<","&lt;")
       :gsub(">","&gt;")
       :gsub('"',"&quot;")
       :gsub("'","&#39;")
  return s
end

teamyar.write_log("=== WH_PRODUCT_SEARCH START ===")
teamyar.write_log("type_input=" .. tostring(type_input))
teamyar.write_log("raw_input=" .. json.encode(input))

-- =========================
-- API: Search (type=1)
-- =========================
if type_input == 1 then
  teamyar.write_log("[API] Search request")

  db.use_db(DB_NAME)

  local description = input.description
  local limit = tonumber(input.limit) or 50
  if limit < 1 then limit = 1 end
  if limit > 5000 then limit = 5000 end

  teamyar.write_log("[API] description(raw)=" .. json.encode(description))
  teamyar.write_log("[API] limit=" .. tostring(limit))

  if is_empty(description) then
    teamyar.write_log("[API][ERR] description empty")
    teamyar.write_result(json.encode({ ok=false, message="شناسه سایت خالی است", count=0, items={} }))
    return
  end

  description = to_en_digits(description)
  description = tostring(description):gsub("^%s+", ""):gsub("%s+$", "")
  local q = escape_sql_string(description)

  local sqlquery =
    "select id, code, full_code, full_name, description " ..
    "from wh_product " ..
    "where description like '%" .. q .. "%' " ..
    "order by id desc " ..
    "limit " .. tostring(limit)

  teamyar.write_log("[SQL] " .. sqlquery)

  db.query({ query = sqlquery, params = {} })

  local items = {}
  local record = {}
  local n = 0
  while db.query_fetch(record) do
    n = n + 1
    if n <= 3 then
      teamyar.write_log("[DB] row#" .. tostring(n) .. "=" .. json.encode(record))
    end

    table.insert(items, {
      id = record[1],
      code = record[2] and tostring(record[2]) or "",
      full_code = record[3] and tostring(record[3]) or "",
      full_name = record[4] and tostring(record[4]) or "",
      description = record[5] and tostring(record[5]) or ""
    })
  end

  db.query_free()

  teamyar.write_log("[API] rows=" .. tostring(#items))
  teamyar.write_log("=== WH_PRODUCT_SEARCH END(API) ===")

  teamyar.write_result(json.encode({
    ok = true,
    q = description,
    count = #items,
    items = items
  }))
  return
end

-- =========================
-- UI: type=0
-- =========================
teamyar.write_log("[UI] returning UI html")

local userinfo = teamyar.get_user_info()
local lang = "English"
if userinfo and userinfo.lang_id == 4 then
  lang = "Persian"
end

-- UI (self-contained): Search + Table + Excel + i
local res_data = [[
<div style="font-family:tahoma;direction:rtl;padding:12px">
  <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:10px">
    <div style="font-weight:800;font-size:15px">جستجوی کالا (انبار)</div>

    <button onclick="__wh_showInfo()" title="info"
      style="margin-right:auto;width:28px;height:28px;border-radius:50%;border:1px solid #999;background:#f6f6f6;cursor:pointer;font-weight:800">i</button>
  </div>

  <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-bottom:10px">
    <label style="font-size:12px">شناسه/کد سایت (description):</label>
    <input id="wh_desc" type="text" placeholder="مثال: 137317 یا 222731"
      style="padding:8px 10px;border:1px solid #ccc;border-radius:10px;min-width:260px;direction:ltr;text-align:left" />

    <label style="font-size:12px">Limit:</label>
    <input id="wh_limit" type="number" value="50" min="1" max="5000"
      style="padding:8px 10px;border:1px solid #ccc;border-radius:10px;width:110px;direction:ltr;text-align:left" />

    <button onclick="__wh_run()"
      style="padding:8px 12px;border-radius:10px;border:1px solid #bbb;background:#eee;cursor:pointer;font-weight:800">جستجو</button>

    <button onclick="__wh_downloadXLSX()"
      style="padding:8px 12px;border-radius:10px;border:1px solid #bbb;background:#f6f6f6;cursor:pointer;font-weight:800">دانلود اکسل</button>

    <span style="font-size:12px;margin-right:10px">تعداد: <b id="wh_count">0</b></span>
  </div>

  <div id="wh_msg" style="font-size:12px;color:#c62828;margin:6px 0;"></div>

  <div style="overflow:auto;border:1px solid #e5e5e5;border-radius:12px">
    <table id="wh_table" style="border-collapse:collapse;width:100%;font-size:12px">
      <thead>
        <tr style="background:#f5f5f5">
          <th style="border-bottom:1px solid #ddd;padding:8px">ID</th>
          <th style="border-bottom:1px solid #ddd;padding:8px">کد</th>
          <th style="border-bottom:1px solid #ddd;padding:8px">کد کامل</th>
          <th style="border-bottom:1px solid #ddd;padding:8px">نام کامل</th>
          <th style="border-bottom:1px solid #ddd;padding:8px">توضیحات</th>
        </tr>
      </thead>
      <tbody id="wh_tbody">
      </tbody>
    </table>
  </div>
</div>

<script src="/bot/run/443/wh_product_search/]]..lang..[[.js?v=1"></script>
<script src="/bot/run/443/wh_product_search/xlsx.full.min.js?v=1"></script>

<link href="/bot/run/443/wh_product_search/main.css?v=2" rel="stylesheet" />

<script>
(function(){
  // ---- Config
  const DEV_NAME = "]]..esc_html(DEV_NAME)..[[";
  const PRODUCT_INFO = "]]..esc_html(PRODUCT_INFO)..[[";
  const ENDPOINT = window.location.href.split('?')[0];

  // ---- State
  window.__wh_last_items = [];

  // ---- Helpers
  function setMsg(t, isErr){
    const el = document.getElementById('wh_msg');
    el.style.color = isErr ? '#c62828' : '#2e7d32';
    el.textContent = t || '';
  }
  function esc(s){
    if(s === null || s === undefined) return '';
    return String(s)
      .replaceAll('&','&amp;')
      .replaceAll('<','&lt;')
      .replaceAll('>','&gt;')
      .replaceAll('"','&quot;')
      .replaceAll("'","&#39;");
  }

  // ---- Info
  window.__wh_showInfo = function(){
    alert("توسعه‌دهنده: " + DEV_NAME + "\\n" + PRODUCT_INFO + "\\n" + "RUN: 443 | Bot: wh_product_search");
  };

  // ---- Render
  function render(items){
    window.__wh_last_items = items || [];
    document.getElementById('wh_count').textContent = String(window.__wh_last_items.length);

    const tb = document.getElementById('wh_tbody');
    tb.innerHTML = "";

    window.__wh_last_items.forEach((it, idx) => {
      const bg = (idx % 2 === 0) ? '#fff' : '#fafafa';
      const tr = document.createElement('tr');
      tr.style.background = bg;

      tr.innerHTML = `
        <td style="border-bottom:1px solid #eee;padding:8px;direction:ltr;text-align:left">${esc(it.id)}</td>
        <td style="border-bottom:1px solid #eee;padding:8px;direction:ltr;text-align:left">${esc(it.code)}</td>
        <td style="border-bottom:1px solid #eee;padding:8px;direction:ltr;text-align:left">${esc(it.full_code)}</td>
        <td style="border-bottom:1px solid #eee;padding:8px">${esc(it.full_name)}</td>
        <td style="border-bottom:1px solid #eee;padding:8px">${esc(it.description)}</td>
      `;
      tb.appendChild(tr);
    });
  }

  // ---- Run
  window.__wh_run = async function(){
    const desc = (document.getElementById('wh_desc').value || '').trim();
    const limit = Number(document.getElementById('wh_limit').value || 50);

    if(!desc){
      setMsg("شناسه/کد سایت را وارد کنید.", true);
      render([]);
      return;
    }

    setMsg("در حال جستجو ...", false);

    try{
      const resp = await fetch(ENDPOINT, {
        method: "POST",
        headers: {"Content-Type":"application/json;charset=utf-8"},
        body: JSON.stringify({type: 1, description: desc, limit: limit})
      });

      const txt = await resp.text();
      let data;
      try { data = JSON.parse(txt); } catch(e){ data = null; }

      if(!data || data.ok !== true){
        const msg = (data && (data.message || data.error)) ? (data.message || data.error) : "پاسخ معتبر نیست";
        setMsg(msg, true);
        render([]);
        return;
      }

      setMsg("انجام شد.", false);
      render(data.items || []);
    }catch(err){
      setMsg("خطا در ارتباط: " + (err && err.message ? err.message : String(err)), true);
      render([]);
    }
  };

  // ---- Excel Export (XLSX)
  window.__wh_downloadXLSX = function(){
    const items = window.__wh_last_items || [];
    if(!items.length){
      alert("دیتایی برای خروجی وجود ندارد.");
      return;
    }
    if(typeof XLSX === "undefined"){
      alert("کتابخانه XLSX لود نشده است.");
      return;
    }

    const rows = items.map(it => ({
      ID: it.id,
      CODE: it.code,
      FULL_CODE: it.full_code,
      FULL_NAME: it.full_name,
      DESCRIPTION: it.description
    }));

    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Products");

    const filename = "wh_product_search.xlsx";
    XLSX.writeFile(wb, filename);
  };

})();
</script>
]]

teamyar.write_result(res_data)
teamyar.write_log("=== WH_PRODUCT_SEARCH END(UI) ===")
