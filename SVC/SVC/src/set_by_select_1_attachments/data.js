report[reportPath].getFilters = function () {
    return [
        $.Teamyar.acl({
            id: "org_id",
            name: "org_id",
            multiedit: false,
            typevalue: 'object',
            shownone: 'true',
            value: report[reportPath].getCash("org_id", true),
            title: "<span style='color:red;padding:5px;'> * </span>"+report[reportPath].translateWord("_filter_org"),
            events: {"onchange": ['report.' + reportPath + '.setAclsUrl']},
            url: report[reportPath].getAclUrl("org_id"),
        }),
        $.Teamyar.DateTimePicker({
            name: 'from_date',
          id: 'from_date',
            value: report[reportPath].getCash("from_date"),
            title: "<span style='color:red;padding:5px;'> * </span>"+report[reportPath].translateWord("_filter_from_date")
        }),
        $.Teamyar.DateTimePicker({
            name: 'to_date',
          	id: 'to_date',
            value: report[reportPath].getCash("to_date"),
            title: "<span style='color:red;padding:5px;'> * </span>"+report[reportPath].translateWord("_filter_to_date")
        }),
        $.Teamyar.input.text({
            id: "filter_invoice_id",
            name: "filter_invoice_id",
            value: report[reportPath].getCash("filter_invoice_id", false, ""),
            title: report[reportPath].translateWord("_filter_invoice_id"),
          type:"number"
        }),
        $.Teamyar.input.text({
            id: "filter_title",
            name: "filter_title",
            value: report[reportPath].getCash("filter_title", false, ""),
            title: report[reportPath].translateWord("_filter_title"),
              type:"text"
        }),
        $.Teamyar.acl({
            id: "filter_client",
            name: "filter_client",
            multiedit: true,
            typevalue: 'object',
            shownone: 'true',
            value: report[reportPath].getCash("filter_client", true),
            title: report[reportPath].translateWord("_filter_client"),
            events: {"onchange": ['report.' + reportPath + '.setAclsUrl']},
            url: report[reportPath].getAclUrl("filter_client"),
        }),
        $.Teamyar.acl({
            id: "filter_warehouse",
            name: "filter_warehouse",
            multiedit: true,
            typevalue: 'object',
            shownone: 'true',
            value: report[reportPath].getCash("filter_warehouse", true),
            title: report[reportPath].translateWord("_filter_warehouse"),
            events: {"onchange": ['report.' + reportPath + '.setAclsUrl']},
            url: report[reportPath].getAclUrl("filter_warehouse"),
        }),
        $.Teamyar.acl({
            id: "filter_product",
            name: "filter_product",
            multiedit: true,
            typevalue: 'object',
            shownone: 'true',
            value: report[reportPath].getCash("filter_product", true),
            title: report[reportPath].translateWord("_filter_product"),
            events: {"onchange": ['report.' + reportPath + '.setAclsUrl']},
            url: report[reportPath].getAclUrl("filter_product"),
        }),


    ];
}

report[reportPath].renderItemReport = function (dataResponse) {
    let reportName = dataResponse.hasOwnProperty("name") ? dataResponse.name : null;
    switch (reportName) {
        case "table":
            report[reportPath].responseReportMain(dataResponse);
            break;
    }
}

// -------------------------------------------------------------------------
// صف تسویه گروهی (انتخاب فاکتورها حفظ‌شده بین صفحات جدول)
// -------------------------------------------------------------------------
// چون جدول با صفحه‌بندی (۲۰ ردیف در هر صفحه) توسط res_v2 رندر می‌شود، چک‌باکس‌های
// .settle-check فقط برای صفحه‌ی جاری در DOM وجود دارند و با تغییر صفحه از بین می‌روند.
// این Set در حافظه‌ی مرورگر (نه در DOM) نگه داشته می‌شود و بین صفحات باقی می‌ماند؛
// بعد از هر بار رندر جدول (responseReportMain) روی چک‌باکس‌های صفحه‌ی جدید اعمال می‌شود.
report[reportPath].selectedIds = report[reportPath].selectedIds || new Set();

