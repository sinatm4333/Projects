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

report[reportPath].responseReportMain = function (dataResponse) {
    const reportHtml = dataResponse.hasOwnProperty("report") ? dataResponse.report : [];
    const elementId = dataResponse.hasOwnProperty("report") ? dataResponse.elementId : [];
    $("#" + elementId).html(reportHtml);
    // هر بار جدول (هر صفحه) دوباره رندر می‌شود، چک‌باکس‌های همین صفحه با صف انتخاب
    // هم‌گام می‌شوند — نه فقط علامت‌گذاری اولیه، بلکه اتصال رویداد تغییر هم دوباره لازم
    // است چون این عناصر تازه به DOM اضافه شده‌اند.
    report[reportPath].bindQueueCheckboxes();
}

// -------------------------------------------------------------------------
// صف انتخاب چندصفحه‌ای — چون هر صفحه فقط _PAR_PAGE (۲۰) ردیف نشان می‌دهد، اگر
// چک‌باکس‌ها فقط از DOM صفحه‌ی جاری خوانده شوند، ورق‌زدن صفحه انتخاب‌های صفحه‌ی
// قبل را از دست می‌دهد. اینجا انتخاب‌ها در یک Set سراسری (بین صفحات) نگه داشته
// می‌شوند و مبنای «تسویه گروهی» (تابع settleSelected پایین‌تر) قرار می‌گیرند.
// -------------------------------------------------------------------------
report[reportPath].selectedIds = report[reportPath].selectedIds || new Set();

// چک‌باکس‌های همین صفحه را با صف انتخاب هم‌گام می‌کند و رویداد تغییر را (دوباره) وصل
// می‌کند؛ بعد از هر رندر جدول (responseReportMain) و بعد از toggleAll صدا زده می‌شود
report[reportPath].bindQueueCheckboxes = function () {
    $(".settle-check").each(function () {
        var id = $(this).val();
        $(this).prop("checked", report[reportPath].selectedIds.has(id));
    });
    $(".settle-check").off("change.settleQueue").on("change.settleQueue", function () {
        var id = $(this).val();
        if (this.checked) {
            report[reportPath].selectedIds.add(id);
        } else {
            report[reportPath].selectedIds.delete(id);
        }
        report[reportPath].refreshQueueToolbar();
    });
    report[reportPath].refreshQueueToolbar();
}

// نشان «صف تسویه: N فاکتور» بالای جدول — تعداد کل انتخاب‌شده‌ها را نشان می‌دهد
// (همه‌ی صفحات با هم)، نه فقط چک‌باکس‌های تیک‌خورده‌ی صفحه‌ی جاری
report[reportPath].refreshQueueToolbar = function () {
    var toolbar = document.querySelector(".alert.alert-info");
    if (!toolbar) return;
    var badge = document.getElementById("settle-queue-count-badge");
    if (!badge) {
        badge = document.createElement("span");
        badge.id = "settle-queue-count-badge";
        badge.className = "settle-queue-badge";
        toolbar.insertBefore(badge, toolbar.firstChild);
    }
    badge.textContent = "صف تسویه: " + report[reportPath].selectedIds.size + " فاکتور";
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
// دو فراخوانی API خارجی دارد، و بات محدودیت زمان اجرا دارد؛ یک درخواست حجیم برای
// دهها/صدها فاکتور ریسک برخورد به همان محدودیت را دارد). به‌جایش صف انتخاب‌شده
// (که حالا بین صفحات هم حفظ می‌شود) در دسته‌های SETTLE_BATCH_SIZE‌تایی می‌شکند و
// دسته‌ها یکی‌یکی (نه هم‌زمان) به همان اندپوینت تسویه گروهی موجود (type=201)
// فرستاده می‌شوند — سمت سرور بدون تغییر، چون idsCsv با هر طولی را از قبل می‌پذیرفت.
// در پایان صف، نتیجه‌ی تجمیعی (موفق/ناموفق) در یک گزارش پاپ‌آپ نمایش داده می‌شود.
// -------------------------------------------------------------------------
report[reportPath].SETTLE_BATCH_SIZE = 20;
report[reportPath].settleQueueRunning = false;

// یک پاسخ تسویه‌ی تک‌فاکتور (از details برگشتی بک‌اند) موفق حساب می‌شود اگر خطا
// نداشته باشد و success=true باشد — هم‌راستا با شرط موفقیت خود بک‌اند (settleInvoices)
function isSettleResponseOk(resp) {
    if (!resp) {
        return false;
    }
    var hasError = (typeof resp.error !== "undefined" && resp.error !== null);
    return !hasError && resp.success === true;
}

// تسویه گروهی — کل صف انتخاب‌شده (از هر تعداد صفحه‌ای که انتخاب شده باشد)، نه فقط
// چک‌باکس‌های تیک‌خورده‌ی صفحه‌ی جاری
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
// بعدی فرستاده می‌شود تا کل صف تمام شود
report[reportPath].runSettleQueue = function (batches, index, totals, org_id, datef, datet) {
    if (index >= batches.length) {
        report[reportPath].settleQueueRunning = false;
        report[reportPath].setSettleButtonsEnabled(true);
        report[reportPath].selectedIds.clear();
        report[reportPath].removeQueueProgressBadge();
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
    var badge = document.getElementById("settle-queue-progress-badge");
    if (!badge) {
        badge = document.createElement("span");
        badge.id = "settle-queue-progress-badge";
        badge.className = "settle-queue-badge settle-queue-badge-progress";
        toolbar.insertBefore(badge, toolbar.firstChild);
    }
    badge.textContent = "در حال تسویه صف (" + totalCount + " فاکتور) — دسته " + currentBatch + " از " + totalBatches;
}

report[reportPath].removeQueueProgressBadge = function () {
    var badge = document.getElementById("settle-queue-progress-badge");
    if (badge) {
        badge.remove();
    }
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
        overlay.className = "settle-report-overlay";
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
        '<div class="settle-report-modal">' +
        '<div class="settle-report-modal-header">' +
        '<strong>گزارش تسویه گروهی</strong>' +
        '<button type="button" class="settle-report-close">&times;</button>' +
        '</div>' +
        '<div class="settle-report-modal-body">' +
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

    overlay.querySelector(".settle-report-close").addEventListener("click", function () {
        overlay.style.display = "none";
    });
    overlay.style.display = "flex";
}

// انتخاب/عدم انتخاب همه‌ی چک‌باکس‌های صفحه‌ی جاری (به صف اضافه/حذف می‌شود؛
// صفحات دیگر که قبلاً انتخاب شده بودند دست‌نخورده می‌مانند)
report[reportPath].toggleAll = function (el) {
    $(".settle-check").prop("checked", el.checked).each(function () {
        var id = $(this).val();
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
