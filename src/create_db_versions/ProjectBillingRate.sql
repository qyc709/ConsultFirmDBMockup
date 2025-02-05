-- '2020-07-01'
WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT 
    "ProjectID" AS "project_tmp_id",
    "T" || "TitleID" AS "titleID",
    ROUND(AVG("Rate"), 1) AS "rate"
FROM "ProjectBillingRate"
WHERE "ProjectID" IN (
    SELECT "ProjectID"
    FROM "Project"
    WHERE "CreatedAt" < DATE((SELECT * FROM get_date), '+1 day')
)
GROUP BY "ProjectID", "TitleID";