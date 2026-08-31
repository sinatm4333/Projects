-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/09 20:20

-- ابزار موقت نگهداری bot_command: قطع/اتصال لینک مبدأ و اصلاح run_path در صورت drift.
-- پیش‌نیاز ذخیرهٔ بات‌های لینک‌شده (که بدون قطع لینک با 502 مواجه می‌شود — CLAUDE.md) و
-- رفع باگ شناخته‌شدهٔ drift کردن run_path بعد از آپدیت API (همان مستند).
-- ورودی: bot_id (الزامی)، mode = detach_src | reattach_src | set_run_path.
-- reattach_src نیاز به src_command_id و src_domain دارد. set_run_path نیاز به run_path دارد.
-- خروجی JSON {ok, error?}. بعد از استفاده حذف/غیرفعال شود.

local input = teamyar.get_input() or {}
local bot_id = tonumber(input["bot_id"])
local mode = input["mode"] or "detach_src"

local function out(o) teamyar.write_result(json.encode(o)) end

if bot_id == nil or bot_id <= 0 then
    out({ ok = false, error = "bot_id نامعتبر است" })
    return
end

local function run_update(query, params)
    local ok, err = pcall(function()
        db.use_db("0000000")
        db.start()
        db.query_immediate({ query = query, params = params })
        db.commit()
        db.query_free()
    end)
    return ok, err
end

if mode == "detach_src" then
    local ok, err = run_update(
        "UPDATE bot_command SET SRC_COMMAND_ID = 0, SRC_DOMAIN = '' WHERE ID = ?",
        { bot_id }
    )
    if not ok then out({ ok = false, error = tostring(err) }); return end
    out({ ok = true, bot_id = bot_id, mode = mode })
    return
end

if mode == "reattach_src" then
    local src_command_id = tonumber(input["src_command_id"])
    local src_domain = input["src_domain"]
    if src_command_id == nil or src_domain == nil or src_domain == "" then
        out({ ok = false, error = "src_command_id/src_domain نامعتبر است" })
        return
    end
    local ok, err = run_update(
        "UPDATE bot_command SET SRC_COMMAND_ID = ?, SRC_DOMAIN = ? WHERE ID = ?",
        { src_command_id, src_domain, bot_id }
    )
    if not ok then out({ ok = false, error = tostring(err) }); return end
    out({ ok = true, bot_id = bot_id, mode = mode })
    return
end

if mode == "set_run_path" then
    local run_path = input["run_path"]
    if run_path == nil or run_path == "" then
        out({ ok = false, error = "run_path نامعتبر است" })
        return
    end
    local ok, err = run_update(
        "UPDATE bot_command SET run_path = ? WHERE ID = ?",
        { run_path, bot_id }
    )
    if not ok then out({ ok = false, error = tostring(err) }); return end
    out({ ok = true, bot_id = bot_id, mode = mode, run_path = run_path })
    return
end

out({ ok = false, error = "mode ناشناخته" })
