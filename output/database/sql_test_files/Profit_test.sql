SELECT a.ProjectID, a.total_hours, b.total_actualhours_byd, c.hours_by_project, c.Progress
    FROM (
        SELECT D.ProjectID, SUM(CD.Hours) as total_hours
        FROM Consultant_Deliverable CD
            LEFT JOIN Deliverable D ON CD.DeliverableID = D.DeliverableID
        GROUP BY D.ProjectID
         ) a
    INNER JOIN (
        SELECT ProjectID, SUM(ActualHours) as total_actualhours_byd
        FROM Deliverable
        GROUP BY ProjectID
    ) b
    ON a.ProjectID = b.ProjectID
    INNER JOIN (
        SELECT ProjectID, ActualHours as hours_by_project, Progress
        FROM Project
    ) c
    ON a.ProjectID = c.ProjectID;

-- Consultant hours per project per month
SELECT CD.ConsultantID, D.ProjectID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours)
    FROM Consultant_Deliverable CD
        LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
    GROUP BY CD.ConsultantID, D.ProjectID, month
    ORDER BY ConsultantID, month;

SELECT * FROM Consultant_Deliverable
ORDER BY ConsultantID, Date;

--------------------------------------
-- Consultant hours per month
SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours)
    FROM Consultant_Deliverable CD
        LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
    GROUP BY CD.ConsultantID, month;
--------------------------------------

-- Consultant hours per day
SELECT ConsultantID, Date, SUM(Hours)
FROM Consultant_Deliverable
GROUP BY ConsultantID, Date;


-------------------------------------------------------------------------
---------------------------- Main query ---------------------------------
-- 1. total hours per consultant per day (H1)
-- 2. total hours per consultant per month (H2)
-- 3. match consultant monthly hours with salary
--
--
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------
With main_table AS (
    SELECT H1.ConsultantID, H1.Date, H1.day_hours/H2.month_hours AS day_hours_percentage, P.Amount AS Salary
    FROM (
        -- Consultant hours per day
        SELECT ConsultantID, Date, SUM(Hours) as day_hours
        FROM Consultant_Deliverable
        GROUP BY ConsultantID, Date
         ) H1
        LEFT JOIN (
        -- Consultant hours per month
        SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours) month_hours
        FROM Consultant_Deliverable CD
            LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
        GROUP BY CD.ConsultantID, month
        ) H2 ON H1.ConsultantID = H2.ConsultantID AND STRFTIME('%Y-%m', H1.Date) = H2.month
        LEFT JOIN Payroll P ON H1.ConsultantID = P.ConsultantID AND STRFTIME('%Y-%m', EffectiveDate) = H2.month
--     ;
)
-------------------------------------------------------------------------

-- SELECT COUNT(*) as a
-- FROM main_table
-- WHERE Salary ISNULL
-- ;


-- Count all working months without salary
-- SELECT N1.a, N2.b, round(CAST(a as float)/CAST(b as float), 2) as salary_null_percentage
--     FROM (
--         SELECT COUNT(*) as a
--         FROM main_table
--         WHERE Salary ISNULL
--          ) N1,
--         (
--         SELECT COUNT(*) as b
--         FROM main_table
--         ) N2
-- ;

-- Check all months has payroll without work
SELECT P.*, H1.monthly_working_hours
    FROM Payroll P
    LEFT JOIN
        (
            SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours) as monthly_working_hours
            FROM Consultant_Deliverable CD
                LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
            GROUP BY CD.ConsultantID, month
        ) H1 ON P.ConsultantID = H1.ConsultantID AND STRFTIME('%Y-%m', P.EffectiveDate) = H1.month
    WHERE monthly_working_hours IS NULL
    ORDER BY P.ConsultantID, P.EffectiveDate;

-- Check percentage of data has payroll without work
SELECT N1.a, N2.b, round(CAST(b as float)/CAST(a as float), 2) as hours_null_percentage
    FROM (
        SELECT COUNT(*) as a
        FROM Payroll P
        LEFT JOIN
            (
                SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours) as monthly_working_hours
                FROM Consultant_Deliverable CD
                    LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
                GROUP BY CD.ConsultantID, month
            ) H1 ON P.ConsultantID = H1.ConsultantID AND STRFTIME('%Y-%m', P.EffectiveDate) = H1.month
         ) N1,
        (
            SELECT COUNT(*) as b
            FROM Payroll P
            LEFT JOIN
                (
                    SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours) as monthly_working_hours
                    FROM Consultant_Deliverable CD
                        LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
                    GROUP BY CD.ConsultantID, month
                ) H1 ON P.ConsultantID = H1.ConsultantID AND STRFTIME('%Y-%m', P.EffectiveDate) = H1.month
            WHERE monthly_working_hours IS NULL
        ) N2;


