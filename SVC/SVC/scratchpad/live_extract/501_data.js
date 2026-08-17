report[reportPath].getFilters = function () {
  return [

    $.Teamyar.DateTimePicker({
      pickTime: true,
      get_second: true,
      title: "<span style='color:red;padding:5px;'> * </span>"+report[reportPath].translateWord ("DATE_FROM")+" : ",
      value: report[reportPath].getCash("datef" ),
      name: "datef",    
      id: 'datef',
      nofuture: true,
    }),
    $.Teamyar.DateTimePicker({
      pickTime: true,
      get_second: true,
      title: "<span style='color:red;padding:5px;'> * </span>"+report[reportPath].translateWord ("DATE_TO")+" : ",
      value: report[reportPath].getCash("datet" ),
      name: "datet",   
      id: 'datet',
      nofuture: true,
    }),
    $.Teamyar.acl({                                                                     
      id: "org",
      multiedit: false,
      shownone:'true',
      value: report[reportPath].getCash("org" , true),
      name: "org",
      typevalue: 'object',
      title: report[reportPath].translateWord ("ORG")+" : ",
      format: "input",
      url:"/",   
      events: {
        ongetdata: ['GetDataACL',6],
      }
    }),
    $.Teamyar.acl({                                                                     
      id: "crm",
      multiedit: false,
      shownone:'true',
      value: report[reportPath].getCash("crm" , true),
      name: "crm",
      typevalue: 'object',
      title: report[reportPath].translateWord ("CRM")+" : ",
      format: "input",
      url:"/",   
      events: {
        ongetdata: ['GetDataACL',7],
      }
    }),
    $.Teamyar.acl({                                                                     
      id: "cat",
      multiedit: false,
      shownone:'true',
      value: report[reportPath].getCash("cat" , true),
      name: "cat",
      typevalue: 'object',
      title: report[reportPath].translateWord ("CAT")+" : ",
      format: "input",
      url:"/",   
      events: {
        ongetdata: ['GetDataACL',9],
      }
    }),
    $.Teamyar.acl({                                                                     
      id: "ctype",
      multiedit: false,
      shownone:'true',
      value: report[reportPath].getCash("ctype" , true),
      name: "ctype",
      typevalue: 'object',
      title: report[reportPath].translateWord ("ctype")+" : ",
      format: "input",
      url:"/",   
      events: {
        ongetdata: ['GetDataACL',8],
      }
    }),
    $.Teamyar.input.text({
      id: "box_id",              
      name: "box_id",   

      title:report[reportPath].translateWord("BOX_ID"),                   
      format: "input",     
      type:"number",

    }),  "",
      
        $.Teamyar.editor({
      id: "txt",              
      name: "txt",              
      title:report[reportPath].translateWord ("txt")+":",                   
      format: "input",     
      type:"text",

    }),

    "<button type='button' id:'save_all_btn' style='margin-top: 40px;' class='btn core_btn  ty-btn-default btn btn-warning' onclick='ty__main.save_all()'>"+  report[reportPath].translateWord("ارسال گروهی پیامک")+"</button>",
  
    "<div id='err_msg'></div>"


  ];
}

///-----------------------------------------------
function GetDataACL(ty,p2)
{
  let path=report[reportPath].getBotPath()
  let org = $.Teamyar.acl.get('#org', 'value');
  let client_data=[]
  $.Teamyar.ajax({
    block_holder: 'body',
    options: {
      url: path,
      type: 'POST',
      dataType: 'json',
      async: false,
      data: {
        customform: JSON.stringify({
          type:ty, data: {
            from: p2.data.from,
            org_id:org.id,
            count: p2.data.count,
            search: p2.data.search,
          }
        })
      }
    },
    events: {
      success: function (res) {
        client_data = res
      }
    }
  });
  return client_data;
}
//-----------------------------------------------
ty__main.save_all=function (crm_id) {
    let box_id = $.Teamyar.input.text.get('#box_id', 'value');
  let txt = $.Teamyar.editor.get('#txt', 'value');
  $.Teamyar.ajax({
    block_holder: 'body',
    options: {
      url: 'bot/run/2/crm_rfm',
      type: 'POST',
      dataType: 'json',
      async: false,
      data: {
        customform: JSON.stringify({
          type:11, data: {
            crms: ty__main.crms,
            box_id:box_id,
            txt:txt,
          }
        })
      }
    },
    events: {
      success: function (res) {
        console.log(res)
        document.getElementById("err_msg").innerHTML=res.msg
      }
    }
  });
}
//-----------------------------------------------
ty__main.onChangeCheckInput=function (crm_id) {
  ty__main.crms= ty__main.crms+','+crm_id

}
//-----------------------------------------------
ty__main.send_sms=function (crm_id) {
      let box_id = $.Teamyar.input.text.get('#box_id', 'value');
      let txt = $.Teamyar.editor.get('#txt', 'value');
  $.Teamyar.ajax({
    block_holder: 'body',
    options: {
      url: 'bot/run/2/crm_rfm',
      type: 'POST',
      dataType: 'json',
      async: false,
      data: {
        customform: JSON.stringify({
          type:10, data: {
           // segment: segment,
            crm_id: crm_id,
            box_id:box_id,
            txt:txt,
          }
        })
      }
    },
    events: {
      success: function (res) {
        console.log(res)
        document.getElementById("err_msg").innerHTML=res.msg
      }
    }
  });
}
///-----------------------------------------------
report[reportPath].renderItemReport = function (dataResponse) {
  let reportName = dataResponse.hasOwnProperty("name") ? dataResponse.name : null;
  switch (reportName){
    case "table":
      report[reportPath].responseReportMain(dataResponse);
      break;
  }   
}
report[reportPath].responseReportMain =  function (dataResponse){
  const report = dataResponse.hasOwnProperty("report") ? dataResponse.report : [];
  const elementId = dataResponse.hasOwnProperty("report") ? dataResponse.elementId : [];
  $("#" + elementId).html(report);
}

