-- botName = example_bot
-- creator = developer_name
-- date = 1/01/2024
-- version= 0.1
------------------
local inputs = teamyar.get_input();
local req_type = 0;
if inputs.type ~= nil then
    req_type = inputs.type;
end

-- default page
if req_type == 0 then 
    db.use_db("0000000_bot")
    local params={
        name="production_daily_operation",
        fields="id bigint not null AUTO_INCREMENT,operation_date bigint default 0 not null,transference_date bigint default 0 not null,receipt_date bigint default 0 not null",
        index_items={
            {1,"primary","id"}, -- 1 = SQLINDEX_PRIMARY
            {2,"idx1","operation_date"} -- 2 = SQLINDEX_KEY
        }
    };
    db.check_table(params) 

    local params2={
        name="production_daily_operation_det",
        fields="id bigint not null AUTO_INCREMENT,op_id bigint default 0 not null,product_id bigint default 0 not null,attribute_id bigint default 0 not null,line_id bigint default 0 not null,operator_id bigint default 0 not null,quantity DOUBLE default 0 not null",
        index_items={
            {1,"primary","id"}, -- 1 = SQLINDEX_PRIMARY
            {2,"idx1","product_id,attribute_id"}, -- 2 = SQLINDEX_KEY
            {2,"idx2","op_id"} -- 3 = SQLINDEX_KEY
        }
    };
    db.check_table(params2) 

    db.use_db("0000000")         
    local template = teamyar.get_attachment("periodic_order.html");
    template = string.gsub(template, "{$run_path}", teamyar.self().run_path)
    teamyar.write_result(template)
--get info
elseif req_type == '1' then
    db.use_db("0000000_bot")
    local res = "";

    local op_date = 0;
    if inputs.op_date ~= nil then
        op_date = inputs.op_date;
    end

    local param3 = {
        query="select id,operation_date,transference_date,receipt_date from production_daily_operation where (operation_date - mod(operation_date,864000000000 )) = ?",
        params={op_date}
    }
    db.query(param3)
    local record={};
    local main_data = {}
    if db.query_fetch(record) then
        main_data = {
            id = record[1] ,
            operation_date = record[2] ,
            transference_date = record[3] ,
            receipt_date = record[4] ,
            details = {}
        }
    else
        main_data = {
            id = 0 ,
            operation_date = 0 ,
            transference_date = 0 ,
            receipt_date = 0 ,
            details = {}
        }
    end
    db.query_free();

    db.use_db("0000000") 
    local record1={};
    -- gte details
    local param4 = {
        query="SELECT DET.ID,DET.OP_ID,DET.PRODUCT_ID,DET.ATTRIBUTE_ID,DET.LINE_ID,DET.OPERATOR_ID,DET.QUANTITY,CONCAT(LINE.CODE, ' - ',LINE.TITLE) AS LINE_TITLE, PN.PRODUCT_NAME, PM.FULLNAME , SC.DECIMAL_NUM FROM 0000000_BOT.PRODUCTION_DAILY_OPERATION_DET DET  INNER JOIN PROD_LINE LINE ON LINE.ID = DET.LINE_ID  LEFT JOIN WH_VIEW_GET_PRODUCT_NAMES PN ON PN.PRODUCT_ID = DET.PRODUCT_ID AND PN.ATTRIBUTE_ID = DET.ATTRIBUTE_ID  LEFT JOIN WH_PRODUCT P ON P.ID = DET.PRODUCT_ID LEFT JOIN WH_STOCK_CAPACITY SC ON SC.ID = P.CAPACITY_ID INNER JOIN PROFILE_MAIN PM ON PM.ID = DET.OPERATOR_ID  WHERE DET.OP_ID = ?; ",
        params={main_data.id}
    }
    db.query(param4)
    while db.query_fetch(record1) do
        local det = {
            id = record1[1],
            op_id = record1[2],
            product_id = record1[3],
            attribute_id = record1[4],
            line_id = record1[5],
            operator_id = record1[6],
            quantity = record1[7],
            line_title = record1[8],
            product_title = record1[9],
            operator_title = record1[10],
            decimal_num = record1[11]
        };
        table.insert(main_data.details,det);
    end
    db.query_free();

    local exp = json.encode(main_data);
    if inputs.done == '1' then
        local result = teamyar.call_api (34,"/api/order/dailyProduction",main_data);
        teamyar.write_result(json.encode(result));
    else
        teamyar.write_result(exp);
    end
--update info
elseif req_type == '2' then
    local data = {};
    local detail_data = {};
    if inputs.data ~= nil then
        data = json.decode(inputs.data);
        if data.op_date ~= nil then
            db.use_db("0000000_bot")
            db.start();
            --delete previous data
            local params = {
                query="DELETE det from production_daily_operation_det det inner join production_daily_operation op on op.id = det.op_id where (op.operation_date - mod(op.operation_date,864000000000 )) = ?",
                params={data.op_date}
            }
            db.query_immediate(params)
            local params1={
                query="DELETE FROM production_daily_operation where (operation_date - mod(operation_date,864000000000 )) = ?",
                params={data.op_date}
            };
            db.query_immediate(params1)
            
            if inputs.is_delete ~= '1' then
                -- update production_daily_operation
                local params2={
                    query="INSERT INTO production_daily_operation(operation_date,transference_date,receipt_date) VALUES(?,?,?)",
                    params={data.operation_date,data.transference_date,data.receipt_date}
                };

                db.query_immediate(params2)

                local last_id = teamyar.query('SELECT LAST_INSERT_ID()', {}, 3);

                --update production_daily_operation_det
                for i,v in ipairs(data.details) do
                    local params3={
                        query="INSERT INTO production_daily_operation_det(op_id,product_id,attribute_id,line_id,operator_id,quantity) VALUES(?,?,?,?,?,?)",
                        params={last_id,v.product_id,v.attribute_id,v.line_id,v.operator_id,v.quantity}
                    };
                    db.query_immediate(params3)
                end
            end

            db.commit();
            db.use_db("0000000")
            teamyar.write_result("ok");
        end
    end
end
