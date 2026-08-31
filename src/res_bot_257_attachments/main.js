ty__main.botGetlang = (name) => {

    if (ty__main.BOT_LANG[name] == undefined) {
        return name;
    }

    return ty__main.BOT_LANG[name];

}

ty__main.botGetlang.add = ({ lang})=>{
  
  for (var key in lang){
     if(   ty__main.BOT_LANG[key]  != undefined){
    			 console.error("There is dublicate lang =>"+key);
     }
      ty__main.BOT_LANG[key] = lang[key];
  }
 

}

ty__main.botTPL = ({ html = '', tpl_name, holder_id }) => {

    let str = '',
        lang = ty__fullinfo.user_info.language;

    str = `<script src='/bot/run/2/res_bot/${lang}.js'></script>
    ${html}
     <link href='/bot/run/2/res_bot/main.css' rel='stylesheet' /> 
    <script src='/bot/run/2/res_bot/template_${tpl_name}.js'></script>`

    $(holder_id).append(str);
}

