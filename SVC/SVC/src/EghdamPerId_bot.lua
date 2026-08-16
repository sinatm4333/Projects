-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- خلاصه اقدام با آی دی: مراحل گردش‌کار یک اقدام (todo_task) + کامنت‌های هر مرحله
-- خروجی: HTML (پیش‌فرض) یا JSON با پارامتر format=json (سازگاری با فراخوانی‌های قبلی)

local input = teamyar.get_input()
local task_id = input["task_id"] or input["taskId"] or input["id"]
local as_json = tostring(input["format"] or ""):lower() == "json"

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

local function status_css_class(label)
    if label == "پیش نویس" then return "status-draft" end
    if label == "تایید شده" then return "status-approved" end
    if label == "کامل شده" then return "status-done" end
    if label == "رد شده" then return "status-rejected" end
    if label == "در حال انجام" then return "status-inprogress" end
    return "status-unknown"
end

local REPORT_CSS = [[
<style>
@font-face {
    font-family: "EghdamReport";
    src: local("Yekan Bakh"), local("YekanBakh"), local("IRANSans");
    font-weight: 400; font-style: normal; font-display: swap;
}
* { font-family: "EghdamReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
body { margin: 0; padding: 12px; font-size: 14px; background: linear-gradient(135deg, #f5f7fb 0%, #e8edf5 100%); color: #1e293b; }
#reportRoot:fullscreen { background: #f5f7fb; padding: 12px; overflow: auto; }
.toolbar { display: flex; justify-content: flex-end; gap: 8px; margin-bottom: 10px; flex-wrap: wrap; }
.btn-toolbar { background: linear-gradient(135deg, #0073e6, #005bb5); color: #fff; border: none; border-radius: 8px; padding: 8px 16px; font-family: inherit; font-size: 14px; font-weight: bold; cursor: pointer; box-shadow: 0 2px 8px rgba(0,115,230,0.3); }
.btn-toolbar:hover { filter: brightness(0.95); }
.report-header { background: linear-gradient(135deg, #D2E0FB 0%, #bcd4f7 100%); text-align: center; border: 1px dotted #000; border-radius: 12px; padding: 16px 12px 20px; margin-bottom: 14px; }
.report-header h2 { margin: 0 0 6px; font-size: 15px; font-weight: bold; color: #1e3a5f; }
.report-header p { margin: 3px 0; font-size: 14px; color: #334155; }
.summary-strip { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 14px; }
.summary-card { flex: 1 1 180px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.summary-card .s-label { font-size: 15px; font-weight: bold; color: #64748b; }
.summary-card .s-value { font-size: 14px; font-weight: bold; color: #0073e6; margin-top: 4px; }
.table-wrap { overflow: auto; border: 2px solid #000; border-radius: 8px; background: #fff; }
table.main-table { width: auto; table-layout: auto; border-collapse: collapse; text-align: center; }
table.main-table thead th { position: sticky; top: 0; z-index: 2; background: linear-gradient(135deg, #0073e6, #005bb5); color: #fff; border: 1px dashed #000; padding: 10px 8px; font-size: 15px; font-weight: bold; white-space: nowrap; width: 1%; cursor: pointer; user-select: none; }
table.main-table thead th.no-sort { cursor: default; }
table.main-table thead th.sort-asc::after { content: ' ▲'; }
table.main-table thead th.sort-desc::after { content: ' ▼'; }
table.main-table tbody td { border: 1px dashed #000; padding: 8px; font-size: 14px; vertical-align: middle; white-space: nowrap; width: 1%; }
table.main-table tbody tr:nth-child(even) { background: #f8fafc; }
table.main-table tbody tr.current-row { background: #fff7ed !important; }
table.main-table tbody tr.over-sla,
table.main-table tbody tr.over-sla:nth-child(even) { background: #fef2f2 !important; }
table.main-table tbody tr.over-sla:hover { background: #fee2e2 !important; }
table.main-table tbody tr.over-sla td { border-color: #ef4444 !important; color: #991b1b !important; }
.name-cell { text-align: right; font-weight: bold; }
.status-badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 14px; font-weight: bold; white-space: nowrap; }
.status-draft { background: #e2e8f0; color: #475569; }
.status-approved { background: #dbeafe; color: #1e40af; }
.status-done { background: #dcfce7; color: #166534; }
.status-rejected { background: #fee2e2; color: #991b1b; }
.status-inprogress { background: #fef3c7; color: #92400e; }
.status-unknown { background: #f1f5f9; color: #64748b; }
.sla-ok { background: #dcfce7; color: #166534; }
.sla-breach { background: #fee2e2; color: #991b1b; }
.sla-na { background: #f1f5f9; color: #64748b; }
.current-tag { display: inline-block; margin-left: 6px; padding: 1px 6px; border-radius: 6px; background: #f59e0b; color: #fff; font-size: 14px; font-weight: bold; }
.btn-comments { background: #0073e6; color: #fff; border: none; border-radius: 6px; padding: 4px 10px; font-family: inherit; font-size: 14px; font-weight: bold; cursor: pointer; }
.btn-comments:hover { background: #005bb5; }
.btn-comments.empty { background: #cbd5e1; color: #475569; }
.empty-row { padding: 24px !important; color: #666; font-size: 14px; }
.footer { text-align: center; color: #94a3b8; font-size: 14px; margin-top: 12px; }
.modal { display: none; position: fixed; z-index: 1000; inset: 0; background: rgba(0,0,0,0.45); }
.modal.active { display: flex; align-items: center; justify-content: center; }
.modal-content { background: #fefefe; padding: 0; border-radius: 10px; width: 92%; max-width: 640px; max-height: 82vh; overflow-y: auto; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; background: linear-gradient(135deg, #0073e6, #005bb5); color: #fff; border-radius: 10px 10px 0 0; position: sticky; top: 0; }
.modal-header h3 { margin: 0; font-size: 15px; font-weight: bold; }
.modal-close { background: none; border: none; font-size: 20px; cursor: pointer; color: #fff; }
.modal-body { padding: 16px; font-size: 14px; line-height: 1.8; text-align: right; }
.modal-body h4 { font-size: 15px; font-weight: bold; margin: 10px 0 6px; }
.modal-body ul { margin: 8px 0; padding-right: 20px; }
.modal-body li { margin: 6px 0; font-size: 14px; }
.step-instruction { background: #f0f7ff; border: 1px dashed #0073e6; border-radius: 8px; padding: 10px 12px; margin-bottom: 10px; white-space: pre-wrap; font-size: 14px; }
.comment-item { border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 10px; margin-bottom: 8px; }
.comment-meta { font-size: 14px; color: #64748b; margin-bottom: 4px; }
.comment-text { font-size: 14px; white-space: pre-wrap; }
.error-card { max-width: 520px; margin: 60px auto; background: #fff; border: 2px solid #ef4444; border-radius: 12px; padding: 24px; text-align: center; }
.error-card h2 { color: #991b1b; font-size: 15px; margin: 0 0 8px; }
.error-card p { font-size: 14px; color: #475569; }
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
function closeStepModal() { document.getElementById('stepModal').classList.remove('active'); }

function openStepModal(id) {
    var d = (typeof STEPS_DATA !== 'undefined') ? STEPS_DATA[String(id)] : null;
    var body = document.getElementById('stepModalBody');
    body.innerHTML = '';
    document.getElementById('stepModalTitle').textContent = d ? ('مرحله: ' + (d.step_name || '—')) : 'جزئیات مرحله';
    if (!d) {
        var p0 = document.createElement('p'); p0.textContent = 'داده‌ای یافت نشد.'; body.appendChild(p0);
        document.getElementById('stepModal').classList.add('active');
        return;
    }
    if (d.step_text) {
        var h4a = document.createElement('h4'); h4a.textContent = 'دستورالعمل / توضیح مرحله'; body.appendChild(h4a);
        var box = document.createElement('div'); box.className = 'step-instruction'; box.textContent = d.step_text; body.appendChild(box);
    }
    var comments = Array.isArray(d.comments) ? d.comments : [];
    var h4b = document.createElement('h4'); h4b.textContent = 'کامنت‌ها (' + comments.length + ')'; body.appendChild(h4b);
    if (comments.length === 0) {
        var p1 = document.createElement('p'); p1.textContent = 'کامنتی ثبت نشده است.'; body.appendChild(p1);
    } else {
        comments.forEach(function (c) {
            var item = document.createElement('div'); item.className = 'comment-item';
            var meta = document.createElement('div'); meta.className = 'comment-meta';
            meta.textContent = (c.author_name || '—') + ' | ' + (c.date_create || '—') + ' | ' + (c.visibility || '') + ' | ' + (c.content_type_label || '');
            var txt = document.createElement('div'); txt.className = 'comment-text';
            txt.textContent = c.content_text || c.content || '';
            item.appendChild(meta); item.appendChild(txt);
            body.appendChild(item);
        });
    }
    document.getElementById('stepModal').classList.add('active');
}

window.onclick = function (event) {
    var help = document.getElementById('helpModal');
    var step = document.getElementById('stepModal');
    if (event.target === help) closeHelp();
    if (event.target === step) closeStepModal();
};
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { closeHelp(); closeStepModal(); }
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
    for (var h = 0; h < heads.length - 1; h++) hl.push(csvCell(heads[h].innerText));
    lines.push(hl.join(','));
    var rows = table.querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
        if (rows[i].querySelector('td.empty-row')) continue;
        var cells = rows[i].querySelectorAll('td');
        var line = [];
        for (var c = 0; c < cells.length - 1; c++) line.push(csvCell(cells[c].innerText));
        lines.push(line.join(','));
    }
    var fileName = 'خلاصه-اقدام-' + (typeof TASK_ID !== 'undefined' ? TASK_ID : '') + '.csv';
    downloadCsv(lines, fileName);
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
            if (th.classList.contains('no-sort')) return;
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

local function render_error_html(message)
    return '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>خلاصه اقدام - خطا</title>\n'
        .. REPORT_CSS
        .. '</head>\n<body>\n<div id="reportRoot">'
        .. '<div class="error-card"><h2>خطا</h2><p>' .. escape_html(message) .. '</p></div>'
        .. '</div>\n</body>\n</html>'
end

if task_id == nil or task_id == "" then
    if as_json then
        teamyar.write_result(json.encode({
            ok = false,
            error = "شناسه اقدام (task_id) وارد نشده است"
        }))
    else
        teamyar.write_result(render_error_html("شناسه اقدام (task_id) وارد نشده است"))
    end
    return
end

local COMMENT_TABLE_CANDIDATES = {
    "todo_task_comments",
    "todo_content",
    "todo_task_content",
    "todo_comment",
    "todo_task_comment",
    "todo_task_steps_comment"
}

-- تبدیل filetime به تاریخ-ساعت شمسی (خروجی رشته‌ای، بدون عدد علمی)
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

local function sql_ident(name)
    return "`" .. string.gsub(name, "`", "``") .. "`"
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

local function fail_query(context, err)
    teamyar.write_result(json.encode({
        ok = false,
        error = "خطا در اجرای کوئری" .. (context and (": " .. context) or ""),
        detail = tostring(err)
    }))
end

local function fetch_rows(query, params)
    local ok, err = pcall(function()
        db.query({
            query = query,
            params = params or {}
        })
    end)
    if not ok then
        return nil, err
    end

    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do
            row[i] = record[i]
        end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

local function fetch_table_columns(table_name)
    local columns = {}
    local rows = fetch_rows([[
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    ]], { table_name })

    if rows == nil then
        return nil
    end

    for _, row in ipairs(rows) do
        columns[string.upper(row[1] or "")] = row[1]
    end
    return columns
end

local function pick_column(columns, candidates)
    for _, name in ipairs(candidates) do
        local col = columns[string.upper(name)]
        if col then
            return col
        end
    end
    return nil
end

local function discover_step_text_column()
    local columns = fetch_table_columns("todo_task_steps")
    if columns == nil then
        return nil
    end
    return pick_column(columns, {
        "DESCRIPTION",
        "STEP_DESC",
        "BODY",
        "CONTENT",
        "COMMENT",
        "NOTE",
        "STEP_TEXT",
        "STEP_COMMENT"
    })
end

local function discover_comment_source()
    for _, table_name in ipairs(COMMENT_TABLE_CANDIDATES) do
        local columns = fetch_table_columns(table_name)
        if columns ~= nil and next(columns) ~= nil then
            local step_col = pick_column(columns, {
                "TASK_STEP_ID",
                "STEP_ROW_ID",
                "TASK_STEP_ROW_ID",
                "REF_ID"
            })
            local content_col = pick_column(columns, {
                "DESCRIPTION",
                "CONTENT",
                "BODY",
                "COMMENT_TEXT",
                "TEXT",
                "COMMENT"
            })

            if step_col and content_col then
                return {
                    table_name = table_name,
                    id_col = pick_column(columns, { "ID" }) or "id",
                    step_col = step_col,
                    content_col = content_col,
                    author_col = pick_column(columns, {
                        "AUTHOR_ID",
                        "CREATOR_ID",
                        "PROFILE_ID",
                        "OWNER_ID",
                        "USER_ID"
                    }),
                    author_name_col = pick_column(columns, {
                        "AUTHOR_NAME",
                        "FULLNAME",
                        "CREATOR_NAME"
                    }),
                    date_col = pick_column(columns, {
                        "DATE_CREATE",
                        "DATE_CREATED",
                        "CREATE_DATE",
                        "CREATED_AT"
                    }),
                    private_col = pick_column(columns, {
                        "IS_PRIVATE",
                        "PRIVATE",
                        "IS_CONFIDENTIAL"
                    }),
                    type_col = pick_column(columns, {
                        "TYPE",
                        "CONTENT_TYPE",
                        "COMMENT_TYPE"
                    }),
                    task_col = pick_column(columns, { "TASK_ID" })
                }
            end
        end
    end
    return nil
end

local function normalize_text(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    if text == "" then
        return nil
    end

    return text
end

local function utf8_from_codepoint(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + (cp % 0x40))
    elseif cp < 0x10000 then
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    else
        return string.char(
            0xF0 + math.floor(cp / 0x40000),
            0x80 + (math.floor(cp / 0x1000) % 0x40),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    end
end

local HTML_ENTITIES = {
    nbsp = " ",
    amp = "&",
    lt = "<",
    gt = ">",
    quot = "\"",
    apos = "'",
    laquo = "«",
    raquo = "»",
    mdash = "—",
    ndash = "–",
    hellip = "…",
    zwnj = utf8_from_codepoint(0x200C)
}

local function decode_html_entities(text)
    text = text:gsub("&#[xX](%x+);", function(hex)
        return utf8_from_codepoint(tonumber(hex, 16))
    end)
    text = text:gsub("&#(%d+);", function(dec)
        return utf8_from_codepoint(tonumber(dec))
    end)
    text = text:gsub("&(%a+);", function(name)
        return HTML_ENTITIES[name] or ("&" .. name .. ";")
    end)
    return text
end

-- تبدیل محتوای HTML کامنت به متن ساده و خوانا
local function html_to_text(html)
    if html == nil then
        return nil
    end

    local text = html
    text = text:gsub("<[bB][rR]%s*/?>", "\n")
    text = text:gsub("</[pP]%s*>", "\n")
    text = text:gsub("</[dD][iI][vV]%s*>", "\n")
    text = text:gsub("</[lL][iI]%s*>", "\n")
    text = text:gsub("</[hH]%d%s*>", "\n")
    text = text:gsub("</[sS][eE][cC][tT][iI][oO][nN]%s*>", "\n")
    text = text:gsub("<[^>]*>", "")
    text = decode_html_entities(text)
    text = text:gsub("[ \t\r]+", " ")
    text = text:gsub(" *\n *", "\n")
    text = text:gsub("\n\n+", "\n")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    if text == "" then
        return nil
    end
    return text
end

local function comment_visibility_label(is_private)
    if tonumber(is_private) == 1 then
        return "محرمانه"
    end
    return "عمومی"
end

local function comment_type_label(content_type)
    local type_code = tonumber(content_type)
    if type_code == nil then
        return "کامنت"
    end
    if type_code == 0 or type_code == 1 then
        return "کامنت"
    end
    if type_code == 2 then
        return "توضیح"
    end
    if type_code == 3 then
        return "دستورالعمل"
    end
    return "متن"
end

local function is_user_comment(content_type)
    local type_code = tonumber(content_type)
    return type_code == 0 or type_code == 1
end

local function is_step_instruction(content_type)
    return tonumber(content_type) == 3
end

local function append_comment(comments_by_step, step_row_id, comment)
    if comments_by_step[step_row_id] == nil then
        comments_by_step[step_row_id] = {}
    end
    table.insert(comments_by_step[step_row_id], comment)
end

local function build_comment_record(row)
    local is_private = tonumber(row[6]) or 0
    local content_type = row[7]
    local content = normalize_text(row[5])

    if content == nil then
        return nil
    end

    return {
        comment_id = row[2],
        author_id = row[3],
        author_name = row[4],
        content = content,
        content_text = html_to_text(content),
        comment_number = tonumber(row[9]) or row[9],
        is_private = is_private == 1,
        visibility = comment_visibility_label(is_private),
        content_type = content_type,
        content_type_label = comment_type_label(content_type),
        date_create = row[8]
    }
end

local function load_todo_task_comments(task_id_value)
    local comments_by_step = {}
    local query = [[
        SELECT
            tc.TASK_STEP_ID AS step_row_id,
            tc.ID AS comment_id,
            tc.AUTHOR_ID AS author_id,
            COALESCE(pm.fullname, tc.AUTHOR_NAME) AS author_name,
            tc.DESCRIPTION AS content,
            COALESCE(tc.IS_PRIVATE, 0) AS is_private,
            tc.TYPE AS content_type,
            ]] .. fmt_jalali_datetime("tc.DATE_CREATE") .. [[ AS date_create,
            tc.COMMENT_NUMBER AS comment_number
        FROM todo_task_comments tc
        LEFT JOIN profile_main pm
            ON pm.id = tc.AUTHOR_ID
        WHERE tc.TASK_ID = ?
        ORDER BY tc.TASK_STEP_ID, tc.COMMENT_NUMBER, tc.ID
    ]]

    local comment_rows = fetch_rows(query, { task_id_value })
    if comment_rows == nil then
        return comments_by_step, false
    end

    for _, row in ipairs(comment_rows) do
        local step_row_id = tonumber(row[1]) or row[1]
        local comment = build_comment_record(row)
        if comment ~= nil then
            append_comment(comments_by_step, step_row_id, comment)
        end
    end

    return comments_by_step, true
end

local function load_step_comments(task_id_value, source)
    local comments_by_step = {}
    if source == nil then
        return comments_by_step
    end

    local author_join = ""
    local author_select = "NULL AS author_id, NULL AS author_name"
    local step_col = sql_ident(source.step_col)
    local id_col = sql_ident(source.id_col)
    local content_col = sql_ident(source.content_col)

    if source.author_col then
        local author_col = sql_ident(source.author_col)
        author_join = "LEFT JOIN profile_main pm ON pm.id = tc." .. author_col
        if source.author_name_col then
            local author_name_col = sql_ident(source.author_name_col)
            author_select = "tc." .. author_col .. " AS author_id, COALESCE(pm.fullname, tc." .. author_name_col .. ") AS author_name"
        else
            author_select = "tc." .. author_col .. " AS author_id, pm.fullname AS author_name"
        end
    end

    local date_select = "NULL AS date_create"
    if source.date_col then
        date_select = fmt_jalali_datetime("tc." .. sql_ident(source.date_col)) .. " AS date_create"
    end

    local private_select = "0 AS is_private"
    if source.private_col then
        private_select = "COALESCE(tc." .. sql_ident(source.private_col) .. ", 0) AS is_private"
    end

    local type_select = "NULL AS content_type"
    if source.type_col then
        type_select = "tc." .. sql_ident(source.type_col) .. " AS content_type"
    end

    local where_clause = ""
    local params = {}
    if source.task_col then
        where_clause = "WHERE tc." .. sql_ident(source.task_col) .. " = ?"
        params = { task_id_value }
    else
        where_clause = "WHERE tc." .. step_col .. " IN (" ..
            "SELECT tts2.id FROM todo_task_steps tts2 WHERE tts2.TASK_ID = ?)"
        params = { task_id_value }
    end

    local order_col = source.date_col and ("tc." .. sql_ident(source.date_col)) or ("tc." .. id_col)
    local query = [[
        SELECT
            tc.]] .. step_col .. [[ AS step_row_id,
            tc.]] .. id_col .. [[ AS comment_id,
            ]] .. author_select .. [[,
            tc.]] .. content_col .. [[ AS content,
            ]] .. private_select .. [[,
            ]] .. type_select .. [[,
            ]] .. date_select .. [[
        FROM ]] .. sql_ident(source.table_name) .. [[ tc
        ]] .. author_join .. [[
        ]] .. where_clause .. [[
        ORDER BY tc.]] .. step_col .. [[, ]] .. order_col .. [[
    ]]

    local comment_rows = fetch_rows(query, params)
    if comment_rows == nil then
        return comments_by_step
    end

    for _, row in ipairs(comment_rows) do
        local step_row_id = tonumber(row[1]) or row[1]
        local comment = build_comment_record(row)
        if comment ~= nil then
            append_comment(comments_by_step, step_row_id, comment)
        end
    end

    return comments_by_step
end

local function load_step_texts(task_id_value, column_name)
    local texts_by_step = {}
    if column_name == nil then
        return texts_by_step
    end

    local col = sql_ident(column_name)
    local rows = fetch_rows(
        "SELECT id, NULLIF(TRIM(" .. col .. "), '') AS step_text FROM todo_task_steps WHERE TASK_ID = ?",
        { task_id_value }
    )
    if rows == nil then
        return texts_by_step
    end

    for _, row in ipairs(rows) do
        local text = normalize_text(row[2])
        if text ~= nil then
            texts_by_step[tonumber(row[1]) or row[1]] = text
        end
    end

    return texts_by_step
end

local function attach_step_texts_and_comments(steps, texts_by_step, comments_by_step)
    for _, step in ipairs(steps) do
        local step_row_id = step.step_row_id
        step._all_comments = comments_by_step[step_row_id] or {}

        if step.step_text == nil then
            step.step_text = texts_by_step[step_row_id]
        end

        if step.step_text == nil then
            for _, comment in ipairs(step._all_comments) do
                if comment.content_type_label == "توضیح" and comment.content ~= nil then
                    step.step_text = comment.content_text or comment.content
                    break
                end
            end
        end
    end
end

local function finalize_step_comments(steps)
    for _, step in ipairs(steps) do
        local all_comments = step._all_comments or {}
        local user_comments = {}
        local step_instruction = nil

        for _, comment in ipairs(all_comments) do
            if is_user_comment(comment.content_type) then
                if step.step_order and comment.comment_number then
                    comment.comment_label = step.step_order .. "_" .. comment.comment_number
                end
                table.insert(user_comments, comment)
            elseif is_step_instruction(comment.content_type) and step_instruction == nil then
                step_instruction = {
                    comment_id = comment.comment_id,
                    comment_number = comment.comment_number,
                    author_id = comment.author_id,
                    author_name = comment.author_name,
                    content_text = comment.content_text,
                    date_create = comment.date_create
                }
            end
        end

        if step.step_text == nil and step_instruction ~= nil then
            step.step_text = step_instruction.content_text
        end

        step.comments = user_comments
        step.comment_count = #user_comments
        step.step_instruction = step_instruction
        step._all_comments = nil
    end
end

-- زمان فعال‌شدن واقعی مرحله در جریان کار
local function step_active_start_ts(step)
    if step.status_code == 0 and step.date_modify_raw > step.date_create_raw then
        return step.date_modify_raw
    end
    return step.date_create_raw
end

local function step_workflow_sort_key(step)
    return step_active_start_ts(step)
end

-- مدتی که هر مرحله واقعاً طول کشیده است:
-- مرحله جاری (در حال انجام) → از شروع تا الان
-- مرحله انجام‌شده → از ایجاد تا تایید/رد (DATE_CREATE تا DATE_MODIFY همان مرحله)
-- توجه: این «مدت انجام خود مرحله» است، نه فاصله تا مرحله بعد —
-- چون مرحله بعد معمولاً همان لحظه تایید مرحله قبل ساخته می‌شود و آن فاصله همیشه صفر است.
local function apply_step_elapsed(steps, now_raw)
    if #steps == 0 then
        return
    end

    now_raw = tonumber(now_raw) or 0

    table.sort(steps, function(a, b)
        local ka = step_workflow_sort_key(a)
        local kb = step_workflow_sort_key(b)
        if ka == kb then
            return (a.step_row_id or 0) < (b.step_row_id or 0)
        end
        return ka < kb
    end)

    for i, step in ipairs(steps) do
        local elapsed_raw = nil
        local elapsed_type = nil
        local is_current = step.status_code == 0

        if is_current then
            if now_raw > 0 then
                local start_ts = step_active_start_ts(step)
                if start_ts and start_ts > 0 then
                    elapsed_raw = now_raw - start_ts
                    elapsed_type = "to_now"
                end
            end
        elseif step.date_create_raw and step.date_create_raw > 0 and step.date_modify_raw and step.date_modify_raw > 0 then
            elapsed_raw = step.date_modify_raw - step.date_create_raw
            elapsed_type = "step_duration"
        end

        step.step_order = i
        step.is_current_step = is_current
        step.step_elapsed_type = elapsed_type
        step.step_elapsed_seconds = elapsed_raw and math.max(0, math.floor(elapsed_raw / 10000000)) or nil
        step.step_elapsed_label = format_duration(elapsed_raw and math.max(0, elapsed_raw) or nil)

        step.step_row_id = nil
        step.date_create_raw = nil
        step.date_modify_raw = nil
        step.status_code = nil
    end
end

local function record_to_step(record)
    return {
        task_id = record[1],
        profile_main_id = record[2],
        profile_main_fullname = record[3],
        task_title = record[4],
        t_start_date = record[5],
        t_return_date = record[6],
        t_end_date = record[7],
        t_real_end_date = record[8],
        step_name = record[9],
        duration = record[10],
        time_unit_label = record[11],
        microsecond_duration = record[12],
        time_unit = record[13],
        DATE_NOW = record[14],
        DATE_MODIFY = record[15],
        DATE_CREATE = record[16],
        status = record[17],
        unit_id = record[18],
        unit_name = record[19],
        a_hh_mm = record[20],
        wf_id = record[21],
        wf_title = record[22],
        hiring_status = record[23],
        step_row_id = record[24],
        date_create_raw = tonumber(record[25]) or 0,
        date_modify_raw = tonumber(record[26]) or 0,
        status_code = tonumber(record[27]) or 0,
        step_text = nil
    }
end

local step_text_column = discover_step_text_column()
local comment_source = discover_comment_source()

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
        pu.NAME             AS name_fa,
        pu.SURNAME          AS family_fa,
        hp.PERSONNEL_CODE   AS personnel_code,
        hp.PERSONNEL_ID     AS personnel_id,
        oouA.id             AS oou_id_A,
        ouA.name            AS unit_name_A,
        ouB.id              AS ou_id_B,
        ouB.name            AS unit_name_B,
        oouB.oou_id         AS oou_id_B,
        oouP.id             AS oou_id_P,
        ouP.name            AS unit_name_P,
        COALESCE(oouA.id, oouB.oou_id, oouP.id) AS unit_org_unit_id,
        COALESCE(ouA.name, ouB.name, ouP.name, 'بدون واحد') AS unit_name,
        hp.HIRING_STATUS
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
),

LeaveByDay AS (
    SELECT
        het.personnel_id,
        TIMESTAMP(DATE(FROM_UNIXTIME(het.EXT_DATE / 10000000 - 11644473600))) AS g_dt,
        CONCAT(
            LPAD(FLOOR(FLOOR(FLOOR(SUM(het.time_to - het.time_from) / 10000000)) / 3600), 2, '0'),
            ':',
            LPAD(FLOOR(MOD(FLOOR(SUM(het.time_to - het.time_from) / 10000000), 3600) / 60), 2, '0')
        ) AS a_hh_mm
    FROM HR_EXT_TIME het
    WHERE het.enable = 1
      AND het.type IN (2, 3, 4, 5)
    GROUP BY
        het.personnel_id,
        TIMESTAMP(DATE(FROM_UNIXTIME(het.EXT_DATE / 10000000 - 11644473600)))
)

SELECT
    tts.task_id,
    pm.id AS profile_main_id,
    pm.fullname AS profile_main_fullname,
    tt.task_title,
    ]] .. fmt_jalali_datetime("tt.t_start_date") .. [[ AS t_start_date,
    ]] .. fmt_jalali_datetime("tt.t_return_date") .. [[ AS t_return_date,
    ]] .. fmt_jalali_datetime("tt.t_end_date") .. [[ AS t_end_date,
    ]] .. fmt_jalali_datetime("tt.t_real_end_date") .. [[ AS t_real_end_date,
    ts.step_name,
    ts.duration,
    CASE
        WHEN ts.time_unit = 0 THEN 'ندارد'
        WHEN ts.time_unit = 1 THEN 'دقیقه'
        WHEN ts.time_unit = 2 THEN 'ساعت'
        WHEN ts.time_unit = 3 THEN 'روز'
        ELSE 'نامشخص'
    END AS time_unit_label,
    CAST(
        CASE
            WHEN ts.time_unit = 1 THEN ts.duration * 60 * 10000000
            WHEN ts.time_unit = 2 THEN ts.duration * 60 * 60 * 10000000
            WHEN ts.time_unit = 3 THEN ts.duration * 24 * 60 * 60 * 10000000
            ELSE ts.duration
        END AS CHAR
    ) AS microsecond_duration,
    ts.time_unit,
    ]] .. fmt_jalali_datetime("(UNIX_TIMESTAMP() + 11644473600) * 10000000") .. [[ AS DATE_NOW,
    ]] .. fmt_jalali_datetime("tts.DATE_MODIFY") .. [[ AS DATE_MODIFY,
    ]] .. fmt_jalali_datetime("tts.DATE_CREATE") .. [[ AS DATE_CREATE,
    CASE
        WHEN tts.STATUS = 0 THEN 'پیش نویس'
        WHEN tts.STATUS = 1 THEN 'تایید شده'
        WHEN tts.STATUS = 2 THEN 'کامل شده'
        WHEN tts.STATUS = 3 THEN 'رد شده'
        ELSE 'نامشخص'
    END AS STATUS,
    pi.unit_org_unit_id AS unit_org_unit_id,
    pi.unit_name AS unit_name,
    COALESCE(lbd.a_hh_mm, '00:00') AS a_hh_mm,
    tw.id AS wf_id,
    tw.wf_title AS wf_title,
    pi.HIRING_STATUS,
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
LEFT JOIN LeaveByDay lbd
    ON lbd.personnel_id = pi.personnel_id
   AND lbd.g_dt = TIMESTAMP(DATE(FROM_UNIXTIME(tts.DATE_CREATE / 10000000 - 11644473600)))
WHERE tt.id = ?
ORDER BY tts.id
    ]],
    params = { task_id }
}

local steps = {}
local now_raw = 0

local ok, query_err = pcall(function()
    db.query(param)
end)
if not ok then
    if as_json then
        fail_query("task_steps", query_err)
    else
        teamyar.write_result(render_error_html("خطا در اجرای کوئری مراحل اقدام"))
    end
    return
end

local record = {}
while db.query_fetch(record) do
    if now_raw == 0 then
        now_raw = tonumber(record[28]) or 0
    end

    table.insert(steps, record_to_step(record))
end
db.query_free()

local texts_by_step = load_step_texts(task_id, step_text_column)
local comments_by_step, comments_loaded = load_todo_task_comments(task_id)
if not comments_loaded then
    comments_by_step = load_step_comments(task_id, comment_source)
end
attach_step_texts_and_comments(steps, texts_by_step, comments_by_step)
apply_step_elapsed(steps, now_raw)
finalize_step_comments(steps)

if #steps == 0 then
    if as_json then
        teamyar.write_result(json.encode({
            ok = false,
            task_id = tonumber(task_id) or task_id,
            step_count = 0,
            steps = {},
            error = "اقدامی با این شناسه یافت نشد یا مرحله‌ای ندارد"
        }))
    else
        teamyar.write_result(render_error_html("اقدامی با این شناسه یافت نشد یا مرحله‌ای ندارد"))
    end
    return
end

if as_json then
    teamyar.write_result(json.encode({
        ok = true,
        task_id = tonumber(task_id) or task_id,
        step_count = #steps,
        steps = steps
    }))
    return
end

-- ── HTML: بخش‌های داینامیک ─────────────────────────────────────────────

local current_step = nil
for _, s in ipairs(steps) do
    if s.is_current_step then
        current_step = s
        break
    end
end
local overall_status = current_step and "در حال انجام" or (steps[#steps].status or "نامشخص")

local rows_html = {}
local js_steps_data = {}

for _, s in ipairs(steps) do
    local current_tag = s.is_current_step and '<span class="current-tag">جاری</span>' or ''

    local duration_label = "—"
    local duration_num = tonumber(s.duration)
    if duration_num ~= nil and duration_num > 0 then
        duration_label = tostring(s.duration) .. ' ' .. (s.time_unit_label or '')
    end

    local gap_label = "—"
    if s.step_elapsed_label ~= nil then
        if s.step_elapsed_type == "to_now" then
            gap_label = s.step_elapsed_label .. ' (تا الان)'
        else
            gap_label = s.step_elapsed_label .. ' (زمان انجام مرحله)'
        end
    end

    local sla_label = "—"
    local sla_class = "sla-na"
    local allotted_seconds = nil
    local time_unit_num = tonumber(s.time_unit)
    local microsecond_duration_num = tonumber(s.microsecond_duration)
    if time_unit_num ~= nil and time_unit_num ~= 0 and microsecond_duration_num ~= nil and microsecond_duration_num > 0 then
        allotted_seconds = math.floor(microsecond_duration_num / 10000000)
    end
    if allotted_seconds ~= nil and s.step_elapsed_seconds ~= nil then
        if s.step_elapsed_seconds <= allotted_seconds then
            sla_label = "رعایت شده"
            sla_class = "sla-ok"
        else
            sla_label = "رد شده"
            sla_class = "sla-breach"
        end
    end

    local comment_count = s.comment_count or 0
    local comment_btn_class = comment_count > 0 and "btn-comments" or "btn-comments empty"

    local row_classes = {}
    if s.is_current_step then table.insert(row_classes, "current-row") end
    if sla_class == "sla-breach" then table.insert(row_classes, "over-sla") end
    local row_class = #row_classes > 0 and (' class="' .. table.concat(row_classes, " ") .. '"') or ''

    local row = '<tr' .. row_class .. ' data-step="' .. tostring(s.step_order) .. '">'
        .. '<td>' .. tostring(s.step_order) .. '</td>'
        .. '<td class="name-cell">' .. current_tag .. escape_html(s.step_name) .. '</td>'
        .. '<td>' .. escape_html(s.profile_main_fullname) .. '</td>'
        .. '<td>' .. escape_html(s.unit_name) .. '</td>'
        .. '<td><span class="status-badge ' .. status_css_class(s.status) .. '">' .. escape_html(s.status) .. '</span></td>'
        .. '<td>' .. escape_html(s.DATE_CREATE) .. '</td>'
        .. '<td>' .. escape_html(s.DATE_MODIFY) .. '</td>'
        .. '<td>' .. escape_html(duration_label) .. '</td>'
        .. '<td>' .. escape_html(gap_label) .. '</td>'
        .. '<td><span class="status-badge ' .. sla_class .. '">' .. escape_html(sla_label) .. '</span></td>'
        .. '<td><button type="button" class="' .. comment_btn_class .. '" onclick="openStepModal(' .. tostring(s.step_order) .. ')">' .. tostring(comment_count) .. '</button></td>'
        .. '</tr>'
    table.insert(rows_html, row)

    local comments_payload = {}
    for _, c in ipairs(s.comments or {}) do
        table.insert(comments_payload, {
            author_name = c.author_name,
            date_create = c.date_create,
            visibility = c.visibility,
            content_type_label = c.content_type_label,
            content_text = c.content_text or c.content
        })
    end

    js_steps_data[tostring(s.step_order)] = {
        step_name = s.step_name,
        step_text = s.step_text,
        comments = comments_payload
    }
end

local rows_joined = table.concat(rows_html, "\n")
if rows_joined == "" then
    rows_joined = '<tr><td colspan="11" class="empty-row">مرحله‌ای یافت نشد</td></tr>'
end

local head = steps[1]
local meta_html = '<p>عنوان اقدام: ' .. escape_html(head.task_title) .. '</p>'
    .. '<p>شناسه اقدام: #' .. escape_html(tostring(task_id)) .. ' | گردش‌کار: ' .. escape_html(head.wf_title or '—') .. '</p>'
    .. '<p>تاریخ شروع: ' .. escape_html(head.t_start_date or '—')
    .. ' | سررسید: ' .. escape_html(head.t_return_date or '—')
    .. ' | پایان: ' .. escape_html(head.t_end_date or '—')
    .. ' | پایان واقعی: ' .. escape_html(head.t_real_end_date or '—') .. '</p>'

local summary_html = '<div class="summary-strip">'
    .. '<div class="summary-card"><div class="s-label">تعداد مراحل</div><div class="s-value">' .. tostring(#steps) .. '</div></div>'
    .. '<div class="summary-card"><div class="s-label">وضعیت اقدام</div><div class="s-value"><span class="status-badge ' .. status_css_class(overall_status) .. '">' .. escape_html(overall_status) .. '</span></div></div>'
    .. '<div class="summary-card"><div class="s-label">مرحله جاری</div><div class="s-value">' .. escape_html(current_step and current_step.step_name or '—') .. '</div></div>'
    .. '<div class="summary-card"><div class="s-label">مسئول مرحله جاری</div><div class="s-value">' .. escape_html(current_step and current_step.profile_main_fullname or '—') .. '</div></div>'
    .. '</div>'

local steps_json = json.encode(js_steps_data)
steps_json = steps_json:gsub("</", "<\\/")
local task_id_json = json.encode(tostring(task_id))

local html = '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>خلاصه اقدام #' .. escape_html(tostring(task_id)) .. '</title>\n'
    .. REPORT_CSS
    .. '</head>\n<body>\n<div id="reportRoot">'
    .. '<div class="toolbar"><button type="button" class="btn-toolbar" onclick="toggleFullScreen()">تمام صفحه</button><button type="button" class="btn-toolbar" onclick="exportToExcel()">خروجی Excel</button><button type="button" class="btn-toolbar" onclick="openHelp()">راهنما</button></div>'
    .. '<div class="report-header"><h2>خلاصه اقدام #' .. escape_html(tostring(task_id)) .. '</h2>' .. meta_html .. '</div>'
    .. summary_html
    .. '<div class="table-wrap"><table class="main-table"><thead><tr>'
    .. '<th>#</th><th>نام مرحله</th><th>مسئول</th><th>واحد</th><th>وضعیت</th><th>تاریخ ایجاد</th><th>تاریخ تغییر</th><th>مدت تعیین‌شده</th><th>مدت انجام</th><th>وضعیت SLA</th><th class="no-sort">کامنت‌ها</th>'
    .. '</tr></thead><tbody>' .. rows_joined .. '</tbody></table></div>'
    .. '<div class="footer">خلاصه اقدام — Teamyar</div>'
    .. '</div>'
    .. '<div id="helpModal" class="modal"><div class="modal-content"><div class="modal-header"><h3>راهنمای گزارش</h3><button class="modal-close" onclick="closeHelp()">×</button></div><div class="modal-body">'
    .. '<p>این گزارش مراحل گردش‌کار اقدام (Task) با شناسه واردشده (task_id) را نمایش می‌دهد.</p>'
    .. '<h4>ستون‌ها</h4><ul>'
    .. '<li><strong>وضعیت:</strong> پیش‌نویس، تایید شده، کامل شده یا رد شده</li>'
    .. '<li><strong>مدت تعیین‌شده:</strong> مدت زمان تعریف‌شده برای مرحله در گردش‌کار</li>'
    .. '<li><strong>مدت انجام:</strong> برای مرحله جاری، مدت از شروع تا الان؛ برای مراحل انجام‌شده، مدت زمانی که از ایجاد تا تایید/رد آن مرحله طول کشیده</li>'
    .. '<li><strong>وضعیت SLA:</strong> مقایسه «مدت انجام» با «مدت تعیین‌شده» — رعایت شده (سبز) یا رد شده (قرمز)؛ اگر مرحله مدت تعیین‌شده نداشته باشد «—» نمایش داده می‌شود</li>'
    .. '<li><strong>کامنت‌ها:</strong> تعداد کامنت‌های ثبت‌شده روی مرحله — با کلیک، متن کامل و دستورالعمل مرحله نمایش داده می‌شود</li>'
    .. '</ul>'
    .. '<h4>تعامل‌ها</h4><ul>'
    .. '<li>ردیف با برچسب «جاری» مرحله در حال انجام است</li>'
    .. '<li>کلیک روی هدر ستون‌ها (به‌جز کامنت‌ها) → مرتب‌سازی صعودی/نزولی</li>'
    .. '<li>تمام صفحه / خروجی Excel از نوار ابزار بالا در دسترس است</li>'
    .. '</ul>'
    .. '</div></div></div>'
    .. '<div id="stepModal" class="modal"><div class="modal-content"><div class="modal-header"><h3 id="stepModalTitle">جزئیات مرحله</h3><button class="modal-close" onclick="closeStepModal()">×</button></div><div class="modal-body" id="stepModalBody"></div></div></div>'
    .. '<script>var STEPS_DATA = ' .. steps_json .. ';var TASK_ID = ' .. task_id_json .. ';</script>'
    .. REPORT_JS
    .. '</body>\n</html>'

teamyar.write_result(html)
