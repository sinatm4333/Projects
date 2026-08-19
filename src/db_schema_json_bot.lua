-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

local input = teamyar.get_input() or {}
local table_filter = input["table"] or input["table_name"] or input["tableName"]
local schema_name = input["schema"] or input["database"] or input["db"]

local params = {}
local schema_clause = "TABLE_SCHEMA = DATABASE()"
if schema_name ~= nil and schema_name ~= "" then
    schema_clause = "TABLE_SCHEMA = ?"
    table.insert(params, schema_name)
end

local table_clause = ""
if table_filter ~= nil and table_filter ~= "" then
    table_clause = " AND TABLE_NAME LIKE ?"
    table.insert(params, table_filter)
end

local tables_query = [[
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE,
    ENGINE,
    TABLE_ROWS,
    TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE ]] .. schema_clause .. [[
  AND TABLE_TYPE = 'BASE TABLE'
]] .. table_clause .. [[
ORDER BY TABLE_NAME
]]

local columns_query = [[
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    COLUMN_DEFAULT,
    IS_NULLABLE,
    DATA_TYPE,
    COLUMN_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    COLUMN_KEY,
    EXTRA,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE ]] .. schema_clause .. table_clause .. [[
ORDER BY TABLE_NAME, ORDINAL_POSITION
]]

local fk_query = [[
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_SCHEMA,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE ]] .. schema_clause .. [[
  AND REFERENCED_TABLE_NAME IS NOT NULL
]] .. table_clause .. [[
ORDER BY TABLE_NAME, ORDINAL_POSITION
]]

local indexes_query = [[
SELECT
  TABLE_NAME,
  INDEX_NAME,
  NON_UNIQUE,
  SEQ_IN_INDEX,
  COLUMN_NAME,
  INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE ]] .. schema_clause .. table_clause .. [[
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX
]]

local function run_query(query, query_params)
    db.query({
        query = query,
        params = query_params or {}
    })

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

local table_rows = run_query(tables_query, params)
if #table_rows == 0 then
    teamyar.write_result(json.encode({
        ok = false,
        error = "جدولی یافت نشد",
        schema = schema_name,
        table_filter = table_filter
    }))
    return
end

local schema = table_rows[1][1]
local tables = {}

for _, row in ipairs(table_rows) do
    local table_name = row[2]
    tables[table_name] = {
        table_type = row[3],
        engine = row[4],
        approx_rows = row[5],
        comment = row[6] or "",
        columns = {},
        primary_key = {},
        foreign_keys = {},
        indexes = {}
    }
end

for _, row in ipairs(run_query(columns_query, params)) do
    local table_name = row[1]
    local table_info = tables[table_name]
    if table_info ~= nil then
        local column = {
            name = row[2],
            position = row[3],
            default = row[4],
            nullable = row[5] == "YES",
            data_type = row[6],
            column_type = row[7],
            max_length = row[8],
            numeric_precision = row[9],
            numeric_scale = row[10],
            key = row[11],
            extra = row[12] or "",
            comment = row[13] or ""
        }
        table.insert(table_info.columns, column)

        if row[11] == "PRI" then
            table.insert(table_info.primary_key, row[2])
        end
    end
end

for _, row in ipairs(run_query(fk_query, params)) do
    local table_name = row[1]
    local table_info = tables[table_name]
    if table_info ~= nil then
        table.insert(table_info.foreign_keys, {
            column = row[2],
            constraint = row[3],
            referenced_schema = row[4],
            referenced_table = row[5],
            referenced_column = row[6]
        })
    end
end

local index_map = {}
for _, row in ipairs(run_query(indexes_query, params)) do
    local table_name = row[1]
    local table_info = tables[table_name]
    if table_info ~= nil then
        local index_name = row[2]
        local map_key = table_name .. "::" .. index_name
        if index_map[map_key] == nil then
            index_map[map_key] = {
                name = index_name,
                unique = row[3] == 0,
                type = row[6],
                columns = {}
            }
            table.insert(table_info.indexes, index_map[map_key])
        end
        table.insert(index_map[map_key].columns, row[5])
    end
end

local table_names = {}
for table_name, _ in pairs(tables) do
    table.insert(table_names, table_name)
end
table.sort(table_names)

local ordered_tables = {}
for _, table_name in ipairs(table_names) do
    ordered_tables[table_name] = tables[table_name]
end

teamyar.write_result(json.encode({
    ok = true,
    schema = schema,
    table_filter = table_filter,
    table_count = #table_names,
    tables = ordered_tables
}))
