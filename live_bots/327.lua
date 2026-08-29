-- botName = NumberOfNewCustomers
-- creator = MozhganRajabali
-- date = 21/08/1403
-- version= 1
--------------------------------------------
--- install [report]
--------------------------------------------
local _BAT_RES_PATH = "2/res_v2";
function readyCodes()
    local data = teamyar.get_input();
    data["res_type"] = "codes"
    data["config"] = json.decode(teamyar.get_attachment("data.txt"))
    local responseRes = teamyar.run_command(_BAT_RES_PATH , data);
    if responseRes ~= nil then
        responseRes = json.decode(responseRes)
        for i = 1 , #responseRes, 1 do
            local loadedFunction, errorMessage = load(responseRes[i])
            if loadedFunction then
                loadedFunction();
            else
                teamyar.write_log("Error: " .. errorMessage);
            end
        end
    end

end
readyCodes();
install_res.resCash();
--------------------------------------------
--- Report
--------------------------------------------
function queryResult(select_query,user_param)
    db.use_db("0000000")
    local params = {
      query = select_query,
      params = user_param
    }
    db.query(params);
    local res_text={};
    local record={};
    while db.query_fetch(record) do
      local tmp=record;
      teamyar.write_log(json.encode(record))
      table.insert(res_text, {JYEARINVOICE = record[1],Current_Datee = record[2],Season = record[3],
                              JTMONTH = record[4],FULLNAME2 = record[5],INVOICE_ID1 = record[6],
                              INVOICE_ID = record[7],TITLE = record[8],MinApprovalDate = record[9],
                              ORG_ID1 = record[10],ProfileID1 = record[11],Product_Id =record[12]
                             });
    end
    db.query_free();
    return res_text;
end
------------------------------------------
function queryResultTotal(select_query,user_param)
    db.use_db("0000000");
      local params1 = {
        query = select_query,
        params = user_param
    }
    db.query(params1);
    local res_text = db.query_fetch();
    db.query_free();
    return res_text[1];
  end

------------------------------------------------
function report()
    local page =getInput("page");
    local res =  teamyar.get_user_info();  
    -- teamyar.write_log(json.encode(res));
    time_zone = json.encode(res["timezone"]);
    local current_date = time.current(); 
    local org = getInput("org");
    local sales_engineer = getInput("salesEngineer");
    local product = getInput("product");
    local date_from = getInput("dateFrom");
    local date_to = getInput("dateTo");
  

    local where_con = "where 1=1";

      if org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil then
         org_id =json.encode(org[1]["id"]);
         where_con = where_con .. " AND ORG_ID1 = " .. org_id ;
      end

      if sales_engineer ~= nil and #sales_engineer>0  then
        where_con = where_con .. " AND ProfileID1 IN (";
        for i=1,#sales_engineer ,1 do
          local item_sales_engineer = sales_engineer[i];
          if item_sales_engineer ~= nil and item_sales_engineer.id ~= nil then
            where_con = where_con .. item_sales_engineer.id ;
            if i<#sales_engineer  then
              where_con = where_con .. "," ;
            end
          end

        end
        where_con = where_con .. ")";
      end

      if product ~= nil and #product>0  then
        where_con = where_con .. " AND Product_Id IN (";
        for i=1,#product ,1 do
          local item_product = product[i];
          if item_product ~= nil and item_product.id ~= nil then
            where_con = where_con .. item_product.id ;
            if i<#product  then
              where_con = where_con .. "," ;
            end
          end

        end
        where_con = where_con .. ")";
      end

      if date_from ~= nil and date_from ~= "" and tonumber(date_from)>0 then
        where_con = where_con .. " AND MinApprovalDate >= " .. date_from ;
     end
     
     if date_to ~= nil and date_to ~= "" and tonumber(date_to)>0 then
        where_con = where_con .. " AND MinApprovalDate <=" .. date_to ;
     end

     
      local result = teamyar.get_attachment("query_number_of_new_customers.txt");
      teamyar.write_log("where_con-----"..where_con);
      local result = string.gsub(result,"{{time_zone}}",time_zone);
      local result = string.gsub(result,"{{current_date}}",current_date);
      local result = string.gsub(result,"{{where_condition}}",where_con);
      teamyar.write_log(result);
      local rep_data = {};
      local total = 0;
      if (org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil) then
         rep_data = queryResult(result.." limit ?,20",{page});
         total = queryResultTotal("select count(*) from ("..result..")res",{});
      end
      
      -------------------------------------------------------------------------------------
     local report = {
       {
           name = "main" ,
           title = "جدول" ,
           report = {
            data ={total=total ,data=rep_data,page=page} ,
            page = page
     }
       } 
   }

     teamyar.write_result(json.encode(report));
    -- teamyar.write_log(json.encode(result));
end

--------------------------------------------
--- manager
-------------------------------------------
function saleaEngineerAcl()
  local query = teamyar.get_attachment("query_sales_engineer_acl.txt");
  teamyar.write_log(query)
  local dataQuery = {
    query= query,
    params={}
  }
  db.query(dataQuery)
  
  local record={};
  local res = {};
  while db.query_fetch(record) do
      table.insert(res,{id = record[1],name = record[2]})
  end
  db.query_free();
  teamyar.write_result(json.encode(res));
  teamyar.write_log("ppppp" .. json.encode(res));
end
--------------------------------------------
local type = getInput("type");
if type ~= nil and type == 2 then 
  saleaEngineerAcl()
elseif type ~= nil and type == 100 then
    report()
else
    local responseResReport = install_res.resReport();
    teamyar.write_result(responseResReport);
end