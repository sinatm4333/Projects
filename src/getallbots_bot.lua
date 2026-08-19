local query = [[
SELECT
    bc.ID,
    bc.NAME,
    bc.DESCRIPTION,
    bc.COMMAND,
    COALESCE(bcr.RUN_COUNT, 0) AS RUN_COUNT,
    bc.DISABLED,
    bc.OPEN_SOURCE,
    bc.SRC_VERSION
FROM bot_command bc
LEFT JOIN bot_command_run bcr
    ON bcr.COMMAND_ID = bc.ID
ORDER BY bc.ID DESC
]]

local ok = pcall(function()
    db.query({
        query = query,
        params = {}
    })
end)

if not ok then
    teamyar.write_result(json.encode({
        ok = false,
        error = "خطا در دریافت فهرست بات‌ها"
    }))
    return
end

local bots = {}
local record = {}

while db.query_fetch(record) do
    table.insert(bots, {
        id = tonumber(record[1]) or record[1],
        name = record[2],
        description = record[3],
        source_code = record[4],
        run_count = tonumber(record[5]) or 0,
        disabled = tonumber(record[6]) == 1,
        open_source = tonumber(record[7]) == 1,
        source_version = tonumber(record[8]) or 0
    })
end

db.query_free()

teamyar.write_result(json.encode({
    ok = true,
    bot_count = #bots,
    bots = bots
}))
