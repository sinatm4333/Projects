--Bot Evalue Info by Zmo
local input = teamyar.get_input()
local user_info = teamyar.get_user_info();
-------------------------------------------------------------------------------------------
function queryResultTotal(select_query, user_param)
  db.use_db("0000000")
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text==nill then
    return "";
  else
    return res_text[1];
  end
end
---------------------------------------------
function queryResultData(select_query,user_param)
  db.use_db("0000000")
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local record = {}
  local all = {}
  while db.query_fetch(record) do
    table.insert(all, {user_id = record[1], user_name = record[2],  dd = record[3], mark = record[4]})
  end
  db.query_free();
  return all;
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  if user_info.lang_id == 4 then
    str_title="لیست رای دهندگان"
    str_lang=teamyar.get_attachment("Persian.js");
  else
    str_title="Voters List"
    str_lang=teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_evaluate_info_rep",
      tpl_name = "html",
      title =str_title ,
      body = "<div id=\\'ei_holder_body_html_"..random.."\\'></div>",
      script= [[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#ei_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
----------------------------------------
--main
if input.type == 1 then 
  local request_id = input.request_id
  if request_id == nill then 
    request_id = 0;
  end
  local qselect = [[ select* from (select  distinct p.id ,p.fullname ,min(COALESCE((select min(VOTE_DATE) from poll_result r where r.question_id=q.id and r.user_id=p.id),0)) dd,
                          COALESCE((select round(mark/100) from poll_mark m where m.QUESTIONNAIRE_ID=q.questionnaire_id and m.USER_ID=p.id),'--') m
                          from poll_question q
                          inner join poll_qr_assigned rel on rel .QUESTIONNAIRE_ID=q.questionnaire_id 
                          inner join  profile_main p on p.id=rel.USER_ID   and p.type=1
                          where q.questionnaire_id=]]..request_id..[[   group by  p.id ,p.fullname, m )vv order by dd desc]]
  teamyar.write_log(qselect)
  local qtotal = [[  select count(*) from (]]..qselect..[[ )tmp ]]
  if input.select_all == 1 then 
  	res_data = queryResultData(qselect, {})
  else
     res_data = queryResultData(qselect.." limit ?,? ", {input.from, input.count})
  end
  local  totall = queryResultTotal(qtotal,{})

  local count_user_query = " select count(distinct(r.user_id)) c from poll_question q inner join poll_result r on r.QUESTION_ID=q.id where questionnaire_id="..request_id
  local countUser = queryResultTotal(count_user_query,{}) 

  local user_count_query = [[ select count( distinct nname) c from(( select p.id as nname from poll_qr_assigned i inner join profile_main p on i.user_id=p.id where questionnaire_id=]]..request_id..[[ and p.type=1) union 
                                              (select pm.id as nname from (select p.id from poll_qr_assigned i inner join profile_main p on i.user_id=p.id where questionnaire_id=]]..request_id..[[  and p.type=2 ) u 
                                              inner join profile_group_member gp on u.id=gp.group_id inner join profile_main pm on pm.id=gp.user_id where pm.type=1)) vv]]
  local all_user_count = queryResultTotal(user_count_query, {})
  local mid_score_q=[[  select  round(sum((select score from poll_option where id=r.option_id))/100) s  from poll_result r 
                                      where 1=1 and( select questionnaire_id from poll_question q where q.id=r.question_id)=]]..request_id
  
  local mid_score = queryResultTotal(mid_score_q, {})
local  max_score = queryResultTotal ([[ select round(TOTAL_SCORE/100)score from 
                                       poll_questionnaire where id =]]..request_id,{})
  data = { from = input.from, count = input.count, data = res_data, total = totall,
    countuser = countUser, 
    all_user_count = all_user_count, mid_score = mid_score,max_score = max_score,
    count_result_user = count_result_user}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate() 
end
