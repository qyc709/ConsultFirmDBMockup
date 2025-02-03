DROP TABLE IF EXISTS project;

CREATE TABLE "project" (
"projectID" TEXT PRIMARY KEY,
  "created_at" DATETIME,
  "clientID" INTEGER,
  "unitID" INTEGER,
  "name" VARCHAR,
  "type" VARCHAR,
  "price" FLOAT,
  "estimated_budget" FLOAT,
  "planned_hours" INTEGER,
  "planned_start_date" DATE,
  "planned_end_date" DATE,
  "status" VARCHAR,
  "actual_start_date" DATE,
  "actual_end_date" DATE,
  "progress" FLOAT,
  "last_update" DATETIME
--   FOREIGN KEY("clientID") REFERENCES "Client" ("ClientID"), 
--   FOREIGN KEY("unitID") REFERENCES "BusinessUnit" ("BusinessUnitID")
);

CREATE TRIGGER generate_project_id
AFTER INSERT ON project
FOR EACH ROW
WHEN NEW.projectID IS NULL
BEGIN
    UPDATE project
    SET projectID = 'PROJ-' || substr(hex(randomblob(4)), 1, 4)
    WHERE rowid = NEW.rowid;
END;