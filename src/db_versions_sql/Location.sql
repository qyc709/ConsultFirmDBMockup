WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT "LocationID" AS "locationID",
    State AS "state",
    "City" AS "city"
FROM "Location"
;