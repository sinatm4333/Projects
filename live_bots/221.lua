local IdGenerator = {
  x1 = math.random(100,1000),
  x2 = math.random(1,1000),
  getId = function(self)
    self.x1 = self.x1 + 1;
    if self.x1 > 1000 then
      self.x1 = 100;
    end
    self.x2 = self.x2 + 1;
    if self.x2 > 1000 then
      self.x2 = 1;
    end
    return self.x1 * 1000 + self.x2;
  end
}
local random= IdGenerator:getId();

function WidgetTemplate()
  local script = teamyar.get_attachment("main.js");
   local str_title="Business Bank Account"; 
  local user_info = teamyar.get_user_info();
  if user_info.lang_id == 4 then 
    str_title="حسابهای بانکی"
  end 
  -- local random= math.random(1,1000);
     local params = {title = str_title,description="15655456456-854",header="<div id=\\'holder_header_bussiness_bank_account_"..random.."\\'></div>"}

     local res = teamyar.run_command("2/res_bot",{
     id = "Business_Bank_Account_Bot"..random,
     tpl_name = "chart",
     title = params.title,
      path='2/Business_Bank_Account_Bot',
      lang=1,
     header=params.header,
     description="",
     script=[[
     (function(){
   
         var holder_id= "#holder_header_bussiness_bank_account_]]..random..[[",
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
    ajax=[[{url: 'bot/run/2/Business_Bank_Account_Bot',data: ()=>{
     return ty__main.BotOnClickApplyBusinessBankAccount()
    
    }  }]]
    , generatedata= [[ (data)=>{  return ty__main.bbachangechartBusinessBankAccount(data)  } ]]
     
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

function getData(data) 
    local user_lang =teamyar.get_user_info()
    local QueryInfo = teamyar.get_attachment("QUERY_BusinessBankAccount.sql");
    QueryInfo = string.gsub(QueryInfo,"{param1}",math.floor(data.account_id))
    QueryInfo = string.gsub(QueryInfo,"{param2}",math.floor(data.org_id))
    QueryInfo = string.gsub(QueryInfo,"{param3}",data.date_from)
    QueryInfo = string.gsub(QueryInfo,"{param4}",data.date_to)
    QueryInfo = string.gsub(QueryInfo,"{lang}",math.floor(user_lang.lang_id))

    db.use_db("0000000");
    local params = {
              query=QueryInfo,
              params={}
    };
    db.query(params)
    local record={};
    local result = {};
    local  CASH = {}
    local DATE = {};
    local REMAIN = {};
    counter = 1;
    while db.query_fetch(record) do

      DATE[counter] = record[2];
      REMAIN[counter] = tonumber(record[3]);
      counter = counter +1;
      end
     CASH[1] =record[3];
     CASH[2] =record[4];
     CASH[3] =record[5];
     result[1] = DATE;
     result[2] = REMAIN;
     result[3] = CASH;
     teamyar.write_result(json.encode(result))
      db.query_free(); 
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
else
  WidgetTemplate();
end
