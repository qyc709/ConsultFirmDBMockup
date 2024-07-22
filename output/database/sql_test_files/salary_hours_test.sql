-- Work without salary
SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours), P.EffectiveDate, P.Amount
FROM Consultant_Deliverable CD
        LEFT JOIN Payroll P ON CD.ConsultantID = P.ConsultantID AND STRFTIME('%Y-%m', CD.Date) = STRFTIME('%Y-%m', EffectiveDate)
WHERE P.Amount IS NULL
GROUP BY CD.ConsultantID, month;


-- Salary without work
SELECT P.*, H1.monthly_working_hours
    FROM Payroll P
    LEFT JOIN
        (
            SELECT CD.ConsultantID, STRFTIME('%Y-%m', CD.Date) as month, SUM(CD.Hours) as monthly_working_hours
            FROM Consultant_Deliverable CD
                LEFT JOIN Deliverable D on D.DeliverableID = CD.DeliverableID
            GROUP BY CD.ConsultantID, month
        ) H1 ON P.ConsultantID = H1.ConsultantID AND STRFTIME('%Y-%m', P.EffectiveDate) = H1.month
    WHERE H1.monthly_working_hours IS NULL
    ORDER BY P.ConsultantID, P.EffectiveDate;