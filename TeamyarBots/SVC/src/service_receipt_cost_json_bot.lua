-- تحلیل و ایجاد توسط مهدی جهانی 09125632329

local input = teamyar.get_input() or {}

local receipt_no = input["receipt_no"] or input["receiptNo"] or input["code"]
    or input["receipt_number"] or input["receiptNumber"]

local MONEY_SCALE = 10000000.0

local function fail(message, detail)
    if detail ~= nil and detail ~= "" then
        message = message .. ": " .. tostring(detail)
    end
    teamyar.write_result(json.encode({
        ok = false,
        error = message
    }))
end

local function normalize_text(value)
    if value == nil then
        return nil
    end
    local s = tostring(value):match("^%s*(.-)%s*$")
    if s == "" then
        return nil
    end
    return s
end

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then
        return n
    end
    return nil
end

local function normalize_product_code(code)
    if code == nil or code == "" then
        return nil
    end
    return tostring(code):match("^%s*(.-)%s*$")
end

local function normalize_money_value(value)
    local n = tonumber(value) or 0
    if n <= 0 then
        return 0
    end
    if n >= MONEY_SCALE then
        return math.floor(n / MONEY_SCALE + 0.5)
    end
    return math.floor(n + 0.5)
end

local function normalize_quantity_value(value)
    local n = tonumber(value) or 0
    if n <= 0 then
        return 0
    end
    if n >= MONEY_SCALE then
        return n / MONEY_SCALE
    end
    return n
end

local function multiply_cogs(unit_cogs, quantity_raw)
    return normalize_money_value(unit_cogs) * normalize_quantity_value(quantity_raw)
end

local function build_in_clause(values)
    local placeholders = {}
    for _ = 1, #values do
        table.insert(placeholders, "?")
    end
    return table.concat(placeholders, ", ")
end

local function run_query(query, params)
    pcall(function()
        db.use_db("0000000")
    end)
    db.query({
        query = query,
        params = params or {}
    })
end

