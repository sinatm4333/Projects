// بررسی وضعیت مودی[Module] — main.js
// بازطراحی‌شده طبق پالت/فونت/برند جدید (CLAUDE.md، افزوده 1405/05/19 و 1405/05/23) + بزرگ‌سازی
// فیلد جستجو طبق بازخورد کاربر (1405/06/09 شب). ساختار درخواست AJAX و شناسه‌های ورودی
// (national_id, type:5) بدون تغییر مانده‌اند تا با منطق سمت سرور (مبدأ لینک‌شده) سازگار بمانند.
//
// نکتهٔ ساختاری مهم: یک $.Teamyar.layout تودرتو با selector تکراری ('#myDiv') باعث می‌شود آن
// لایوت داخلی (چون خودش هم فراخوانی $.Teamyar.layout است و بلافاصله در DOM درج می‌شود) زودتر
// از هر رشتهٔ HTML دیگری در آرایهٔ بیرونی ظاهر شود — مستقل از ترتیبش در آرایه. راه‌حل: فقط یک
// $.Teamyar.layout در کل فایل داریم؛ خروجی $.Teamyar.input.text(...) خودش یک رشتهٔ HTML است
// (بدون اثر جانبی) پس مستقیم داخل رشتهٔ ردیف جستجو ترکیب می‌شود.
ty__main.botGetlang = (name) => {
  if (ty__main.BOT_LANG[name] == undefined) {
    return name;
  }
  return ty__main.BOT_LANG[name];
}

// نشان برند 140 (فقط آیکون، بدون واژه‌نشان). نسخهٔ سفید: روی پس‌زمینهٔ آبی #16509D هدر
// طبق قانون جفت‌سازی لوگو با پس‌زمینه (assets/brand140/README.md)
ty__main.MV140_LOGO_B64 = "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";

//---------------------------------------------------
// نکته: متن‌های خودمان مستقیم فارسی نوشته شده‌اند (نه از BOT_LANG/Persian.js) چون زمان‌بندی
// لود این پیوست‌ها تضمین‌شده نیست — گاهی main.js زودتر از Persian.js اجرا می‌شود و کلید خام
// (مثلاً "HELP_BTN") به‌جای ترجمه نمایش داده می‌شود؛ نوشتن مستقیم این ریسک را کاملاً حذف می‌کند.
ty__main.mv140_help_modal_html = function () {
  return "<div class='mv140-help-overlay' id='mv140HelpOverlay'>" +
    "<div class='mv140-help-modal'>" +
      "<div class='mv140-help-modal-header'>" +
        "<span>راهنمای بررسی وضعیت مودی</span>" +
        "<button type='button' class='mv140-help-close' onclick='ty__main.close_help()'>×</button>" +
      "</div>" +
      "<div class='mv140-help-modal-body'>" +
        "<p>این فرم <b>شماره اقتصادی (شناسه مالیاتی)</b> واردشده را به سامانه مودیان مالیاتی کشور استعلام می‌کند.</p>" +
        "<p>شماره اقتصادی مودی موردنظر را در فیلد ورودی وارد کرده و روی دکمه «استعلام وضعیت مودی» کلیک کنید.</p>" +
        "<p>نتیجهٔ استعلام (وضعیت فعال/غیرفعال بودن مودی در سامانه) در همان صفحه، زیر دکمه نمایش داده می‌شود.</p>" +
      "</div>" +
    "</div>" +
  "</div>";
};
ty__main.open_help = function () {
  var el = document.getElementById('mv140HelpOverlay');
  if (el) { el.classList.add('mv140-open'); }
};
ty__main.close_help = function () {
  var el = document.getElementById('mv140HelpOverlay');
  if (el) { el.classList.remove('mv140-open'); }
};

//---------------------------------------------------
// یک $.Teamyar.layout در سطح بالا — بدون nested layout با selector تکراری (دلیل بالا).
// ترتیب اجزای هدر: عنوان، لوگو، سپس دکمهٔ راهنما آخر — طبق CLAUDE.md دکمهٔ راهنما باید
// در سمت چپ بنشیند (flex-end در صفحهٔ RTL) که یعنی آخرین فرزند DOM.
$.Teamyar.layout
({
  selector: '#myDiv',
  type: 'COL-1',
  class_name: 'mv140-widget mv140-card',
  controls:
  [
    "<div class='mv140-header'>" +
      "<span class='mv140-title'>بررسی وضعیت مودی</span>" +
      "<img class='mv140-brand-logo' src='data:image/png;base64," + ty__main.MV140_LOGO_B64 + "' alt='140' />" +
      "<button type='button' class='mv140-help-btn' onclick='ty__main.open_help()'>راهنما</button>" +
    "</div>",
    "<div class='mv140-row'>" +
      $.Teamyar.input.text({
        id: "national_id",
        name: "national_id",
        title: "شماره اقتصادی : ",
        format: "input",
        type: "number",
      }) +
      "<button type='button' id='show_row_btn' class='mv140-submit-btn' onclick='ty__main.get_status()'>استعلام وضعیت مودی</button>" +
    "</div>"
    , "<div id='err_msg'></div>"
    , "<div class='mv140-footer'>موبایل 140</div>"
    , ty__main.mv140_help_modal_html()
  ]});
///------------------------------------------------------
// جعبهٔ نتیجه (res.msg) از سرور مبدأ می‌آید و با استایل اینلاین (نه کلاس) رندر می‌شود —
// چیزی برای هدف‌گیری با CSS class نیست، پس اینجا با جاوااسکریپت بعد از درج، بازرنگ‌آمیزی
// طبق پالت پروژه و افزودن دکمهٔ کپی جلوی «نام تجاری» انجام می‌شود.
ty__main.mv140_style_result = function () {
  var box = document.querySelector('#err_msg > div');
  if (!box) return;
  box.style.background = '#ffffff';
  box.style.boxShadow = '0 1px 5px 0 rgba(0,0,0,0.15)';
  box.style.border = '1px solid #f5f5f5';
  box.style.color = '#000';

  var rows = box.children;
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    var isNameRow = row.textContent.indexOf('نام تجاری') > -1;
    var cells = row.children.length ? row.children : [row];
    var valueEl = null;
    for (var j = 0; j < cells.length; j++) {
      var cell = cells[j];
      var styleAttr = cell.getAttribute && (cell.getAttribute('style') || '');
      // بج‌های رنگی احتمالی (مثل وضعیت NOT_ALLOCATED) را به پالت پروژه تبدیل می‌کنیم
      if (styleAttr.indexOf('background') > -1) {
        cell.style.background = '#16509D';
        cell.style.color = '#ffffff';
      }
      if (cell.textContent.indexOf('نام تجاری') === -1 && cell.textContent.trim() !== '') {
        valueEl = cell;
      }
    }
    if (isNameRow && valueEl && !row.querySelector('.mv140-copy-btn')) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'mv140-copy-btn';
      btn.title = 'کپی نام تجاری';
      btn.textContent = 'کپی';
      (function (valueEl, btn) {
        btn.onclick = function () {
          var text = valueEl.textContent.trim();
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text);
          }
          var old = btn.textContent;
          btn.textContent = 'کپی شد';
          setTimeout(function () { btn.textContent = old; }, 1500);
        };
      })(valueEl, btn);
      valueEl.insertAdjacentElement('afterend', btn);
    }
  }
};
///------------------------------------------------------
ty__main.get_status = function ()
{
  let national_id = $.Teamyar.input.text.get('#national_id', 'value');
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
          document.getElementById("err_msg").innerHTML = res.msg
          ty__main.mv140_style_result()
        }
      }
    }
  });
}
//------------------------------------
