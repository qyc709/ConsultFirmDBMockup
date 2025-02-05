WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT 'T' || "TitleID" AS titleID,
    "Title" AS "title_name"
FROM "Title"