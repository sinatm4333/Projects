--***Author : Mahdi Jahani 09125632329***
local myArray = {}
Res_chart = [[
<html dir="rtl" lang="fa">
<h3 style="background-color:#00bf7d;text-align: center;border:1px dots black;height:40px;weight:100%%;padding-top:5px">فروش بر اساس محصول</h3>
<table>
  <thead>
	  <tr style="background-color:#0073e6;color:white;">
				<th>ردیف</th>
				<th>سال</th>
				<th>محصول</th>
				<th>وضعیت</th>
                <th>حجم فروش</th>
	  </tr>
  </thead>
  <tbody id="result">
  </tbody>
</table>

<style>

body {
  font-family: IRANSansWeb_Light, sans-serif;
  font-size:14px;
}

table {
  font-family: IRANSansWeb_Light, sans-serif;
  border-collapse: collapse;
  width: 100%%;
 text-align: center;
}

td, th {
  border: 4px solid #dddddd;
  text-align: center;
  padding: 8px;
 text-align: center;
}

tr:nth-child(even) {
  background-color: #eeeeee;
 text-align: center;
}
</style>
<script>   
      var row = %s,   
      len = row.length,
	  str = '';
      for(var i = 0; i < len ;i++){
		  str+='<tr>';
                  str+='<td>'+(i+1)+'</td>'
		  for(var j = 0; j < row[i].length ;j++){
			str+='<td>'+row[i][j]+'</td>'
		  }
		  str+='</tr>';
	  }
	  document.getElementById('result').innerHTML = str;
</script>
]]

input = [[ {"domain":"78.135.73.244","port":8001,"method":"GET","url":"/api/karbalad/salesbyproductamount","ssl":true,"secure":false}]]

output = teamyar.call_url(context,input)
--teamyar.write_result(context,output)

local res = json.decode(output)
--{"type":"ok","result":{"status":200
local status = res["result"]["status"]

 if tonumber(status)==200 then
  local body = res["result"]["body"]
 --teamyar.write_result(context,body)
   local  JD = json.decode(body)
   for i=1 , #JD, 1 do
        table.insert(myArray, {JD[i]["shamsiSalesYear"],JD[i]["catName"],JD[i]["salesStatus"],JD[i]["sum"]}) 
     end
local formattedChart = string.format( Res_chart ,  json.encode(myArray ) )
teamyar.write_result( context,formattedChart )

end
