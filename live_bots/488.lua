-- Bot: action_kpi_discover_cols

db.use_db("0000000")

local function fetch_cols(tbl)
  local cols = {}
  db.query({
    query = [[
      select COLUMN_NAME, DATA_TYPE
      from information_schema.COLUMNS
      where TABLE_SCHEMA = '0000000'
        and TABLE_NAME = ?
      order by ORDINAL_POSITION
    ]],
    params = { tbl }
  })

  local r = {}
  while db.query_fetch(r) do
    table.insert(cols, { name = r[1], type = r[2] })
  end
  db.query_free()
  return cols
end

local function fetch_suspects(tbl)
  local cols = {}
  db.query({
    query = [[
      select COLUMN_NAME, DATA_TYPE
      from information_schema.COLUMNS
      where TABLE_SCHEMA = '0000000'
        and TABLE_NAME = ?
        and (
          COLUMN_NAME like '%create%' or
          COLUMN_NAME like '%date%' or
          COLUMN_NAME like '%time%' or
          COLUMN_NAME like '%author%' or
          COLUMN_NAME like '%creator%' or
          COLUMN_NAME like '%user%' or
          COLUMN_NAME like '%status%' or
          COLUMN_NAME like '%state%' or
          COLUMN_NAME like '%owner%'
        )
      order by COLUMN_NAME
    ]],
    params = { tbl }
  })

  local r = {}
  while db.query_fetch(r) do
    table.insert(cols, { name = r[1], type = r[2] })
  end
  db.query_free()
  return cols
end

local out = {
  todo_task = {
    suspects = fetch_suspects("todo_task"),
    all = fetch_cols("todo_task")
  },
  todo_task_steps = {
    suspects = fetch_suspects("todo_task_steps"),
    all = fetch_cols("todo_task_steps")
  }
}

teamyar.write_result(json.encode(out))
