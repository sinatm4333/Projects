-- =========================================
-- Bot: SalesInvoice NOTE Mismatch
-- Fix: remove ALL whitespace + NBSP + ZWSP + ZWJ + WJ + BOM + bidi marks
-- Fix: Arabic Yeh variants -> Persian "ی" (DO NOT touch 'ئ')
-- Fix: نمایش ستون فاکتور = invoice_display (از DB تشخیص داده می‌شود)
-- Link همیشه با si.ID (row_id) ساخته می‌شود
-- UI: Status sort + Client/Invoice filters + CSV + Print
-- Developer: سینا تقوی مقدم
-- =========================================

local DB_NAME      = "0000000"
local BASE_URL_INV = "https://erp.bimehland.com/?page=/sales/invoice/view_invoice/"
local BASE_URL_CRM = "https://erp.bimehland.com/?page=/crm/history/show_sales/"
local DEV_NAME     = "سینا تقوی مقدم"
local REPORT_NAME  = "مغایرت‌گیری توضیحات با صاحب فاکتور"
local LIMIT        = 200000

-- -------------------------
-- Helpers
-- -------------------------
local function esc(s)
  if s == nil then return "" end
  s = tostring(s)
  s = s:gsub("&","&")
       :gsub("<","<")
       :gsub(">"," >")
       :gsub("\"","\"")
       :gsub("'","'")
  return s
end

