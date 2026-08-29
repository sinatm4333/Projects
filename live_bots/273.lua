local param = {
    	query=teamyar.get_attachment("leads_by_source_query.txt");
    	params={} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
  local total=0 

    while db.query_fetch(record) do 
      table.insert(result,{src=record[1],count=record[2]}) 
    end 
  db.query_free(); 
  result=json.encode(result)
  local template = teamyar.run_command("2/res_bot",{
    id = "crm_leads_by_source",
    tpl_name = "chart",
    title = "LEADS_BY_SOURCE",
    script='',
    src='<script src="/res/gui/res/js/chart/variable-pie.js" type="text/javascript"></script>',
	data= [=[()=>{  debugger
		response=]=]..result..[=[;
		if(Object.keys(response).length >0)
		{
		var output_data = response.map(item => ({
			name: item.src,
			y: item.count,
			z: 5
		  }));
		}

		return  {     
				chart: 
					{
						type: 'variablepie'
					},
					title: {
						text: ty__main.botGetlang('LEADS_BY_SOURCE'),
						align: 'center'
					},
					tooltip: {
						headerFormat: '',
						pointFormat: '<span style="color:{point.color}">\u25CF</span> <b> {point.name}: <b>{point.y}</b>'
					},
					series: [{
						minPointSize: 10,
						innerSize: '80%',
						zMin: 0,
						name: 'countries',
						borderRadius: 5,
						data: output_data
					}]
			}
  }]=]

});
teamyar.write_result(template);
