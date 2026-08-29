--Bot Final Price zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id=0;
end
local datef = input.df;
local datet = input.dt;
local month = input.month;
local mali_year= input.mali_yr
if account_id == nill then 
  account_id = "";
end 

---------------------------------------------
function loadData()
  local data = teamyar.get_data("afp_data")
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
function productAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,concat('#',code,'_',name)n from wh_product where 1=1 ]] 
    if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end

-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
   local  str_t="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
     str_t=" گزارش مجموع هزینه ها";
  else
     str_lang = teamyar.get_attachment("English.js");
     str_t="Final Price Report";
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_final_price",
      tpl_name = "html",
      title = str_t,
      body = "<div id=\\'afp_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#afp_holder_body_html_]]..random..[[';
    var random_id = ]] .. random .. [[;
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
  elseif input.type == 4 then 
  productAcl(input.data)

elseif input.type == 1 then
  local chash_data = {afp_org_id = org_id, afp_gn = input.gn, afp_datet = datet, afp_datef = datef,
    								 afp_product_id = input.product_id, afp_pn = input.pn}
  teamyar.set_data("afp_data", json.encode(chash_data));
  if datet ~= nill  and datet ~= "" then 
	datet=datet + (24 * 60 * 60 * 10000000);
end
  local qselect=  [[ with cte_symbol_sums as(
                               select ac.CODE, vr.symbol_id, vr.type, sum(vr.deb - vr.crd) base_symbol_sum, sum(vr.fx_deb - vr.fx_crd) symbol_sum  
                               from pa_voucher_record vr 
                               inner join pa_voucher vo on vr.voucher_id = vo.id and VR.ORG_ID =]]..org_id..[[
                               AND VO.ORG_ID =]]..org_id..[[ AND  vr.deleted <>1 ]]
    if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
      qselect = qselect..[[ and vo.run_date<]]..datet..[[ and vo.run_date>]]..datef
    end
qselect=qselect.. [[ and vo.deleted = 0 AND vo.status <> 1
                               inner join pa_account ac on vr.account_id = ac.id  AND ac.org_id = ]]..org_id..[[ and  ac.deleted = 0 
                               and ac.code like CONCAT('','%') 
                               group by ac.code, vr.symbol_id, vr.type) 
                               select  concat('#',ac.code,'_',ac.name) acname
                                ,coalesce((select name from pa_account where id=ac.parent limit 1),'--')ackol, 
                               (select coalesce(abs(sum(base_symbol_sum))/POWER(10,COALESCE((select DECIMAL_COUNT from  PA_SYMBOLS where id=po.BASE_CURRENCY limit 1 ))),0) from cte_symbol_sums s where s.CODE like CONCAT(ac.CODE, '%')) as rp 
                               from PA_ACCOUNT ac inner join PA_ORGANIZATIONS po on po.org_id=ac.org_id
                               where ac.DELETED = 0 and ac.ORG_ID=]]..org_id

qselect = qselect..[[ order by ac.code  ]]
local query_select = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("cn", acname, "ck",ackol,"rp",rp)) from ( ]]..qselect.. [[ limit ?,? )tmp]]
      teamyar.write_log(query_select)
  res_data = queryResult(query_select , {input.from, input.count})
    -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]

  local  totall= queryResult(qtotal, {})

  data = {from = input.from, count = input.count, data = res_data, total = totall}
  teamyar.write_result(json.encode(data))
else
	WidgetTemplate()
end
