SELECT *
    FROM Deliverable LEFT JOIN Consultant_Deliverable C on Deliverable.DeliverableID = C.DeliverableID
WHERE Deliverable.ProjectID = 1
    AND C.Date BETWEEN '2015-01-11' and '2015-04-02';

SELECT *
FROM Project
WHERE Status = 'In Progress'
ORDER BY ActualStartDate;

SELECT DISTINCT Consultant_Deliverable.Date
FROM Deliverable
    LEFT JOIN Consultant_Deliverable ON Deliverable.DeliverableID = Consultant_Deliverable.DeliverableID
-- WHERE Deliverable.ProjectID = 87
ORDER BY Consultant_Deliverable.Date DESC ;


SELECT *
FROM Project
ORDER BY PlannedStartDate;

WITH RECURSIVE
    sequence(n) AS (
        SELECT 1
        UNION ALL
        SELECT n + 1
        FROM sequence
        WHERE n < 10
    )
SELECT n
FROM sequence;

        SELECT ProjectID, MIN(PlannedStartDate)
        FROM Project;

SELECT STRFTIME('%W', '2015-01-01') AS week;

WITH RECURSIVE
    test(id
        , planned_start_date
        , actual_end_date
        , status
        , w
        , t1
        ) AS (
--      initial select
        SELECT ProjectID
             , MIN(PlannedStartDate)
             , ActualEndDate
             , Status
-----------     update daily   ------------------
--              , MIN(PlannedStartDate)

-----------     update weekly   ------------------
             , CAST(STRFTIME('%W', MIN(PlannedStartDate)) AS INTEGER) AS week_number
             , date(MIN(PlannedStartDate), 'weekday 6')
        FROM Project

        UNION

--      recursive select
        SELECT Project.ProjectID
             , Project.PlannedStartDate
             , Project.ActualEndDate
             , Project.Status
-----------     update daily   ------------------
--              , date(t1, '+1 days') AS t1_day

-----------     update weekly   ------------------
             , w+1 AS week_number
             , date(t1, 'weekday 6', '+7 days') AS end_date_of_the_week
--------------------------------------------------
        FROM Project, test
        WHERE
-----------     update daily   ------------------
--             PlannedStartDate <= t1_day

-----------     update weekly   ------------------
            PlannedStartDate <= end_date_of_the_week
            AND ActualEndDate >= end_date_of_the_week
--------------------------------------------------
        AND PlannedStartDate <= '2015-12-31'
    )

SELECT  * FROM test;