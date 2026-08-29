--Bot Monthly Open Account by zmo
--ver 001
--start 2024-4-18
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
res_id = 0;

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
  if res_id==nill then 
    res_id=0;
  end 

  local str_query =[[ SELECT JSON_ARRAYAGG(JSON_OBJECT("name",t, "d", d)) 
                                FROM ( select count(tmp.id) d, tmp.t from(                     
                                select c.id ,(select jmonth from report_dimdate where run_date>=datekey and 
                                run_date<=(datekey+(24*60*60*10000000)) limit 1)t from crm_info c inner join crm_ty_permission p on p.id=c.id where
                                DELETED=0 and p.perm=4 and  p.user_id=]]..res_id..[[)tmp  where t is not null
                                group by tmp.t)tt
                                ]]
  teamyar.write_log(str_query);
  local res1 =  getQueryResponse(str_query  , {});
  teamyar.write_log(json.encode(res1));
  if res1 == nill or #res1 == 0 then
    res1="[]";
  end
  local res = teamyar.run_command("2/res_bot",{
      id = "monthly_open_account_chart_id",
      tpl_name = "chart",
      title = "",
      script = '',
      data= [[()=>{ 
      var data = ]] .. res1 .. [[;
      var ex=[];
      var exval=0;  
      var tmp_month=0;
      var ex_is_pushed=false;

      for(var j=1;j<=12;j++)//for month
      {
      var added_ex=false;

      for(var i=0;i<data.length;i++)
      {                                
      if(data[i].name!=j)//for special  (j) month hasent value              
      continue;
      if(tmp_month==data[i].name)// if month is repeated
      {
      if (!isNaN(data[i].d) && data[i].d!="")                           
      exval+=Number(data[i].d)                     

    }
    else//for next month
      {                 
      if (!isNaN(data[i].d) && data[i].d!="")                             
      exval+=Number(data[i].d);                          

      if(tmp_month==j)
      {
      if(!isNaN(exval)  )//if hasent value for this month
      {
      ex.push(Number(exval));
      exval=0;
      added_ex=true;
    }
      tmp_month=data[i].name;
    }
      tmp_month=data[i].name;
      if(i==data.length-1)//for end step 
      {              
      if( !isNaN(exval) && added_ex==false)
      {
      ex.push(Number(exval));
      exval=0;
      added_ex=true;
    }
    }  
    }
    }//end for i
      if  ( added_ex==false)
      if(exval!=0)
      {
      ex.push(exval);
      exval=0;
    }
    else
      ex.push(null);                     
    }//end for j
      console.log(data)
      console.log(ex)
      var labs=[  ty__main.MOA_BOT_LANG.M_1, ty__main.MOA_BOT_LANG.M_2, ty__main.MOA_BOT_LANG.M_3, ty__main.MOA_BOT_LANG.M_4, ty__main.MOA_BOT_LANG.M_5,
      ty__main.MOA_BOT_LANG.M_6, ty__main.MOA_BOT_LANG.M_7, ty__main.MOA_BOT_LANG.M_8, ty__main.MOA_BOT_LANG.M_9, ty__main.MOA_BOT_LANG.M_10,
      ty__main.MOA_BOT_LANG.M_11, ty__main.MOA_BOT_LANG.M_12];
      return {
      chart:{   type: 'spline'
    },
      title: {
      text: '',
      align: 'left'
    },
      tooltip: {
      useHTML: true,
      formatter: function() {                                                                                                         
      return   '<div lang="fa" dir="'+ty__main.MOA_BOT_LANG.DIR+'"> '+ty__main.MOA_BOT_LANG.MONTH+' : ' +
      this.key +'<br>'+this.series.name+':'+ this.y.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + '</div>';
    }
    },
      yAxis: {
      labels: {
      formatter: function () {
      return Highcharts.numberFormat(this.value, 0,'','');
    }
    },
      title: {
      text: ty__main.MOA_BOT_LANG.OPEN_ACC_COUNT,
      floating: true,
      x: -15,
      style:{                                                                                                                   			
      fontSize: '1.5em',
      fontWeight:'bold',
    }
    }
    },
      xAxis: {
      title: {
      floating: true,
      y:21, 
      text: ty__main.MOA_BOT_LANG.MONTHS,
      style:{                                                                                                                  				
      fontSize: '1.5em',
      padding:'10px',
      fontWeight:'bold',
    }
    },
      categories:labs,
    },
      legend: {
      layout: 'vertical',
      align: 'right',
      verticalAlign: 'middle',
      itemMarginTop: 10,
      itemMarginBottom: 10,
    },
      plotOptions: {
      series: {
      connectNulls: true,
      label: {
      connectorAllowed: false
    },                                                                                              
    }
    },
      series: [{
      name: ty__main.MOA_BOT_LANG.ACC_COUNT_MONTHLY,
      data:ex
    }],
      responsive: {
      rules: [{
      condition: {
      maxWidth: 500
    },
      chartOptions: {
      legend: {
      layout: 'horizontal',
      align: 'center',
      verticalAlign: 'bottom'
    }
    }
    }]
    }
    }
    }
      ]]

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
function loadData()
  local data = teamyar.get_data("moa_data")
  teamyar.write_result(json.encode(data));
end
----------------------
function resAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select id i,title n from project_project where title<>"" ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and title like N'%]]..data.search..[[%'  ]]
  end
  if data.status ~= nil and tonumber(data.status)<=1 then
    query_param = query_param ..  [[ and status=]]..data.status
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(getQueryResponse(query_param , {}));
end
------------------
function WidgetTemplate2()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  local  str_title = "";
  if user_info.lang_id == 4 then
    str_title = "نمودار تعداد افتتاح حساب ماهانه"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Monthly Account Opening Chart"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template =  teamyar.run_command("2/res_bot",{
      id = "prj_monthly_open_account_chart",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'moa_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[       
      var holder_id = '#moa_holder_body_html_]]..random..[[';
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
  resAcl(input.data)
elseif input.type == 3 then 
  local chash_data = {moa_res = input.res, moa_rn = input.rn}
  teamyar.set_data("moa_data", chash_data);
  data = teamyar.get_data("moa_data")
  res_id = data.value.moa_res;
  if res_id ~= nill  and res_id ~= "" then 
    WidgetTemplate()  
  end
elseif input.type == 4 then 
  local chash_data =  {moa_res= input.res, moa_rn = input.rn}
  teamyar.set_data("moa_data", chash_data);
  res_id = input.res;
  if res_id == nill then 
    res_id = 0;
  end 
  local str_query =[[ SELECT JSON_ARRAYAGG(JSON_OBJECT("name",t, "d", d)) 
                                FROM ( select count(tmp.id) d, tmp.t from(                     
                                select c.id ,(select jmonth from report_dimdate where run_date>=datekey and 
                                run_date<=(datekey+(24*60*60*10000000)) limit 1)t from crm_info c inner join crm_ty_permission p on p.id=c.id where
                                DELETED=0 and p.perm=4 and  p.user_id=]]..res_id..[[)tmp  where t is not null
                                group by tmp.t)tt
                                ]]
  local res1 =  getQueryResponse(str_query, {});
  res_id = input.res;
  teamyar.write_result(json.encode(res1));
else
  data = teamyar.get_data("moa_data")
  res_id = data.value.moa_res;
  WidgetTemplate2();
  if res_id ~= nill and res_id ~= "" then 
    WidgetTemplate()  
  end 
end





