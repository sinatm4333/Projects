local config = teamyar.get_config()
local url = ""
local config_data ={}
if config ~= nil then 
  config_data = config.data
  url = config_data.url
end 
local site=[[<iframe id='content'  style='width:100%;' src="]]..url..[[" title="description"></iframe><script>
document.getElementById('content').style.height=document.getElementById('content').parentElement.parentElement.scrollHeight+'px'
</script>]]
teamyar.write_result(site)