--Bot Category Lead Count by zmo
--ver 001
--start 2024-4-18
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
project_id = 0;
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
  local str_query =[[   SELECT JSON_ARRAYAGG(JSON_OBJECT( 'name',name, 'n',n)) from (select count(p.fullname) n,c.name from crm_classify_person c
  								  inner join crm_cross cc on c.profile_id=cc.refere_id inner join profile_main p on p.id=cc.client_id group by c.name)tmo ]]
  local res1 = getQueryResponse(str_query  , {});
  if res1 == nill or #res1 == 0 then
    res1="[]";
  end
    local  str_title = "";
      local  str_cat= "";
        local  str_leads= "";
  local str_linc="";
 local str_cats="";
  if user_info.lang_id == 4 then
     str_title = "نمودار تعداد لید های هر رده"
    str_cat="رده"
    str_cats="رده های مشتریان"
    str_leads="لیدها"
    str_linc="تعداد لیدها در رده ها"
  else
     str_title = " Category Lead Count Chart"
    str_cat="Category"
        str_cats="Categories"
    str_leads="Leads"
    str_linc="Count Leads In Categories"
  end
  local res = teamyar.run_command("2/res_bot",{
      id = "p_category_lead_count_chart_id",
      tpl_name = "chart",
      title = str_title,
      script = '',
      data= [[()=>{ 
      var data = ]] .. res1 .. [[;
 var labs=[],new_data=[];
            for(var i=0;i<data.length;i++)
            {     
      labs.push(data[i].name)
      new_data.push(data[i].n)
            }//end for i
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
                                            return   '<div lang="fa" dir=""> '+"]]..str_cat..[["+' : ' +
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
                                            text: "]]..str_leads..[[",
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
                                            text:"]]..str_cats..[[",
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
                                          name: "]]..str_linc..[[",
                                          data: new_data
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
----------------------main
 WidgetTemplate()  