// نشان «صف تسویه: N فاکتور» + لوگوی ۱۴۰ را داخل نوار بالای جدول (alert-info) قرار/به‌روزرسانی می‌کند
report[reportPath].refreshQueueToolbar = function () {
    var toolbar = document.querySelector(".alert.alert-info");
    if (!toolbar) return;

    var badge = document.getElementById("settle-queue-badge");
    if (!badge) {
        badge = document.createElement("span");
        badge.id = "settle-queue-badge";
        badge.className = "settle-queue-badge";
        toolbar.insertBefore(badge, toolbar.firstChild);
    }
    badge.textContent = "صف تسویه: " + report[reportPath].selectedIds.size + " فاکتور";

    if (!document.getElementById("settle-brand140-logo")) {
        var img = document.createElement("img");
        img.id = "settle-brand140-logo";
        img.className = "settle-brand140-logo";
        img.src = "data:image/png;base64,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";
        img.alt = "140";
        toolbar.appendChild(img);
    }
}

// وضعیت چک‌باکس‌های صفحه‌ی جاری را با صف انتخاب‌شده (selectedIds) هماهنگ می‌کند
report[reportPath].applySelectionState = function () {
    $(".settle-check").each(function () {
        var id = String($(this).val());
        this.checked = report[reportPath].selectedIds.has(id);
    });
    report[reportPath].refreshQueueToolbar();
}

// هر بار چک‌باکس یک ردیف عوض شود (روی هر صفحه‌ای) — صف را به‌روز می‌کند
// (event delegation روی document: صرف‌نظر از این‌که جدول چند بار دوباره رندر شود کار می‌کند)
$(document).on("change", ".settle-check", function () {
    var id = String($(this).val());
    if (this.checked) {
        report[reportPath].selectedIds.add(id);
    } else {
        report[reportPath].selectedIds.delete(id);
    }
    report[reportPath].refreshQueueToolbar();
});

report[reportPath].responseReportMain = function (dataResponse) {
    const reportHtml = dataResponse.hasOwnProperty("report") ? dataResponse.report : [];
    const elementId = dataResponse.hasOwnProperty("report") ? dataResponse.elementId : [];
    $("#" + elementId).html(reportHtml);
    report[reportPath].applySelectionState();
}

// تسویه تکی یک فاکتور
report[reportPath].settleSingle = function (invoiceId) {
    if (!confirm("آیا از تسویه این فاکتور مطمئن هستید؟")) {
        return;
    }
   let org_id=  $.Teamyar.acl.get('#org_id', 'value');
    let datef = $.Teamyar.DateTimePicker.get('#from_date', 'value');
    let datet = $.Teamyar.DateTimePicker.get('#to_date', 'value');
    report[reportPath].sendSettleRequest("?type=200", { invoice_id: invoiceId ,org_id:org_id.id, from_date:datef ,to_date :datet});
}

// -------------------------------------------------------------------------
// صف پردازش تسویه گروهی — بدون محدودیت تعداد
// -------------------------------------------------------------------------
// همه‌ی فاکتورهای انتخاب‌شده در یک درخواست فرستاده نمی‌شوند (هر فاکتور پشت‌بک‌اند
// دو فراخوانی API خارجی دارد، بنابراین یک درخواست حجیم ریسک برخورد به
// max_execute_time بک‌اند را دارد). به‌جایش صف انتخاب‌شده در دسته‌های
// SETTLE_BATCH_SIZE‌تایی می‌شکند و دسته‌ها یکی‌یکی (نه هم‌زمان) به همان اندپوینت
// تسویه گروهی (type=201) فرستاده می‌شوند تا کل صف — از هر تعدادی که باشد —
// پردازش شود. در پایان صف، نتیجه‌ی تجمیعی (موفق/ناموفق) در یک گزارش پاپ‌آپ
// نمایش داده می‌شود.
report[reportPath].SETTLE_BATCH_SIZE = 20;
report[reportPath].settleQueueRunning = false;

// یک پاسخ تسویه‌ی تک‌فاکتور (از details برگشتی بک‌اند) موفق حساب می‌شود اگر خطا
// نداشته باشد و success=true باشد — هم‌راستا با شرط موفقیت خود بک‌اند
function isSettleResponseOk(resp) {
    if (!resp) {
        return false;
    }
    var hasError = (typeof resp.error !== "undefined" && resp.error !== null);
    return !hasError && resp.success === true;
}

