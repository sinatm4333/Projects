function res_query()
  
 query= {query="select  id, SECTION_ID, name,sort_id from crm_classify_person",params={}}
  
    db.query(query);
   local result= {}
  local Out_Query={}
  while db.query_fetch(result) do
    Out_Query[#Out_Query+1] = {ID=result[1],SECTION_ID=result[2],name=result[3],sort_id=result[4]};
  end
  
  db.query_free();
  
   teamyar.write_result(json.encode(Out_Query))
  
 
  if #Out_Query>0 then
        return Out_Query
  end
      return "[]"
end


 res_query()
