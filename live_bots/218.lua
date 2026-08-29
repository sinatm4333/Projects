function getData()
    input = {
    manager= 9111,
    deals_days= 1,
    deposit_days= 1
    }
    result =teamyar.call_api(37,'/api/mt5/Dashboard_blc',input) 
    return json.encode(result.data)
end

function WidgetTemplate()
   local user_info = teamyar.get_user_info()
    local lang = user_info["lang_id"]
    local date = ""
    if lang == 4 then 
       date = time.get_shamsi_str(time.current());
    else
      date = time.get_str(time.current());
    end
    local output = getData()
    local res = teamyar.run_command("2/res_bot",{
    id = "DailyDepositsWithdrawals",
    tpl_name = "chart",
    title = "DailyDepositsWithdrawals",
    script='',
    lang=1,
    data=[[()=>{ 
   var data = ]] .. output .. [[;
   return {
     chart: {
        type: 'bar'
    },
    title: {
        text:  ty__main.botGetlang('DailyDepositsWithdrawals')
    },
    xAxis: {
        categories:  [ty__main.botGetlang('Withdrawals'), ty__main.botGetlang('Deposits')]
    },
    yAxis: {
        min: 0,
        title: {
            text: ty__main.botGetlang('last_day')
        }
    },
    legend: {
        reversed: true
    },
    plotOptions: {
        series: {
            stacking: 'normal',
            dataLabels: {
                enabled: true
            }
        }
    },
    series: [{
        name: ty__main.botGetlang('Price'),
        data: [data.total_deposit, data.total_deposit]
    }]

}
}]]
    
});
  
teamyar.write_result(res);
end

WidgetTemplate();



