ty__main.botControlProgress =   ({width="100%",title1='',title2='',value=0,tooltip})=>{
    	var str = '<div class=\'botControlProgress_holder_each_percent\'  '+(tooltip!=undefined?'title=\''+tooltip+'\'':'')+' ><div class=\'botControlProgress_holder_each_percent_absolute\'>'+
		$.Teamyar.progress({value:value,value_color:'#e1701d',color:'#dbdfdf',stroke:20,width:'100%'}) +
        '<div  class=\'botControlProgress_holder_title\'><label class=\'botControlProgress_title\'>'+title1+'</label><label class=\'botControlProgress_title\'>'+title2+'</label></div>'+
        '</div></div>'
		return str;
}