-- botName = sales_settlement_report
-- creator = Cascade
-- date = 1405/04/29
-- version = 1.0
-- توضیح: نمایش لیست فاکتورهای قابل تسویه به همراه دکمه تسویه تکی و چک‌باکس برای تسویه گروهی
--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local _PAR_PAGE = 20
local _QUERY_TYPE = {
  _TYPE_TOTAL_SUM = 1,
  _TYPE_TOTAL_COUNT = 2,
  _TYPE_PAGE_REPORT = 3,
  _TYPE_PAGE_EXCEL = 4,
  _TYPE_PAGE_PRINT = 5,
}
local _TYPE_SETTLE_SINGLE = 200;
local _TYPE_SETTLE_BULK = 201;
--------------------------------------------
--- install [RES]
--------------------------------------------
local _BAT_RES_PATH = "2/res_v2";
function readyCodes()
  local data = teamyar.get_input();
  data["res_type"] = "codes"
  data["config"] = json.decode(teamyar.get_attachment("data.txt"))
  local responseRes = teamyar.run_command(_BAT_RES_PATH, data);
  if responseRes ~= nil then
    responseRes = json.decode(responseRes)
    for i = 1, #responseRes, 1 do
      local loadedFunction, errorMessage = load(responseRes[i])
      if loadedFunction then
        loadedFunction();
      else
        teamyar.write_log("Error: " .. errorMessage);
      end
    end
  end
end
readyCodes();
--------------------------------------------
--- tools
--------------------------------------------
function configData()
  local cfg = teamyar.get_config();
  if cfg ~= nil and cfg.data ~= nil then
    return cfg.data;
  end
  return {};
end
--------------------------------------------
function num(v, d)
  local n = tonumber(v);
  if n == nil then
    return d;
  end
  return n;
end
--------------------------------------------
function str(v)
  if v == nil then
    return "";
  end
  return tostring(v);
end
--------------------------------------------
function sqlStr(v)
  local s = str(v);
  s = string.gsub(s, "\\", "\\\\");
  s = string.gsub(s, "'", "\\'");
  return "'" .. s .. "'";
end
--------------------------------------------
function aclIds(v)
  local ids = {};
  if v ~= nil and type(v) == "table" then
    for i, item in ipairs(v) do
      if item ~= nil and item.id ~= nil then
        table.insert(ids, tostring(item.id));
      end
    end
  end
  return ids;
end
--------------------------------------------
-- تبدیل تاریخ امروز (ساعت 00:00:00) به FileTime
function todayFileTime()
  local day = time.get_day(time.current());
  local month = time.get_month(time.current());
  local year = time.get_year(time.current());
  return time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month .. [[,"day":]] .. day .. [[,"hour":0,"minute":0,"second":0}]]);
end
--------------------------------------------
-- بازه زمانی گزارش بر اساس day_befor در config
function dateRangeFileTime()
  local cfg = configData();
  local dayBefore = num(cfg.day_befor, 0);
  local temp_time = todayFileTime();
  local from_date = temp_time - ((60 * 60 * 24 * 10000000 * dayBefore) + (60 * 60 * 24 * 10000000));
  local to_date = temp_time + (60 * 60 * 3 * 10000000);
  return string.format("%.0f", from_date), string.format("%.0f", to_date);
end
--------------------------------------------
--- HTML controls (تولید کنترل‌ها در بک‌اند)
--------------------------------------------
function rowCheckbox(invoiceId)
  return '<input type="checkbox" class="settle-check" value="' .. invoiceId .. '">';
end
--------------------------------------------
function settleButton(invoiceId)
  return '<button class="btn btn-success btn-sm" onclick="report[reportPath].settleSingle(' .. invoiceId .. ')">تسویه</button>';
