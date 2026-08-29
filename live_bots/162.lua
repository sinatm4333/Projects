-- query for section
function res_query()
    
query= {query="select cs.ID,cs.SECTION_NAME from crm_section as cs order by cs.ID ",params={}}
  
  db.query(query);
   local result= {}
  local Out_Query={}
  while db.query_fetch(result) do
    Out_Query[#Out_Query+1] = {ID=result[1],SECTION_NAME=result[2]};
  end
  
  db.query_free();
  
   teamyar.write_result(json.encode(Out_Query))


  if #Out_Query>0 then
        return Out_Query
  end
      return "[]"
end


documents_updats = res_query()