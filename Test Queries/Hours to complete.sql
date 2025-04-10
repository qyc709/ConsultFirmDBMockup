-- Active: 1744047474754@@127.0.0.1@3306
SELECT
    d.projectID,
    p.name,
    strftime('%Y-%m', cd.date) AS month,
    p.progress,
    p.planned_hours,
--------------------------
    p.planned_hours - SUM(cd.hours) AS planned_hours_to_complete
--------------------------
FROM Deliverable d
JOIN Project p ON d.projectID = p.projectID
JOIN ConsultantDeliverable cd ON d.deliverableID = cd.deliverableID
GROUP BY d.projectID, p.name, month
ORDER BY month;