end
--------------------------------------------
--- data
--------------------------------------------
function getData(queryType, pageFrom, perPage, pageTo)
  local cfg = configData();
  local dataQuery = {
    query = teamyar.get_attachment("mySqlQuery.txt"),
    params = {}
  };

  local qs = getQuery_select(queryType)

  -- org_id: filter overrides config
  local orgInput = getInput("org_id");
  local orgId;
  local orgIds = aclIds(orgInput);
  if #orgIds > 0 then
    orgId = tonumber(orgIds[1]);
  else
    orgId = num(cfg.org_id, 0);
  end

  -- date range: filter overrides config day_befor
  local filterFromDate = getInput("from_date");
  local filterToDate = getInput("to_date");
  local from_date, to_date;
  if filterFromDate ~= nil and filterFromDate ~= "" then
    from_date = tostring(filterFromDate);
  else
    from_date = dateRangeFileTime();
  end
  if filterToDate ~= nil and filterToDate ~= "" then
    to_date = tostring(filterToDate);
  else
    local _, d2 = dateRangeFileTime();
    to_date = d2;
  end

  -- inner CTE filters (string-based, appended as "and ...")
  -- status filter (default: status=2 if not selected)
  local statusInput = getInput("filter_status");
  local statusIds = aclIds(statusInput);
  local whereStatus = " and i.status = 2 ";
  if #statusIds > 0 then
    whereStatus = " and i.status in (" .. table.concat(statusIds, ",") .. ") ";
  end

  -- client filter (inside CTE on cl.id)
  local clientInput = getInput("filter_client");
  local clientIds = aclIds(clientInput);
  local whereClient = "";
  if #clientIds > 0 then
    whereClient = " and cl.id in (" .. table.concat(clientIds, ",") .. ") ";
  end

  -- product filter (EXISTS subquery on sales_invoice_product)
  local productInput = getInput("filter_product");
  local productIds = aclIds(productInput);
  local whereProduct = "";
  if #productIds > 0 then
    whereProduct = " and i.id in (select invoice_id from sales_invoice_product where product_id in (" .. table.concat(productIds, ",") .. ")) ";
  end

  -- warehouse filter (EXISTS subquery on sales_invoice_product)
  local warehouseInput = getInput("filter_warehouse");
  local warehouseIds = aclIds(warehouseInput);
  local whereWarehouse = "";
  teamyar.write_log("warehouseIds---"..json.encode(warehouseIds))
  if #warehouseIds > 0 then
    whereWarehouse = " and i.id in (select invoice_id from sales_invoice_product where stock_id in (" .. table.concat(warehouseIds, ",") .. ")) ";
  end

  -- outer query filters (via queryTools.where)
  local invoiceIdInput = getInput("filter_invoice_id");
  local titleInput = getInput("filter_title");
  local clientTypeInput = getInput("filter_client_type");
  local clientTypeIds = aclIds(clientTypeInput);

  local whereOuterInit = {" 1=1 "};
 local whereOuter = queryTools.where:init(whereOuterInit);

  -- invoice_id LIKE
  teamyar.write_log("innnnnn--------------------"..json.encode(invoiceIdInput))
  teamyar.write_log(type(json.encode(invoiceIdInput)))
  local where_inv_id = ""
  if invoiceIdInput ~= nil and invoiceIdInput ~= "" and tonumber(invoiceIdInput)> 0 then
    where_inv_id = [[ and i.id=]]..invoiceIdInput
  end
  -- title LIKE
  if titleInput ~= nil and titleInput ~= "" then
  --  whereOuter = whereOuter:addLike("invoice_title", titleInput);
  end
  -- client_type IN
  if #clientTypeIds > 0 then
 --   whereOuter = whereOuter:addInStr("client_type", table.concat(clientTypeIds, ","));
  end

  dataQuery.query, dataQuery.params = whereOuter.run(dataQuery.query, dataQuery.params, "{{whereInvoice}}");

  dataQuery.query = string.gsub(dataQuery.query, "{{slicePageNumber}}", getQuery_page(queryType, pageFrom, perPage, pageTo));
  dataQuery.query = string.gsub(dataQuery.query, "{{select}}", qs);
  dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", tostring(orgId));
  dataQuery.query = string.gsub(dataQuery.query, "{{from_date}}", from_date);
  dataQuery.query = string.gsub(dataQuery.query, "{{to_date}}", to_date);
  dataQuery.query = string.gsub(dataQuery.query, "{{whereStatus}}", whereStatus);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_inv_id}}", where_inv_id);
  dataQuery.query = string.gsub(dataQuery.query, "{{whereClient}}", whereClient);
  dataQuery.query = string.gsub(dataQuery.query, "{{whereProduct}}", whereProduct);
  dataQuery.query = string.gsub(dataQuery.query, "{{whereWarehouse}}", whereWarehouse);
-- teamyar.write_log(dataQuery.query)
  local res1 = getQuery_result(queryType, dataQuery);
  return res1
end
--------------------------------------------
function getQuery_select(queryType)
  if queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    return getTableConfig_sum()
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    return getTableConfig_count()
  else
    return getTableConfig_select();
  end
