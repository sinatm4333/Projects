local input = teamyar.get_input() or {}
local dialog_id = input["dialog_id"] or input["dialogId"]
    or input["conversation_id"] or input["conversationId"]
    or input["id"]

if dialog_id == nil or dialog_id == "" then
    teamyar.write_result(json.encode({
        ok = false,
        error = "شماره گفتگو (dialog_id) وارد نشده است"
    }))
    return
end

dialog_id = tonumber(dialog_id) or dialog_id

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

local function fail(message, detail)
    teamyar.write_result(json.encode({
        ok = false,
        error = message,
        detail = detail
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

local function dialog_status_label(status_code)
    local code = tonumber(status_code)
    if code == nil then
        return "نامشخص"
    end
    if code == 0 then
        return "باز"
    end
    if code == 1 then
        return "بسته"
    end
    if code == 2 then
        return "در انتظار"
    end
    return "وضعیت " .. code
end

local function dialog_type_label(type_code)
    local code = tonumber(type_code)
    if code == nil then
        return "نامشخص"
    end
    if code == 0 then
        return "خصوصی"
    end
    if code == 1 then
        return "گروهی"
    end
    if code == 2 then
        return "عمومی"
    end
    if code == 3 then
        return "ربات"
    end
    return "نوع " .. code
end

local function message_type_label(type_code)
    local code = tonumber(type_code)
    if code == nil then
        return "نامشخص"
    end
    if code == 0 then
        return "متن"
    end
    if code == 1 then
        return "فایل"
    end
    if code == 2 then
        return "تصویر"
    end
    if code == 3 then
        return "صوت"
    end
    if code == 4 then
        return "ویدیو"
    end
    if code == 5 then
        return "سیستمی"
    end
    if code == 6 then
        return "ربات"
    end
    return "نوع " .. code
end

local SOURCE_LABELS = {
    dialog_author = "ایجادکننده گفتگو",
    dialog_related = "مخاطب مرتبط",
    dialog_contact = "مخاطب گفتگو",
    dialog_favorite = "نشان‌شده",
    dialog_mute = "بی‌صدا",
    message_sender = "فرستنده پیام"
}

local function source_labels_from_csv(sources_csv)
    if sources_csv == nil or sources_csv == "" then
        return {}
    end

    local labels = {}
    for source in string.gmatch(sources_csv, "[^,%s]+") do
        table.insert(labels, SOURCE_LABELS[source] or source)
    end
    return labels
end

local function build_participant_record(row)
    local message_count = tonumber(row[4]) or 0
    local sources = normalize_text(row[3])

    return {
        user_id = tonumber(row[1]) or row[1],
        user_name = normalize_text(row[2]),
        sources = sources,
        source_labels = source_labels_from_csv(sources),
        message_count = message_count,
        has_sent_message = message_count > 0,
        is_group = tonumber(row[8]) == 1,
        first_message_date = row[5],
        last_message_date = row[6],
        last_view_time = row[7]
    }
end

local function load_dialog_participants(dialog_id_value)
    local participants_query = [[
SELECT
    participants.user_id,
    pm.fullname AS user_name,
    participants.sources,
    COALESCE(msg_stats.message_count, 0) AS message_count,
    COALESCE(pm.is_role, 0) AS is_group
FROM (
    SELECT
        merged.user_id,
        GROUP_CONCAT(DISTINCT merged.source ORDER BY merged.source SEPARATOR ', ') AS sources,
        MAX(merged.view_time) AS view_time
    FROM (
        SELECT
            cd.AUTHOR_ID AS user_id,
            'dialog_author' AS source,
            NULL AS view_time
        FROM chat_dialogs cd
        WHERE cd.ID = ?
          AND cd.AUTHOR_ID IS NOT NULL
          AND cd.AUTHOR_ID > 0

        UNION ALL

        SELECT
            cd.RELATED_ID AS user_id,
            'dialog_related' AS source,
            NULL AS view_time
        FROM chat_dialogs cd
        WHERE cd.ID = ?
          AND cd.RELATED_ID IS NOT NULL
          AND cd.RELATED_ID > 0

        UNION ALL

        SELECT
            cdv.USER_ID AS user_id,
            'dialog_contact' AS source,
            cdv.VIEW_TIME AS view_time
        FROM chat_dialog_view cdv
        WHERE cdv.DIALOG_ID = ?
          AND cdv.USER_ID IS NOT NULL
          AND cdv.USER_ID > 0

        UNION ALL

        SELECT
            cdf.USER_ID AS user_id,
            'dialog_favorite' AS source,
            NULL AS view_time
        FROM chat_dialog_favorite cdf
        WHERE cdf.DIALOG_ID = ?
          AND cdf.USER_ID IS NOT NULL
          AND cdf.USER_ID > 0

        UNION ALL

        SELECT
            cdm.USER_ID AS user_id,
            'dialog_mute' AS source,
            NULL AS view_time
        FROM chat_dialog_mute cdm
        WHERE cdm.DIALOG_ID = ?
          AND cdm.USER_ID IS NOT NULL
          AND cdm.USER_ID > 0

        UNION ALL

        SELECT
            cm.USER_ID AS user_id,
            'message_sender' AS source,
            NULL AS view_time
        FROM chat_message cm
        WHERE cm.DIALOG_ID = ?
          AND cm.USER_ID IS NOT NULL
          AND cm.USER_ID > 0
    ) merged
    GROUP BY merged.user_id
) participants
LEFT JOIN profile_main pm
    ON pm.id = participants.user_id
LEFT JOIN (
    SELECT
        cm.USER_ID,
        COUNT(*) AS message_count,
        MIN(cm.DATE_CREATE) AS first_message_raw,
        MAX(cm.DATE_CREATE) AS last_message_raw
    FROM chat_message cm
    WHERE cm.DIALOG_ID = ?
      AND cm.USER_ID IS NOT NULL
      AND cm.USER_ID > 0
    GROUP BY cm.USER_ID
) msg_stats
    ON msg_stats.USER_ID = participants.user_id
ORDER BY
    COALESCE(pm.is_role, 0) ASC,
    COALESCE(msg_stats.message_count, 0) DESC,
    pm.fullname,
    participants.user_id
]]

    return fetch_rows(participants_query, {
        dialog_id_value,
        dialog_id_value,
        dialog_id_value,
        dialog_id_value,
        dialog_id_value,
        dialog_id_value,
        dialog_id_value
    })
end

local function split_participants(participant_rows)
    local participants = {}
    local participants_with_messages = {}
    local participants_without_messages = {}

    for _, row in ipairs(participant_rows) do
        local participant = build_participant_record(row)
        table.insert(participants, participant)

        if participant.has_sent_message then
            table.insert(participants_with_messages, participant)
        elseif not participant.is_group then
            table.insert(participants_without_messages, participant)
        end
    end

    return participants, participants_with_messages, participants_without_messages
end

local dialog_query = [[
SELECT
    cd.ID AS dialog_id,
    cd.GROUP_ID AS group_id,
    cg.NAME AS group_name,
    cg.PUBLIC_NAME AS group_public_name,
    cd.STATUS AS status_code,
    cd.TYPE AS type_code,
    cd.TOPIC AS topic,
    cd.AUTHOR_ID AS author_id,
    COALESCE(pm.fullname, cd.AUTHOR_NAME) AS author_name,
    cd.AUTHOR_MOBILE AS author_mobile,
    cd.SESSION AS session,
    cd.RELATED_ID AS related_id,
    cd.bot_id AS bot_id,
    cd.disconnect_from_bot AS disconnect_from_bot,
    cd.one_way_channel AS one_way_channel,
    COALESCE(cd.deleted, 0) AS deleted
FROM chat_dialogs cd
LEFT JOIN chat_group cg
    ON cg.ID = cd.GROUP_ID
LEFT JOIN profile_main pm
    ON pm.id = cd.AUTHOR_ID
WHERE cd.ID = ?
LIMIT 1
]]

local dialog_rows, dialog_err = fetch_rows(dialog_query, { dialog_id })
if dialog_rows == nil then
    fail("خطا در دریافت اطلاعات گفتگو", tostring(dialog_err))
    return
end

if #dialog_rows == 0 then
    teamyar.write_result(json.encode({
        ok = false,
        error = "گفتگویی با این شماره یافت نشد",
        dialog_id = dialog_id
    }))
    return
end

local dialog_row = dialog_rows[1]
local dialog = {
    dialog_id = tonumber(dialog_row[1]) or dialog_row[1],
    group_id = tonumber(dialog_row[2]) or dialog_row[2],
    group_name = dialog_row[3],
    group_public_name = dialog_row[4],
    status_code = tonumber(dialog_row[5]) or dialog_row[5],
    status_label = dialog_status_label(dialog_row[5]),
    type_code = tonumber(dialog_row[6]) or dialog_row[6],
    type_label = dialog_type_label(dialog_row[6]),
    topic = dialog_row[7],
    author_id = tonumber(dialog_row[8]) or dialog_row[8],
    author_name = dialog_row[9],
    author_mobile = dialog_row[10],
    session = dialog_row[11],
    date_create = dialog_row[12],
    date_end = dialog_row[13],
    last_modified = dialog_row[14],
    related_id = tonumber(dialog_row[15]) or dialog_row[15],
    bot_id = tonumber(dialog_row[16]) or dialog_row[16],
    disconnect_from_bot = tonumber(dialog_row[17]) == 1,
    one_way_channel = tonumber(dialog_row[18]) == 1,
    deleted = tonumber(dialog_row[19]) == 1
}

local messages_query = [[
SELECT
    cm.ID AS message_id,
    cm.USER_ID AS sender_id,
    COALESCE(sender.fullname, '') AS sender_name,
    cm.RELATED_USER_ID AS related_user_id,
    COALESCE(related.fullname, '') AS related_user_name,
    cm.TYPE AS type_code,
    cm.CONTENT AS content,
        cm.REPLY_ID AS reply_id,
    cm.forward_id AS forward_id,
    COALESCE(cm.is_public, 0) AS is_public
FROM chat_message cm
LEFT JOIN profile_main sender
    ON sender.id = cm.USER_ID
LEFT JOIN profile_main related
    ON related.id = cm.RELATED_USER_ID
WHERE cm.DIALOG_ID = ?
ORDER BY cm.DATE_CREATE ASC, cm.ID ASC
]]

local message_rows, messages_err = fetch_rows(messages_query, { dialog_id })
if message_rows == nil then
    fail("خطا در دریافت پیام‌های گفتگو", tostring(messages_err))
    return
end

local messages = {}
for _, row in ipairs(message_rows) do
    local content = normalize_text(row[7])
    table.insert(messages, {
        message_id = tonumber(row[1]) or row[1],
        sender_id = tonumber(row[2]) or row[2],
        sender_name = normalize_text(row[3]),
        related_user_id = tonumber(row[4]) or row[4],
        related_user_name = normalize_text(row[5]),
        type_code = tonumber(row[6]) or row[6],
        type_label = message_type_label(row[6]),
        content = content,
        content_text = html_to_text(content),
        date_create = row[8],
        last_modified = row[9],
        reply_id = tonumber(row[10]) or row[10],
        forward_id = tonumber(row[11]) or row[11],
        is_public = tonumber(row[12]) == 1
    })
end

local participant_rows, participants_err = load_dialog_participants(dialog.dialog_id)
if participant_rows == nil then
    fail("خطا در دریافت شرکت‌کنندگان گفتگو", tostring(participants_err))
    return
end

local participants, participants_with_messages, participants_without_messages =
    split_participants(participant_rows)

teamyar.write_result(json.encode({
    ok = true,
    dialog_id = dialog.dialog_id,
    dialog = dialog,
    participant_count = #participants,
    active_participant_count = #participants_with_messages,
    silent_participant_count = #participants_without_messages,
    participants = participants,
    participants_with_messages = participants_with_messages,
    participants_without_messages = participants_without_messages,
    message_count = #messages,
    messages = messages
}))
