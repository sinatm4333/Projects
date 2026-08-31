/* بررسی وضعیت مودی[Module] 140 — main.js
   بازطراحی‌شده طبق main.css (پالت #16509D، فونت Peyda، لوگو 140، دکمه راهنما).
   منطق استعلام (get_status/AJAX به bot/run/2/tax_client_st_m) دست‌نخورده مانده — فقط ظاهر عوض شده.

   نکتهٔ فنی مهم: $.Teamyar.layout با یک controls array شامل هم رشتهٔ HTML و هم آبجکت
   ویجت (مثلاً یک لایوت تودرتوی دیگر) را به ترتیب آرایه رندر نمی‌کند — آبجکت‌های ویجت
   زودتر از رشته‌های HTML ظاهر می‌شوند (تأیید شده روی داده زنده: باکس جستجو بالای هدر
   می‌افتاد). راه‌حل: تمام اسکلت ثابت (هدر/اسلات خالی/err_msg/فوتر) یک‌جا به‌صورت HTML
   خام و پشت سر هم درج می‌شود (ترتیب DOM تضمین‌شده)، و فقط ویجت واقعی ورودی/دکمه با
   $.Teamyar.layout درون همان اسلات خالی (با selector اختصاصی خودش) رندر می‌شود. */
ty__main.botGetlang = (name) => {
  if (ty__main.BOT_LANG[name] == undefined) {
    return name;
  }
  return ty__main.BOT_LANG[name];
}
//---------------------------------------------------
ty__main.toggleHelp = function (show) {
  var overlay = document.getElementById('mv140-help-overlay');
  if (!overlay) return;
  if (show) { overlay.classList.add('mv140-open'); }
  else { overlay.classList.remove('mv140-open'); }
}
//---------------------------------------------------
(function () {
  var root = document.querySelector('#myDiv');
  if (!root) return;
  root.classList.add('mv140-widget');

  var skeleton =
    "<div class='mv140-card'>"
      + "<div class='mv140-header'>"
        + "<img class='mv140-brand-logo' src='data:image/png;base64,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' alt='140' />"
        + "<span class='mv140-title'>" + ty__main.botGetlang("بررسی وضعیت مودی") + "</span>"
        + "<button type='button' class='mv140-help-btn' onclick='ty__main.toggleHelp(true)'>" + ty__main.botGetlang("راهنما") + "</button>"
      + "</div>"
      + "<div id='mv140-search-slot' class='mv140-search-slot'></div>"
      + "<div id='err_msg'></div>"
      + "<div class='mv140-footer'>140</div>"
    + "</div>"
    + "<div id='mv140-help-overlay' class='mv140-help-overlay'>"
      + "<div class='mv140-help-modal'>"
        + "<div class='mv140-help-modal-header'>"
          + "<span>" + ty__main.botGetlang("راهنمای بات") + "</span>"
          + "<button type='button' class='mv140-help-close' onclick='ty__main.toggleHelp(false)'>×</button>"
        + "</div>"
        + "<div class='mv140-help-modal-body'>"
          + "<p><b>" + ty__main.botGetlang("این ابزار چیست؟") + "</b> " + ty__main.botGetlang("وضعیت فعال‌بودن مودی (شخص حقیقی یا حقوقی) در سامانه مودیان مالیاتی را استعلام می‌کند.") + "</p>"
          + "<p><b>" + ty__main.botGetlang("نحوه استفاده") + "</b> " + ty__main.botGetlang("کد ملی (اشخاص حقیقی) یا شناسه اقتصادی (اشخاص حقوقی) را در کادر وارد کرده و روی دکمه «استعلام وضعیت مودی» کلیک کنید.") + "</p>"
          + "<p><b>" + ty__main.botGetlang("نتیجه") + "</b> " + ty__main.botGetlang("پاسخ سامانه مودیان زیر همان دکمه نمایش داده می‌شود.") + "</p>"
        + "</div>"
      + "</div>"
    + "</div>";

  root.insertAdjacentHTML('beforeend', skeleton);

  $.Teamyar.layout
  ({
    selector: '#mv140-search-slot',
    type: 'COL-4',
    class_name: 'mv140-row',
    controls:
    [
      $.Teamyar.input.text({
        id: "national_id",
        name: "national_id",
        title: ty__main.botGetlang("NATIONAL_ID") + " : ",
        format: "input",
        type: "number",
      }),
      "<button type='button' id='show_row_btn' class='" + ty__main.botGetlang("BUTTON_CLASS") + " btn ty-btn-default core_btn btnforsubmit core_btn_submit_Form core_btn_revers_change ty-btn-ok mv140-submit-btn' onclick='ty__main.get_status()'>" + ty__main.botGetlang("استعلام وضعیت مودی") + "</button>",
    ]
  });
})();
///------------------------------------------------------
ty__main.get_status = function ()
{
  let national_id = $.Teamyar.input.text.get('#national_id', 'value');
  console.log(national_id)
  $.Teamyar.ajax({
    block_holder: 'body',
    options: {
      url: 'bot/run/2/tax_client_st_m',
      type: 'POST',
      dataType: 'json',
      data: { customform: JSON.stringify({ type: 5, national_id: national_id }) }
    },
    events: {
      success: function (res) {
        if (res)
        {
          console.log(res)
          document.getElementById("err_msg").innerHTML = res.msg
        }
      }
    }
  });
}
//------------------------------------
