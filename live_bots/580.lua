-- botName = inquery_factor
-- description = استعلام فاکتور سامانه مودیان
-- version = 1
------------------------------------
local input = teamyar.get_input();
local intype = tonumber(input.type) or 0;

------------------------------------
function queryResultAcl(select_query, user_param)
  db.use_db("0000000");
  local params = {
    query = select_query,
    params = user_param
  };
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, {id = record[1], name = record[2], type = 1});
  end
  db.query_free();
  return res_text;
end

------------------------------------
function orgAcl(data)
  local query_param = [[select id, name from org_info]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param .. [[ where name like N'%]] .. data.search .. [[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d", tonumber(data.from) or 0, tonumber(data.count) or 20);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end

------------------------------------
-- ACL: type=7 → orgAcl
if intype == 7 then
  orgAcl(input.data);
  return;
end

------------------------------------
-- type=10 → execute inquiry
if intype == 10 then
  local invoice_id = input.invoice_id;
  local referenceNumber = input.referenceNumber;
  local org_id = input.org_id;

  if invoice_id == nil or invoice_id == '' then
    teamyar.write_result(json.encode({msg = '<p class="error-msg">شناسه فاکتور الزامی است</p>'}));
    return;
  end
  if referenceNumber == nil or referenceNumber == '' then
    teamyar.write_result(json.encode({msg = '<p class="error-msg">شماره مرجع الزامی است</p>'}));
    return;
  end
  if org_id == nil or org_id == '' then
    teamyar.write_result(json.encode({msg = '<p class="error-msg">انتخاب شعبه الزامی است</p>'}));
    return;
  end

  local res_bot = teamyar.run_command("2/inquery_invoice_taxpayer_m/", {
    referenceNumber = referenceNumber,
    invoice_id = tostring(invoice_id),
    org_id = org_id
  });
 -- teamyar.write_log("res_bot---" .. tostring(res_bot));

  local res_status = teamyar.run_command("2/fact_st_m", {
    invoice_id = tostring(invoice_id),
    org_id = org_id
  });
  --teamyar.write_log("res_status---" .. tostring(res_status));

  local result_html = '<div class="result-card">';
  result_html = result_html .. '<div class="result-section">';
  result_html = result_html .. '<h3>نتیجه استعلام فاکتور</h3>';
  result_html = result_html .. '<div class="result-box">' .. tostring(res_bot) .. '</div>';
  result_html = result_html .. '</div>';
  result_html = result_html .. '<div class="result-section">';
  result_html = result_html .. '<h3>وضعیت فاکتور</h3>';
  result_html = result_html .. '<div class="result-box">' .. tostring(res_status) .. '</div>';
  result_html = result_html .. '</div>';
  result_html = result_html .. '</div>';

  teamyar.write_result(json.encode({msg = result_html}));
  return;
end

------------------------------------
-- default: show HTML form
local html = [[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: Tahoma, Arial, sans-serif; background: #fdf6f0; padding: 20px; }
  .card { background: white; border-radius: 12px; padding: 30px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); max-width: 600px; margin: 0 auto; }
  .card-title { color: #e8791a; text-align: center; margin-bottom: 25px; font-size: 20px; }
  .form-group { margin-bottom: 18px; }
  .form-label { display: block; font-weight: bold; margin-bottom: 6px; color: #444; font-size: 14px; }
  .form-input { width: 100%; padding: 10px 14px; border: 1px solid #ddd; border-radius: 8px; font-size: 14px; transition: border-color 0.2s; }
  .form-input:focus { border-color: #e8791a; outline: none; }
  .btn-execute { background: #e8791a; color: white; border: none; padding: 12px 30px; border-radius: 8px; font-size: 16px; cursor: pointer; width: 100%; margin-top: 10px; transition: background 0.2s; }
  .btn-execute:hover { background: #d06a10; }
  .btn-execute:disabled { background: #aaa; cursor: not-allowed; }
  .result-area { margin-top: 20px; }
  .result-card { background: #fef9f3; border-radius: 10px; padding: 20px; margin-top: 15px; }
  .result-section { margin-bottom: 15px; }
  .result-section:last-child { margin-bottom: 0; }
  .result-section h3 { color: #e8791a; font-size: 15px; margin-bottom: 8px; }
  .result-box { background: white; border: 1px solid #f0e0d0; border-radius: 6px; padding: 12px; font-size: 13px; color: #333; line-height: 1.6; word-break: break-all; }
  .loading-msg { text-align: center; color: #666; padding: 20px; }
  .error-msg { color: #d32f2f; text-align: center; padding: 10px; }
  .acl-container { margin-bottom: 18px; }
  .acl-container label { display: block; font-weight: bold; margin-bottom: 6px; color: #444; font-size: 14px; }
</style>
</head>
<body>
<div class="card">
  <h2 class="card-title">استعلام فاکتور سامانه مودیان</h2>
  <div class="form-group">
    <label class="form-label">شناسه فاکتور:</label>
    <input type="number" id="invoice_id" class="form-input" placeholder="مثلا 12345" />
  </div>
  <div class="form-group">
    <label class="form-label">شماره مرجع:</label>
    <input type="text" id="referenceNumber" class="form-input" placeholder="مثلا h8ieeB-oCzYeLcKB0-..." />
  </div>
  <div class="acl-container">
    <label>شعبه:</label>
    <div id="org_acl_container"></div>
  </div>
  <button id="btn_execute" class="btn-execute" onclick="executeInquiry()">استعلام</button>
  <div id="result" class="result-area"></div>
</div>
<script>
  $(function() {
    var orgAcl = $.Teamyar.acl({
      id: 'org_id',
      name: 'org_id',
      title: '',
      format: 'input',
      typevalue: 'object',
      shownone: 'true',
      url: '/',
      events: {
        ongetdata: ['GetDataOrgAcl', 7]
      }
    });
    $('#org_acl_container').append(orgAcl);
  });

  function GetDataOrgAcl(ty, p2) {
    var client_data = [];
    $.Teamyar.ajax({
      block_holder: 'body',
      options: {
        block_holder: 'body',
        url: '/bot/run/2/inquery_factor_m',
        type: 'POST',
        dataType: 'json',
        async: false,
        data: {
          customform: JSON.stringify({
            type: ty,
            data: {
              from: p2.data.from,
              count: p2.data.count,
              search: p2.data.search
            }
          })
        }
      },
      events: {
        success: function(res) {
          client_data = res;
        }
      }
    });
    return client_data;
  }

  function executeInquiry() {
    var btn = document.getElementById('btn_execute');
    var btnText = 'استعلام';
    var invoice_id = document.getElementById('invoice_id').value.trim();
    var referenceNumber = document.getElementById('referenceNumber').value.trim();
    var org_id = $.Teamyar.acl.get('#org_id', 'value');

    if (!invoice_id) {
      document.getElementById('result').innerHTML = '<p class="error-msg">شناسه فاکتور الزامی است</p>';
      return;
    }
    if (!referenceNumber) {
      document.getElementById('result').innerHTML = '<p class="error-msg">شماره مرجع الزامی است</p>';
      return;
    }
    if (!org_id) {
      document.getElementById('result').innerHTML = '<p class="error-msg">لطفا شعبه را انتخاب کنید</p>';
      return;
    }

    btn.disabled = true;
    btn.textContent = 'در حال استعلام...';
    document.getElementById('result').innerHTML = '<p class="loading-msg">لطفا صبر کنید...</p>';

    $.Teamyar.ajax({
      block_holder: 'body',
      options: {
        block_holder: 'body',
        url: '/bot/run/2/inquery_factor_m',
        type: 'POST',
        dataType: 'json',
        async: true,
        data: {
          customform: JSON.stringify({
            type: 10,
            invoice_id: invoice_id,
            referenceNumber: referenceNumber,
            org_id: org_id
          })
        }
      },
      events: {
        success: function(res) {
          btn.disabled = false;
          btn.textContent = btnText;
          document.getElementById('result').innerHTML = res.msg || 'خطا: پاسخ خالی';
        },
        error: function() {
          btn.disabled = false;
          btn.textContent = btnText;
          document.getElementById('result').innerHTML = '<p class="error-msg">خطا در ارتباط با سرور</p>';
        }
      }
    });
  }
</script>
</body>
</html>
]]

teamyar.write_result(html);
