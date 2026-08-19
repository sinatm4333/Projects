-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- آنالیز مراحل اقدام های باز: فقط اقدام‌هایی که هنوز بسته نشده‌اند
-- (نه با پایان موفق و نه با پایان ناموفق) — یعنی T_REAL_END_DATE خالی/صفر است.

local function escape_html(value)
    if value == nil then return "" end
    local amp_entity = string.char(38) .. "amp;"
    local lt_entity = string.char(38) .. "lt;"
    local gt_entity = string.char(38) .. "gt;"
    local quot_entity = string.char(38) .. "quot;"
    return tostring(value)
        :gsub("&", amp_entity)
        :gsub("<", lt_entity)
        :gsub(">", gt_entity)
        :gsub('"', quot_entity)
end

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
    if diff == nil or diff < 0 then
        return nil
    end

    local total_sec = math.floor(diff / 10000000)
    local days = math.floor(total_sec / 86400)
    local hours = math.floor((total_sec % 86400) / 3600)
    local mins = math.floor((total_sec % 3600) / 60)
    local secs = total_sec % 60

    local parts = {}
    if days > 0 then
        table.insert(parts, days .. " روز")
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

local function step_active_start_ts(step)
    if step.status_code == 0 and step.date_modify_raw > step.date_create_raw then
        return step.date_modify_raw
    end
    return step.date_create_raw
end

local function step_workflow_sort_key(step)
    return step_active_start_ts(step)
end

-- مرحله جاری هر اقدام: اولین مرحله در وضعیت «پیش نویس» بر اساس ترتیب شروع
local function pick_current_step(steps)
    table.sort(steps, function(a, b)
        local ka = step_workflow_sort_key(a)
        local kb = step_workflow_sort_key(b)
        if ka == kb then
            return (a.step_row_id or 0) < (b.step_row_id or 0)
        end
        return ka < kb
    end)

    local current = nil
    for _, step in ipairs(steps) do
        if step.status_code == 0 then
            current = step
            break
        end
    end
    return current
end

local function record_to_step(record)
    return {
        task_id = record[1],
        profile_main_id = record[2],
        profile_main_fullname = record[3],
        task_title = record[4],
        t_start_date = record[5],
        t_return_date = record[6],
        step_name = record[9],
        sla_duration = tonumber(record[10]) or 0,
        sla_unit_label = record[11],
        sla_raw = tonumber(record[12]) or 0,
        DATE_MODIFY = record[15],
        DATE_CREATE = record[16],
        status = record[17],
        unit_name = record[19],
        wf_title = record[22],
        step_row_id = record[24],
        date_create_raw = tonumber(record[25]) or 0,
        date_modify_raw = tonumber(record[26]) or 0,
        status_code = tonumber(record[27]) or 0
    }
end

