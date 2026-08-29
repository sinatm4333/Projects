local IdGenerator = {
  x1 = math.random(100,1000),
  x2 = math.random(1,1000),
  getId = function(self)
    self.x1 = self.x1 + 1;
    if self.x1 > 1000 then
      self.x1 = 100;
    end
    --
    self.x2 = self.x2 + 1;
    if self.x2 > 1000 then
      self.x2 = 1;
    end
    return self.x1 * 1000 + self.x2;
  end
}
local random= IdGenerator:getId();
local user_lang =teamyar.get_user_info()

function WidgetTemplate()
  local script = teamyar.get_attachment("main.js");
  
     local params = {title = "Total_Cash_InAndOut",description="15655456456-854",header="<div id=\\'holder_header_Total_Cash_InAndOut_"..random.."\\'></div>"}

     local res = teamyar.run_command("2/res_bot",{
     id = "Total_Cash_InAndOut_"..random,
     tpl_name = "chart",
     title = params.title,
      path='2/Total_Cash_InAndOut',
      lang=1,
     header=params.header,
     description="",
     script=[[
     (function(){
   
         var holder_id= "#holder_header_Total_Cash_InAndOut_]]..random..[[",
        random = "]]..random..[[";
      ]]..script..[[
      
  })();
  
    ]],
  css=[[
    .bba_label_title_result_header{
       text-align: end;
      width:100%;
  }

      .bot_bba_link_btn{
      width:150px;
      margin-bottom:10px;
    }
    
    .bba_label_result_header{
    width:120px;
    text-align: start;
    padding-inline-start: 5px;
   } 
      
    .bot_bba_td_btn_title{
      width:16.66666667%;
    }
      
     .bot_bba_td_btn{
      width:66.66666667%;
    }
      
      .bot_bba_td_title{
        width:66.66666667%;
      height:40px;
    }
      .bot_bba_td_result{
        width:16.66666667%;
      height:40px;
    }
      @media (max-width:992px){
       .bot_bba_td_title,
      .bot_bba_td_result{
          width:50%;
        }
      
       .bot_bba_td_btn{
        width:100%;
      text-align:center;
        }
      .bot_bba_td_btn_title{
       display:none;
      } 
    }
    ]],
    ajax=[[{url: 'bot/run/2/Total_Cash_InAndOut',data: ()=>{
     return ty__main.BotOnClickApplyTotalCashInAndOut()
    }  }]]
    , generatedata= [[ (data)=>{  return ty__main.bbachangechartTotalCashInAndOut(data)  } ]]
     
   });
   teamyar.write_result(res);   
  
end

function LoadData()
  local data = teamyar.get_data("data");  
  if data.modify_time == 0 then
  	data.value = '""';
  end
  
  teamyar.write_result(data.value);
end

function OrganizationAcl(data)
    local query_param = "with cte_data as(select ID, NAME from ORG_INFO"
    if data.search ~= nil and #data.search > 0 then
       query_param = query_param .. " where instr(NAME,'" .. data.search .. "')>0"
    end
    query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ')' .. 
    "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data"
  
    local params = {
              query=query_param,
              params={}
              };
    db.query(params)
    local record={};
    while db.query_fetch(record) do
         teamyar.write_result(record[1])
    end
    db.query_free();
end

function FiscalYearAclList(data)
      local query_param ="with cte_data as(select fy.ID AS ID, fy.TITLE AS NAME  from pa_fiscal_year fy where fy.ORG_ID=" .. data.org_id;
      if data.search ~= nil and #data.search > 0 then
         query_param = query_param .. " and (instr(fy.TITLE,'" .. data.search .. "')>0) "
      end
      query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ') ' .. 
      "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data"

      local params = {
                query=query_param,
                params={}
             };
      db.query(params)
      local record={};
      while db.query_fetch(record) do
           teamyar.write_result(record[1])
      end
      db.query_free();
end

function AccountAclList(data)
      local query_param ="with cte_data as(select pa.ID AS ID, concat(pa.NAME,'-',pa.code) AS NAME  from pa_account pa where pa.ORG_ID=" .. data.org_id;
      if data.search ~= nil and #data.search > 0 then
         query_param = query_param .. " and (instr(pa.NAME,'" .. data.search .. "')>0 or instr(pa.CODE,'" .. data.search .. "')>0)"
      end
      query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ')' .. 
      "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data"

      local params = {
                query=query_param,
                params={}
             };
      db.query(params)
      local record={};
      while db.query_fetch(record) do
           teamyar.write_result(record[1])
      end
      db.query_free();
end