-- Project Expenses
SELECT ProjectID, Date, SUM(Amount) as total_expenses
FROM ProjectExpense
-- WHERE IsBillable = 1
GROUP BY ProjectID, Date;

SELECT *
FROM ProjectExpense
-- WHERE IsBillable = 1
ORDER BY ProjectID, Date
;

-- check project expense rationality
With get_date AS(
    SELECT ProjectID,
           ProjectExpenseID,
           Date,
           ROW_NUMBER() OVER (PARTITION BY ProjectID ORDER BY Date) AS first_expense,
           ROW_NUMBER() OVER (PARTITION BY ProjectID ORDER BY Date DESC) AS last_expense
    FROM ProjectExpense
)

        SELECT ProjectID,
               MIN(CASE WHEN first_expense = 1 THEN Date END) AS first_date,
               MIN(CASE WHEN first_expense = 1 THEN ProjectExpenseID END) AS first_expense_id,
               MIN(CASE WHEN last_expense = 1 THEN Date END) AS last_date,
               MIN(CASE WHEN last_expense = 1 THEN ProjectExpenseID END) AS last_expense_id
        FROM get_date
        WHERE first_expense = 1 OR last_expense = 1
        GROUP BY ProjectID;

---------------------------------------------------------------------------

SELECT expense_date.ProjectID, expense_date.first_date, expense_date.last_date, P.ActualStartDate, P.ActualEndDate,
       (CASE
--            First expense after project starts and last expense before project ends or enddate is null
           WHEN (expense_date.first_date >= P.ActualStartDate AND expense_date.last_date <= IFNULL(P.ActualEndDate, '9999-12-31')) THEN 1
--            expense before the project starts
           WHEN (expense_date.first_date IS NOT NULL AND P.ActualStartDate IS NULL) THEN 'NULL'
           ELSE 0 END) AS rationality
FROM (
        SELECT ProjectID,
               MIN(Date) as first_date,
               MAX(Date) as last_date
        FROM ProjectExpense
        GROUP BY ProjectID
     ) expense_date
    LEFT JOIN Project P on expense_date.ProjectID = P.ProjectID
WHERE rationality = 0 OR rationality IS NULL;


-- check consultants unit and business unit consistency
SELECT DISTINCT P.ProjectID, P.UnitID, CD.DeliverableID, CD.ConsultantID, C.BusinessUnitID
FROM Project P
    LEFT JOIN Deliverable D ON P.ProjectID = D.ProjectID
    LEFT JOIN Consultant_Deliverable CD ON D.DeliverableID = CD.DeliverableID
    LEFT JOIN Consultant C ON CD.ConsultantID = C.ConsultantID
WHERE P.UnitID != C.BusinessUnitID;



SELECT ProjectID, UnitID
FROM Project
WHERE UnitID <> 1;


SELECT DISTINCT D.ProjectID, D.Name, D.Status, C.ConsultantID
FROM Deliverable D
LEFT JOIN main.Consultant_Deliverable C on D.DeliverableID = C.DeliverableID
ORDER BY D.ProjectID;

-- Attrition consultant hiring history
SELECT *
FROM Consultant_Title_History
WHERE Consultant_Title_History.ConsultantID in (SELECT C.ConsultantID
                    FROM Consultant_Title_History C
                    WHERE C.EventType = 'Attrition')
ORDER BY ConsultantID;


-- Attrition consultant working history
SELECT *
FROM Consultant_Deliverable
WHERE Consultant_Deliverable.ConsultantID in (SELECT C.ConsultantID
                    FROM Consultant_Title_History C
                    WHERE C.EventType = 'Attrition');

-- Attrition consultant payroll history
SELECT *
FROM Payroll
WHERE Payroll.ConsultantID in (SELECT C.ConsultantID
                    FROM Consultant_Title_History C
                    WHERE C.EventType = 'Attrition');

SELECT DISTINCT ConsultantID, TitleID, StartDate, EndDate
FROM Consultant_Title_History;