end
--------------------------------------------
function getQuery_page(queryType, pageFrom, perPage, pageTo)
  local slicePageNumber = "";
  if queryType == _QUERY_TYPE._TYPE_PAGE_REPORT then
    local limit = tonumber(perPage);
    local offset = tonumber(pageFrom);
    slicePageNumber = "LIMIT " .. limit .. " OFFSET " .. offset;
  elseif queryType == _QUERY_TYPE._TYPE_PAGE_EXCEL then
    local limit = tonumber(perPage) * (tonumber(pageTo) - tonumber(pageFrom) + 1);
    local offset = tonumber(perPage) * (tonumber(pageFrom) - 1);
    slicePageNumber = "LIMIT " .. limit .. " OFFSET " .. offset;
  end
  return slicePageNumber;
end
--------------------------------------------
function getQuery_result(queryType, dataQuery)
  local resultExp = nil;

  db.query(dataQuery)
  local record = {};
  if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    record = db.query_fetch();
    if record ~= nil then
      resultExp = record[1];
    else
      resultExp = 0;
    end
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    local columnsSelected = {};
    local columns = getTableConfig();
    for i = 1, #columns, 1 do
      local itemColumns = columns[i];
      if itemColumns.key ~= nil and itemColumns.sum ~= nil and itemColumns.sum == true then
        table.insert(columnsSelected, itemColumns.key)
      end
    end
    if #columns > 0 then
      resultExp = {};
      record = db.query_fetch();
      for i = 1, #columnsSelected, 1 do
        resultExp[columnsSelected[i]] = record[i];
      end
    end
  else
    resultExp = {};
    while db.query_fetch(record) do
      local itemRow = {};
      local columns = getTableConfig();
      for i = 1, #columns, 1 do
        local itemColumns = columns[i];
        if itemColumns.key ~= nil then
          itemRow[itemColumns.key] = record[i];
        end
      end
      -- تولید کنترل‌های HTML در بک‌اند و جایگزینی مقادیر خالی
      itemRow.row_checkbox = rowCheckbox(itemRow.invoice_id);
      itemRow.settle_button = settleButton(itemRow.invoice_id);
      table.insert(resultExp, itemRow)
    end
  end
  db.query_free();
  db.use_db("0000000");

  return resultExp;
end
--------------------------------------------
function getTableConfig()
  -- ترتیب ستون‌ها باید دقیقا با ترتیب ستون‌های CTE به نام data در mySqlQuery.txt یکسان باشد
  local cols = {
    { show = true,  key = "row_checkbox",  value = "_table_report_col_checkbox" },
      { show = false,  key = "invoice_id",    value = "invoice_id" },
    { show = true,  key = "invoice_link",    value = "_table_report_col_invoice_id" },
    { show = true,  key = "run_date",      value = "_table_report_col_run_date", type = "date" },
    { show = true,  key = "amount",        value = "_table_report_col_amount",type="price", sum = true },
    { show = true,  key = "symbol_name",   value = "_table_report_col_symbol" },
    { show = false,  key = "client_code",   value = "_table_report_col_client" },
   { show = true,  key = "client_name",   value = "client_name" },
    { show = false, key = "client_id",     value = "client_id" },
    { show = false, key = "client_type",   value = "client_type" },
    { show = false, key = "invoice_title", value = "invoice_title" },
    { show = false, key = "invoice_status",value = "invoice_status" },
    { show = false, key = "symbol_id",     value = "symbol_id" },
    { show = false, key = "fee_decimal",   value = "fee_decimal" },
    { show = false, key = "symbol_rate",   value = "symbol_rate" },
    { show = false, key = "float_code",    value = "float_code" },
    { show = false, key = "project_code",  value = "project_code" },
    { show = false, key = "center_code",   value = "center_code" },
    { show = true,  key = "settle_button", value = "_table_report_col_settle" },
  };
  return cols
end
--------------------------------------------
function getTableConfig_sum()
  local columnsSelected = {};
  local select = "";
  local columns = getTableConfig();
  for i = 1, #columns, 1 do
    local itemColumns = columns[i];
    if itemColumns.key ~= nil and itemColumns.sum ~= nil and itemColumns.sum == true then
      table.insert(columnsSelected, itemColumns.key)
    end
  end
  for i = 1, #columnsSelected, 1 do
    local itemColumnsSelected = columnsSelected[i];
    select = select .. "sum(" .. itemColumnsSelected .. ")"
    if i < #columnsSelected then
      select = select .. ",";
    end
  end
  return select;
