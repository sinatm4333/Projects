--Bot Net Profit zmo
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
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
local datef = input.df;
local datet = input.dt;
if account_id == nill then 
  account_id = "";
end 
---------------------------------------------
function loadData()
  local data = teamyar.get_data("apl_data")
  teamyar.write_result(data. value);
end
  --------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
    local params1 = {
      query = select_query,
      params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
----------------------
function orgAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
  										from (select id,name from org_info ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
  else
	query_param = query_param .. [[) p ]]
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(queryResult(query_param, {}));
end
----------------------
function accountAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,concat('#',code,'_',name)n from pa_account where 1=1 ]] 
    if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function WidgetTemplate()  
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  local str_title="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
    str_title="درآمد و هزینه "
  else
     str_lang = teamyar.get_attachment("English.js");
    str_title="Profit And Loss"
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "accounting_profit_loss_rep",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'apl_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#apl_holder_body_html_]]..random..[[';
    var random_id = ]] .. random .. [[;
          var random = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main
if input.type == 3 then 
   loadData()
elseif input.type == 2 then 
  orgAcl(input.data)
  elseif input.type == 6 then 
  accountAcl(input.data)
elseif input.type == 1 then 
  local los_accounts =json.encode(input.account_id_l)
  local pro_accounts =json.encode(input.account_id_p)
  local chash_data = {apl_org_id = org_id, apl_gn = input.gn, apl_pro_accounts = pro_accounts, apl_los_accounts = los_accounts, apl_datet = datet, apl_datef = datef}
  teamyar.set_data("apl_data", json.encode(chash_data));

  local qselect= [[
                          with cte_symbol_sums as( select ac.CODE, vr.symbol_id, vr.type, sum(vr.deb - vr.crd) base_symbol_sum, 
                            sum(vr.fx_deb - vr.fx_crd) symbol_sum from pa_voucher_record vr inner join pa_voucher vo on vr.voucher_id = vo.id and VR.ORG_ID =]]..org_id..[[ AND VO.ORG_ID =]]..org_id
      if datet~=nill  and datet~="" then 
		datet=datet+(24*60*60*10000000);
	end
    if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
      qselect = qselect..[[ and vo.run_date<]]..datet..[[ and vo.run_date>]]..datef
    end
  qselect=qselect..[[ AND vr.deleted <>1 and vo.deleted = 0 
                            AND vo.status <> 1 inner join pa_account ac on vr.account_id = ac.id AND ac.org_id =]]..org_id..[[ and 
                            ac.deleted = 0 and ac.code like CONCAT('','%') group by ac.code, vr.symbol_id, vr.type) select concat('#',ac.code,'_',ac.name) acname,  ac.id id ,
                            (select coalesce(abs(sum(base_symbol_sum))/POWER(10,COALESCE((select DECIMAL_COUNT from PA_SYMBOLS where id=po.BASE_CURRENCY limit 1 ))),0) 
                            from cte_symbol_sums s where s.CODE like CONCAT(ac.CODE, '%')) as rp from PA_ACCOUNT ac inner join 
                            PA_ORGANIZATIONS po on po.org_id=ac.org_id where ac.DELETED = 0 and ac.ORG_ID=]]..org_id
  local ids_loss = ""; 
  local ids_profit = ""; 
  local ids="";
  -------------------------------
  if type(input.account_id_l) == "number"   then   
    ids_loss = input.account_id_l
  else
    for i, v in ipairs(input.account_id_l) do
      if v == 0 then
        ids = v;
      end
      if  ids_loss=="" then
        ids_loss = ids_loss..tostring(v.id);
      else
        ids_loss = ids_loss..","..tostring(v.id);
      end

    end
  end
    -------------------------------
  if type(input.account_id_p) == "number"   then   
    ids_profit = input.account_id_p
  else
    for i, v in ipairs(input.account_id_p) do
      if v == 0 then
        ids_profit = v;
      end
      if  ids_profit=="" then
        ids_profit = ids_profit..tostring(v.id);
      else
        ids_profit = ids_profit..","..tostring(v.id);
      end

    end
  end
  if ids_profit ~= "" and ids_loss ~= "" then 
 	 ids = ids_profit..","..ids_loss;
  elseif ids_profit == "" then
      ids = ids_loss;
  elseif ids_loss == "" then
      ids = ids_profit;
  end
  ------------------------------------
   if ids ~= nill and ids ~= "" then 
      qselect = qselect.. [[ and ac.id in (]]..ids..[[) ]]
    end
  local query_data=  [[  SELECT JSON_ARRAYAGG(JSON_OBJECT("cn", acname,"rp",rp,"id",id)) from ( ]]..qselect..[[ order by ac.code )tmp ]]
  res_data = queryResult(query_data, {})
    -------------------

  data = { data = res_data, acc_l = ids_loss, acc_p = ids_profit}
  teamyar.write_result(json.encode(data))
else
	WidgetTemplate()
end
