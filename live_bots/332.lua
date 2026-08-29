--Bot Project Chat Today By Zmo
input = teamyar.get_input();
local group_id = 0;
local kind = 0;
local user_info = teamyar.get_user_info();
local cur_date=time.current();
local query=[[SELECT JSON_ARRAYAGG(JSON_OBJECT('name',n, 'y',y)) from (SELECT count(m.id) as n,  FLOOR(MOD(m.date_create+]] .. user_info.timezone ..[[,864000000000)/(10000000*60*60) )  as y  FROM chat_message m 
		 join chat_dialogs d on d.id=m.dialog_id 
		 where m.type in (1,2) and (m.date_create - MOD(m.date_create,864000000000))=(]]..cur_date..[[ - MOD(]]..cur_date..[[,864000000000))  ]];
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
  if project_id==nill then 
    project_id=0;
  end 
        if input.kind==1 then
         query = query .. "and d.group_id=1 and d.type=1 "
      elseif  input.kind==2 then  
        if  input.group_id~="" then
              query = query .. "and d.group_id=" ..input.group_id  .. " and d.type=1 "
        else
              query = query .. "and d.group_id>1 and d.type=1 "
        end
      elseif input.kind==3 then
        if input.group_id ~="" then
              query = query .. "and d.group_id=" .. input.group_id .. " and d.type=0 "
        else
              query = query .. "and d.group_id>1 and d.type=0 "
        end
      end
      query = query .." group by y order by y)mm "  
        teamyar.write_log(query);
  
        local res1 =  getQueryResponse(query  , {});
         teamyar.write_log(json.encode(res1));
        if res1 == nill or #res1 == 0 then
   			 res1 = "[]";
  		end
        local res = teamyar.run_command("2/res_bot",{
            id = "p_project_chat_today_id",
            tpl_name = "chart",
            title = "",
            script = '',
                     data = [[()=>{ 
            var data = ]] .. res1 .. [[;
      		var ldata =[],vdata=[];
            for(var i=0;i<data.length;i++){
                     ldata.push(data[i].name);
                     vdata.push(data[i].y);
             }
      var  lang = ty__fullinfo.user_info.language;
        var rtl_legend=false;
        var align_legend='right';
        if(lang=='Persian')
        {
        rtl_legend=true;
        align_legend ='left';
      }

        return {
     chart: {
                                                                                                     type: 'column'
                                                                                                   },
                                                                                                     title: {
                                                                                                       text: '',
                                                                                                       align: 'left'
                                                                                                     },
                                                                                                     xAxis: {
                                                                                                       allowDecimals: false,
                                                                                                       categories: vdata,
                                                                                                           title: {  

                                                                                                                 floating: false,
                                                                                                             allowDecimals: false,
                                                                                                                    y:21, 
                                                                                                             style:{                                                                                                                   			
                                                                                                               fontSize: '1.8em',
                                                                                                               fontWeight:'bold',
                                                                                                             }
                                                                                                       }


                                                                                                     },
                                                                                                     yAxis: {
                                                                                                                     formatter: function () {
                                                                                                           return Math.trunc(this.value * 10) / 10;
                                                                                                         },
                                                                                                           type: 'number',
                                                                                                       allowDecimals: false,
                                                                                                       min: 0,
                                                                                                       title: {
                                                                                           
                                                                                                         text: ty__main.PCT_BOT_LANG.MESSAGE_COUNT,
                                                                                                        floating: false,
                                                                                                         allowDecimals: false,
                                                                                                         x: -15,
                                                                                                         style:{                                                                                                                   			
                                                                                                           fontSize: '1.10em',
                                                                                                           fontWeight:'bold',
                                                                                                         }
                                                                                                       },
                                                                                                       stackLabels: {
                                                                                                         enabled: false
                                                                                                       }
                                                                                                     },
                                                                                                     tooltip: {
                                                                                                       useHTML: true,
                                                                                                       formatter: function() {                                                                                  
                                                                                                         return '<div lang="fa" dir="rtl"> ' +
                                                                                                           "<span class='tlabel'>"+this.series.name + ' : ' +"</span><span class='tcontent'> "+this.y+"</span><br>"+
                                                                                                           "<span class='tlabel'>"+ty__main.PCT_BOT_LANG.COUNT_MESSAGE+ ' : ' +"</span><span class='tcontent'> "+this.x+"</span><br>"+
                                                                                                           '</div>';
                                                                                                       }

                                                                                                     },
                                                                                                     plotOptions: {
                                                                                                       column: {
                                                                                                         stacking: 'normal',
                                                                                                         dataLabels: {
                                                                                                           enabled: true
                                                                                                         }
                                                                                                       }
                                                                                                     },
                                                                                                     series: [{
                                                                                                       name: ty__main.PCT_BOT_LANG.TIME_OF_MESSAGE,
                                                                                                       data: ldata
                                                                                                     }]                                                                       
      }
      }]]

    });
    local str = "<div style='color:red;font-size:16px;'>There isnt any data to show!!</div>"
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
function loadData()
  local data = teamyar.get_data("pct_data")
   teamyar.write_result(json.encode(data));
end
----------------------
function groupAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,name n from chat_group where status=1 ]]
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
 --       if data.kind ~= nil and tonumber(data.kind) <=1 then
 --    query_param = query_param ..  [[ and status=]]..data.status
 -- end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(getQueryResponse(query_param , {}));
