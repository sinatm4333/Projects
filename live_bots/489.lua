-- =========================================
-- Bot: Open Local HTML File (No Guess Path)
-- Opens an HTML file that is uploaded in THIS bot's Files
-- Developer: سینا تقوی مقدم
-- =========================================

local FILE_NAME = "kpi-dashboard.html"  -- اسم دقیق فایل داخل Files همین بات

local html = [[
<div style="font-family:tahoma;direction:rtl;padding:12px">
  <div style="margin-bottom:10px;font-size:12px;color:#444">
    اگر 404 شد، لینک تست زیر را باز کن:
    <a id="testLink" href="#" target="_blank" style="color:#0b63ce;text-decoration:none">باز کردن فایل</a>
    <span id="debug" style="margin-right:8px;color:#888"></span>
  </div>

  <iframe id="frm"
    src="about:blank"
    style="width:100%;height:90vh;border:1px solid #ddd;border-radius:10px;background:#fff;"
    allowfullscreen>
  </iframe>
</div>

<script>
(function(){
  var fileName = "]] .. FILE_NAME .. [[";
  var p = window.location.pathname || "";

  // مسیر پایه: اگر آدرس روی خود بات باشد، همین مسیر را پایه بگیر
  // مثال رایج: /bot/run/443/open_html_file
  // خروجی: /bot/run/443/open_html_file/report.html
  if(p.slice(-1) !== "/") p += "/";

  var fileUrl = p + fileName;

  // ست روی iframe و لینک تست
  var frm = document.getElementById("frm");
  var a = document.getElementById("testLink");
  var dbg = document.getElementById("debug");

  if(frm) frm.src = fileUrl + "?v=1";
  if(a) a.href = fileUrl + "?v=1";
  if(dbg) dbg.innerText = " | مسیر ساخته‌شده: " + fileUrl;

})();
</script>
]]

teamyar.write_result(html)
