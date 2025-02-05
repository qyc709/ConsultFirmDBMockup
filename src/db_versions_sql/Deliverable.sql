-- '2020-07-01'
WITH 

get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
),

DeliverableHourSpent AS (
    SELECT d."DeliverableID", SUM(cd."Hours") AS Hours
    FROM "Consultant_Deliverable" cd 
        LEFT JOIN "Deliverable" d ON cd."DeliverableID" = d."DeliverableID"
    WHERE cd."Date" < DATE((SELECT * FROM get_date), '+1 day')
    GROUP BY d."DeliverableID"
)
SELECT 
    d."DeliverableID" AS "deliverable_tmp_id",
    d."ProjectID" AS "project_tmp_id",
    d."Name" AS "name",
    p."CreatedAt" AS "created_at",
    d."Price" AS "price",
    d."PlannedStartDate" AS "planned_start_date",
    CASE WHEN d."ActualStartDate" > (SELECT * FROM get_date) THEN NULL ELSE d."ActualStartDate" END AS "actual_start_date",
    d."PlannedHours" AS "planned_hours",
    d."DueDate" AS "due_date",
    CASE 
        WHEN d."ActualStartDate" > (SELECT * FROM get_date) THEN "Not Started" 
        WHEN d."SubmissionDate" > (SELECT * FROM get_date) AND d."Status" = "Completed" THEN "In Progress" 
        ELSE d."Status"
    END AS "status",

    CASE WHEN d."ActualStartDate" > (SELECT * FROM get_date) OR d."ActualStartDate" IS NULL THEN 0 
        ELSE ROUND(dhs."Hours"/(d."ActualHours"/d."Progress"), 1) 
    END AS "progress",

    CASE WHEN d."SubmissionDate" > (SELECT * FROM get_date) THEN NULL ELSE d."SubmissionDate" END AS "submission_date",
    CASE WHEN d."InvoicedDate" > (SELECT * FROM get_date) THEN NULL 
        WHEN p."ActualEndDate" < DATE((SELECT * FROM get_date), '+1 day') AND d."InvoicedDate" IS NULL THEN DATE(p."ActualEndDate")
        ELSE d."InvoicedDate" 
    END AS "invoiced_date",
    DATETIME((SELECT * FROM get_date)) AS "last_update"
FROM "Deliverable" d 
    LEFT JOIN "Project" p ON d."ProjectID" = p."ProjectID"
    LEFT JOIN "DeliverableHourSpent" dhs ON d."DeliverableID" = dhs."DeliverableID"
WHERE d."ProjectID" IN (
    SELECT "ProjectID"
    FROM "Project"
    WHERE "CreatedAt" < DATE((SELECT * FROM get_date), '+1 day')
);
