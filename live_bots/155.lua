local res =  teamyar.get_user_info()
local lang_id=res["lang_id"];
user_info = json.encode(lang_id)
teamyar.write_result(user_info)