// تسویه گروهی — کل صف انتخاب‌شده (از هر تعداد صفحه‌ای که انتخاب شده باشد)، نه فقط صفحه‌ی جاری
report[reportPath].settleSelected = function () {
    if (report[reportPath].settleQueueRunning) {
        return;
    }
    var ids = Array.from(report[reportPath].selectedIds);
    if (ids.length === 0) {
        $.Teamyar.message({ message: "صف تسویه خالی است — هیچ فاکتوری انتخاب نشده.", type: "warning" });
        return;
    }
    if (!confirm("آیا از تسویه " + ids.length + " فاکتور (کل صف تسویه) مطمئن هستید؟")) {
        return;
    }
    let org_id = $.Teamyar.acl.get('#org_id', 'value');
    let datef = $.Teamyar.DateTimePicker.get('#from_date', 'value');
    let datet = $.Teamyar.DateTimePicker.get('#to_date', 'value');

    var batches = [];
    for (var i = 0; i < ids.length; i += report[reportPath].SETTLE_BATCH_SIZE) {
        batches.push(ids.slice(i, i + report[reportPath].SETTLE_BATCH_SIZE));
    }

    report[reportPath].settleQueueRunning = true;
    report[reportPath].setSettleButtonsEnabled(false);
    report[reportPath].runSettleQueue(
        batches, 0,
        { total: ids.length, ok: 0, fail: 0, failedIds: [] },
        org_id, datef, datet
    );
}

// پردازش دسته‌ی شماره‌ی index از صف؛ به‌محض پایان یک دسته (موفق یا ناموفق)، دسته‌ی
// بعدی فرستاده می‌شود تا صف تمام شود
report[reportPath].runSettleQueue = function (batches, index, totals, org_id, datef, datet) {
    if (index >= batches.length) {
        report[reportPath].settleQueueRunning = false;
        report[reportPath].setSettleButtonsEnabled(true);
        report[reportPath].selectedIds.clear();
        report[reportPath].refreshQueueToolbar();
        report[reportPath].showSettleReport(totals);
        report[reportPath].onclickFormSubmit();
        return;
    }

    var batchIds = batches[index];
    report[reportPath].updateQueueProgress(index + 1, batches.length, totals.total);

    $.Teamyar.ajax({
        block_holder: "body",
        options: {
            url: report[reportPath].botPath + "?type=201",
            type: "POST",
            dataType: "json",
            async: true,
            data: { invoice_ids: batchIds.join(","), org_id: org_id.id, from_date: datef, to_date: datet }
        },
        events: {
            success: function (res) {
                if (res && typeof res.ok === "number") {
                    totals.ok += res.ok;
                    totals.fail += (typeof res.fail === "number") ? res.fail : 0;
                    if (res.details) {
                        res.details.forEach(function (d) {
                            if (!isSettleResponseOk(d.response)) {
                                totals.failedIds.push(d.invoice_id);
                            }
                        });
                    }
                } else {
                    // پاسخ نامعتبر یا بدون فاکتور قابل‌تسویه در این دسته — کل دسته ناموفق ثبت می‌شود
                    totals.fail += batchIds.length;
                    totals.failedIds = totals.failedIds.concat(batchIds);
                }
                report[reportPath].runSettleQueue(batches, index + 1, totals, org_id, datef, datet);
            },
            errors: function () {
                // خطای شبکه/بک‌اند روی کل این دسته — دسته ناموفق ثبت می‌شود و صف ادامه می‌یابد
                totals.fail += batchIds.length;
                totals.failedIds = totals.failedIds.concat(batchIds);
                report[reportPath].runSettleQueue(batches, index + 1, totals, org_id, datef, datet);
            }
        }
    });
}

// نمایش پیشرفت صف روی همان نشان بالای جدول، در طول پردازش دسته‌ها
report[reportPath].updateQueueProgress = function (currentBatch, totalBatches, totalCount) {
    var toolbar = document.querySelector(".alert.alert-info");
    if (!toolbar) return;
    var badge = document.getElementById("settle-queue-badge");
    if (!badge) {
        badge = document.createElement("span");
        badge.id = "settle-queue-badge";
        badge.className = "settle-queue-badge";
        toolbar.insertBefore(badge, toolbar.firstChild);
    }
    badge.textContent = "در حال تسویه صف (" + totalCount + " فاکتور) — دسته " + currentBatch + " از " + totalBatches;
}

