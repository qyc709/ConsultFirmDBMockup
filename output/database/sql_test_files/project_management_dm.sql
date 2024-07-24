/*
 Recursive CTE test code
 */
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

-- STRFTIME test code
SELECT STRFTIME('%W', '2015-01-01') AS week;

/*
 This CTE recursively add all active projects to the table before specific date depending on business requirement.
 The dm can be updated daily/weekly/monthly.
 The following sample sql updates the datamart weekly.
 */
WITH RECURSIVE
    datamart_base(
        t
        , ProjectID
        , ClientID
        , UnitID
        , CreatedAt
        , status
        , planned_start_date
        , actual_start_date
        , actual_end_date
        , percent_completed
        , target_hours
        , w
        ) AS (
--      initial select
        SELECT
            date(CreatedAt, 'weekday 6')
            , ProjectID
            , ClientID
            , UnitID
            , CreatedAt
            , Status
            , PlannedStartDate
            , ActualStartDate
            , ActualEndDate
            , Progress
            , CASE
                WHEN Status = 'Completed' THEN ActualHours
                WHEN (Status = 'In Progress' AND Progress <> 0) THEN ROUND(ActualHours/(Progress*0.01), 1)
                ELSE PlannedHours END
-----------     update daily   ------------------
--             , MIN(PlannedStartDate)

-----------     update weekly   ------------------
            , CAST(STRFTIME('%W', CreatedAt) AS INTEGER) AS week_number
        FROM Project
        WHERE CreatedAt = (SELECT MIN(p.CreatedAt) FROM Project p)

        UNION

--      recursive select
        SELECT
            date(t, 'weekday 6', '+7 days') AS end_date_of_the_week
            , Project.ProjectID
            , Project.ClientID
            , Project.UnitID
            , Project.CreatedAt
            , Project.Status
            , Project.PlannedStartDate
            , Project.ActualStartDate
            , Project.ActualEndDate
            , Project.Progress
             , CASE
                WHEN Project.Status = 'Completed' THEN Project.ActualHours
                WHEN (Project.Status = 'In Progress' AND Project.Progress <> 0) THEN ROUND(ActualHours/(Progress*0.01), 1)
                ELSE Project.PlannedHours END
-----------     update daily   ------------------
--              , date(t1, '+1 days') AS t1_day

-----------     update weekly   ------------------
            , w+1 AS week_number
--------------------------------------------------
        FROM Project, datamart_base
        WHERE
-----------     update daily   ------------------
--             PlannedStartDate <= t1_day

-----------     update weekly   ------------------
            Project.CreatedAt <= end_date_of_the_week
            AND (ActualEndDate >= end_date_of_the_week
                    OR ActualEndDate IS NULL
                    OR julianday(end_date_of_the_week) - julianday(ActualEndDate) < 7)
--------------------------------------------------
--         AND Project.CreatedAt <= '2015-12-31'
        AND end_date_of_the_week <= '2017-12-31'
    )
,

week_project_extract AS(
    SELECT DISTINCT
         date(C.Date, 'weekday 6') AS end_date_of_the_week
        , D.ProjectID AS ProjectID
    FROM Consultant_Deliverable C
    JOIN Deliverable D on C.DeliverableID = D.DeliverableID
)
,

/*
 This CTE calculate the Consultant_Deliverable accumulating Hours before the end of each week for each project
 */
weekly_hours AS (
    SELECT
        week_project_extract.end_date_of_the_week
        , week_project_extract.ProjectID
        , SUM(C.Hours) AS Hours
    FROM week_project_extract
        INNER JOIN Deliverable D ON D.ProjectID = week_project_extract.ProjectID
--         INNER JOIN Consultant_Deliverable C ON D.DeliverableID = C.DeliverableID
        INNER JOIN Consultant_Deliverable C
    WHERE C.date <= week_project_extract.end_date_of_the_week
        AND D.DeliverableID = C.DeliverableID
    GROUP BY week_project_extract.end_date_of_the_week, week_project_extract.ProjectID
)
,

/*
 This CTE
 first fill in Hours for the week that has no working hours of a project with the same values as before.
 This means the Hours stay the same if no hours for the week.
 Then calculate the actual percentage completed every week for each project
 */
get_actual_progress AS (
    SELECT a.t
        , a.ProjectID
        , a.target_hours
    --     , COALESCE(a.end_date_of_the_week, a.t) AS end_date_of_the_week
        , MAX(a.Hours) OVER (PARTITION BY a.ProjectID, a.same_hours) AS total_hours_to_date
        , ROUND(MAX(a.Hours) OVER (PARTITION BY a.ProjectID, a.same_hours)/a.target_hours*100, 1) AS actual_percent_completed
    --     , a.if_null_hours
    --     , a.same_hours
    FROM (
        SELECT datamart_base.t
             , datamart_base.ProjectID
             , datamart_base.target_hours
             , weekly_hours.end_date_of_the_week
             , weekly_hours.Hours
             , CASE WHEN weekly_hours.Hours IS NOT NULL THEN 1 ELSE 0 END AS if_null_hours
             , SUM(CASE WHEN weekly_hours.Hours IS NOT NULL THEN 1 ELSE 0 END)
                   OVER (PARTITION BY datamart_base.ProjectID ORDER BY datamart_base.t) AS same_hours
        FROM datamart_base
            LEFT JOIN weekly_hours ON datamart_base.t = weekly_hours.end_date_of_the_week
                                          AND datamart_base.ProjectID = weekly_hours.ProjectID
         ) a
--     ORDER BY
    --     a.ProjectID,
--         a.t
    )
,

correct_base_by_progress AS(
    SELECT
        db.t
        , db.ProjectID
        , db.ClientID
        , db.UnitID
        , db.CreatedAt
        , CASE
             WHEN gp.actual_percent_completed IS NULL THEN 'Not Started'
             WHEN gp.actual_percent_completed >= 100 THEN 'Completed'
             ELSE 'In Progress'
            END AS actual_status
        , db.planned_start_date
        , CASE WHEN gp.actual_percent_completed IS NOT NULL
                 THEN db.actual_start_date ELSE NULL END AS actual_start_date
        , gp.actual_percent_completed
        , CASE WHEN gp.actual_percent_completed >= 100
                 THEN db.actual_end_date ELSE NULL END AS actual_end_date
        , gp.total_hours_to_date
    FROM datamart_base db JOIN get_actual_progress gp
    WHERE db.t = gp.t
        AND db.ProjectID = gp.ProjectID
    ORDER BY db.t
)
,

add_flags_and_fields AS (
    SELECT
        *
        , CASE WHEN actual_start_date > planned_start_date THEN 1 ELSE 0 END AS if_late_start_flag
        , julianday(t) - julianday(actual_start_date)  AS duration
        , (julianday(t) - julianday(actual_start_date))/(actual_percent_completed*0.01) AS forcasted_duration
        , CASE WHEN actual_status = 'Completed' THEN 1 ELSE 0 END AS is_last_update_flag
    FROM correct_base_by_progress
    ORDER BY
        t
)

SELECt *,
       date(actual_start_date, '+'
               || CAST((-1 * CAST(-1 * forcasted_duration AS INTEGER) + (forcasted_duration != CAST(forcasted_duration AS INTEGER))) AS INTEGER)
               || ' days') AS new_date
FROM add_flags_and_fields

--     ProjectID
;