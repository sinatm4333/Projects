  local user_info = teamyar.get_user_info()
  local param = {
    	query=teamyar.get_attachment("ducuments_summary_query.txt");
    	params={user_info.id,user_info.id,user_info.id} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
  local total=0 

    while db.query_fetch(record) do 
      table.insert(result,record[1]) 
    end 

  db.query_free(); 

local result1=0 ; 
if result[2] ~= nil then result1=result[2] end
local result2=0 ; 
if result[3] ~= nil then result2=result[3] end
local result3=0 ;
if result[1] ~= nil then result3=result[1] end

local res = teamyar.run_command("2/res_bot",{
    id = "documents_summary",
    tpl_name = "chart",
    title = "DOCUMENTS_SUMMARY",
    script='',
    src='<script src="/res/gui/res/js/chart/variable-pie.js" type="text/javascript"></script>',
    data= [=[()=>{  return { chart: 
                                    {
                                        type: 'variablepie'
                                    },
                                    title: {
                                        text: ty__main.botGetlang('DOCUMENTS_SUMMARY'),
                                        align: 'center'
                                    },
                                    tooltip: {
                                        headerFormat: '',
                                        pointFormat: '<span style="color:{point.color}">\u25CF</span> <b> {point.name}: <b>{point.y}</b>'
                                    },
                                    series: [{
                                        minPointSize: 10,
                                        innerSize: '80%',
                                        zMin: 0,
                                        name: 'countries',
                                        borderRadius: 5,
                                        data: [{
                                            name: ty__main.botGetlang('APPROVED'),
                                            y: ]=]..result1 ..[=[,
                                            z: 5
                                        }, {
                                            name: ty__main.botGetlang('REJECTED'),
                                            y: ]=].. result2..[=[,
                                            z: 5
                                        }, {
                                            name: ty__main.botGetlang('PENDING'),
                                            y: ]=].. result3..[=[,
                                            z: 5
                                        }],
                                        colors: [
                                            '#33ff3c',
                                            '#ff3355',
                                            '#ff9633'
                                        ]
                                    }]
                                }
  }]=]
    
});

teamyar.write_result(res);
