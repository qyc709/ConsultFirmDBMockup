-- '2020-07-01'
WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT 
    "ConsultantID" AS "consultantID",
    "BusinessUnitID" AS "businessUnitID",
    "FirstName" AS "first_name",
    "LastName" AS "last_name",
    "Email" AS "email",
    "Contact" AS "contact",
    "HireYear" AS "hire_year",
    DATETIME((SELECT * FROM get_date)) AS "last_update"
FROM "Consultant"
WHERE "ConsultantID" IN (
    SELECT "ConsultantID"
    FROM "Consultant_Title_History"
    WHERE "StartDate" < DATE((SELECT * FROM get_date), '+1 day')
)
;