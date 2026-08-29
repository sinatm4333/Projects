local input =  teamyar.get_input();
function getList()
    teamyar.set_data("recent_documents_data", json.encode(input));
  local user_info =  teamyar.get_user_info()
    local param = {
          query=teamyar.get_attachment("document_recent_documents_query.txt"),
          params={input.date_from,input.date_from, input.date_to,input.date_to, input.date_from, input.date_from,  input.date_to,input.date_to,
      	  				 user_info.id,
        				 input.date_from, input.date_from,  input.date_to, input.date_to, input.date_from, input.date_from,  input.date_to,input.date_to, input.from, input.count}
    }
    db.query(param)
    local result={total=0,list={}}  ;
    local record={};
    local total=0

    if db.query_fetch(record) then 
        result.total=record[1];
  
        while db.query_fetch(record) do
  
            table.insert(result.list,{record[2],record[6],record[9],record[11],record[15]})
        end 
    end
    db.query_free();
    return result;
end
  local IdGenerator = {
    x1 = math.random(100,1000),
    x2 = math.random(1,1000),
    getId = function(self)
        self.x1 = self.x1 + 1;
        if self.x1 > 1000 then
        self.x1 = 100;
        end
        self.x2 = self.x2 + 1;
        if self.x2 > 1000 then
        self.x2 = 1;
        end
        return self.x1 * 1000 + self.x2;
    end
    }
  
  local random= IdGenerator:getId();
  local script =  teamyar.get_attachment("recent_documents.js");

  if input.type == nil then
    local template = teamyar.run_command("2/res_bot",{
        id = "document_recent_documents",
        tpl_name = "table",
        title = "RECENT_DOCUMENTS",
        script=[[
            (function(){
            var holder_id = ']]..random..[[';
            ]]..script..[[
                
            })();
        ]],
        data= [[{header:['FILE_ICON','FILE_NAME','FILE_SIZE','TIME_MODIFY'],styles:['width:3%;','width:67%;','width:10%;','width:20%;']} ]],
        settable = 1,
        header="<div id=\\'holder_header_table_"..random.."\\'></div>",
        generatetd = [[(row)=>{
        
            return  [
                                    $.Teamyar.icon({type:row[2]}),
                                        $.Teamyar.link({title:row[1],href: "/document/file/show_version/" +row[0] ,target:"_blank"}),
                                    $.Teamyar.tools.BytesToString(row[3]),
                                    $.Teamyar.smartDate(row[4],1)
                                ]
        }]],
        ajax = [[{url:'bot/run/2/document_recent_documents',data:()=>{
            return	{type:1,
            date_from:$.Teamyar.DateTimePicker.get('#document_recent_documents_date_from_]]..random..[[','value'),
            date_to:$.Teamyar.DateTimePicker.get('#document_recent_documents_date_to_]]..random..[[','value'),
            }
        } }]]
    });
    teamyar.write_result(template);
  elseif input.type == 1 then
    teamyar.write_result(json.encode(getList()));
  elseif input.type == 2 then
    local document_recent_documents=teamyar.get_data("recent_documents_data");
     if document_recent_documents.modify_time == 0 then
        document_recent_documents.value = '""';
     end
     teamyar.write_result(document_recent_documents.value);  
  end