function WidgetTemplate()
    local count = 0
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
            if result.data[i].Entry ~= 0 and result.data[i].profit < 0 then
                count = count + 1
         	end
        end
     end
    end
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
  teamyar.write_log(json.encode(result))
    teamyar.write_log(count)
    local random= IdGenerator:getId();
    --local script =  teamyar.get_attachment("crm_lost_deals.js");
    local css =  teamyar.get_attachment("crm_lost_deals.css");
    local template = teamyar.run_command("2/res_bot",{
        id = "crm_lost_deals",
        tpl_name = "html",
        title = "LOST_DEALS",
        body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
              css=css,
        script=[[
        (function(){
        var holder_id = '#holder_body_html_]]..random..[[';
        $.Teamyar.layout({
            selector:holder_id,
            id: "crm_lost_deals_]]..random..[[",
            type: "COL-1",
            controls: [
        
        " <div class='holder_box_lost_deals'> " +
        " <div class='each_holder_lost_deals'> " +
        "   <div class='each_holder_absolute_lost_deals'> " +
        "     <div class='holder_black_lost_deals'> " +
        " <p> <span id='crm_lost_deals_count_"+]]..random..[[+"' style='font-size:25px;color:white;'>" +$.Teamyar.tools.numConvertor(]]..count..[[)+ "</span></p>"+
        "<br>" +
        " <p> <span id='crm_lost_deals_title_"+]]..random..[[+"' style='color:white;'>" +ty__main.botGetlang("LOST_DEALS")+ "</span></p>"+
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

