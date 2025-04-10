-- Active: 1744047474754@@127.0.0.1@3306
SELECT
    p.projectID,
    p.name,
    strftime('%Y-%m', cd.date) AS month,
    SUM(cd.hours) AS hours_expended,
    SUM(pe.amount) AS expenses_to_date
FROM Project p
JOIN Deliverable d ON p.projectID = d.projectID
JOIN ConsultantDeliverable cd ON cd.deliverableID = d.deliverableID
JOIN ProjectExpense pe ON p.projectID = pe.projectID
    AND strftime('%Y-%m', pe.date) = strftime('%Y-%m', cd.date)
GROUP BY p.projectID, p.name, month
ORDER BY month;
