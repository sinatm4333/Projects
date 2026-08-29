local input = teamyar.get_input();
local sms_content =""
local count_day = 0
local sms_box_id = 0
local email_box_id =0
local email_subject = 0
local from_date = 0
local to_date = 0
local config =teamyar.get_config()
local config_data={}
if config ~=nil then 
  config_data = config.data
   sms_content =config_data.sms_content
 --  count_day = config_data.count_day
   sms_box_id = config_data.sms_box_id
   email_box_id = config_data.email_box_id
   email_subject = config_data.email_subject
--   from_date = config_data.from_date
end 

if sms_box_id == nil then 
  sms_box_id = 0
end

if count_day == nil then 
  count_day = 5
end
if email_box_id == nil then 
  email_box_id = 0
end
if email_subject == nil then 
  email_subject = "پیش فاکتورها"
end
if sms_content == nil then 
  sms_content = "مشتری گرامی لطفا جهت ثبت فاکتورهای خود اقدام نمایید "
end
------------------------------------------
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f", temp_time);
local user = teamyar.get_user_info()
-- teamyar.write_log("user----"..json.encode(user))
to_date =( temp_time-(60*60*24*30*10000000))- user.timezone- (60*60*10000000)
to_date = string.format("%18.0f", to_date);
from_date =( temp_time-(60*60*24*30*10000000))-(60*60*24*10000000)-user.timezone- (60*60*10000000)
from_date = string.format("%18.0f", from_date);
teamyar.write_log("from_date----"..from_date)
teamyar.write_log("to_date----"..to_date)
-------------------------------------------
function queryResultAcl(select_query,user_param)
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
    table.insert(res_text, {profile_id = record[1], email = record[2] });
  end
  db.query_free();
  return res_text;
end
--------------------------------------------------
local query = [[ with c_email as(select c.id cid,e.email ,org_id from pa_client c inner join profile_email e on e.user_id=c.reffere_id ) 
select i.id,i.client_id , (case when i.client_id>0  then  (select reffere_id from pa_client where id=CLIENT_ID and org_id=i.org_id) else (select id from profile_main where id=abs(i.client_id)) end )profile_id
,(case when  i.client_id>0  then (select email from c_email where cid=abs(i.CLIENT_ID) and org_id=i.org_id ) else (select email from profile_email where user_id=abs(i.client_id) )end)EMAIL from sales_invoice i where  i.type=2
  and (select count(r.INVOICE_ID) from sales_invoice_return r where INVOICE_ID=i.id)=0 
                         and i.RUN_DATE between ]]..from_date..[[ and ]]..to_date
 teamyar.write_log(query)
local res_data = queryResultAcl(query,{})
 for i, v in ipairs(res_data) do
---------------------------------------send sms
    local info =	{box_id = tonumber(sms_box_id), messages = {{content = sms_content, send_to = {profile_ids = {v.profile_id}}}}, module_id = 26}
    local   res = teamyar.call_api(16, '/api/sms/send', info);
     teamyar.write_log("ارسال پیامک :   "..json.encode(res))
---------------------------------------send email
  if v.email ~= nil and v.email ~="" then
          local info_e =	{
          box_id = tonumber(email_box_id),
          address = v.email,
          email_content = sms_content,
          email_subject = email_subject
         }
         --teamyar.write_log("info_e----"..json.encode(info_e))
          local   res_email = teamyar.call_api(12, '/api/email/emailmsgadd', info_e);
     teamyar.write_log(" ارسال ایمیل"..json.encode(res_email))
  end
end
