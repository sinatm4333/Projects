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

// تسویه گروهی فاکتورهای انتخاب‌شده
report[reportPath].settleSelected = function () {
    var ids = [];
    $(".settle-check:checked").each(function () {
        ids.push($(this).val());
    });
    if (ids.length === 0) {
        $.Teamyar.message({ message: "هیچ فاکتوری انتخاب نشده است.", type: "warning" });
        return;
    }
    if (!confirm("آیا از تسویه " + ids.length + " فاکتور انتخاب‌ شده مطمئن هستید؟")) {
        return;
    }
  let org_id=  $.Teamyar.acl.get('#org_id', 'value');
  let datef = $.Teamyar.DateTimePicker.get('#from_date', 'value');
    let datet = $.Teamyar.DateTimePicker.get('#to_date', 'value');
  console.log(datef)
    report[reportPath].sendSettleRequest("?type=201", { invoice_ids: ids.join(",") ,org_id:org_id.id, from_date:datef ,to_date :datet});
}

// انتخاب/عدم انتخاب همه چک‌باکس‌ها
report[reportPath].toggleAll = function (el) {
    $(".settle-check").prop("checked", el.checked);
}

// ارسال درخواست تسویه به بک‌اند
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
