-- '2020-07-01'
SELECT
    "ProjectExpenseID" AS "ID",
    "ProjectID" AS "project_tmp_id",
    "DeliverableID" AS "deliverable_tmp_id",
    "Date" AS "date",
    "Amount" AS "amount",
    "Description" AS "description",
    "Category" AS "category",
    "IsBillable" AS "is_billable"
FROM "ProjectExpense"
WHERE "Date" < ?
;