--local total_param = teamyar.get_input(form_param)

    query = [[
             select wh_product.ID as product_id
,k.ATTRIBUTE_ID
,wh_product.FULL_CODE
,wh_product.full_name
,k.content_att as ATTRIBUTE
,case when k.content_att is not null then CONCAT(wh_product.full_name,' - ',k.content_att)  else wh_product.full_name end
as FullNameAttribute
from wh_product
left join
(
SELECT
		*
	FROM
		(
		SELECT
			REFERENCE_ID AS PRODUCT_ID,
			ATTRIBUTE_ID,
			GROUP_CONCAT( DISTINCT CONTENT ORDER BY FIELD_ID ASC SEPARATOR ' , ' ) AS CONTENT_ATT 
		FROM
			WH_PR_ATTRIBUTE_DETAIL 
		WHERE
			TYPE = 1 
		GROUP BY
			ATTRIBUTE_ID,
			REFERENCE_ID 
		) PAD
		LEFT JOIN WH_PRODUCT_ATTRIBUTE ATP ON PAD.ATTRIBUTE_ID = ATP.ID
    ) as k on wh_product.ID = k.PRODUCT_ID
    where PRODUCT_TYPE_ID = 4 and LENGTH(FULL_CODE)>4 and org_id=8
    order by wh_product.ID
    ]];

local param = {
    query = query,
    param = {}
}
-------------------------------------
local result = {}
db.query(param)
local record = {}
while db.query_fetch(record) do
    table.insert(result, {
        product_id=record[1],
        ATTRIBUTE_ID=record[2],
              FULL_CODE=record[3],
      FULL_NAME=record[4],
        ATTRIBUTE=record[5],
        FullNameAttribute=record[6]
    })
end
db.query_free()
local jsonResult = json.encode(result)
teamyar.write_result(jsonResult)