-- '2020-07-01'
SELECT 
    "ClientID" AS "clientID",
    "ClientName" AS "client_name",
    "LocationID" AS "locationID",
    "PhoneNumber" AS "phone_number",
    "Email" AS "email",
    DATETIME(?, '-1 day') AS "last_update"
FROM "Client"
;