// غیرفعال/فعال کردن دکمه‌ی «تسویه گروهی» حین اجرای صف (جلوگیری از اجرای هم‌زمان دو صف)
report[reportPath].setSettleButtonsEnabled = function (enabled) {
    $(".alert.alert-info .btn-primary").prop("disabled", !enabled);
}

// گزارش پاپ‌آپ پایان صف: تعداد عملیات موفق/ناموفق + شماره فاکتورهای ناموفق
report[reportPath].showSettleReport = function (totals) {
    var overlay = document.getElementById("settle-report-overlay");
    if (!overlay) {
        overlay = document.createElement("div");
        overlay.id = "settle-report-overlay";
        overlay.className = "settle-help-overlay";
        document.body.appendChild(overlay);
        overlay.addEventListener("click", function (e) {
            if (e.target === overlay) overlay.style.display = "none";
        });
        document.addEventListener("keydown", function (e) {
            if (e.key === "Escape") overlay.style.display = "none";
        });
    }

    var failedListHtml = "";
    if (totals.failedIds.length > 0) {
        failedListHtml =
            '<p class="settle-report-failed-title"><strong>شماره فاکتورهای ناموفق:</strong></p>' +
            '<div class="settle-report-failed-list">' + totals.failedIds.join('، ') + '</div>';
    }

    overlay.innerHTML =
        '<div class="settle-help-modal settle-report-modal">' +
        '<div class="settle-help-modal-header">' +
        '<strong>گزارش تسویه گروهی</strong>' +
        '<button type="button" class="settle-help-close">&times;</button>' +
        '</div>' +
        '<div class="settle-help-modal-body">' +
        '<div class="settle-report-summary">' +
        '<div class="settle-report-stat">' +
        '<span class="settle-report-num settle-report-ok">' + totals.ok + '</span>' +
        '<span class="settle-report-label">موفق</span>' +
        '</div>' +
        '<div class="settle-report-stat">' +
        '<span class="settle-report-num settle-report-fail">' + totals.fail + '</span>' +
        '<span class="settle-report-label">ناموفق</span>' +
        '</div>' +
        '<div class="settle-report-stat">' +
        '<span class="settle-report-num">' + totals.total + '</span>' +
        '<span class="settle-report-label">مجموع</span>' +
        '</div>' +
        '</div>' +
        failedListHtml +
        '</div>' +
        '</div>';

    overlay.querySelector(".settle-help-close").addEventListener("click", function () {
        overlay.style.display = "none";
    });
    overlay.style.display = "flex";
}

// انتخاب/عدم انتخاب همه چک‌باکس‌های صفحه‌ی جاری (به صف هم اضافه/حذف می‌شود)
report[reportPath].toggleAll = function (el) {
    $(".settle-check").each(function () {
        var id = String($(this).val());
        this.checked = el.checked;
        if (el.checked) {
            report[reportPath].selectedIds.add(id);
        } else {
            report[reportPath].selectedIds.delete(id);
        }
    });
    report[reportPath].refreshQueueToolbar();
}

// ارسال درخواست تسویه‌ی تکی به بک‌اند (تسویه گروهی از صف runSettleQueue استفاده می‌کند)
report[reportPath].sendSettleRequest = function (typeQuery, data) {
    $.Teamyar.ajax({
        block_holder: "body",
        options: {
            url: report[reportPath].botPath + typeQuery,
            type: "POST",
            dataType: "json",
            async: true,
            data: data
        },
        events: {
            success: function (res) {
                if (res && res.status === true) {
                    $.Teamyar.message({ message: res.msg, type: "success" });
                    report[reportPath].onclickFormSubmit();
                } else {
                    $.Teamyar.message({ message: res && res.msg ? res.msg : "خطا در ثبت تسویه", type: "danger" });
                    report[reportPath].onclickFormSubmit();
                }
            },
            errors: function (error) {
                $.Teamyar.message({ message: error, type: "danger" });
            }
        }
    });
}

