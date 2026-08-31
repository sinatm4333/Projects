(function(){
var id_this_chart,
    chart =-1,
    data_this_chart,
    btn_for_afterload = "";
ty__main.botTplchart = ({holder_id,id,title,ajax={},description,setchart=1,generatedata,header,data}) => {
  
  
  data_this_chart = data;
  id_this_chart = id;
  var controls = [],
      has_header = true;

  if(ajax.data == undefined){
      ajax.data =()=>{ return {} };
      has_header = false;
  }
  
  if(generatedata == undefined || generatedata ==""){
  	generatedata = (val)=>{
    	return val;
    }
  }
  
  if(title != undefined && title !=""){
  	controls.push(    $.Teamyar.label({class_name:'bot_title_main_chart', title: ty__main.botGetlang(title) }))
  }
    if(description != undefined || description != ""){
  	controls.push(    $.Teamyar.label({class_name:'bot_description_main_chart ty-muted', title: ty__main.botGetlang(description) }))
  }

   	controls.push(    $.Teamyar.line({ }))
  
   if(header != undefined || header != ""){
  	controls.push( header  )
          if(has_header){
            
 
              if(ajax.selector_btn == undefined){
                    controls.push( $.Teamyar.layout({
                                              type: 'COL-1',
                                              class_name:'ty-dir-revers ty-md-b-padding ',
                                              controls: [
                                               	  $.Teamyar.button({selector:ajax.selector_btn ,title: $.Teamyar.lang('FILTER'),class_name:'ty-btn-ok',events:{onclick:['ty__main.changechart'+id]}})
                                              ]
                                          }));
              	}else{
                	btn_for_afterload = ajax.selector_btn
                }
            
            }
  }
  
  controls.push(  '<div id=\'' + id + '\'></div>')
  
    $.Teamyar.layout({
        selector: holder_id,
        type: 'COL-1',
        controls: controls
    });
  
    ty__main['changechart'+id]= function(param1,param2){
      
      data_of_ajax = ajax.data();
      
      if(data_of_ajax == -1){
      	  return;
      }
      
      $.Teamyar.ajax({
                  block_holder:'body',
                  options:{
                      url: ajax.url,
                      type: 'POST',
                      dataType:'json',
                      data:{customform:JSON.stringify(data_of_ajax)}
                
                  },
                  events:{
                      success : function (response)
                      {
                        
                         var new_data = generatedata(response)
                   
                         new_data = {...new_data,  credits: {
                                              enabled: false
                                            }};
                        // add by zmo for multiple chart in wiedjet
                        chart=Highcharts.chart(id,new_data) 
                         if(chart == -1){
                             chart = Highcharts.chart(id,new_data);
                         }else{
                            chart.update(new_data);
                         }
                        
                      }
                  }
         });
   }


}

ty__main.botTplchart.afterload =  function(){
  
  var new_data ={};
   if(data_this_chart != '' && data_this_chart!= undefined){
      if(typeof data_this_chart == "function"){
          new_data = data_this_chart();
      }
        new_data = {...new_data,  credits: {
                                              enabled: false
                                            }};
      chart = Highcharts.chart(id_this_chart,new_data);
  }else{
    	 ty__main['changechart'+id_this_chart]();
  }
  
      if(btn_for_afterload != ""){
            		  $.Teamyar.button({selector:btn_for_afterload ,title: $.Teamyar.lang('FILTER'),class_name:'ty-btn-ok',events:{onclick:['ty__main.changechart'+id_this_chart]}})
       }
  

}

 
})();