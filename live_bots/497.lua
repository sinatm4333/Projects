-- botName = stock_kpi_wh10
-- version = 1.0

db.use_db("0000000")

local sql = [[
WITH
buy_ranked AS (
    SELECT
        d.PRODUCT_ID,
        d.QUANTITY,
        d.PRICE,
        h.RUN_DATE,
        h.INVOICE_NUM,
        ROW_NUMBER() OVER (
            PARTITION BY d.PRODUCT_ID
            ORDER BY h.RUN_DATE DESC
        ) AS rn
    FROM purchase_invoice_product d
    JOIN purchase_invoice h
        ON h.ID = d.INVOICE_ID
    WHERE h.DELETED = 0
      AND h.CANCELED = 0
      AND h.PRE_INVOICE = 0
      AND h.RUN_DATE > 0
      AND d.STOCK_ID = 10
),

buy_data AS (
    SELECT
        PRODUCT_ID,
        SUM(QUANTITY * PRICE) / NULLIF(SUM(QUANTITY),0) AS AvgBuyPrice,
        MAX(RUN_DATE) AS LastBuyDate
    FROM buy_ranked
    GROUP BY PRODUCT_ID
),

buy_last_invoice AS (
    SELECT PRODUCT_ID, INVOICE_NUM AS LastBuyInvoiceNo
    FROM buy_ranked
    WHERE rn = 1
),

sell_ranked AS (
    SELECT
        d.PRODUCT_ID,
        d.QUANTITY,
        d.FEE,
        h.RUN_DATE,
        h.INVOICE_CODE,
        ROW_NUMBER() OVER (
            PARTITION BY d.PRODUCT_ID
            ORDER BY h.RUN_DATE DESC
        ) AS rn
    FROM sales_invoice_product d
    JOIN sales_invoice h
        ON h.ID = d.INVOICE_ID
    WHERE h.DELETED = 0
      AND h.CANCELED = 0
      AND h.PRE_INVOICE = 0
      AND h.RUN_DATE > 0
      AND d.STOCK_ID = 10
),

sell_data AS (
    SELECT
        PRODUCT_ID,
        SUM(QUANTITY * FEE) / NULLIF(SUM(QUANTITY),0) AS AvgSellPrice,
        MAX(RUN_DATE) AS LastSellDate
    FROM sell_ranked
    GROUP BY PRODUCT_ID
),

sell_last_invoice AS (
    SELECT PRODUCT_ID, INVOICE_CODE AS LastSellInvoiceNo
    FROM sell_ranked
    WHERE rn = 1
),

stock_data AS (
    SELECT
        PRODUCT_ID,
        SUM(CASE WHEN TYPE = 1 THEN QUANTITY ELSE 0 END) -
        SUM(CASE WHEN TYPE = 2 THEN QUANTITY ELSE 0 END) AS StockBalance
    FROM wh_operation_details
    WHERE DELETED = 0
      AND STOCK_ID = 10
    GROUP BY PRODUCT_ID
)

SELECT
    p.ID AS ProductID,
    p.FULL_NAME,
    b.AvgBuyPrice,
    s.AvgSellPrice,
    bl.LastBuyInvoiceNo,
    sl.LastSellInvoiceNo,
    st.StockBalance,
    ddb.JNDATE AS LastBuyDateShamsi,
    dds.JNDATE AS LastSellDateShamsi

FROM wh_product p

LEFT JOIN buy_data b           ON b.PRODUCT_ID = p.ID
LEFT JOIN sell_data s          ON s.PRODUCT_ID = p.ID

LEFT JOIN report_dimdate ddb
ON b.LastBuyDate BETWEEN ddb.DATEKEY AND ddb.DATEKEY + (60*60*24*10000000)

LEFT JOIN report_dimdate dds
ON s.LastSellDate BETWEEN dds.DATEKEY AND dds.DATEKEY + (60*60*24*10000000)

LEFT JOIN buy_last_invoice bl  ON bl.PRODUCT_ID = p.ID
LEFT JOIN sell_last_invoice sl ON sl.PRODUCT_ID = p.ID
INNER JOIN stock_data st       ON st.PRODUCT_ID = p.ID

WHERE p.ACTIVE = 1
  AND sl.LastSellInvoiceNo <> ''
  AND p.ORG_ID = 8;
]]
   
local ok, err = pcall(function()
    db.query({ query = sql })
end)

if not ok then
    teamyar.write_result("SQL ERROR: "..tostring(err))
    return
end

local result = {}
local r = {}

while db.query_fetch(r) do
    table.insert(result,{
        ProductID = tonumber(r[1]),
        FullName = r[2],
        AvgBuyPrice = tonumber(r[3]),
        AvgSellPrice = tonumber(r[4]),
        LastBuyInvoiceNo = r[5],
        LastSellInvoiceNo = r[6],
        StockBalance = tonumber(r[7])
    })
end

db.query_free()

local jsonResult = json.encode(result)
teamyar.write_result(jsonResult)