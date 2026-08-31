(function(){
  var id_this_table,
        settable_this_table,
    	btn_for_afterload = "";
        ty__main.botTpltable = ({ holder_id, id, title, description, header, data,beforegenerate,ajax ={},generatetd,settable = 0}) => {
  
  
		id_this_table = id;
        settable_this_table = settable;
        var controls = [],
            has_header = true;

        if(ajax.data == undefined){
          ajax.data =()=>{ return {} };
          has_header = false;
        }
        
       
        
        if (title != undefined && title != "") {
            controls.push($.Teamyar.label({ class_name: 'bot_title_main_chart', title: ty__main.botGetlang(title) }))
        }
        if (description != undefined && description != "") {
            controls.push($.Teamyar.label({ class_name: 'bot_description_main_chart ty-muted', title: ty__main.botGetlang(description) }))
        }

        controls.push($.Teamyar.line({}))
 	
        if(header != undefined && header != "" ){
             controls.push(header)
          
            if(has_header){
              	   if(ajax.selector_btn == undefined){
                          controls.push( $.Teamyar.layout({
                                                    type: 'COL-1',
                                                    class_name:'ty-dir-revers ty-md-b-padding ',
                                                    controls: [
                                                      $.Teamyar.button({title: $.Teamyar.lang('FILTER'),class_name:'ty-btn-ok',events:{onclick:['ty__main.filterTable'+id]}})
                                                    ]
                                                }))
                   }else{
                	btn_for_afterload = ajax.selector_btn
                   }
            }
        }
  
        ty__main['filterTable'+id ] = function(){
          
            ty__main['changetable'+id_this_table]();
        }
  
        var table,
            obj_header = [],
            arrayId = [];
        data = { ...{ styles: [], header: [], rows: [] ,total:0, count:10, combobox:[5,10,20,50]}, ...data };

        for (var i = 0; i < data.header.length; i++) {
            arrayId.push('bot_table_each_column_'+ id+'_'+i);
            obj_header.push({ id: 'bot_table_each_column_'+ id+'_'+i, content: ty__main.botGetlang(data.header[i]), style: (data.styles[i] != undefined ?  data.styles[i]:'') })
        }
 
        console.log(obj_header);

        table = $.Teamyar.table({
            id: "bot_table_"+id,
            arrayId: arrayId,
            from: 1,
            objHeader: obj_header
        });

        controls.push(table);
        controls.push($.Teamyar.pageNumerator({
			id: 'bot_table_pagenum_'+id,
			combobox:data.combobox,
			from: 0,
			total: data.total,
			count: data.count,
			events: { onclick: ['ty__main.changetable'+id,{id:id}] }
		}) );
  
    
  
       ty__main['changetable'+id]= function(param1,param2){
              let from =0,
              count=10,
              data_of_ajax = ajax.data();
         
              if (param2!=undefined) 
              {
                  from=param2.from;
                  count=param2.count;
              }

             if(typeof  generatetd != "function"){
                    generatetd = (val)=>{
                      	if(val.length != undefined)
                            return val;
                        else{
                        	var row = [];
                             for(var key in val){
                             	row.push(val[key])
                             }
                          
                           return row;
                        }
                    
                    }
             }
         
              $.Teamyar.ajax({
                  block_holder:'body',
                  options:{
                      url: ajax.url,
                      type: 'POST',
                      dataType:'json',
                      data:{customform:JSON.stringify({from:from,count:count,...data_of_ajax})}
                
                  },
                  events:{
                      success : function (response)
                      {
                        
                        if(typeof beforegenerate == 'function'){
                        
                          	beforegenerate(response);
                        
                        }
                        
                        var list = [],
                            total = -1;
                         if(response.total == undefined) 
                         {
                         	list =  response;
                         }else{
                              total = response.total;
                              list = response.list;
                         }
                        
                           let rows =[],
                           after_generated,
                           each_row =[] ;
                          for (let i=0 ; i < list.length; i++)
                          {
                              
                            after_generated =  generatetd(list[i]);
                             each_row =[];
                            
                             for(var j = 0 ; j<after_generated.length; j++){
                                if(typeof after_generated[j] == "string") {  
                                       each_row.push({content: after_generated[j]})
                                }else{
                                        each_row.push({content: after_generated[j].content,style: after_generated[j].style})
                                }
                             }
                            
                            rows.push(each_row)

                              
                          }
                          $.Teamyar.table.setData({
                              id: "bot_table_"+id,
                              objData: rows,
                              from:from+1,
                              oddrow: true
                          });
                        
                          if(total != -1){
                            $.Teamyar.pageNumerator.show('#bot_table_pagenum_'+id, [from, count, total]);
                          }
                      },
                      error: function (status,text){
                      }
                  }
              });
       }
  
        $.Teamyar.layout({
            selector: holder_id,
            type: 'COL-1',
            controls: controls
        });
  
  	  
    }

      ty__main.botTpltable.afterload = function(){
        
          if(settable_this_table ==1){
             ty__main['changetable'+id_this_table]();
          }
        
           if(btn_for_afterload != ""){
                      $.Teamyar.button({selector:btn_for_afterload ,title: $.Teamyar.lang('FILTER'),class_name:'ty-btn-ok',events:{onclick:['ty__main.filterTable'+id]}})
              }
      }

})();