local function run_fetch_all(sql)
  db.use_db(DB_NAME)
  local ok, err = pcall(function()
    db.query({ query = sql, params = {} })
  end)
  if not ok then
    return nil, "db.query error: " .. tostring(err), sql
  end

  local out = {}
  while true do
    local row = db.query_fetch()
    if row == nil then break end
    out[#out+1] = row
  end
  db.query_free()
  return out, nil, sql
end

local function first_cell(rows)
  if rows and rows[1] and rows[1][1] ~= nil then
    return tostring(rows[1][1])
  end
  return ""
end

-- -----------------------
-- Get report datetime (try multiple DB syntaxes)
-- -----------------------
local function get_report_date()
  local candidates = {
    "SELECT NOW()",
    "SELECT CURRENT_TIMESTAMP",
    "SELECT SYSDATE()",
    "SELECT GETDATE()",
    "SELECT CONVERT(VARCHAR,GETDATE(),120)",
    "SELECT to_char(current_timestamp,'YYYY-MM-DD HH24:MI:SS')",
  }
  for i=1,#candidates do
    local q = candidates[i]
    local rows, err = run_fetch_all(q)
    if err == nil then
      local v = first_cell(rows)
      if v ~= "" then return v end
    end
  end
  return ""
end

local REPORT_DATE = get_report_date()
local PRINT_USER  = DEV_NAME

-- -----------------------
-- Base where
-- -----------------------
local function base_where()
  return table.concat({ "si.DELETED = 0", "si.CLIENT_ID > 0" }, " AND ")
end

-- -----------------------
-- Status SQL
-- -----------------------
local function status_case_sql()
  return "CASE " ..
         "WHEN si.CANCELED = 1 THEN 'لغو شده' " ..
         "WHEN si.CLOSE_PRE = 1 AND si.CANCELED = 0 THEN 'کامل' " ..
         "WHEN (si.INVOICE_ID = 0 OR si.PRE_INVOICE = 1) AND si.CANCELED = 0 THEN 'پیش‌نویس' " ..
         "WHEN si.INVOICE_ID > 0 AND si.CANCELED = 0 THEN 'اجرا شده' " ..
         "ELSE 'نامشخص' END"
end

-- -----------------------
-- Lua Normalize (Yeh ONLY -> 'ی') + remove invisible chars
-- -----------------------
local function esc_pat(s)
  return (s:gsub("(%W)","%%%1"))
end

local function replace_list(s, list, to)
  if s == nil then return "" end
  s = tostring(s)
  for i=1,#list do
    local from = list[i]
    if from ~= nil and from ~= "" then
      s = s:gsub(esc_pat(from), to)
    end
  end
  return s
end

-- فقط ی‌های عربی (بدون 'ئ')
local AR_YEH = { "ی","ی","ﻱ","ﻲ","ﻳ","ﻴ","ﯼ","ﯽ","ﯾ","ﯿ" }

-- invisible chars
local ZWNJ = "‌"  -- U+200C
local TATWEEL = "ـ" -- U+0640
local LRM = "‎"   -- U+200E
local RLM = "‏"   -- U+200F
local ZWSP = "​"  -- U+200B
local ZWJ  = "‍"  -- U+200D
local WJ   = "⁠"  -- U+2060
local BOM  = "﻿"  -- U+FEFF

local function normalize_fa(s)
  if s == nil then return "" end
  s = tostring(s)

  s = s:gsub("%s+", "")                 -- all whitespace
  s = s:gsub(string.char(194,160), "")  -- NBSP (C2 A0)

  s = s:gsub(ZWNJ, "")
  s = s:gsub(TATWEEL, "")
  s = s:gsub(LRM, "")
  s = s:gsub(RLM, "")
  s = s:gsub(ZWSP, "")
  s = s:gsub(ZWJ, "")
  s = s:gsub(WJ, "")
  s = s:gsub(BOM, "")

  s = replace_list(s, AR_YEH, "ی")
  return s
end

local function note_has_client_name(note, client_name)
  local nn = normalize_fa(note)
  local nm = normalize_fa(client_name)
  if nm == "" then return true end
  return (nn:find(nm, 1, true) ~= nil)
end

-- -----------------------
-- Detect invoice display field (NO guessing, DB test)
-- -----------------------
local function detect_invoice_display_expr()
  -- candidates: try in this order, only if column exists and has meaningful values
  local cols = {
    "si.INVOICE_ID",
    "si.SERIAL",
    "si.SERIAL_NO",
    "si.SERIAL_NUMBER",
    "si.NUMBER",
    "si.NO",
    "si.INVOICE_NO",
    "si.FACTOR_NO",
    "si.DOCUMENT_NO",
    "si.DOC_NO"
  }

  local function is_meaningful(v)
    if v == nil then return false end
    local s = tostring(v)
    if s == "" then return false end
    local n = tonumber(s)
    if n ~= nil then
      if n <= 0 then return false end
      return true
    end
    -- اگر رشته‌ایه، حداقل 2 کاراکتر داشته باشه
    return (#s >= 2)
  end

  for i=1,#cols do
    local col = cols[i]
    local q =
      "SELECT " .. col .. " AS v " ..
      "FROM sales_invoice si " ..
      "WHERE si.DELETED = 0 " ..
      "ORDER BY si.ID DESC " ..
      "LIMIT 30"
    local rows, err = run_fetch_all(q)
    if err == nil and rows ~= nil then
      local ok_count = 0
      for r=1,#rows do
        local v = rows[r] and rows[r][1] or nil
        if is_meaningful(v) then ok_count = ok_count + 1 end
      end
      -- اگر حداقل چندتا مقدار معنی‌دار داشت، همین فیلد را انتخاب کن
      if ok_count >= 3 then
        -- invoice_display = COALESCE(NULLIF(col,0), si.ID) برای numeric ها
        return "COALESCE(NULLIF(" .. col .. ",0), si.ID)"
      end
    end
  end

  -- fallback: row id
  return "si.ID"
end

local INVOICE_DISPLAY_EXPR = detect_invoice_display_expr()

-- -----------------------
-- Counts
-- -----------------------
local function fetch_total_count()
  local sql = "SELECT COUNT(*) AS cnt FROM sales_invoice si WHERE " .. base_where()
  local r, e, s = run_fetch_all(sql)
  if e then return nil, e, s end
  return tonumber(first_cell(r) or 0) or 0, nil
end

-- -----------------------
-- Data candidates
-- -----------------------
local function fetch_candidates()
  local sql =
    "SELECT " ..
    "  si.ID AS row_id, " ..
    "  " .. INVOICE_DISPLAY_EXPR .. " AS invoice_display, " ..
    "  " .. status_case_sql() .. " AS invoice_status, " ..
    "  c.NAME AS client_name, " ..
    "  c.REFFERE_ID AS crm_id, " ..
    "  si.NOTE AS note " ..
    "FROM sales_invoice si " ..
    "JOIN pa_client c ON c.ID = si.CLIENT_ID " ..
    "WHERE " .. base_where() .. " " ..
    "ORDER BY si.ID DESC " ..
    "LIMIT " .. tostring(LIMIT)

  local raw, err, err_sql = run_fetch_all(sql)
  if err then return nil, err, err_sql end

  local out = {}
  for i=1,#raw do
    local r = raw[i]
    out[#out+1] = {
      row_id          = r[1],
      invoice_display = r[2],
      invoice_status  = r[3],
      client_name     = r[4],
      crm_id          = r[5],
      note            = r[6]
    }
  end
  return out, nil, sql
end

local total_all, terr, terr_sql = fetch_total_count()
if terr then
  teamyar.write_result("<div style='font-family:tahoma;direction:rtl;color:#c62828'>ERROR: " .. esc(terr) .. "</div><pre>" .. esc(terr_sql or "") .. "</pre>")
  return
end

local candidates, err, data_sql = fetch_candidates()
if err then
  teamyar.write_result("<div style='font-family:tahoma;direction:rtl;color:#c62828'>ERROR: " .. esc(err) .. "</div><pre>" .. esc(data_sql or "") .. "</pre>")
  return
end

-- -----------------------
-- Mismatch filter (in Lua)
-- -----------------------
local data = {}
local mismatch = 0
local checked = #candidates

for i=1,#candidates do
  local r = candidates[i]
  local note = r.note
  local name = r.client_name

  local is_mis = false
  if note == nil or tostring(note) == "" then
    is_mis = true
  else
    if not note_has_client_name(note, name) then
      is_mis = true
    end
  end

  if is_mis then
    mismatch = mismatch + 1
    data[#data+1] = r
  end
end

local ok_cnt = checked - mismatch
if ok_cnt < 0 then ok_cnt = 0 end

-- -----------------------
-- Table HTML (نمایش invoice_display، لینک با row_id)
-- -----------------------
local function build_table_html(rows)
  local h = ""
  h = h .. "<table id='resultTable' style='width:100%;border-collapse:collapse;font-family:tahoma;font-size:12px;direction:rtl'>"
  h = h .. "<thead><tr style='background:#f5f5f5'>"
  h = h .. "<th style='border:1px solid #ddd;padding:8px'>فاکتور</th>"
  h = h .. "<th id='thStatus' style='border:1px solid #ddd;padding:8px;cursor:pointer;user-select:none' title='برای سورت کلیک کنید'>"
        .. "وضعیت <span id='statusSortIcon' style='font-size:11px;color:#666'>⇅</span></th>"
  h = h .. "<th style='border:1px solid #ddd;padding:8px'>مشتری</th>"
  h = h .. "<th style='border:1px solid #ddd;padding:8px'>NOTE</th>"
  h = h .. "</tr></thead><tbody>"

  for i=1,#rows do
    local r = rows[i]
    local row_id = r.row_id
    local inv_link = BASE_URL_INV .. tostring(row_id or "")
    local inv_text = tostring(r.invoice_display or "")

    local crm_id_num = tonumber(r.crm_id or 0) or 0
    local client_cell = ""
    if crm_id_num > 0 then
      local crm_link = BASE_URL_CRM .. tostring(crm_id_num)
      client_cell =
        "<a href='" .. esc(crm_link) .. "' target='_blank' style='text-decoration:none;color:#0b63ce'>"
        .. esc(r.client_name) .. "</a>"
    else
      client_cell = esc(r.client_name)
    end

    local bg = (i % 2 == 0) and "#ffffff" or "#fafafa"

    h = h .. "<tr style='background:"..bg.."'>"
    h = h .. "<td style='border:1px solid #ddd;padding:6px;white-space:nowrap;direction:ltr;text-align:left'>"
          .. "<a href='" .. esc(inv_link) .. "' target='_blank' style='text-decoration:none;color:#0b63ce'>"
          .. esc(inv_text) .. "</a></td>"
    h = h .. "<td style='border:1px solid #ddd;padding:6px;white-space:nowrap'>" .. esc(r.invoice_status) .. "</td>"
    h = h .. "<td style='border:1px solid #ddd;padding:6px;white-space:nowrap'>" .. client_cell .. "</td>"
    h = h .. "<td style='border:1px solid #ddd;padding:6px;max-width:900px'>" .. esc(r.note) .. "</td>"
    h = h .. "</tr>"
  end

  h = h .. "</tbody></table>"
  return h
end

local i_text =
  "Developer: " .. DEV_NAME .. "\\n" ..
  "Report: " .. REPORT_NAME .. "\\n" ..
  "DB: " .. DB_NAME .. "\\n" ..
  "Report Date: " .. (REPORT_DATE ~= "" and REPORT_DATE or "(نامشخص)") .. "\\n" ..
  "Invoice display expr: " .. INVOICE_DISPLAY_EXPR .. "\\n" ..
  "Link: " .. BASE_URL_INV .. "{si.ID}\\n" ..
  "Normalize: حذف whitespace + NBSP + ZWSP/ZWJ/WJ/BOM + LRM/RLM + ZWNJ/کشیده + فقط ی‌های عربی→ی (بدون تغییر 'ئ')\\n" ..
  "Limit: " .. tostring(LIMIT)

-- -----------------------
-- UI
-- -----------------------
local ui = [[
<style>
.ty-icon-btn{
  width:44px;height:44px;border-radius:50%;
  background:#111;border:0;
  display:inline-flex;align-items:center;justify-content:center;
  cursor:pointer;
  box-shadow:0 2px 6px rgba(0,0,0,0.18);
  transition:transform .08s ease, background .08s ease;
}
.ty-icon-btn:hover{ transform:translateY(-1px); background:#000; }
.ty-icon-btn:active{ transform:translateY(0px); }
.ty-icon-btn svg{ width:22px;height:22px; fill:#fff; }
.ty-toolbar{ display:flex; align-items:center; gap:10px; flex-wrap:wrap; }
.ty-toolbar-right{ margin-right:auto; display:flex; gap:10px; align-items:center; flex-wrap:wrap; }

.ty-badge{
  padding:6px 10px;border:1px solid #ddd;border-radius:10px;font-size:12px;
}
.ty-badge.neutral{ background:#fafafa; }
.ty-badge.bad{ background:#fff5f5; border-color:#f3c6c6; }
.ty-badge.good{ background:#f5fff5; border-color:#c9efc9; }

.ty-filter{
  padding:8px 10px;border:1px solid #ccc;border-radius:10px;
  font-family:tahoma;font-size:12px; min-width:220px;
}
.ty-filter-wrap{ display:flex; gap:10px; flex-wrap:wrap; align-items:center; }

@media print{
  .no-print{ display:none !important; }
  .print-header{ display:block !important; }
}
.print-header{ display:none; margin:0 0 12px 0; font-family:tahoma; direction:rtl; }
.print-header .row{ display:flex; gap:18px; flex-wrap:wrap; font-size:12px; }
</style>

<script>
function printReport(){ window.print(); }

function downloadCSV(){
  const table=document.getElementById('resultTable');
  if(!table){ alert('جدول پیدا نشد'); return; }

  const rows=[];
  rows.push(['نام گزارش: {{REPORT_NAME}}']);
  rows.push(['تاریخ اخذ گزارش: {{REPORT_DATE}}']);
  rows.push(['تهیه/پرینت توسط: {{PRINT_USER}}']);
  rows.push([]);

  const ths=table.querySelectorAll('thead th');
  rows.push(Array.from(ths).map(th => `"${(th.innerText||'').trim().replace(/"/g,'""')}"`));

  table.querySelectorAll('tbody tr').forEach(tr=>{
    if(tr.style.display==='none') return;
    const tds=tr.querySelectorAll('td');
    const row=Array.from(tds).map(td=>{
      const a=td.querySelector('a');
      let v=a ? a.innerText : td.innerText;
      v=(v||'').replace(/\r?\n/g,' ').trim().replace(/"/g,'""');
      return `"${v}"`;
    });
    rows.push(row);
  });

  const csv="\ufeff"+rows.map(r=>r.join(",")).join("\n");
  const blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});
  const url=URL.createObjectURL(blob);
  const a=document.createElement('a');
  a.href=url;
  a.download='sales_invoice_note_mismatch.csv';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function normalizeFa(s){
  return (s||'')
    .replace(/\u00a0/g,'')       // NBSP
    .replace(/\s+/g,'')          // whitespace
    .replace(/\u200c/g,'')       // ZWNJ
    .replace(/\u200b/g,'')       // ZWSP
    .replace(/\u200d/g,'')       // ZWJ
    .replace(/\u2060/g,'')       // Word Joiner
    .replace(/\ufeff/g,'')       // BOM
    .replace(/\u200e/g,'')       // LRM
    .replace(/\u200f/g,'')       // RLM
    .replace(/ـ/g,'')            // Tatweel
    .replace(/[ییﻱﻲﻳﻴﯼﯽﯾﯿ]/g,'ی') // Yeh variants -> ی (بدون 'ئ')
    .trim()
    .toLowerCase();
}

let statusSortDir = 0;
function sortByStatus(){
  const table = document.getElementById('resultTable');
  if(!table) return;
  const tbody = table.querySelector('tbody');
  const rows = Array.from(tbody.querySelectorAll('tr'));
  statusSortDir = (statusSortDir === 1) ? -1 : 1;

  rows.sort((a,b)=>{
    const av = normalizeFa((a.cells[1] && a.cells[1].innerText) || '');
    const bv = normalizeFa((b.cells[1] && b.cells[1].innerText) || '');
    if(av < bv) return -1 * statusSortDir;
    if(av > bv) return  1 * statusSortDir;
    return 0;
  });

  rows.forEach(r => tbody.appendChild(r));
  const icon = document.getElementById('statusSortIcon');
  if(icon){ icon.innerText = (statusSortDir === 1) ? '▲' : '▼'; }
}

function applyFilters(){
  const table = document.getElementById('resultTable');
  if(!table) return;
  const invQ = normalizeFa((document.getElementById('fltInvoice')||{}).value || '');
  const cusQ = normalizeFa((document.getElementById('fltCustomer')||{}).value || '');

  let visible = 0;
  table.querySelectorAll('tbody tr').forEach(tr=>{
    const inv = normalizeFa((tr.cells[0] && tr.cells[0].innerText) || '');
    const cus = normalizeFa((tr.cells[2] && tr.cells[2].innerText) || '');
    const show = (invQ==='' || inv.indexOf(invQ)!==-1) && (cusQ==='' || cus.indexOf(cusQ)!==-1);
    tr.style.display = show ? '' : 'none';
    if(show) visible++;
  });

  const el = document.getElementById('visibleCount');
  if(el) el.innerText = String(visible);
}

function clearFilters(){
  const a=document.getElementById('fltInvoice'); if(a) a.value='';
  const b=document.getElementById('fltCustomer'); if(b) b.value='';
  applyFilters();
}

document.addEventListener('DOMContentLoaded', function(){
  const th = document.getElementById('thStatus');
  if(th) th.addEventListener('click', sortByStatus);

  const a = document.getElementById('fltInvoice');
  const b = document.getElementById('fltCustomer');
  if(a) a.addEventListener('input', applyFilters);
  if(b) b.addEventListener('input', applyFilters);

  applyFilters();
});
</script>

<div style="font-family:tahoma;direction:rtl;padding:12px">

  <div class="print-header">
    <div style="font-weight:700;font-size:14px;margin-bottom:6px;">{{REPORT_NAME}}</div>
    <div class="row">
      <div><b>تاریخ اخذ گزارش:</b> {{REPORT_DATE}}</div>
      <div><b>تهیه/پرینت توسط:</b> {{PRINT_USER}}</div>
      <div><b>تعداد رکورد:</b> {{ROWS_COUNT}}</div>
    </div>
    <hr style="border:0;border-top:1px solid #ddd;margin:10px 0">
  </div>

  <div class="ty-toolbar no-print" style="margin-bottom:10px;">
    <div style="font-weight:800;font-size:14px;">{{REPORT_NAME}}</div>

    <div class="ty-toolbar-right">
      <button class="ty-icon-btn" title="اطلاعات" onclick="alert('{{I_TEXT}}')">
        <svg viewBox="0 0 24 24"><path d="M11 10h2v8h-2v-8zm0-4h2v2h-2V6zm1 16C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16z"></path></svg>
      </button>

      <button class="ty-icon-btn" title="خروجی اکسل" onclick="downloadCSV()">
        <svg viewBox="0 0 24 24">
          <path d="M4 3h10l6 6v12H4V3zm10 1.5V9h4.5L14 4.5z"></path>
          <path d="M7.2 17.8l2.2-3.1-2.1-3h1.9l1.2 1.9 1.2-1.9h1.8l-2.1 3 2.2 3.1h-1.9l-1.3-2-1.3 2H7.2z"></path>
        </svg>
      </button>

      <button class="ty-icon-btn" title="پرینت" onclick="printReport()">
        <svg viewBox="0 0 24 24">
          <path d="M6 9V3h12v6H6zm10-2V5H8v2h8z"></path>
          <path d="M6 19v-4h12v4H6zm14-10H4a2 2 0 0 0-2 2v6h4v4h12v-4h4v-6a2 2 0 0 0-2-2zm-2 6H6v-2h12v2z"></path>
        </svg>
      </button>
    </div>
  </div>

  <div class="no-print" style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:12px;">
    <div class="ty-badge neutral"><b>تاریخ گزارش:</b> {{REPORT_DATE}}</div>
    <div class="ty-badge neutral"><b>تهیه کننده:</b> {{PRINT_USER}}</div>

    <div class="ty-badge neutral"><b>کل فاکتورهای سیستم:</b> {{ST_TOTAL_ALL}}</div>
    <div class="ty-badge neutral"><b>بررسی‌شده در این اجرا:</b> {{ST_CHECKED}}</div>

    <div class="ty-badge bad"><b>مغایرت‌ها (این اجرا):</b> {{ST_MISMATCH}}</div>
    <div class="ty-badge good"><b>سالم‌ها (این اجرا):</b> {{ST_OK}}</div>

     </div>

  <div class="no-print ty-filter-wrap" style="margin-bottom:12px;">
    <input id="fltInvoice" class="ty-filter" placeholder="فیلتر فاکتور (شماره نمایشی)" />
    <input id="fltCustomer" class="ty-filter" placeholder="فیلتر مشتری (نام/بخشی از نام)" />
    <button onclick="clearFilters()" style="padding:8px 12px;border-radius:10px;border:1px solid #bbb;background:#eee;cursor:pointer;font-weight:700">پاک کردن</button>
    <div style="font-size:12px;color:#666;">(برای سورت وضعیت روی ستون «وضعیت» کلیک کنید)</div>
  </div>

  <div style="overflow:auto;">
    {{TABLE_HTML}}
  </div>

</div>
]]

-- SAFE token replace (no % issues)
local function rep(token, value)
  value = value or ""
  ui = ui:gsub(token, function() return value end)
end

rep("{{REPORT_NAME}}", esc(REPORT_NAME))
rep("{{REPORT_DATE}}", esc(REPORT_DATE))
rep("{{PRINT_USER}}",  esc(PRINT_USER))
rep("{{ROWS_COUNT}}",  tostring(#data))
rep("{{TABLE_HTML}}",  build_table_html(data))
rep("{{I_TEXT}}",      esc(i_text))

rep("{{ST_TOTAL_ALL}}", tostring(total_all))
rep("{{ST_CHECKED}}",   tostring(checked))
rep("{{ST_MISMATCH}}",  tostring(mismatch))
rep("{{ST_OK}}",        tostring(ok_cnt))

teamyar.write_result(ui)