end
--------------------------------------------
function getTableConfig_select()
  local columnsSelected = {};
  local select = "";
  local columns = getTableConfig();
  for i = 1, #columns, 1 do
    local itemColumns = columns[i];
    if itemColumns.key ~= nil then
      table.insert(columnsSelected, itemColumns.key)
    end
  end
  for i = 1, #columnsSelected, 1 do
    local itemColumns = columnsSelected[i];
    select = select .. itemColumns;
    if i < #columnsSelected then
      select = select .. ",";
    end
  end
  return select;
end
--------------------------------------------
function getTableConfig_count()
  return "count(*)";
end
--------------------------------------------
function getTableConfig_header()
  local headers = {};
  local totalHeader = getTableConfig();
  for i = 1, #totalHeader, 1 do
    local itemHeader = totalHeader[i];
    if itemHeader.show ~= nil and itemHeader.show == true then
      table.insert(headers, itemHeader);
    end
  end
  return headers;
end
--------------------------------------------
--- Report
--------------------------------------------
function report()
  local data = getTableSectionOne()
  local report = {
    {
      name = "table",
      title = "table",
      report = data
    }
  }
  return report;
end
--------------------------------------------
function getTableSectionOne()
  local repId = getInput("rep_id");
  local headers = getTableConfig_header();
  local from = getInput("page");
  local values = getData(_QUERY_TYPE._TYPE_PAGE_REPORT, from, _PAR_PAGE);
  local total = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT);
  local toolbar = '<div class="alert alert-info" style="display:flex;align-items:center;gap:12px;flex-wrap:wrap;">'
    .. '<button class="btn btn-primary btn-sm" onclick="report[reportPath].settleSelected()">تسویه گروهی انتخاب‌شده‌ها</button>'
    .. '<label style="margin:0;cursor:pointer;"><input type="checkbox" onclick="report[reportPath].toggleAll(this)"> انتخاب همه</label>'
    .. '<span>برای تسویه هر فاکتور از دکمه «تسویه» استفاده کنید یا چند مورد را انتخاب و «تسویه گروهی» بزنید.</span>'
    .. '</div>';
  return toolbar .. install_res.resTable(repId, headers, values, total, _PAR_PAGE, from, nil);
end
--------------------------------------------
--- excel
--------------------------------------------
function excel()
  local excelFileName = getInput("excel_file_name");
  local excelFormPage = getInput("excel_from_page");
  local excelToPage = getInput("excel_to_page");
  local excelPerPage = getInput("excel_per_page");
  local headers = getTableConfig_header();
  local values = getData(_QUERY_TYPE._TYPE_PAGE_EXCEL, excelFormPage, excelPerPage, excelToPage)
  return install_res.resExcel(headers, values, excelFileName);
end
--------------------------------------------
--- print
--------------------------------------------
function print()
  local headers = getTableConfig_header();
  local values = getData(_QUERY_TYPE._TYPE_PAGE_PRINT)
  return install_res.resPrint(headers, values);
end
--------------------------------------------
--- settlement
--------------------------------------------
-- دریافت مبالغ به‌روز فاکتورها از روی همان کوئری، فیلترشده بر اساس شناسه‌ها (محاسبه سمت سرور)
function fetchSettlementRows(idsCsv, orgId, from_date, to_date)
-- teamyar.write_log("from_date----"..from_date)
  local q = teamyar.get_attachment("mySqlQuery.txt");
  q = string.gsub(q, "{{select}}", "invoice_id, run_date, amount, symbol_name ");
  q = string.gsub(q, "{{whereInvoice}}", "where invoice_id in (" .. idsCsv .. ")");
  q = string.gsub(q, "{{slicePageNumber}}", "");
  q = string.gsub(q, "{{org_id}}", tostring(orgId));
  --q = string.gsub(q, "{{from_date}}", from_date);
 -- q = string.gsub(q, "{{to_date}}", to_date);
  q = string.gsub(q, "{{whereStatus}}", " and i.status = 2 ");
  q = string.gsub(q, "{{whereClient}}", "");
  q = string.gsub(q, "{{whereProduct}}", "");
  q = string.gsub(q, "{{whereWarehouse}}", "");
   q = string.gsub(q, "{{where_inv_id}}", "");
    q = string.gsub(q, "and i.RUN_DATE >= {{from_date}} and i.RUN_DATE <= {{to_date}}" , "");
teamyar.write_log("************---"..q)
  db.query({ query = q, params = {} });
  local rows = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(rows, { id = record[1], date = record[2], amount = record[3], symbol_name = record[4] });
  end
  db.query_free();
  db.use_db("0000000");
  return rows;