// -------------------------------------------------------------------------
// دکمه‌ی «راهنما» (الزامی طبق قانون این ریپو برای بات‌های HTML) — طبق همان الگوی
// اثبات‌شده‌ی بات ۶۰۰ (crm_rfm_1_bot.lua / data.js): section[data-name] + MutationObserver
// -------------------------------------------------------------------------
(function () {
    var BOT_NAME = "set_by_select_1";

    var helpContent =
        "<h4>تسویه اتوماتیک گروهی — راهنما</h4>" +
        "<p>این گزارش فهرست فاکتورهای فروش قابل‌تسویه را نشان می‌دهد.</p>" +
        "<ul>" +
        "<li><b>تسویه تکی</b> — دکمه «تسویه» روی همان ردیف، فقط همان فاکتور را تسویه می‌کند.</li>" +
        "<li><b>صف تسویه گروهی</b> — چک‌باکس فاکتورهای موردنظر را بزنید. این انتخاب بین صفحات مختلف گزارش" +
        " حفظ می‌شود (نشان «صف تسویه: N فاکتور» بالای جدول، تعداد کل انتخاب‌شده‌ها را نشان می‌دهد، نه فقط" +
        " صفحه‌ی جاری). می‌توانید چند صفحه را ورق بزنید و از هرکدام چند فاکتور انتخاب کنید؛ همه در صف باقی" +
        " می‌مانند تا وقتی روی «تسویه گروهی انتخاب‌شده‌ها» بزنید.</li>" +
        "<li><b>بدون محدودیت تعداد</b> — با زدن «تسویه گروهی انتخاب‌شده‌ها» کل صف — از هر تعدادی که باشد —" +
        " در دسته‌های ۲۰تایی پشت‌سرهم به بک‌اند فرستاده می‌شود (نه یک‌جا)؛ پیشرفت پردازش («دسته X از Y») روی" +
        " همان نشان بالای جدول نمایش داده می‌شود.</li>" +
        "<li><b>گزارش پایان کار</b> — بعد از پردازش کل صف، یک پاپ‌آپ با تعداد عملیات موفق، ناموفق و مجموع" +
        " باز می‌شود؛ در صورت وجود مورد ناموفق، شماره فاکتورهای آن هم در همان پاپ‌آپ فهرست می‌شود.</li>" +
        "<li><b>انتخاب همه</b> — همه‌ی چک‌باکس‌های صفحه‌ی جاری را انتخاب/لغو می‌کند (به صف اضافه/حذف می‌شود).</li>" +
        "</ul>" +
        "<p><strong>فیلترها:</strong> شعبه (اجباری)، بازه تاریخ فاکتور، شناسه فاکتور، برچسب، مشتری، انبار، کالا — از فرم بالای گزارش.</p>" +
        "<p><strong>خروجی اکسل/چاپ:</strong> از نوار ابزار بالای گزارش.</p>";

    function buildModal() {
        if (document.getElementById("settle-help-overlay")) return;
        var overlay = document.createElement("div");
        overlay.id = "settle-help-overlay";
        overlay.className = "settle-help-overlay";
        overlay.innerHTML =
            '<div class="settle-help-modal">' +
            '<div class="settle-help-modal-header">' +
            "<strong>راهنمای گزارش تسویه</strong>" +
            '<button type="button" class="settle-help-close">&times;</button>' +
            "</div>" +
            '<div class="settle-help-modal-body">' + helpContent + "</div>" +
            "</div>";
        document.body.appendChild(overlay);
        overlay.querySelector(".settle-help-close").addEventListener("click", closeHelp);
        overlay.addEventListener("click", function (e) {
            if (e.target === overlay) closeHelp();
        });
    }

    function openHelp() {
        buildModal();
        document.getElementById("settle-help-overlay").style.display = "flex";
    }

    function closeHelp() {
        var overlay = document.getElementById("settle-help-overlay");
        if (overlay) overlay.style.display = "none";
    }

    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") closeHelp();
    });

    function injectHelpButton() {
        var toolbar = document.querySelector('section[data-name="' + BOT_NAME + '"] .core_navbar');
        if (!toolbar || document.getElementById("settle-help-btn")) return;
        var btn = document.createElement("button");
        btn.type = "button";
        btn.id = "settle-help-btn";
        btn.className = "btn btn-settle-help";
        btn.style.float = "left";
        btn.style.margin = "4px";
        btn.textContent = "راهنما";
        btn.addEventListener("click", openHelp);
        toolbar.appendChild(btn);
    }

    var root = document.querySelector('section[data-name="' + BOT_NAME + '"]');
    if (root) {
        injectHelpButton();
        var observer = new MutationObserver(function () {
            injectHelpButton();
        });
        observer.observe(root, { childList: true, subtree: true });
    }
})();
