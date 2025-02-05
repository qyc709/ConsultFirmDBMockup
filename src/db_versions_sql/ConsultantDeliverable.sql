-- '2020-07-01'
WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT 
    "ID",
    "ConsultantID" AS "consultantID",
    "DeliverableID" AS "deliverable_tmp_id",
    "Date" AS "date",
    "Hours" AS "hours",
    DATETIME((SELECT * FROM get_date)) AS "last_update"
FROM "Consultant_Deliverable"
WHERE "Date" < DATE((SELECT * FROM get_date), '+1 day')
ORDER BY ConsultantID
;