end
--------------------------------------------
function settleInvoices(idsCsv, org_id, datef, datet)
  local cfg = configData();
 local orgId = org_id
 -- if orgId <= 0 then
  --  return { status = false, msg = "پیکربندی سازمان (org_id) انجام نشده است." };
 -- end

  local rows = fetchSettlementRows(idsCsv, org_id, datef, datet);
  
  teamyar.write_log("rows---------------"..json.encode(rows))
  if #rows == 0 then
    return { status = false, msg = "فاکتور قابل تسویه‌ای یافت نشد." };
  end

  local okCount = 0;
  local failCount = 0;
  local details = {};

  for i, v in ipairs(rows) do
    local info_settelment = {
      org_id = tonumber(orgId),
      invoice_id = tonumber(v.id),
      settlements = {
        {
          date = v.date,
          type = cfg.kind,
          price = tostring(v.amount),
          center_code = cfg.center_code,
          client_code = cfg.client_code,
          symbol_name = v.symbol_name,
          symbol_rate = "1",
          account_code = cfg.account_code,
          project_code = cfg.project_code,
          floating_code = cfg.float_code
        }
      }
    };
    teamyar.write_log("info_settelment----" .. json.encode(info_settelment));
    local res_settelment = teamyar.call_api(23, '/api/sales/create_settlement', info_settelment);
    teamyar.write_log("res_settelment----" .. json.encode(res_settelment));

    local success = res_settelment ~= nil and res_settelment.error == nil and res_settelment.success == true ;
    if success then
      okCount = okCount + 1;
      local info_log = {
        org_id = orgId,
        history = "ثبت تسویه در فاکتور توسط بات",
        invoice_id = tonumber(v.id)
      };
      local res_log = teamyar.call_api(23, '/api/sales/update_invoice_history', info_log);
      teamyar.write_log("res_log---" .. json.encode(res_log));
    else
      failCount = failCount + 1;
    end
    table.insert(details, { invoice_id = v.id, response = res_settelment });
  end

  local msg = "تعداد " .. okCount .. " فاکتور با موفقیت تسویه شد";
  if failCount > 0 then
    msg = msg .. " و " .. failCount .. " مورد ناموفق بود";
  end
  return { status = (okCount > 0), msg = msg, ok = okCount, fail = failCount, details = details };
end
--------------------------------------------
-- پاکسازی ورودی شناسه‌ها: فقط اعداد و ویرگول
function sanitizeIds(raw)
  local s = str(raw);
  s = string.gsub(s, "[^%d,]", "");
  s = string.gsub(s, ",+", ",");
  s = string.gsub(s, "^,", "");
  s = string.gsub(s, ",$", "");
  return s;
end
--------------------------------------------
--- manager
--------------------------------------------
local rtype = num(getInput("type"), 0);
if rtype == 100 then
  install_res.setCashInputs();
  local result = report()
  teamyar.write_result(json.encode(result));
elseif rtype == 101 then
  install_res.setCashInputs();
  local result = excel()
  teamyar.write_result(json.encode(result));
elseif rtype == 102 then
  install_res.setCashInputs();
  local result = print()
  teamyar.write_result(json.encode(result));
elseif rtype == _TYPE_SETTLE_SINGLE then
  local invoiceId = num(getInput("invoice_id"), 0);
    local org_id = num(getInput("org_id"), 0);
  local datef = num(getInput("datef"), 0);
  teamyar.write_log("datef-------------****---"..datef)
  local datet = num(getInput("datet"), 0);
  if invoiceId <= 0 then
    teamyar.write_result(json.encode({ status = false, msg = "شناسه فاکتور نامعتبر است." }));
  else
    teamyar.write_result(json.encode(settleInvoices(tostring(invoiceId), org_id, datef, datet )));
  end
elseif rtype == _TYPE_SETTLE_BULK then
  local org_id = num(getInput("org_id"), 0);
    local datef = num(getInput("from_date"), 0);
  local datet = num(getInput("to_date"), 0);
  local ids = sanitizeIds(getInput("invoice_ids"));
  if ids == "" then
    teamyar.write_result(json.encode({ status = false, msg = "هیچ فاکتوری انتخاب نشده است." }));
  else
    teamyar.write_result(json.encode(settleInvoices(ids, org_id,datef, datet)));
  end
else
  local responseResReport = install_res.resReport(getTableConfig());
  teamyar.write_result(responseResReport);
end

