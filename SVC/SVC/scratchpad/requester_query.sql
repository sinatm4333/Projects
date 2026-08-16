select k.*
from (select rpd.PRODUCT_ID as RequestPRODUCT_ID,rpd.ATTRIBUTE_ID as RequestATTRIBUTE_ID,pr.FULL_CODE as PartCode , pr.full_name as PartName
,(
	SELECT
		PAD.CONTENT_ATT AS ATTRIBUTE_NAME
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
	WHERE
		PRODUCT_ID = rpd.product_id
		AND ATTRIBUTE_ID = rpd.ATTRIBUTE_ID
	) AS PartATTRIBUTE

,CASE
				WHEN rpd.garantee_flag = 1 THEN
				0
				WHEN rpd.garantee_flag = 2 THEN
				1 ELSE 'N/A'
			END AS PartRequestWFlag
      , rpd.QUANTITY_DEMAND as Qty
      , pm.fullname as RequesterName
      , REPORT_FN_JDATE(rp.DATE_REQUEST, '-') as RequestDateJalali
      , LEFT(REPORT_FN_JDATE(rp.DATE_REQUEST, '-'), 4) as RequestYear
      , SUBSTRING(REPORT_FN_JDATE(rp.DATE_REQUEST, '-'), 6, 2) as RequestMonth
FROM
	WH_REQ_PRODUCT AS RP
	LEFT JOIN PM_SERVICE_REQUEST SC ON SC.ID = RP.REF_ID
	LEFT JOIN wh_req_product_details AS rpd ON rp.id = rpd.REQUEST_ID
	LEFT JOIN wh_product AS pr ON pr.id = rpd.PRODUCT_ID
	LEFT JOIN profile_main pm ON pm.id = rp.AUTHOR_ID
WHERE 	rp.DELETED = 0
	AND rp.REQUEST_TYPE = 5
	and 	rp.REF_TYPE= 101
		AND REPLACE ( rpd.reason_of_cancellation, ' ', '' ) = ''
 and rp.`STATUS` = 1

	union all

select rpd.PRODUCT_ID as RequestPRODUCT_ID,rpd.ATTRIBUTE_ID RequestATTRIBUTE_ID,pr.FULL_CODE as PartCode , pr.full_name as PartName
,(
	SELECT
		PAD.CONTENT_ATT AS ATTRIBUTE_NAME
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
	WHERE
		PRODUCT_ID = rpd.product_id
		AND ATTRIBUTE_ID = rpd.ATTRIBUTE_ID
	) AS PartATTRIBUTE
,CASE
				WHEN rpd.garantee_flag = 1 THEN
				0
				WHEN rpd.garantee_flag = 2 THEN
				1 ELSE 'N/A'
			END AS PartRequestWFlag
      , rpd.QUANTITY_DEMAND as Qty
      , pm.fullname as RequesterName
      , REPORT_FN_JDATE(rp.DATE_REQUEST, '-') as RequestDateJalali
      , LEFT(REPORT_FN_JDATE(rp.DATE_REQUEST, '-'), 4) as RequestYear
      , SUBSTRING(REPORT_FN_JDATE(rp.DATE_REQUEST, '-'), 6, 2) as RequestMonth

FROM
	WH_REQ_PRODUCT AS RP
	LEFT JOIN PM_SERVICE_REQUEST SC ON SC.ID = RP.REF_ID
	LEFT JOIN wh_req_product_details AS rpd ON rp.id = rpd.REQUEST_ID
	LEFT JOIN wh_product AS pr ON pr.id = rpd.PRODUCT_ID
	left join pm_cost_declaration_detail as cd on cd.ID = RP.REF_ID
	left join pm_cost_declaration on pm_cost_declaration.ID = cd.COST_DECLARATION_ID
	LEFT JOIN pm_service_request AS sr ON pm_cost_declaration.SERVICE_REQUEST_ID = sr.id
	LEFT JOIN wh_product AS prResid ON prResid.id = sr.PRODUCT_ID
	LEFT JOIN profile_main pm ON pm.id = rp.AUTHOR_ID
WHERE rp.DELETED = 0
	AND rp.REQUEST_TYPE = 5
	and rp.REF_TYPE= 109
		AND REPLACE ( rpd.reason_of_cancellation, ' ', '' ) = ''
 and rp.`STATUS` = 1
 ) as k
