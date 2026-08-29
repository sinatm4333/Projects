function WidgetTemplate()
    local total_count = 0;
    local profit_count = 0;
    local user_info = teamyar.get_user_info()
    local param = {
        query=teamyar.get_attachment("get_login_for_mt5.txt");
        params={user_info.id} 
    } 
    db.query(param) 
    local login=db.query_fetch() 
    db.query_free();
    local cur_time=time.current()+user_info.timezone;
    local unix_date_from=time.get_unixtime([=[{"year":]=]..time.get_year(cur_time)..[=[,"month":]=]..time.get_month(cur_time)..[=[,"day":1,"hour":0,"minute":0,"second":0}]=])
    --local unix_date_from=time.get_unixtime({year=time.get_year(cur_time),month=time.get_month(cur_time),day=1,hour=0,minute=0,second=0})
    local unix_date_to=time.get_unixtime([=[{"year":]=]..time.get_year(cur_time)..[=[,"month":]=]..time.get_month(cur_time)..[=[,"day":]=]..time.get_day(cur_time)..[=[,"hour":]=]..time.get_hour(cur_time)..[=[,"minute":]=]..time.get_minute(cur_time)..[=[,"second":]=]..time.get_second(cur_time)..[=[}]=])
    --local unix_date_to=time.get_unixtime({year=time.get_year(cur_time),month=time.get_month(cur_time),day=time.get_day(cur_time),hour=time.get_hour(cur_time),minute=time.get_minute(cur_time),second=time.get_second(cur_time)})

   if login~=nill then
    local result = teamyar.call_api(37, '/api/mt5/UserDeals', {manager=9111,login=login[1],datefrom=unix_date_from, dateto=unix_date_to});
    if result.success then
        for i = 1, #result.data do
            if result.data[i].Entry ~= 0 and result.data[i].profit > 0 then
                profit_count = profit_count + 1
         	end
      	if result.data[i].Entry ~= 0 then
            total_count = total_count + 1
         	end
        end
    end
  end

    local win_rate=0
    if total_count>0 then
        win_rate = (profit_count/total_count)*100;
    end
    local function round(number, decimal_places)
        local factor = 10 ^ decimal_places
        return math.floor(number * factor + 0.5) / factor
    end
      
    win_rate = round(win_rate, 2)
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
    --local script =  teamyar.get_attachment("crm_win_rate_deals.js");
    local css =  teamyar.get_attachment("crm_win_rate.css");
    local template = teamyar.run_command("2/res_bot",{
        id = "crm_win_rate",
        tpl_name = "html",
        title = "WIN_RATE",
        body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
              css=css,
        script=[[
        (function(){
        var holder_id = '#holder_body_html_]]..random..[[';
        $.Teamyar.layout({
            selector:holder_id,
            id: "crm_win_rate_]]..random..[[",
            type: "COL-1",
            controls: [
        
        " <div class='holder_box_win_rate'> " +
        " <div class='each_holder_win_rate'> " +
        "   <div class='each_holder_absolute_win_rate'> " +
        "     <div class='holder_black_win_rate'> " +
        " <p> <span id='crm_win_rate_count_"+]]..random..[[+"' style='font-size:25px;color:white;'>" +$.Teamyar.tools.numConvertor(]]..win_rate..[[)+'%'+ "</span></p>"+
        "<br>" +
        " <p> <span id='crm_win_rate_title_"+]]..random..[[+"' style='color:white;'>" +ty__main.botGetlang("WIN_RATE")+ "</span></p>"+
        "     </div> " +
        "   </div> " +
        " </div> "+
        " </div> "
        
            ]})
        })();
    
        ]]

        });
    teamyar.write_result(template);
end
WidgetTemplate();