function getList(from,count)
    local res =  teamyar.get_user_info()
    local param = {
          query=teamyar.get_attachment("document_pending_documents_query.txt"),
          params={res.id,from,count}
    }
    db.query(param)
  local result={total=0,list={}}  ;
    local user_ids={};
    local record={};
    local total=0
    if db.query_fetch(record) then 
  
        result.total=record[1];
  
        while db.query_fetch(record) do
  
            table.insert(result.list,{record[2],record[6],record[9],record[11],record[12],record[13]});
            table.insert(user_ids,record[13]);
        end 
         profile_infos=teamyar.call_api(5,"/api/profile_info/get",{ids=user_ids});
        if profile_infos.success == true then
            for i, v in ipairs(profile_infos.data) do 
                for j, value in ipairs(result.list) do 
                        if v.id==value[6] then
            				table.insert(result.list[j],v.fullname)
                        end
                end
            end
        end
      
  
     end
    db.query_free();
    return result;
  end
  input=teamyar.get_input();

  if input.type == nil then
  local res = teamyar.run_command("2/res_bot",{
    id = "document_pending_documents",
    tpl_name = "table",
    title = "PENDING_DOCUMENTS",
    script='',
    data= [[{header:['FILE_ICON','FILE_NAME','FILE_SIZE','AUTHOR','DATE_CREATE'],styles:['width:3%;','width:67%;','width:10%;','width:10%;','width:10%;']} ]],
    settable = 1,
    generatetd = [[(row)=>{
    
        return  [
                                $.Teamyar.icon({type:row[2]}),
                                  $.Teamyar.link({title:row[1],href: "/document/file/show_version/" +row[0] ,target:"_blank"}),
                                $.Teamyar.tools.BytesToString(row[3]),
                                row[6],
                                $.Teamyar.smartDate(row[4],1),
                            ]
    
    }]],
    ajax = [[{url:'bot/run/2/document_pending_documents',data:()=>{
        return	{type:1}
    } }]]
});

teamyar.write_result(res);

elseif input.type == 1 then

teamyar.write_result(json.encode(getList(input.from,input.count)));

end