local function fetch_rows(query, params)
    local ok, err = pcall(function()
        run_query(query, params)
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

local function purchase_invoice_filter_sql()
    return [[
  COALESCE(pi.DELETED, 0) = 0
  AND COALESCE(pi.CANCELED, 0) = 0
  AND COALESCE(pi.REJECT, 0) = 0
  AND COALESCE(pi.TYPE, 0) NOT IN (1, 5)]]
end

local function load_product_unit_cogs(product_ids)
    local cogs_by_product = {}
    local normalized_ids = {}
    local seen = {}

    for _, id in ipairs(product_ids or {}) do
        local normalized = normalize_entity_id(id)
        if normalized ~= nil and not seen[normalized] then
            seen[normalized] = true
            table.insert(normalized_ids, normalized)
        end
    end

    if #normalized_ids == 0 then
        return cogs_by_product
    end

    local id_in_clause = build_in_clause(normalized_ids)
    local id_params = {}
    for _, id in ipairs(normalized_ids) do
        table.insert(id_params, id)
    end

    local cardindex_rows = fetch_rows(
        [[SELECT PRODUCT_ID, MAX(COALESCE(RATE_CARDINDEX, 0)) AS RATE_CARDINDEX
FROM wh_product_cardindex
WHERE PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY PRODUCT_ID
HAVING MAX(COALESCE(RATE_CARDINDEX, 0)) > 0]],
        id_params
    )
    if cardindex_rows ~= nil then
        for _, row in ipairs(cardindex_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 then
                cogs_by_product[product_id] = unit_cogs
            end
        end
    end

    local purchase_query = [[
SELECT
    pip.PRODUCT_ID,
    SUM(
        COALESCE(
            NULLIF(pip.fee_sales, 0),
            NULLIF(pip.FEE, 0),
            CASE
                WHEN COALESCE(pip.PRICE, 0) > 0
                     AND COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 0) > 0
                THEN pip.PRICE / COALESCE(NULLIF(pip.QUANTITY, 0), pip.QUANTITY_SEC, 1)
                ELSE 0
            END
        ) * GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)
    ) / NULLIF(SUM(GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)), 0) AS raw_unit_cost
FROM purchase_invoice_product pip
INNER JOIN purchase_invoice pi
    ON pi.ID = pip.INVOICE_ID
WHERE ]] .. purchase_invoice_filter_sql() .. [[
  AND pip.PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY pip.PRODUCT_ID
HAVING raw_unit_cost > 0
]]

    local purchase_rows = fetch_rows(purchase_query, id_params)
    if purchase_rows ~= nil then
        for _, row in ipairs(purchase_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 and cogs_by_product[product_id] == nil then
                cogs_by_product[product_id] = unit_cogs
            end
        end
    end

    local missing_ids = {}
    for _, id in ipairs(normalized_ids) do
        if cogs_by_product[id] == nil then
            table.insert(missing_ids, id)
        end
    end

    if #missing_ids > 0 then
        local missing_clause = build_in_clause(missing_ids)
        local missing_params = {}
        for _, id in ipairs(missing_ids) do
            table.insert(missing_params, id)
        end
        local price_rows = fetch_rows(
            "SELECT PRODUCT_ID, MAX(COALESCE(PRICE, 0)) AS PRICE FROM wh_product_price WHERE PRODUCT_ID IN ("
                .. missing_clause .. ") GROUP BY PRODUCT_ID HAVING MAX(COALESCE(PRICE, 0)) > 0",
            missing_params
        )
        if price_rows ~= nil then
            for _, row in ipairs(price_rows) do
                local product_id = normalize_entity_id(row[1])
                local unit_cogs = normalize_money_value(row[2])
                if product_id ~= nil and unit_cogs > 0 then
                    cogs_by_product[product_id] = unit_cogs
                end
            end
        end
    end

    return cogs_by_product
end

local function get_unit_cogs(cogs_by_product, product_id)
    local id = normalize_entity_id(product_id)
    if id == nil then
        return 0
    end
    return cogs_by_product[id] or 0
end

local function build_section()
    return {
        exists = false,
        count = 0,
        total_cogs = 0,
        items = {}
    }
end

local function add_item(section, item)
    section.exists = true
    section.count = section.count + 1
    section.total_cogs = section.total_cogs + (tonumber(item.line_cogs) or 0)
    table.insert(section.items, item)
end

local function finalize_section(section)
    section.total_cogs = math.floor((section.total_cogs or 0) + 0.5)
    return section
end

local function receipt_status_label(status)
    local n = tonumber(status)
    if n == 0 then return "پیش پذیرش" end
    if n == 1 then return "بررسی" end
    if n == 2 then return "اجرا" end
    if n == 3 then return "کامل (تعمیر شده)" end
    if n == 4 then return "کامل (رد هزینه)" end
    if n == 5 then return "باطل" end
    if n == 6 then return "آماده تحویل (تعمیر شده)" end
    if n == 7 then return "آماده تحویل (رد هزینه)" end
    if n == 8 then return "آماده تحویل (تعویض شده)" end
    if n == 9 then return "کامل (تعویض شده)" end
    return "نامشخص"
end

local function swap_type_label(swap_type)
    local n = tonumber(swap_type)
    if n == 0 then return "کالای تحویلی" end
    if n == 1 then return "کالای جایگزین" end
    return "سایر"
end

if receipt_no == nil or receipt_no == "" then
    fail("شماره رسید (receipt_no) وارد نشده است")
    return
end

receipt_no = normalize_text(receipt_no)

local sr_rows, sr_err = fetch_rows([[
SELECT
    sr.ID,
    sr.CODE,
    sr.FINAL_STATUS,
    sr.PRODUCT_SERIAL,
    REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') AS breakdown_date,
    orig.FULL_CODE,
    orig.full_name
FROM pm_service_request sr
LEFT JOIN wh_product orig
    ON orig.id = sr.PRODUCT_ID
WHERE sr.CODE = ?
LIMIT 1
]], { receipt_no })

if sr_rows == nil then
    fail("خطا در جستجوی رسید", sr_err)
    return
end

if #sr_rows == 0 then
    fail("رسیدی با شماره " .. tostring(receipt_no) .. " یافت نشد")
    return
end

local sr = sr_rows[1]
local service_request_id = normalize_entity_id(sr[1])
local final_status = tonumber(sr[3]) or sr[3]

local consumed_parts = build_section()
local replacement = build_section()
local refund = build_section()

local product_ids = {}
local seen_product_ids = {}

local function track_product_id(product_id)
    local id = normalize_entity_id(product_id)
    if id ~= nil and not seen_product_ids[id] then
        seen_product_ids[id] = true
        table.insert(product_ids, id)
    end
    return id
end

local parts_rows = fetch_rows([[
SELECT
    parts.PRODUCT_ID,
    parts.product_code,
    parts.product_name,
    parts.qty
FROM (
    SELECT
        rpd.PRODUCT_ID,
        TRIM(wp.FULL_CODE) AS product_code,
        wp.full_name AS product_name,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd
        ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_service_request sr
        ON sr.id = rp.REF_ID
    LEFT JOIN wh_product wp
        ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0
      AND rp.REQUEST_TYPE = 5
      AND rp.REF_TYPE = 101
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id = ?

    UNION ALL

    SELECT
        rpd.PRODUCT_ID,
        TRIM(wp.FULL_CODE) AS product_code,
        wp.full_name AS product_name,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd
        ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_cost_declaration_detail cd
        ON cd.ID = rp.REF_ID
    INNER JOIN pm_cost_declaration c
        ON c.ID = cd.COST_DECLARATION_ID
    INNER JOIN pm_service_request sr
        ON sr.id = c.SERVICE_REQUEST_ID
    LEFT JOIN wh_product wp
        ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0
      AND rp.REQUEST_TYPE = 5
      AND rp.REF_TYPE = 109
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id = ?
) parts
WHERE COALESCE(parts.qty, 0) > 0
]], { service_request_id, service_request_id })

if parts_rows ~= nil then
    for _, row in ipairs(parts_rows) do
        track_product_id(row[1])
    end
end

local swap_rows = fetch_rows([[
SELECT
    psd.PRODUCT_ID,
    TRIM(repl.FULL_CODE) AS product_code,
    repl.full_name AS product_name,
    psd.SWAP_TYPE,
    psd.AMOUNT,
    psd.VALUE,
    REPORT_FN_JDATE(ps.SWAP_DATE, '-') AS swap_date
FROM pm_swap ps
INNER JOIN pm_swap_detail psd
    ON psd.SWAP_ID = ps.ID
LEFT JOIN wh_product repl
    ON repl.id = psd.PRODUCT_ID
WHERE ps.SERVICE_REQUEST_ID = ?
]], { service_request_id })

if swap_rows ~= nil then
    for _, row in ipairs(swap_rows) do
        track_product_id(row[1])
    end
end

local refund_rows = fetch_rows([[
SELECT
    cdd.PRODUCT_ID,
    TRIM(wp.FULL_CODE) AS product_code,
    wp.full_name AS product_name,
    cdd.AMOUNT,
    cdd.COST,
    cd.FINAL_STATUS,
    CASE cd.FINAL_STATUS
        WHEN 5 THEN 'رد هزینه'
        WHEN 0 THEN 'باطل'
        WHEN 1 THEN 'در انتظار تایید'
        WHEN 4 THEN 'تایید'
        ELSE 'سایر'
    END AS status_label
FROM pm_cost_declaration cd
INNER JOIN pm_cost_declaration_detail cdd
    ON cdd.COST_DECLARATION_ID = cd.ID
LEFT JOIN wh_product wp
    ON wp.id = cdd.PRODUCT_ID
WHERE cd.SERVICE_REQUEST_ID = ?
  AND cd.FINAL_STATUS = 5
]], { service_request_id })

if refund_rows ~= nil then
    for _, row in ipairs(refund_rows) do
        track_product_id(row[1])
    end
end

local orig_product_query = fetch_rows(
    "SELECT PRODUCT_ID FROM pm_service_request WHERE ID = ?",
    { service_request_id }
)
if orig_product_query ~= nil and #orig_product_query > 0 then
    track_product_id(orig_product_query[1][1])
end

local cogs_by_product = load_product_unit_cogs(product_ids)

if parts_rows ~= nil then
    for _, row in ipairs(parts_rows) do
        local product_id = normalize_entity_id(row[1])
        local qty = normalize_quantity_value(row[4])
        if qty > 0 then
            local unit_cogs = get_unit_cogs(cogs_by_product, product_id)
            add_item(consumed_parts, {
                product_id = product_id,
                product_code = normalize_product_code(row[2]),
                product_name = normalize_text(row[3]),
                quantity = qty,
                unit_cogs = unit_cogs,
                line_cogs = math.floor(multiply_cogs(unit_cogs, row[4]) + 0.5)
            })
        end
    end
end

if swap_rows ~= nil then
    for _, row in ipairs(swap_rows) do
        local swap_type = tonumber(row[4]) or row[4]
        if tonumber(swap_type) == 1 then
            local product_id = normalize_entity_id(row[1])
            local qty = normalize_quantity_value(row[5])
            if qty <= 0 then
                qty = 1
            end
            local unit_cogs = get_unit_cogs(cogs_by_product, product_id)
            add_item(replacement, {
                product_id = product_id,
                product_code = normalize_product_code(row[2]),
                product_name = normalize_text(row[3]),
                swap_type = swap_type,
                swap_type_label = swap_type_label(swap_type),
                quantity = qty,
                unit_cogs = unit_cogs,
                line_cogs = math.floor(multiply_cogs(unit_cogs, row[5]) + 0.5),
                swap_date = row[7]
            })
        end
    end
end

if refund_rows ~= nil and #refund_rows > 0 then
    for _, row in ipairs(refund_rows) do
        local product_id = normalize_entity_id(row[1])
        local qty = normalize_quantity_value(row[4])
        if qty <= 0 then
            qty = 1
        end
        local declared_cost = normalize_money_value(row[5])
        local unit_cogs = get_unit_cogs(cogs_by_product, product_id)
        local line_cogs = declared_cost
        if line_cogs <= 0 then
            line_cogs = math.floor(multiply_cogs(unit_cogs, row[4]) + 0.5)
        end
        add_item(refund, {
            product_id = product_id,
            product_code = normalize_product_code(row[2]),
            product_name = normalize_text(row[3]),
            quantity = qty,
            declared_cost = declared_cost,
            unit_cogs = unit_cogs,
            line_cogs = line_cogs,
            status_label = normalize_text(row[7])
        })
    end
elseif final_status == 4 or final_status == 7 then
    local orig_id = nil
    if orig_product_query ~= nil and #orig_product_query > 0 then
        orig_id = normalize_entity_id(orig_product_query[1][1])
    end
    local unit_cogs = get_unit_cogs(cogs_by_product, orig_id)
    if unit_cogs > 0 then
        add_item(refund, {
            product_id = orig_id,
            product_code = normalize_product_code(sr[6]),
            product_name = normalize_text(sr[7]),
            quantity = 1,
            unit_cogs = unit_cogs,
            line_cogs = unit_cogs,
            status_label = receipt_status_label(final_status),
            note = "برآورد بر اساس بهای تمام‌شده کالای پذیرش (رد هزینه)"
        })
    end
end

consumed_parts = finalize_section(consumed_parts)
replacement = finalize_section(replacement)
refund = finalize_section(refund)

teamyar.write_result(json.encode({
    ok = true,
    receipt_no = tonumber(receipt_no) or receipt_no,
    service_request_id = service_request_id,
    status_code = final_status,
    status_label = receipt_status_label(final_status),
    product_serial = normalize_text(sr[4]),
    breakdown_date = normalize_text(sr[5]),
    original_product_code = normalize_product_code(sr[6]),
    original_product_name = normalize_text(sr[7]),
    consumed_parts = consumed_parts,
    replacement = replacement,
    refund = refund,
    grand_total_cogs = consumed_parts.total_cogs
        + replacement.total_cogs
        + refund.total_cogs
}))
