-- '2020-07-01'
WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT 
    "ProjectID" AS "project_tmp_id",
    "ConsultantID" AS "consultantID",
    "Role" AS "role",
    MIN(StartDate) AS "start_date",
    CASE WHEN "EndDate" > (SELECT * FROM get_date) THEN NULL ELSE MIN("EndDate") END AS "end_date"
FROM ProjectTeam
WHERE "StartDate" < DATE((SELECT * FROM get_date), '+1 day')
GROUP BY "ProjectID", "ConsultantID", "Role"
;