end

------------------
function WidgetTemplate2()  
  local random = math.random(1, 1000);
  local script =  teamyar.get_attachment("main.js");
    local css =  teamyar.get_attachment("main.css");
    local user_info = teamyar.get_user_info();
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
  else
     str_lang = teamyar.get_attachment("English.js");
  end
  local template =  teamyar.run_command("2/res_bot",{
      id = "prj_chat_today_chart",
      tpl_name = "html",
      title = "PROJECT_CHAT_TODAY_CHART",
      body = "<div id=\\'pct_holder_body_html_"..random.."\\'></div>",
      script = [[
              (function(){
                 ]]..str_lang..[[; 
               var holder_id = '#pct_holder_body_html_]]..random..[[';
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
elseif input.type == 6 then 
 	groupAcl(input.data)
elseif input.type == 3 then 
     local chash_data = {pct_kind = input.kind, pct_kn = input.kn,pct_group_id = input.group_id, pct_gn = input.gn}
    teamyar.set_data("pct_data",chash_data);
    data = teamyar.get_data("pct_data")
 	group_id = data.value.pct_group_id;
    if group_id ~= nill  and group_id ~= "" then 
   		 WidgetTemplate()  
  	end
elseif input.type == 4 then 
     local chash_data = {pct_kind = input.kind, pct_kn = input.kn,pct_group_id = input.group_id, pct_gn = input.gn}
    teamyar.set_data("pct_data",chash_data);

      if input.kind==1 then
        teamyar.write_log("kind 1");
         query = query .. "and d.group_id=1 and d.type=1 "
      elseif  input.kind==2 then  
        teamyar.write_log("kind 2");
        if  input.group_id~="" then
              query = query .. "and d.group_id=" ..input.group_id  .. " and d.type=1 "
        else
              query = query .. "and d.group_id>1 and d.type=1 "
        end
      elseif input.kind==3 then
       teamyar.write_log("kind 3");
        if input.group_id ~="" then
              query = query .. "and d.group_id=" .. input.group_id .. " and d.type=0 "
        else
              query = query .. "and d.group_id>1 and d.type=0 "
        end
      end
      query = query .." group by y order by y)mm " 
      teamyar.write_log(query);
      local res1 =  getQueryResponse(query, {});
 	  group_id = input.group_id;
 	  kind=input.kind
      teamyar.write_result(json.encode(res1));
  else
    data = teamyar.get_data("pct_data")
    group_id = data.value.pct_group_id;
      kind = data.value.pct_kind;
    WidgetTemplate2();
    WidgetTemplate()  
end





