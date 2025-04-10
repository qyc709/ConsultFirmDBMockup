-- Active: 1743006896197@@127.0.0.1@3306
WITH ConsultantTitle AS (
    SELECT
        p.projectID,
        pt.consultantID,
        ct.titleID
    FROM ProjectTeam pt
    JOIN Project p ON pt.projectID = p.projectID
    JOIN Consultant c ON pt.consultantID = c.consultantID
    JOIN ConsultantTitleHistory ct ON ct.consultantID = c.consultantID
    JOIN Title t ON ct.titleID = t.titleID
),
PersonalRevenue AS (
    SELECT
        strftime('%Y-%m', cd.date) AS month,
        p.projectID,
        cd.consultantID,
        ct.titleID,
        cd.hours,
        pbr.rate,
        cd.hours * COALESCE(pbr.rate, 0) AS person_revenue
    FROM Project p
    JOIN ProjectBillingRate pbr ON p.projectID = pbr.ProjectID
    JOIN ConsultantTitle ct ON p.projectID = ct.projectID
    JOIN ConsultantDeliverable cd ON ct.consultantID = cd.consultantID
    WHERE p.type = 'Time and Material'
    GROUP BY month, p.projectID, cd.consultantID
),
TimeAndMaterialRevenue AS (
    SELECT
        pr.month,
        bu.BusinessUnitID,
        p.projectID,
        SUM(pr.person_revenue) AS monthly_revenue
    FROM PersonalRevenue pr
    JOIN Project p ON pr.projectID = p.projectID
    JOIN BusinessUnit bu ON p.unitID = bu.businessUnitID
    GROUP BY pr.month, p.ProjectID
),
FixedRevenue AS (
    SELECT
        strftime('%Y-%m', cd.date) AS month,
        bu.BusinessUnitID,
        p.projectID,
        SUM(d.price) AS monthly_revenue
    FROM Deliverable d
    JOIN Project p ON d.projectID = p.projectID
    JOIN ConsultantDeliverable cd ON d.deliverableID = cd.deliverableID
    JOIN BusinessUnit bu ON p.unitID = bu.businessUnitID
    WHERE d.Status = 'Completed' 
      AND p.Type = 'Fixed' 
      AND strftime('%Y-%m', d.actual_start_date) = strftime('%Y-%m', cd.date)
    GROUP BY month, p.ProjectID
),
MonthlyRevenue AS (
    SELECT *
    FROM TimeAndMaterialRevenue tmr
    UNION
    SELECT *
    FROM FixedRevenue fr
),
TotalRevenueExpensePerProject AS (
    SELECT
        p.projectID,
        SUM(monthly_revenue) AS total_revenue,
        SUM(monthly_revenue)/p.Progress *(100-p.Progress) AS forecasted_revenue,
        SUM(pe.amount) AS total_expense,
        SUM(pe.amount) /p.Progress *(100-p.Progress) AS forecasted_expense
    FROM MonthlyRevenue
    JOIN Project p ON MonthlyRevenue.projectID = p.projectID
    JOIN ProjectExpense pe ON p.projectID = pe.projectID
    WHERE month BETWEEN '2024-01' AND '2024-03'
    GROUP BY p.projectID
),
RevenueExpense As(
    SELECT
        mr.month,
        mr.BusinessUnitID,
        mr.projectID,
        mr.monthly_revenue,
        tre.total_revenue,
        tre.forecasted_revenue,
        tre.total_expense,
        tre.forecasted_expense,
        (tre.forecasted_revenue - tre.forecasted_expense) AS forecasted_profit
    FROM MonthlyRevenue mr
    JOIN TotalRevenueExpensePerProject tre ON mr.projectID = tre.projectID
    WHERE mr.month = '2024-03'
    ORDER BY mr.projectID, mr.month
)
SELECT
    month,
    BusinessUnitID,
    SUM(monthly_revenue) AS monthly_revenue,
    SUM(total_revenue) AS total_revenue,
    SUM(forecasted_revenue) AS forecasted_revenue,
    SUM(forecasted_expense) AS forecasted_expense,
    SUM(forecasted_profit) AS forecasted_profit
FROM RevenueExpense
GROUP BY BusinessUnitID
