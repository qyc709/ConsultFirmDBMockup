-- '2020-07-01'
WITH 

get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
),

ProjectHourSpent AS (
    SELECT d."ProjectID", SUM(cd."Hours") AS Hours
    FROM "Consultant_Deliverable" cd 
        LEFT JOIN "Deliverable" d ON cd."DeliverableID" = d."DeliverableID"
    WHERE cd."Date" < DATE((SELECT * FROM get_date), '+1 day')
    GROUP BY d."ProjectID"
)
SELECT p."ProjectID" AS "project_tmp_id",
    p."CreatedAt" AS created_at,
    p.ClientID AS clientID, p.UnitID AS unitID, p.Name AS name, p.Type AS type, 
    p."Price" AS price, p."EstimatedBudget" AS estimated_budget, p."PlannedHours" as planned_hours, 
    p."PlannedStartDate" AS planned_start_date, p."PlannedEndDate" AS planned_end_date, 
    CASE WHEN p."ActualStartDate" > (SELECT * FROM get_date) THEN "Not Started" 
        WHEN p."ActualEndDate" > (SELECT * FROM get_date) AND "Status" = "Completed" THEN "In Progress" 
        ELSE p.Status END AS "status", 
    CASE WHEN p."ActualStartDate" > (SELECT * FROM get_date) THEN NULL ELSE p."ActualStartDate" END AS "actual_start_date", 
    CASE WHEN p."ActualEndDate" > (SELECT * FROM get_date) THEN NULL ELSE p."ActualEndDate" END AS "actual_end_date", 
    CASE WHEN p."ActualStartDate" > (SELECT * FROM get_date) THEN 0 
        ELSE ROUND(phs."Hours"/(p."ActualHours"/p."Progress"), 1) END AS "progress",
    DATETIME((SELECT * FROM get_date)) AS "last_update"
FROM "Project" p
    LEFT JOIN ProjectHourSpent phs ON p."ProjectID" = phs."ProjectID"
WHERE p."CreatedAt" < DATE((SELECT * FROM get_date), '+1 day')
ORDER BY p."CreatedAt", p."ProjectID";







