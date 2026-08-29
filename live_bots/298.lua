--Bot Accouting Total Revenue  By Zmo
input = teamyar.get_input();
local org_id = input.org_id;
if org_id == nill or org_id == "" then
  org_id = 0
end
--
local str_query = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("name",y, "y", m)) FROM (with cte_symbol_sums as(
                               select coalesce(sum( abs((vr.deb - vr.crd)/POWER(10,COALESCE((select DECIMAL_COUNT from PA_SYMBOLS 
                              where id=po.BASE_CURRENCY limit 1 ),0)))),0)base_symbol_sum, ((select distinct title from pa_fiscal_year where 
                              vo.RUN_DATE > START_DATE and vo.RUN_DATE < END_DATE and org_id= ]]..org_id..[[ limit 1))y from pa_voucher_record vr 
                              inner join pa_voucher vo on vr.voucher_id = vo.id and VR.ORG_ID = ]]..org_id..[[ AND VO.ORG_ID = ]]..org_id..[[ AND vr.deleted <>1
                              and vo.deleted = 0 AND vo.status <> 1 inner join pa_account ac on vr.account_id = ac.id AND ac.org_id =  ]]..org_id..[[
                              and ac.deleted = 0 and ac.code like CONCAT('','%') inner join PA_ORGANIZATIONS po on po.org_id=ac.org_id
                              where ac.DELETED = 0 and ac.ORG_ID= ]]..org_id 
-----------------------------------------------------------
function getQueryResponse(query,query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
-------------------------------
function WidgetTemplate()  
  local code_li={};
  if input.acc_id ~= nill  then 
    if type(input.acc_id) == "number"   then   
      table.insert(code_li, input.acc_id)
    else
      for i, v in ipairs(input.acc_id) do
        if v ~= 0 then
          table.insert(code_li,v.id)
        end                
      end
    end
  end
  if code_li ~= nil and #code_li > 0  then 
    local temp_str="";
    for j, l in ipairs(code_li) do
      if temp_str=="" then 
        temp_str =[[  ac.code like ']]..l..[[%'  ]]
      else
        temp_str = temp_str..[[ or ac.code like ']]..l..[[%'  ]]
      end
    end
    str_query = str_query..[[ and  (]]..temp_str..[[ ) ]]
  end
  str_query = str_query ..[[  group by y) select base_symbol_sum m,y from cte_symbol_sums )oo;]];       

  teamyar.write_log(str_query);
  local res1 =  getQueryResponse(str_query  ,{});
  if res1 == nill or #res1 == 0 then
    res1="[]";
  end
  local res = teamyar.run_command("2/res_bot",{
      id = "bot_total_revenue_chart",
      tpl_name = "chart",
      title = "",
      script = '',
      data= [[()=>{ 
                              var years =[];
                              var data = ]] .. res1 .. [[;
                              for(var i=0;i<data.length;i++)
                              years.push(data[i].name)
                              return {
                              chart: {     
                              type:'column'
                            },
                              title: {
                              text: '' ,
                              direction: 'rtl'
                            },
                              tooltip: {
                              useHTML: true,
                              formatter: function() {
                              return  '<div lang="fa" dir="'+ty__main.botGetlang("DIR")+'"> '+ty__main.botGetlang("FISCAL_YEAR")+' : ' + this.key +'<br>'+ty__main.botGetlang("REMAIDED")+':'+ this.y.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + '</div>';
                            }
                            },
                              subtitle: {
                              text: ''
                            },
                              plotOptions: {
                              series: {
                              allowPointSelect: true,
                              cursor: 'pointer',
                              dataLabels: [{
                              enabled: true,
                              distance: 20
                            }, {
                              enabled: true,
                              distance: -40,
                              style: {
                              fontSize: '1.2em',
                              textOutline: 'none',
                              opacity: 0.7
                            },
                              filter: {
                              operator: '>',
                              value: 10
                            }
                            }]
                            }
                            },
                              series: [
                              {
                              name: "",
                              colorByPoint: true,
                              data: data       
                            }
                              ],   
                              yAxis: {
                              title:"",
                            },
                              xAxis: {
                              categories: years,
                              crosshair: true,
                              accessibility: {
                              description: 'Countries'
                            }
                            },
                            }
                            }]]    
                            });
  local str="<div style='color:red;font-size:16px;'>There isnt any data to show!!</div>"
  local userinfo = teamyar.get_user_info();
  if userinfo.lang_id == 4 then
    str = "<div style='color:red;font-size:16px;'>داده ای برای نمایش وجود ندارد!! </div>"
  end
  if res1 ~= nill and #res1 > 0 then
    teamyar.write_result(res);
  else
    teamyar.write_result(str);
  end
