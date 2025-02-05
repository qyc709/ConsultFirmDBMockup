WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT 
    "BusinessUnitID" AS "businessUnitID",
    "BusinessUnitName" AS "business_unit_name"
FROM "BusinessUnit"