function WithoutConsideringAclList(data)
      local query_param ="WITH CTE_DATA AS (SELECT DISTINCT PV.TYPE, IF(PV.TYPE = 1, IF({lang} =4, 'سند عادی', 'VOUCHER'), IF(PV.TYPE = 11, IF({lang} =4, 'سند تسعیر', 'CONVERSION'), IF(PV.TYPE = 12, IF({lang} =4, 'سند افتتاحیه', 'OPENNING VOUCHE'),IF(PV.TYPE = 13, IF({lang} =4, 'سند اختتامیه', 'CLOSING VOUCHE'), IF(PV.TYPE = 14, IF({lang} =4, 'بستن حساب های موقت', 'TEMPORARY CLOSING'), IF(PV.TYPE = 15, IF({lang} =4, 'سند حقوقی', 'LEGAL VOUCHER'), IF(PV.TYPE = 25, IF({lang} =4, 'سند انتقال سود و زیان جاری', 'PROFIT AND LOSS STATEMENT'),''))))))) AS TYPE_NAME FROM `0000000`.PA_VOUCHER PV INNER JOIN PA_FISCAL_YEAR AS PFY ON PFY.ORG_ID = PV.ORG_ID AND PV.RUN_DATE >= PFY.START_DATE AND PV.RUN_DATE <= PFY.END_DATE WHERE PV.ORG_ID =" .. data.org_id.." AND PFY.ID="..data.fiscal_year;
      if data.search ~= nil and #data.search > 0 then
         query_param = query_param .. " and (instr(IF(TYPE = 1, IF({lang} =4, 'سند عادی', 'voucher'), IF(TYPE = 11, IF({lang} =4, 'سند تسعیر', 'conversion'), IF(TYPE = 12, IF({lang} =4, 'سند افتتاحیه', 'openning vouche'),IF(TYPE = 13, IF({lang} =4, 'سند اختتامیه', 'closing vouche'), IF(TYPE = 14, IF({lang} =4, 'بستن حساب های موقت', 'temporary closing'), IF(TYPE = 15, IF({lang} =4, 'سند حقوقی', 'legal voucher'), IF(TYPE = 25, if({lang} =4, 'سند انتقال سود و زیان جاری', 'profit and loss statement'),''))))))),'" .. data.search .. "')>0) "
      end
      query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ') ' .. "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.type, 'name',cte_data.type_name, 'type',1)) as result from cte_data"
      query_param = string.gsub(query_param,"{lang}",user_lang.lang_id)
       
      local params ={
                query=query_param,
                params={}
             };
      db.query(params)
      local record={};
      while db.query_fetch(record) do
           teamyar.write_result(record[1])
           teamyar.write_log(record[1])
      end
      db.query_free();
end

function getData(data) 
   local accounts = data.accounts
   local accounts_ids = ""
   for i = 1, #accounts, 1 do
     if accounts_ids == nil or accounts_ids == "" then
        accounts_ids = accounts[i]["id"]
    else
        accounts_ids = accounts_ids..","..accounts[i]["id"]
    end
   end
  
   local without_considering = data.without_considering
   local without_considering_ids = ""
   for i = 1, #without_considering, 1 do
     if without_considering_ids == nil or without_considering_ids == "" then
        without_considering_ids = without_considering[i]["id"]
    else
        without_considering_ids = without_considering_ids..","..without_considering[i]["id"]
    end
   end
      
    QueryInfo = teamyar.get_attachment("QUERY_TotalCashInAndOut.sql");
    QueryInfo = string.gsub(QueryInfo,"{param1}",data.org_id)
    QueryInfo = string.gsub(QueryInfo,"{param2}",accounts_ids)
    QueryInfo = string.gsub(QueryInfo,"{param4}",data.fiscal_year)
    if without_considering_ids == '' or without_considering_ids == nil then 
        QueryInfo = string.gsub(QueryInfo,"{param5}", 0) 
    else 
        QueryInfo = string.gsub(QueryInfo,"{param5}",without_considering_ids)    
    end
    QueryInfo = string.gsub(QueryInfo,"{lang}",user_lang.lang_id)
    QueryInfo = string.gsub(QueryInfo,"{timezone}",user_lang.timezone)
    db.use_db("0000000");
    local params = {
              query=QueryInfo,
              params={}
    };
    db.query(params)
    local record={};
    local result = {{},{},{}};
    i = 1;
    while db.query_fetch(record) do
        result[1][i] = record[1];
        result[2][i] = math.floor(record[2]);
        result[3][i] = math.floor(record[3]);
        i = i +1;
    end
    db.query_free(); 
    teamyar.write_result(json.encode(result))

end

-- main --
input = teamyar.get_input();

if input.type == 1 then
  teamyar.set_data("data", input.data);
elseif input.type == 2 then
  OrganizationAcl(input.data);
elseif input.type == 3 then
  AccountAclList(input.data);
elseif input.type == 4 then
  getData(input.data);
elseif input.type == 5 then
 LoadData()
elseif input.type == 6 then
  FiscalYearAclList(input.data)
elseif input.type == 7 then
  WithoutConsideringAclList(input.data)
else
  WidgetTemplate();
end
