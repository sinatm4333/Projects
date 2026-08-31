(function(){

ty__main.botTplhtml = ({ holder_id, id, title, description, body}) => {
         var controls = [];
  
  if (title != undefined && title != "") {
            controls.push($.Teamyar.label({ class_name: 'bot_title_main_chart', title: ty__main.botGetlang(title) }))
        }
        if (description != undefined && description != "") {
            controls.push($.Teamyar.label({ class_name: 'bot_description_main_chart ty-muted', title: ty__main.botGetlang(description) }))
        }
		
        controls.push($.Teamyar.line({}))
  
       controls.push(body)
        $.Teamyar.layout({
            selector: holder_id,
            type: 'COL-1',
            controls: controls
        });
  
  	  
    }

      ty__main.botTplhtml.afterload = function(){
        
       
      }

})();
