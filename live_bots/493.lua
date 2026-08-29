-- botName = rfm3
-- version = v01

local input = teamyar.get_input()
db.use_db("0000000")

------------------------------------------------------------
-- TYPE 10 : SEND SMS
------------------------------------------------------------
if input.type == 10 then

    local function getIds(data)
        local ids = ""
        if data ~= nil then
            for i,v in ipairs(data) do
                if ids == "" then
                    ids = tostring(v.id)
                else
                    ids = ids .. "," .. tostring(v.id)
                end
            end
        end
        return ids
    end

    local selected_ids = getIds(input.client)
    local txt = input.txt

    if selected_ids == "" then
        teamyar.write_result(json.encode({msg="هیچ کاربری انتخاب نشده"}))
        return
    end

    if txt == nil or txt == "" then
        teamyar.write_result(json.encode({msg="متن پیام خالی است"}))
        return
    end

    db.query({
        query = "select p.id,p.fullname from profile_main p where p.id in ("..selected_ids..")"
    })

    local crms = {}
    local r = {}
    while db.query_fetch(r) do
        table.insert(crms,{
            id = r[1],
            name = r[2]
        })
    end
    db.query_free()

    local res_str = ""

    for i,v in ipairs(crms) do

        local msg = txt
        msg = string.gsub(msg,"{{name}}",v.name or "")

        local info = {
            box_id = 0, -- اگر box_id ثابت داری اینجا بگذار
            messages = {{
                content = msg,
                send_to = { profile_ids = {v.id} }
            }},
            module_id = 26
        }

        local res = teamyar.call_api(16, '/api/sms/send', info)

        if res ~= nil and res.success == true then
            res_str = res_str .. "<div style='color:green'>ارسال به "..v.name.." موفق</div>"
        else
            res_str = res_str .. "<div style='color:red'>خطا برای "..v.name.."</div>"
        end
    end

    teamyar.write_result(json.encode({msg=res_str}))
    return
end

------------------------------------------------------------
-- DEFAULT : RFM DASHBOARD
------------------------------------------------------------

local sql = [[
SELECT
    p.REFFERE_ID AS client_id,
    p.NAME,
    MAX(s.DATE_CREATE) AS LastPurchaseTick,
    COUNT(s.ID) AS Frequency,
    SUM(s.RECEPTION_AMOUNT + s.REMAINED_AMOUNT) AS Monetary
FROM sales_invoice s
INNER JOIN pa_client p 
    ON p.ID = s.CLIENT_ID
WHERE s.DELETED = 0
  AND s.CANCELED = 0
  AND s.PRE_INVOICE = 0
GROUP BY p.REFFERE_ID, p.NAME
ORDER BY Monetary DESC
LIMIT 500
]]

local ok = pcall(function()
    db.query({ query = sql })
end)

local data = {}
local r = {}

while db.query_fetch(r) do
    table.insert(data,{
        client_id = r[1],
        name = r[2],
        last = r[3],
        frequency = tonumber(r[4]) or 0,
        monetary = tonumber(r[5]) or 0
    })
end

db.query_free()

-- RFM Scoring
table.sort(data, function(a,b) return a.last < b.last end)
for i,v in ipairs(data) do v.r_score = math.ceil((i/#data)*5) end

table.sort(data, function(a,b) return a.frequency < b.frequency end)
for i,v in ipairs(data) do v.f_score = math.ceil((i/#data)*5) end

table.sort(data, function(a,b) return a.monetary < b.monetary end)
for i,v in ipairs(data) do v.m_score = math.ceil((i/#data)*5) end

local total = 0
for _,v in ipairs(data) do total = total + v.monetary end

local function formatNumber(num)
    local formatted = tostring(math.floor(num or 0))
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local html = [[
<div style="padding:30px;font-family:tahoma;background:#f8fafc">
<h2 style="font-size:22px">📊 RFM Dashboard v01</h2>

<table id="rfmTable" width="100%" style="border-collapse:collapse;background:white;font-size:15px">
<thead>
<tr style="background:#eef2f7">
<th>Select</th>
<th>Customer</th>
<th>Frequency</th>
<th>Monetary</th>
<th>Share %</th>
<th>RFM</th>
</tr>
</thead>
<tbody>
]]

for _,v in ipairs(data) do

    local share = 0
    if total > 0 then share = (v.monetary / total) * 100 end
    local rfm = tostring(v.r_score)..tostring(v.f_score)..tostring(v.m_score)

    html = html .. "<tr>"
    html = html .. "<td style='text-align:center'><input type='checkbox' class='rfm_check' value='"..v.client_id.."'></td>"
    html = html .. "<td><a href='?page=/crm/client/edit/"..v.client_id.."§ion=2' target='_blank'>"..v.name.."</a></td>"
    html = html .. "<td>"..v.frequency.."</td>"
    html = html .. "<td>"..formatNumber(v.monetary).."</td>"
    html = html .. "<td>"..string.format('%.2f',share).."%".."</td>"
    html = html .. "<td>"..rfm.."</td>"
    html = html .. "</tr>"
end

html = html .. [[
</tbody>
</table>

<div style="margin-top:25px">
<textarea id="sms_text" style="width:100%;height:90px;padding:10px" 
placeholder="متن پیام... مثال: {{name}} عزیز"></textarea>

<button onclick="sendSelected()" 
style="margin-top:10px;padding:8px 20px;background:#16a34a;color:white;border:none;border-radius:6px">
ارسال پیامک
</button>
</div>
</div>

<script>
function sendSelected(){

    let selected = [];
    document.querySelectorAll('.rfm_check:checked').forEach(el=>{
        selected.push({id: parseInt(el.value)});
    });

    if(selected.length === 0){
        alert("هیچ کاربری انتخاب نشده");
        return;
    }

    let txt = document.getElementById("sms_text").value;
    if(!txt){
        alert("متن پیام خالی است");
        return;
    }

    fetch(window.location.pathname,{
        method:'POST',
        headers:{
            'Content-Type':'application/x-www-form-urlencoded'
        },
        body:'customform=' + encodeURIComponent(
            JSON.stringify({
                type:10,
                client:selected,
                txt:txt
            })
        )
    })
    .then(r=>r.json())
    .then(res=>{
        alert(res.msg || "ارسال انجام شد");
    });
}
</script>
]]

teamyar.write_result(html)