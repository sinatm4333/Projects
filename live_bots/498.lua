-- botName = stock_kpi_wh10_dashboard
-- version = v02_FULL_PRO

db.use_db("0000000")

local sql = [[
WITH

last_sell_invoice AS (
    SELECT
        d.PRODUCT_ID,
        MAX(si.ID) AS LastSellInvoiceID
    FROM sales_invoice_product d
    JOIN sales_invoice si
        ON si.ID = d.INVOICE_ID
    WHERE si.DELETED = 0
      AND si.CANCELED = 0
      AND si.PRE_INVOICE = 0
      AND si.RUN_DATE > 0
      AND d.STOCK_ID = 10
    GROUP BY d.PRODUCT_ID
),

last_buy_invoice AS (
    SELECT
        d.PRODUCT_ID,
        MAX(pi.ID) AS LastBuyInvoiceID
    FROM purchase_invoice_product d
    JOIN purchase_invoice pi
        ON pi.ID = d.INVOICE_ID
    WHERE pi.DELETED = 0
      AND pi.CANCELED = 0
      AND pi.PRE_INVOICE = 0
      AND pi.RUN_DATE > 0
      AND d.STOCK_ID = 10
    GROUP BY d.PRODUCT_ID
),

sell_avg AS (
    SELECT
        d.PRODUCT_ID,
        SUM(d.QUANTITY * d.FEE) / NULLIF(SUM(d.QUANTITY),0) AS AvgSellPrice
    FROM sales_invoice_product d
    JOIN sales_invoice h ON h.ID = d.INVOICE_ID
    WHERE h.DELETED = 0
      AND h.CANCELED = 0
      AND h.PRE_INVOICE = 0
      AND d.STOCK_ID = 10
    GROUP BY d.PRODUCT_ID
),

buy_avg AS (
    SELECT
        d.PRODUCT_ID,
        SUM(d.QUANTITY * d.PRICE) / NULLIF(SUM(d.QUANTITY),0) AS AvgBuyPrice
    FROM purchase_invoice_product d
    JOIN purchase_invoice h ON h.ID = d.INVOICE_ID
    WHERE h.DELETED = 0
      AND h.CANCELED = 0
      AND h.PRE_INVOICE = 0
      AND d.STOCK_ID = 10
    GROUP BY d.PRODUCT_ID
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
    p.ID,
    p.FULL_NAME,

    ba.AvgBuyPrice,
    sa.AvgSellPrice,

    lb.LastBuyInvoiceID,
    ls.LastSellInvoiceID,

    st.StockBalance,

    ddb.JNDATE AS LastBuyDateShamsi,
    dds.JNDATE AS LastSellDateShamsi

FROM wh_product p

LEFT JOIN buy_avg ba ON ba.PRODUCT_ID = p.ID
LEFT JOIN sell_avg sa ON sa.PRODUCT_ID = p.ID

LEFT JOIN last_buy_invoice lb ON lb.PRODUCT_ID = p.ID
LEFT JOIN last_sell_invoice ls ON ls.PRODUCT_ID = p.ID

LEFT JOIN purchase_invoice pi
    ON pi.ID = lb.LastBuyInvoiceID

LEFT JOIN sales_invoice si
    ON si.ID = ls.LastSellInvoiceID

LEFT JOIN report_dimdate ddb
    ON ddb.DATEKEY = (pi.RUN_DATE DIV 864000000000) * 864000000000

LEFT JOIN report_dimdate dds
    ON dds.DATEKEY = (si.RUN_DATE DIV 864000000000) * 864000000000

LEFT JOIN stock_data st ON st.PRODUCT_ID = p.ID

WHERE p.ACTIVE = 1
AND p.ORG_ID = 8

ORDER BY st.StockBalance DESC
LIMIT 300;
]]

local ok, err = pcall(function()
    db.query({ query = sql })
end)

if not ok then
    teamyar.write_result("SQL ERROR: "..tostring(err))
    return
end

local data = {}
local r = {}

while db.query_fetch(r) do

    local buy = tonumber(r[3]) or 0
    local sell = tonumber(r[4]) or 0
    local stock = tonumber(r[7]) or 0

    local profit = sell - buy
    local margin = 0
    if buy > 0 then
        margin = (profit / buy) * 100
    end

    table.insert(data,{
        id = tonumber(r[1]),
        name = r[2] or "",
        buy = buy,
        sell = sell,
        profit = profit,
        margin = margin,
        buyInv = r[5] or "",
        sellInv = r[6] or "",
        stock = stock,
        buyDate = r[8] or "",
        sellDate = r[9] or ""
    })
end

db.query_free()

local function formatNumber(num)
    if not num then return "0" end
    local formatted = tostring(math.floor(num))
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local productUrl = "https://erp.bimehland.com/?page=/warehouse/product_add/view_product/"
local buyUrl = "https://erp.bimehland.com/?page=/purchase/invoice/view_invoice/"
local sellUrl = "https://erp.bimehland.com/?page=/sales/invoice/view_invoice/"

local html = [[
<div style="padding:30px;font-family:IRANSans,Tahoma;background:#f8fafc">

<h2 style="margin-bottom:20px;font-size:20px;font-weight:600">
📦 Stock KPI Dashboard — WH10
</h2>

<div style="margin-bottom:20px;display:flex;gap:10px">
<input type="text" id="searchBox" placeholder="🔍 جستجوی کالا..."
style="padding:8px 12px;border:1px solid #dbeafe;border-radius:8px;font-size:13px;width:260px">

<select id="stockFilter"
style="padding:8px 12px;border:1px solid #dbeafe;border-radius:8px;font-size:13px">
<option value="">همه</option>
<option value="positive">موجودی مثبت</option>
<option value="zero">بدون موجودی</option>
</select>
</div>

<table id="kpiTable"
style="width:100%;border-collapse:collapse;background:white;border-radius:12px;overflow:hidden;box-shadow:0 6px 18px rgba(0,0,0,0.06);font-size:13px">

<thead>
<tr style="background:#f1f5f9;text-align:center;cursor:pointer">
<th onclick="sortTable(0)">Product</th>
<th onclick="sortTable(1)">Stock</th>
<th onclick="sortTable(2)">Buy Avg</th>
<th onclick="sortTable(3)">Sell Avg</th>
<th onclick="sortTable(4)">Profit</th>
<th onclick="sortTable(5)">Margin</th>
<th>Last Buy</th>
<th>Last Sell</th>
</tr>
</thead>
<tbody>
]]

for _,v in ipairs(data) do

    local color = "#334155"
    if v.margin > 40 then color = "#16a34a"
    elseif v.margin < 10 then color = "#dc2626" end

    html = html.."<tr style='border-bottom:1px solid #eef2f7'>"
    html = html.."<td style='padding:12px;text-align:right;font-size:12px'>"
    html = html.."<a target='_blank' href='"..productUrl..v.id.."' style='color:#2563eb;text-decoration:none'>"..v.name.."</a></td>"

    html = html.."<td align=center>"..formatNumber(v.stock).."</td>"
    html = html.."<td align=center>"..formatNumber(v.buy).."</td>"
    html = html.."<td align=center>"..formatNumber(v.sell).."</td>"
    html = html.."<td align=center style='color:"..color.."'>"..formatNumber(v.profit).."</td>"
    html = html.."<td align=center style='color:"..color..";font-weight:600'>"..string.format("%.1f",v.margin).."%".."</td>"

    html = html.."<td align=center><div><a target='_blank' href='"..buyUrl..v.buyInv.."'>"..v.buyInv.."</a></div><div style='font-size:11px;color:#64748b'>"..v.buyDate.."</div></td>"
    html = html.."<td align=center><div><a target='_blank' href='"..sellUrl..v.sellInv.."'>"..v.sellInv.."</a></div><div style='font-size:11px;color:#64748b'>"..v.sellDate.."</div></td>"

    html = html.."</tr>"
end

html = html..[[</tbody></table></div>

<script>
const table = document.getElementById("kpiTable");
const searchBox = document.getElementById("searchBox");
const stockFilter = document.getElementById("stockFilter");

searchBox.addEventListener("keyup", filterTable);
stockFilter.addEventListener("change", filterTable);

function filterTable(){
    const search = searchBox.value.toLowerCase();
    const filter = stockFilter.value;
    const rows = table.tBodies[0].rows;

    for(let i=0;i<rows.length;i++){
        const product = rows[i].cells[0].innerText.toLowerCase();
        const stock = parseFloat(rows[i].cells[1].innerText.replace(/,/g,''))||0;
        let show = true;
        if(search && !product.includes(search)) show=false;
        if(filter==="positive" && stock<=0) show=false;
        if(filter==="zero" && stock>0) show=false;
        rows[i].style.display = show?"":"none";
    }
}

function sortTable(col){
    const tbody = table.tBodies[0];
    const rows = Array.from(tbody.rows);
    const asc = table.getAttribute("data-sort")!=="asc";
    table.setAttribute("data-sort", asc?"asc":"desc");

    rows.sort((a,b)=>{
        let A=a.cells[col].innerText.replace(/,/g,'');
        let B=b.cells[col].innerText.replace(/,/g,'');
        if(!isNaN(A)&&!isNaN(B)) return asc?A-B:B-A;
        return asc?A.localeCompare(B):B.localeCompare(A);
    });

    rows.forEach(r=>tbody.appendChild(r));
}
</script>
]]

teamyar.write_result(html)