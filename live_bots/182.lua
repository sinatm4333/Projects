--  --------------------------------------------------------------------------------   Create Financial_period table  ----------------------------------------------------------------------------
function Create_FinancialPeriod()
    local param=[[{"name":"financial_period","fields":"ID bigint default 0 not null, NAME varchar(200) default '' not null","index_items":[ [1,"primary","ID"] ]}]];
    db.use_db(context,"0000000_bot")
    db.check_table(context,param)
end
--  --------------------------------------------------------------------------------   Delete And insert financial periods in financial_period table  ----------------------------------------------------------------------------
function Delete_Insert_FinancialPeriods()
    local Period ={{},{},{},{},{}}
    Period[1]["ID"] = "1"
    Period[1]["NAME"] = "دوره یک ماهه"
    Period[2]["ID"] = 2
    Period[2]["NAME"] = "دوره سه ماهه"
    Period[3]["ID"] = 3
    Period[3]["NAME"] = "دوره شش ماهه"
    Period[4]["ID"] = 4
    Period[4]["NAME"] = "دوره نه ماهه"
    Period[5]["ID"] = 5
    Period[5]["NAME"] = "دوره یک ساله"
    local format= [[{"query":"%s","params":[]}]]

    local Query ="delete from  0000000_bot.Financial_period"
    local Res =string.format(format,Query)
    db.start(context);
    db.query_immediate(context,Res)
    db.commit(context);

    for i=1,  #Period, 1 do
        local Query ="insert into 0000000_bot.Financial_period (id,name) values("..Period[i]["ID"] .. "," .. "'"..Period[i]["NAME"] .. "'" .. ")"
        local Res =string.format(format,Query)
        db.start(context);
        db.query_immediate(context,Res)
        db.commit(context);
    end 
        teamyar.write_result(context,'The insert was successful.');
end

Create_FinancialPeriod()
Delete_Insert_FinancialPeriods()
