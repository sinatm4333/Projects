local input = teamyar.get_input()
local hcinvoicenumber = input.hcinvoicenumber

local sqlquery =
    "select si.id, si.invoice_code, si.TITLE, si.DELETED " ..
    "from sales_invoice si " ..
    "where si.TITLE like '%" .. hcinvoicenumber .. "%' " ..
    "and si.DELETED = 0 " ..
    "order by si.ID desc"

local paramParrent = {
    query = sqlquery,
    param = {}
}

local result = {}
local record = {}

db.query(paramParrent)

while db.query_fetch(record) do
    result[#result + 1] = {
        TeamyarInvoiceID     = record[1],
        TeamyarInvoiceNumber = tonumber(record[2]),
        TeamyarInvoiceTitle  = record[3],
        IsDeleted            = record[4]
    }
end

db.query_free()

local jsonResult = json.encode(result)
teamyar.write_result(jsonResult)
