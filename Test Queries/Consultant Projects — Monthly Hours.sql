SELECT
    c.consultantID,
    c.first_name || ' ' || c.last_name AS consultant_name,
    p.name AS project_name,
    strftime('%Y-%m', cd.date) AS month,
    SUM(cd.hours) AS hours_worked
FROM Consultant c
JOIN ConsultantDeliverable cd ON c.consultantID = cd.consultantID
JOIN Deliverable d ON cd.deliverableID = d.deliverableID
JOIN Project p ON d.projectID = p.projectID
GROUP BY c.consultantID, p.name, month
ORDER BY c.consultantID, month;
