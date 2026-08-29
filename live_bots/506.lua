input=teamyar.get_input();
if input.type == nil then
    src=teamyar.get_attachment("poll_quality_report_by_details.js");
   	str=[=[
	<div id='poll_report_by_details'></div>
	]=]..src
	teamyar.write_result(str);
elseif input.type == 1 then
 	res=teamyar.call_api(29, "/api/get_quality_report",input);
	teamyar.write_result(json.encode(res));
end