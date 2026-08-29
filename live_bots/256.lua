--Bot Responsible Calls By Zmo
--ver :001
--start :2024-4-18
input = teamyar.get_input();
local res = 0;
local datef = 0;
local datet = 0;
-----------------------------------------------------------
function getQueryResponse(query,query_params)
  local record={};
  local answer={}; 
  local cancel={}; 
  local result_data={} ; 
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  while db.query_fetch(record) do 
    table.insert(answer,tonumber(record[1]));
    table.insert(cancel,tonumber(record[2]));
  end
  table.insert(result_data, { succ = answer, nsucc = cancel})
  db.query_free();
  teamyar.write_log(json.encode(result_data));
  return result_data;

end
-------------------------------
function WidgetTemplate()  
  if res == nil then 
    res = 0;
  end 
  teamyar.write_log("res"..json.encode(res).."datet"..json.encode(datef).."datef"..json.encode(datet));
  local query = teamyar.get_attachment("query.sql");
  local   box_clause = [[( CallerNum > 100000 OR ConnectedLineNum > 10000)]];
  query = string.gsub(query, "{box_clause}",box_clause);
  local res1 = json.encode(getQueryResponse(query, { datef, datet, res}));
  if res1 == nil or #res1 == 0 then
    res1 = "[]";
  end
  local res = teamyar.run_command("2/res_bot",{
                                                          id = "responsible_calls_chart_id",
                                                          tpl_name = "chart",
                                                          title = "",
                                                          script = '',
                                                          data = [[()=>{ 
                                                          var data = ]] .. res1 .. [[;         
                                                          console.log(data)
                                                          var succ=0,nsucc=0;  
                                                          var dsuccses=[],dnotsucc=[];  
                                                          for(var i=0;i<data.length;i++){
                                                          if(!isNaN(data[i].succ))
                                                          succ+=Number(data[i].succ);
                                                          if(!isNaN(data[i].nsucc))
                                                          nsucc  +=Number(data[i].nsucc);
                                                        }                                                  
                                                          dsuccses.push(succ);
                                                          dnotsucc.push(nsucc);
                                                          var new_data= [	 {name:ty__main.RSC_BOT_LANG.SUCCSES,data:dsuccses},
                                                          {name:ty__main.RSC_BOT_LANG.NOT_SUCCSES,data:dnotsucc}]   ;
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
                                                          type:'column'
                                                        },
                                                          title: {
                                                          text: '' ,
                                                          direction: 'rtl'
                                                        },
                                                          tooltip: {
                                                          useHTML: true,
                                                          formatter: function() {                                                                                  
                                                          return '<div lang="fa" dir="rtl"> ' +
                                                          this.series.name + ' : ' + this.y.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") +
                                                          '</div>';
                                                        }
                                                        },
                                                          legend: {
                                                          layout: 'vertical',
                                                          symbolRadius: 0,
                                                          squareSymbol: false,
                                                          align: align_legend,
                                                          rtl:rtl_legend,
                                                          verticalAlign: 'middle',
                                                          itemMarginTop: 10,
                                                          itemMarginBottom: 10,
                                                          direction:'ltr',
                                                          useHTML: true,
                                                          labelFormatter: function() {
                                                          var legendItem = document.createElement('div'),
                                                          symbol = document.createElement('span'),
                                                          label = document.createElement('span');							
                                                          symbol.innerText =this.name;
                                                          symbol.style.borderColor = this.color;
                                                          symbol.classList.add('xLegendSymbol');
                                                          label.innerText =" - "+ this.userOptions.data[0];
                                                          legendItem.appendChild(symbol);
                                                          legendItem.appendChild(label);
                                                          return legendItem.outerHTML;
                                                        }
                                                        },
                                                          xAxis: {
                                                          title:"",
                                                          categories: [""],
                                                        },
                                                          yAxis: {
                                                          labels: {
                                                          formatter: function () {
                                                          return Highcharts.numberFormat(this.value, 0,'','');
                                                        }
                                                        },
                                                          title:"",                                                                                
                                                        },
                                                          plotOptions: {
                                                          series: {
                                                          allowPointSelect: true,
                                                          cursor: 'pointer',
                                                          dataLabels: [{
                                                          enabled: true,
                                                          formatter: function() {
                                                          return this.series.name
                                                        },
                                                          distance: 20
                                                        },
                                                          ]
                                                        }
                                                        },
                                                          series: new_data,    
                                                        }
                                                        }]]

    });
  local str = "<div style='color:red;font-size:16px;'>There isnt any data to show!!</div>"
  local userinfo = teamyar.get_user_info();
  if userinfo.lang_id == 4 then
    str = "<div style='color:red;font-size:16px;'>داده ای برای نمایش وجود ندارد!! </div>"
  end
  if res1 ~= nil and #res1 > 0 then
    teamyar.write_result(res);
  else
    teamyar.write_result(str);
  end
end
------------------
function loadData()
  local data = teamyar.get_data("rsc_data")
  teamyar.write_result(json.encode(data));
end
----------------------
function resAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select id i,title n from project_project where title<>"" ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and title like N'%]]..data.search..[[%'  ]]
  end
  if data.status ~= nil and tonumber(data.status) <=1 then
    query_param = query_param ..  [[ and status=]]..data.status
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(getQueryResponse(query_param , {}));
end

------------------
function WidgetTemplate2()  
  local random = math.random(1, 1000);
  local script =  teamyar.get_attachment("main.js");
  local css  =  teamyar.get_attachment("main.css");
  local user_info = teamyar.get_user_info();
  local str_title = "";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
    str_title ="نمودار تعداد تماس های موفق و ناموفق"
  else
    str_title ="Count Of Responsible Calls"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template =  teamyar.run_command("2/res_bot",{
      id = "prj_responsible_calls_chart",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'rsc_holder_body_html_"..random.."\\'></div>",
      script = [[
      (function(){
      ]]..str_lang..[[; 
      var holder_id = '#rsc_holder_body_html_]]..random..[[';
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
  --elseif input.type == 6 then 
  -- resAcl(input.data)
elseif input.type == 3 then 
  local chash_data = {rsc_res = input.res, rsc_rn = input.rn,rsc_datef = input.datef, rsc_datet = input.datet}
  teamyar.set_data("rsc_data",chash_data);
  data = teamyar.get_data("rsc_data")
  res = data.value.pbs_res;
  if res ~= nil  and res ~= "" then 
    WidgetTemplate()  
  end
elseif input.type == 4 then 
  local chash_data = {rsc_res = input.res, rsc_rn = input.rn,rsc_datef = input.datef, rsc_datet = input.datet}
  teamyar.set_data("rsc_data", chash_data);
  res = input.res;
  if res == nill then 
    res = 0;
  end 
  local query = teamyar.get_attachment("query.sql");
  local   box_clause = [[( CallerNum > 100000 OR ConnectedLineNum > 10000)]];
  query = string.gsub(query, "{box_clause}",box_clause);
  teamyar.write_log(query);
  local res1 = getQueryResponse(query, { input.datef, input.datet,input.res});
  res = input.res;
  datef = input.datef;
  datet = input.datet;
  teamyar.write_log(json.encode(res1));
  teamyar.write_result(json.encode(res1));
else
  data = teamyar.get_data("rsc_data")
  res = data.value.rsc_res;
  datef =  data.value.rsc_datef;
  datet = data.value.rsc_datet;
  WidgetTemplate2();
  if res ~= nil and res ~= "" then 
    WidgetTemplate()  
  end 
end





