WITH MonthlyExpenses AS (
    SELECT
        pe.projectID,
        strftime('%Y-%m', pe.date) AS month,
        SUM(pe.amount) AS expense_amount
    FROM ProjectExpense pe
    JOIN Project p ON p.projectID = pe.projectID
    WHERE p.type = 'Fixed'
    GROUP BY pe.projectID, month
),
MonthlyPayroll AS (
    SELECT
        pt.projectID,
        strftime('%Y-%m', py.payment_date) AS month,
        SUM(py.amount) AS payroll_amount
    FROM Payroll py
    JOIN ProjectTeam pt ON py.consultantID = pt.consultantID
    GROUP BY pt.projectID, month
),
DeliverableRevenue AS (
    SELECT
        d.projectID,
        SUM(d.price) AS revenue
    FROM Deliverable d
    JOIN Project p ON d.projectID = p.projectID
    WHERE d.Status is 'Completed'
    GROUP BY d.projectID
)
SELECT
    p.projectID,
    p.name,
    me.month,
    p.price AS contract_value,
    ROUND(dr.revenue, 2) AS revenue_to_date,
    ROUND((COALESCE(mp.payroll_amount, 0) + COALESCE(me.expense_amount, 0))/30,2) AS costs_per_day,
    ROUND(
        (100.0 / p.progress) * (COALESCE(mp.payroll_amount, 0) + COALESCE(me.expense_amount, 0)) , 2)
        AS expected_costs_at_completion,
    ROUND(
        p.price - (
            (100.0 / p.progress) * (COALESCE(mp.payroll_amount, 0) + COALESCE(me.expense_amount, 0))
        ),
        2
    ) AS expected_profit
FROM Project p
JOIN DeliverableRevenue dr ON p.projectID = dr.projectID
JOIN MonthlyExpenses me ON p.projectID = me.projectID
JOIN MonthlyPayroll mp ON p.projectID = mp.projectID AND mp.month = me.month
WHERE p.type = 'Fixed'
ORDER BY p.projectID, me.month;