end
------------------
function orgAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
  									from (select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
  else
    query_param = query_param .. [[) p ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(getQueryResponse(query_param, {}));
end
-------------------------------
function accountAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
 									 from (select code i,concat('#',code,'_',name)n from pa_account where 1=1 ]] 
  if geted_org_id~0 then 
    query_param = query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'   or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(getQueryResponse(query_param , {}));
end
-------------------------------------------------
function loadData()
  local data = teamyar.get_data("tr_data")
  teamyar.write_result(json.encode(data));
end
------------------
function WidgetTemplate2()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  local user_info = teamyar.get_user_info();
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_lang = teamyar.get_attachment("English.js");
  end
  local template =  teamyar.run_command("2/res_bot",{
                                                                              id = "prj_total_revenue",
                                                                              tpl_name = "html",
                                                                              title = "ACCOUNTING_TOTAL REVENUE_CHART",
                                                                              body = "<div id=\\'tr_holder_body_html_"..random.."\\'></div>",
                                                                              script=[[
                                                                              (function(){
                                                                              ]]..str_lang..[[      
                                                                              var holder_id = '#tr_holder_body_html_]]..random..[[';
                                                                              var random_id = ]] .. random .. [[;
                                                                              ]]..script..[[
                                                                            })();
                                                                              ]],
                                                                              css = css
                                                                            });
  teamyar.write_result(template);
end
----------------------
if input.type == 5 then 
  loadData()
elseif input.type == 2 then 
  orgAcl(input.data)
elseif input.type == 6 then 
  accountAcl(input.data)  
elseif input.type == 3 then 
  local chash_data = {tr_project_id = input.project_id, tr_gn = input.gn}
  teamyar.set_data("tr_data", chash_data);
  data = teamyar.get_data("tr_data")
  project_id = data.value.project_id;
  if project_id ~= nill  and project_id ~= "" then 
    WidgetTemplate()  
  end
elseif input.type == 4 then 
  local code_li={};
  if input.acc_id ~= nill  then 
    if type(input.acc_id) == "number"   then   
      table.insert(code_li, input.acc_id)
    else
      for i, v in ipairs(input.acc_id) do
        if v ~= 0 then
          table.insert(code_li,v.id)
        end                
      end
    end
  end
  local accounts = json.encode(input.acc_id)
  local chash_data = {tr_org_id = input.org_id, tr_gn = input.on, tr_accounts = accounts}
  teamyar.set_data("tr_data", chash_data);
  if code_li ~= nil and #code_li > 0  then 
    local temp_str="";
    for j, l in ipairs(code_li) do
      if temp_str=="" then 
        temp_str =[[  ac.code like ']]..l..[[%'  ]]
      else
        temp_str = temp_str..[[ or ac.code like ']]..l..[[%'  ]]
      end
    end
    str_query = str_query..[[ and  (]]..temp_str..[[ ) ]]
  end
  str_query = str_query..[[ group by y) select base_symbol_sum m,y from cte_symbol_sums )oo;]];

  teamyar.write_log(str_query);
  local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":2,"second":1}]])
local currentdate = string.format("%18.0f" ,temp_time);
 local s = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("name",y, "y", m,"t",t)) FROM (select title y, org_id m,type t from
  						pa_fiscal_year where  org_id=]].. input.org_id..[[ and ]]..currentdate..[[ > START_DATE and ]]..currentdate..[[< END_DATE  )h]];

  local res1 =  getQueryResponse(str_query, {});
  teamyar.write_result(json.encode(res1));
else
  data = teamyar.get_data("tr_data")
  org_id = data.value.tr_org_id;
  WidgetTemplate2();
  if org_id ~= nill and org_id ~= "" then 
    WidgetTemplate()  
  end
end





