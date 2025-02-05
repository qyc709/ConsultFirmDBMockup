-- '2020-07-01'
WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT *,
DATETIME((SELECT * FROM get_date)) AS "last_update"
FROM (
    SELECT 
        ID,
        "consultantID",
        'T' || "titleID" AS "titleID",
        CASE WHEN "EventType" = 'Hire' OR "EventType" = 'Continuation' THEN "StartDate"
            ELSE "EndDate" END AS "start_date",
        "EventType" AS "event_type",
        "salary"
    FROM "Consultant_Title_History"
) t
WHERE t.start_date < DATE((SELECT * FROM get_date), '+1 day')
ORDER BY "ID"
;