local param = {
    query = [[
WITH
LatestOrder AS (
    SELECT
        hpo.*,
        ROW_NUMBER() OVER (
            PARTITION BY hpo.personnel_id
            ORDER BY hpo.DATE_FROM DESC, hpo.DATE_TO DESC
        ) AS rn
    FROM HR_PERSONNEL_ORDER hpo
),

UnitIdToSingleOrgUnit AS (
    SELECT
        oou.UNIT_ID,
        MIN(oou.id) AS oou_id
    FROM org_organization_unit oou
    GROUP BY oou.UNIT_ID
),

PersonnelInfo AS (
    SELECT
        pm.id               AS personnel_profile_id,
        oouA.id             AS oou_id_A,
        ouA.name            AS unit_name_A,
        ouB.id              AS ou_id_B,
        ouB.name            AS unit_name_B,
        oouB.oou_id         AS oou_id_B,
        oouP.id             AS oou_id_P,
        ouP.name            AS unit_name_P,
        COALESCE(oouA.id, oouB.oou_id, oouP.id) AS unit_org_unit_id,
        COALESCE(ouA.name, ouB.name, ouP.name, 'بدون واحد') AS unit_name
    FROM PROFILE_MAIN pm
    JOIN PROFILE_USER_INFO pu
        ON pu.id = pm.id
    JOIN HR_PERSONNELS hp
        ON hp.PROFILE_ID = pm.ID
    LEFT JOIN LatestOrder hpo
        ON hpo.personnel_id = hp.personnel_id
       AND hpo.rn = 1
    LEFT JOIN org_organization_unit oouA
        ON oouA.id = hpo.unit_id
    LEFT JOIN org_units ouA
        ON ouA.id = oouA.UNIT_ID
    LEFT JOIN org_units ouB
        ON ouB.id = hpo.unit_id
    LEFT JOIN UnitIdToSingleOrgUnit oouB
        ON oouB.UNIT_ID = ouB.id
    LEFT JOIN org_organization_unit oouP
        ON oouP.id = hp.org_id
    LEFT JOIN org_units ouP
        ON ouP.id = oouP.UNIT_ID
)

SELECT
    tts.task_id,
    pm.id AS profile_main_id,
    pm.fullname AS profile_main_fullname,
    tt.task_title,
    ]] .. fmt_jalali_datetime("tt.t_start_date") .. [[ AS t_start_date,
    ]] .. fmt_jalali_datetime("tt.t_return_date") .. [[ AS t_return_date,
    NULL, NULL,
    ts.step_name,
    ts.duration AS sla_duration,
    CASE
        WHEN ts.time_unit = 1 THEN 'دقیقه'
        WHEN ts.time_unit = 2 THEN 'ساعت'
        WHEN ts.time_unit = 3 THEN 'روز'
        ELSE 'ندارد'
    END AS sla_unit_label,
    CAST(
        CASE
            WHEN ts.duration IS NULL OR ts.duration <= 0 THEN 0
            WHEN ts.time_unit = 1 THEN ts.duration * 60 * 10000000
            WHEN ts.time_unit = 2 THEN ts.duration * 60 * 60 * 10000000
            WHEN ts.time_unit = 3 THEN ts.duration * 24 * 60 * 60 * 10000000
            ELSE 0
        END AS CHAR
    ) AS sla_raw,
    ts.time_unit,
    NULL,
    ]] .. fmt_jalali_datetime("tts.DATE_MODIFY") .. [[ AS DATE_MODIFY,
    ]] .. fmt_jalali_datetime("tts.DATE_CREATE") .. [[ AS DATE_CREATE,
    CASE
        WHEN tts.STATUS = 0 THEN 'پیش نویس'
        WHEN tts.STATUS = 1 THEN 'تایید شده'
        WHEN tts.STATUS = 2 THEN 'کامل شده'
        WHEN tts.STATUS = 3 THEN 'رد شده'
        ELSE 'نامشخص'
    END AS STATUS,
    NULL,
    pi.unit_name AS unit_name,
    NULL,
    NULL,
    tw.wf_title AS wf_title,
    NULL,
    tts.id AS step_row_id,
    tts.DATE_CREATE AS date_create_raw,
    tts.DATE_MODIFY AS date_modify_raw,
    tts.STATUS AS status_code,
    (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS now_raw
FROM todo_task_steps tts
JOIN profile_main pm
    ON pm.id = tts.RESPONSIBLE_ID
JOIN todo_task tt
    ON tt.id = tts.TASK_ID
JOIN todo_step ts
    ON ts.id = tts.STEP_ID
LEFT JOIN TODO_WORKFLOW tw
    ON tw.id = ts.wf_id
LEFT JOIN PersonnelInfo pi
    ON pi.personnel_profile_id = pm.id
WHERE (tt.t_real_end_date IS NULL OR tt.t_real_end_date = 0)
  AND EXISTS (
        SELECT 1
        FROM todo_task_steps tts_open
        WHERE tts_open.TASK_ID = tt.id
          AND tts_open.STATUS = 0
    )
ORDER BY tt.id, tts.id
    ]],
    params = {}
}

local tasks_map = {}
local task_ids = {}
local now_raw = 0

local ok, query_err = pcall(function()
    db.query(param)
end)

if not ok then
    teamyar.write_result(
        '<!DOCTYPE html><html dir="rtl" lang="fa"><head><meta charset="UTF-8"></head>' ..
        '<body style="font-family:Tahoma;font-size:14px;padding:20px;">خطا در اجرای پرس‌وجو: ' ..
        escape_html(tostring(query_err)) .. '</body></html>'
    )
    return
end

local record = {}
while db.query_fetch(record) do
    if now_raw == 0 then
        now_raw = tonumber(record[28]) or 0
    end

    local task_id = tonumber(record[1]) or record[1]
    if tasks_map[task_id] == nil then
        tasks_map[task_id] = {
            task_id = task_id,
            task_title = record[4],
            t_start_date = record[5],
            t_return_date = record[6],
            steps = {}
        }
        table.insert(task_ids, task_id)
    end

    table.insert(tasks_map[task_id].steps, record_to_step(record))
end
db.query_free()

local actions = {}
local workflow_totals = {}
local breached_count = 0
local within_sla_count = 0
local no_sla_count = 0

for _, task_id in ipairs(task_ids) do
    local task = tasks_map[task_id]
    local current_step = pick_current_step(task.steps)

    local elapsed_raw = 0
    local elapsed_label = nil
    if current_step ~= nil and now_raw > 0 then
        local start_ts = step_active_start_ts(current_step)
        if start_ts and start_ts > 0 then
            elapsed_raw = now_raw - start_ts
            elapsed_label = format_duration(elapsed_raw)
        end
    end

    -- SLA مرحله جاری: مهلت تعریف‌شده در گردش‌کار (todo_step.duration + time_unit)
    -- مرحله‌ای که مهلت ندارد قابل قضاوت نیست و با «—» علامت می‌خورد
    local sla_raw = (current_step and current_step.sla_raw) or 0
    local sla_label = '—'
    local sla_breached = false
    local sla_flag_label = '—'
    local overdue_label = '—'

    if sla_raw > 0 then
        sla_label = tostring(current_step.sla_duration) .. ' ' .. tostring(current_step.sla_unit_label)
        sla_breached = elapsed_raw > sla_raw
        sla_flag_label = sla_breached and 'بله' or 'خیر'
        if sla_breached then
            overdue_label = format_duration(elapsed_raw - sla_raw) or '—'
        else
            within_sla_count = within_sla_count + 1
        end
    else
        no_sla_count = no_sla_count + 1
    end

    local workflow_name = (current_step and current_step.wf_title) or 'بدون جریان'
    workflow_totals[workflow_name] = (workflow_totals[workflow_name] or 0) + 1
    if sla_breached then
        breached_count = breached_count + 1
    end

    table.insert(actions, {
        task_id = task.task_id,
        task_title = task.task_title,
        t_start_date = task.t_start_date,
        t_return_date = task.t_return_date,
        step_count = #task.steps,
        workflow_name = workflow_name,
        current_step_name = current_step and current_step.step_name or '—',
        current_step_status = current_step and current_step.status or 'نامشخص',
        current_responsible = current_step and current_step.profile_main_fullname or '—',
        current_unit = current_step and current_step.unit_name or '—',
        current_step_since = current_step and current_step.DATE_CREATE or '—',
        elapsed_label = elapsed_label or '—',
        sla_label = sla_label,
        sla_flag_label = sla_flag_label,
        sla_breached = sla_breached,
        overdue_label = overdue_label
    })
end

if #actions == 0 then
    teamyar.write_result(
        '<!DOCTYPE html><html dir="rtl" lang="fa"><head><meta charset="UTF-8"></head>' ..
        '<body style="font-family:Tahoma;font-size:14px;padding:20px;text-align:center;">هیچ اقدام بازی یافت نشد</body></html>'
    )
    return
end

-- ── HTML خروجی ──────────────────────────────────────────────────────────

local REPORT_CSS = [[
<style>
@font-face {
    font-family: "EghdamBazReport";
    src: local("Yekan Bakh"), local("YekanBakh"), local("IRANSans");
    font-weight: 400; font-style: normal; font-display: swap;
}
* { font-family: "EghdamBazReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
body { margin: 0; padding: 12px; font-size: 14px; background: #f5f5f5; color: #000; }
#reportRoot:fullscreen { background: #f5f5f5; padding: 12px; overflow: auto; }
.toolbar { display: flex; justify-content: flex-end; gap: 8px; margin-bottom: 10px; flex-wrap: wrap; }
.btn-toolbar { background: #16509D; color: #fff; border: none; border-radius: 8px; padding: 8px 16px; font-family: inherit; font-size: 14px; font-weight: bold; cursor: pointer; }
.btn-toolbar:hover { filter: brightness(0.9); }
.report-header { background: #fff; text-align: center; border: 2px solid #16509D; border-radius: 12px; padding: 16px 12px 20px; margin-bottom: 14px; }
.report-header h2 { margin: 0 0 6px; font-size: 15px; font-weight: bold; color: #16509D; }
.report-header p { margin: 3px 0; font-size: 14px; color: #555; }
.summary-strip { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 14px; }
.summary-card { flex: 1 1 180px; background: #fff; border: 1px solid #ccc; border-radius: 10px; padding: 10px 12px; text-align: center; }
.summary-card .s-label { font-size: 15px; font-weight: bold; color: #555; }
.summary-card .s-value { font-size: 14px; font-weight: bold; color: #000; margin-top: 4px; }
.dist-table { width: 100%; border-collapse: collapse; text-align: center; }
.dist-table thead th { position: sticky; top: 0; background: #16509D; color: #fff; border: 1px solid #fff; padding: 8px; font-size: 15px; font-weight: bold; }
.dist-table tbody td { border: 1px solid #ccc; padding: 6px 8px; font-size: 14px; color: #000; }
.dist-table tbody tr:nth-child(even) { background: #f5f5f5; }
.summary-card.alert { border-color: #16509D; }
.summary-card.alert .s-value { color: #16509D; }
.table-wrap { overflow: auto; border: 2px solid #000; border-radius: 8px; background: #fff; }
table.main-table { width: auto; table-layout: auto; border-collapse: collapse; text-align: center; }
table.main-table thead th { position: sticky; top: 0; z-index: 2; background: #16509D; color: #fff; border: 1px solid #fff; padding: 10px 8px; font-size: 15px; font-weight: bold; white-space: nowrap; width: 1%; cursor: pointer; user-select: none; }
table.main-table thead th.sort-asc::after { content: ' ▲'; }
table.main-table thead th.sort-desc::after { content: ' ▼'; }
table.main-table tbody td { border: 1px solid #ccc; padding: 8px; font-size: 14px; vertical-align: middle; white-space: nowrap; width: 1%; color: #000; }
table.main-table tbody tr:nth-child(even) { background: #f5f5f5; }
table.main-table tbody tr:hover { background: #eee; }
table.main-table tbody tr.over-sla,
table.main-table tbody tr.over-sla:nth-child(even) { background: #fff !important; }
table.main-table tbody tr.over-sla td { color: #16509D !important; font-weight: bold; border-color: #16509D !important; }
table.main-table tbody tr.over-sla:hover { background: #fdf0f6 !important; }
.sla-badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 14px; font-weight: bold; white-space: nowrap; }
.sla-yes { background: #16509D; color: #fff; }
.sla-no { background: #eee; color: #000; }
.sla-na { background: #fff; color: #888; border: 1px solid #ccc; }
.name-cell { text-align: right; font-weight: bold; }
.status-badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 14px; font-weight: bold; white-space: nowrap; background: #eee; color: #000; }
.footer { text-align: center; color: #888; font-size: 14px; margin-top: 12px; }
.modal { display: none; position: fixed; z-index: 1000; inset: 0; background: rgba(0,0,0,0.45); }
.modal.active { display: flex; align-items: center; justify-content: center; }
.modal-content { background: #fff; padding: 0; border-radius: 10px; width: 92%; max-width: 640px; max-height: 82vh; overflow-y: auto; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; background: #16509D; color: #fff; border-radius: 10px 10px 0 0; position: sticky; top: 0; }
.modal-header h3 { margin: 0; font-size: 15px; font-weight: bold; }
.modal-close { background: none; border: none; font-size: 20px; cursor: pointer; color: #fff; }
.modal-body { padding: 16px; font-size: 14px; line-height: 1.8; text-align: right; }
.modal-body h4 { font-size: 15px; font-weight: bold; margin: 10px 0 6px; }
.modal-body ul { margin: 8px 0; padding-right: 20px; }
.modal-body li { margin: 6px 0; font-size: 14px; }
</style>
]]

local REPORT_JS = [[
<script>
function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    if (!isFull) {
        if (root.requestFullscreen) root.requestFullscreen();
        else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen();
        else if (root.msRequestFullscreen) root.msRequestFullscreen();
    } else {
        if (document.exitFullscreen) document.exitFullscreen();
        else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
        else if (document.msExitFullscreen) document.msExitFullscreen();
    }
}
function openHelp() { document.getElementById('helpModal').classList.add('active'); }
function closeHelp() { document.getElementById('helpModal').classList.remove('active'); }
function openWorkflows() { document.getElementById('workflowModal').classList.add('active'); }
function closeWorkflows() { document.getElementById('workflowModal').classList.remove('active'); }
window.onclick = function (event) {
    if (event.target === document.getElementById('helpModal')) closeHelp();
    if (event.target === document.getElementById('workflowModal')) closeWorkflows();
};
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { closeHelp(); closeWorkflows(); }
});

function csvCell(t) {
    t = (t == null ? '' : String(t)).replace(/\s+/g, ' ').trim();
    if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1 || t.indexOf('\n') !== -1) t = '"' + t.replace(/"/g, '""') + '"';
    return t;
}
function downloadCsv(lines, fileName) {
    var blob = new Blob(['﻿' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
    var url = URL.createObjectURL(blob);
    var link = document.createElement('a');
    link.href = url; link.download = fileName;
    document.body.appendChild(link); link.click(); document.body.removeChild(link);
    URL.revokeObjectURL(url);
}
function exportToExcel() {
    var table = document.querySelector('.table-wrap table');
    if (!table) return;
    var lines = [];
    var heads = table.querySelectorAll('thead th');
    var hl = [];
    for (var h = 0; h < heads.length; h++) hl.push(csvCell(heads[h].innerText));
    lines.push(hl.join(','));
    var rows = table.querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
        if (rows[i].querySelector('td.empty-row')) continue;
        var cells = rows[i].querySelectorAll('td');
        var line = [];
        for (var c = 0; c < cells.length; c++) line.push(csvCell(cells[c].innerText));
        lines.push(line.join(','));
    }
    downloadCsv(lines, 'اقدام-های-باز.csv');
}

function getCellSortValue(cell) {
    var text = cell ? cell.innerText.trim() : '';
    var n = text.replace(/[,٪%]/g, '').trim();
    if (n !== '' && /^-?\d+(\.\d+)?$/.test(n)) return parseFloat(n);
    return text;
}
function sortTableByColumn(table, colIndex, dir) {
    var tbody = table.querySelector('tbody');
    var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
    rows.sort(function (ra, rb) {
        var a = getCellSortValue(ra.children[colIndex]), b = getCellSortValue(rb.children[colIndex]), cmp;
        if (typeof a === 'number' && typeof b === 'number') cmp = a - b;
        else cmp = String(a).localeCompare(String(b), 'fa');
        return dir === 'asc' ? cmp : -cmp;
    });
    rows.forEach(function (row) { tbody.appendChild(row); });
}
function initSortableTables() {
    document.querySelectorAll('table.main-table').forEach(function (table) {
        var headers = table.querySelectorAll('thead th');
        headers.forEach(function (th, colIndex) {
            th.addEventListener('click', function () {
                var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
                headers.forEach(function (h) { h.classList.remove('sort-asc', 'sort-desc'); });
                th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
                sortTableByColumn(table, colIndex, dir);
            });
        });
    });
}
initSortableTables();
</script>
]]

-- ردیف‌های فراتر از SLA بالای جدول می‌آیند تا بدون مرتب‌سازی هم دیده شوند
table.sort(actions, function(a, b)
    if a.sla_breached ~= b.sla_breached then
        return a.sla_breached
    end
    return (a.task_id or 0) > (b.task_id or 0)
end)

local rows_html = {}
for i, a in ipairs(actions) do
    local sla_badge_class = 'sla-na'
    if a.sla_flag_label == 'بله' then
        sla_badge_class = 'sla-yes'
    elseif a.sla_flag_label == 'خیر' then
        sla_badge_class = 'sla-no'
    end

    local row = '<tr' .. (a.sla_breached and ' class="over-sla"' or '') .. '>'
        .. '<td>' .. tostring(i) .. '</td>'
        .. '<td>' .. tostring(a.task_id) .. '</td>'
        .. '<td class="name-cell">' .. escape_html(a.task_title) .. '</td>'
        .. '<td>' .. escape_html(a.workflow_name) .. '</td>'
        .. '<td>' .. escape_html(a.current_step_name) .. '</td>'
        .. '<td><span class="status-badge">' .. escape_html(a.current_step_status) .. '</span></td>'
        .. '<td>' .. escape_html(a.current_responsible) .. '</td>'
        .. '<td>' .. escape_html(a.current_unit) .. '</td>'
        .. '<td>' .. escape_html(a.current_step_since) .. '</td>'
        .. '<td>' .. escape_html(a.elapsed_label) .. '</td>'
        .. '<td>' .. escape_html(a.sla_label) .. '</td>'
        .. '<td><span class="sla-badge ' .. sla_badge_class .. '">' .. escape_html(a.sla_flag_label) .. '</span></td>'
        .. '<td>' .. escape_html(a.overdue_label) .. '</td>'
        .. '<td>' .. tostring(a.step_count) .. '</td>'
        .. '</tr>'
    table.insert(rows_html, row)
end
local rows_joined = table.concat(rows_html, "\n")

local workflow_summary_parts = {}
for wf_name, count in pairs(workflow_totals) do
    table.insert(workflow_summary_parts, { name = wf_name, count = count })
end

-- پرکارترین گردش‌کارها اول؛ فهرست کامل داخل مودال «توزیع گردش‌کار» است نه در نوار خلاصه
table.sort(workflow_summary_parts, function(a, b)
    if a.count == b.count then
        return a.name < b.name
    end
    return a.count > b.count
end)

local workflow_rows = {}
for i, wf in ipairs(workflow_summary_parts) do
    table.insert(workflow_rows,
        '<tr><td>' .. tostring(i) .. '</td>'
        .. '<td class="name-cell">' .. escape_html(wf.name) .. '</td>'
        .. '<td>' .. tostring(wf.count) .. '</td></tr>')
end
local workflow_rows_html = table.concat(workflow_rows, "\n")
if workflow_rows_html == '' then
    workflow_rows_html = '<tr><td colspan="3">گردش‌کاری یافت نشد</td></tr>'
end
local workflow_count = #workflow_summary_parts

local html = '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>آنالیز مراحل اقدام های باز</title>\n'
    .. REPORT_CSS
    .. '</head>\n<body>\n<div id="reportRoot">'
    .. '<div class="toolbar"><button type="button" class="btn-toolbar" onclick="toggleFullScreen()">تمام صفحه</button><button type="button" class="btn-toolbar" onclick="exportToExcel()">خروجی Excel</button><button type="button" class="btn-toolbar" onclick="openWorkflows()">توزیع گردش‌کار</button><button type="button" class="btn-toolbar" onclick="openHelp()">راهنما</button></div>'
    .. '<div class="report-header"><h2>آنالیز مراحل اقدام های باز</h2><p>فقط اقدام‌هایی که هنوز بسته نشده‌اند (نه با پایان موفق و نه با پایان ناموفق)</p></div>'
    .. '<div class="summary-strip">'
    .. '<div class="summary-card"><div class="s-label">تعداد کل اقدام باز</div><div class="s-value">' .. tostring(#actions) .. '</div></div>'
    .. '<div class="summary-card alert"><div class="s-label">فراتر از SLA</div><div class="s-value">' .. tostring(breached_count) .. '</div></div>'
    .. '<div class="summary-card"><div class="s-label">داخل مهلت</div><div class="s-value">' .. tostring(within_sla_count) .. '</div></div>'
    .. '<div class="summary-card"><div class="s-label">بدون SLA تعریف‌شده</div><div class="s-value">' .. tostring(no_sla_count) .. '</div></div>'
    .. '<div class="summary-card"><div class="s-label">تعداد گردش‌کار</div><div class="s-value">' .. tostring(workflow_count) .. '</div></div>'
    .. '</div>'
    .. '<div class="table-wrap"><table class="main-table"><thead><tr>'
    .. '<th>#</th><th>شناسه اقدام</th><th>عنوان اقدام</th><th>گردش‌کار</th><th>مرحله جاری</th><th>وضعیت مرحله</th><th>مسئول مرحله جاری</th><th>واحد</th><th>شروع مرحله جاری</th><th>مدت انتظار</th><th>مهلت (SLA)</th><th>فراتر از SLA</th><th>میزان تأخیر</th><th>تعداد کل مراحل</th>'
    .. '</tr></thead><tbody>' .. rows_joined .. '</tbody></table></div>'
    .. '<div class="footer">آنالیز مراحل اقدام های باز — Teamyar</div>'
    .. '</div>'
    .. '<div id="helpModal" class="modal"><div class="modal-content"><div class="modal-header"><h3>راهنمای گزارش</h3><button class="modal-close" onclick="closeHelp()">×</button></div><div class="modal-body">'
    .. '<p>این گزارش فقط اقدام‌های <strong>باز</strong> (todo_task) را نمایش می‌دهد؛ یعنی اقدام‌هایی که هنوز بسته نشده‌اند — نه با پایان موفق و نه با پایان ناموفق.</p>'
    .. '<h4>ستون‌ها</h4><ul>'
    .. '<li><strong>مرحله جاری:</strong> مرحله‌ای که هم‌اکنون در وضعیت «پیش نویس» (در حال انجام) است</li>'
    .. '<li><strong>مسئول مرحله جاری:</strong> فرد مسئول اجرای مرحله جاری</li>'
    .. '<li><strong>مدت انتظار:</strong> مدت زمانی که از شروع مرحله جاری تاکنون سپری شده</li>'
    .. '<li><strong>مهلت (SLA):</strong> مدت مجاز مرحله که در تعریف گردش‌کار ثبت شده (مثلاً «۳ روز»)</li>'
    .. '<li><strong>فراتر از SLA:</strong> «بله» وقتی مدت انتظار از مهلت مرحله بیشتر شده — این ردیف‌ها با رنگ صورتی/قرمز مشخص و در بالای جدول چیده می‌شوند. «خیر» یعنی هنوز در مهلت است. «—» یعنی برای این مرحله مهلتی تعریف نشده و قابل قضاوت نیست</li>'
    .. '<li><strong>میزان تأخیر:</strong> مقدار زمانی که از مهلت گذشته (فقط برای ردیف‌های «بله»)</li>'
    .. '<li><strong>تعداد کل مراحل:</strong> مجموع مراحل تعریف‌شده برای این اقدام (باز و بسته)</li>'
    .. '</ul>'
    .. '<h4>تعامل‌ها</h4><ul>'
    .. '<li>کلیک روی هدر ستون‌ها → مرتب‌سازی صعودی/نزولی</li>'
    .. '<li>«توزیع گردش‌کار» → فهرست کامل گردش‌کارها به‌همراه تعداد اقدام باز هر کدام</li>'
    .. '<li>تمام صفحه / خروجی Excel از نوار ابزار بالا در دسترس است</li>'
    .. '</ul>'
    .. '</div></div></div>'
    .. '<div id="workflowModal" class="modal"><div class="modal-content"><div class="modal-header"><h3>توزیع اقدام‌های باز بر اساس گردش‌کار</h3><button class="modal-close" onclick="closeWorkflows()">×</button></div><div class="modal-body">'
    .. '<table class="dist-table"><thead><tr><th>#</th><th>گردش‌کار</th><th>تعداد اقدام باز</th></tr></thead><tbody>'
    .. workflow_rows_html
    .. '</tbody></table>'
    .. '</div></div></div>'
    .. REPORT_JS
    .. '</body>\n</html>'

teamyar.write_result(html)
