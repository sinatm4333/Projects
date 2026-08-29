local config = teamyar.get_config()

local url = ""
local config_data = {}

if config ~= nil then
  config_data = config.data
  url = config_data.url
end


local site = [[
<style>
  html, body {
    margin: 0;
    height: 1000px;
  }

  #wrap {
    position: fixed;
    inset: 0;
  }

  #content {
    width: 100%;
    height: 100%;
    border: 0;
    display: block;
  }
</style>
<div id="wrap">
  <iframe
    id="content"
    src="]] .. url .. [["
    title="description">
  </iframe>
</div>
]]


teamyar.write_result(site)