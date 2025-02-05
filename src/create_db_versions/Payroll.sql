-- '2020-07-01'
WITH get_date AS (
    SELECT DATE(?, '-1 day') AS my_date
)
SELECT
    "ConsultantID" AS "consultantID",
    "Amount" AS "amount",
    "EffectiveDate" AS "payment_date"
FROM "Payroll"
WHERE "EffectiveDate" < DATE((SELECT * FROM get_date), '+1 day')
;