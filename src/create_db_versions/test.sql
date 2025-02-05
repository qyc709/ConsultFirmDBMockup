DROP TABLE IF EXISTS tmp_project;
CREATE TABLE tmp_project AS
SELECT * FROM Project;


DROP VIEW IF EXISTS Deliverable_new;
CREATE VIEW Deliverable_new AS
SELECT 
    d."deliverableID",
    p."projectID", 
    d.name,
    d.created_at,
    d.price,
    d.planned_start_date,
    d.actual_start_date,
    d.planned_hours,
    d.due_date,
    d.status,
    d.progress,
    d.actual_start_date,
    d.invoiced_date,
    d.last_update
FROM "Deliverable" d
    LEFT JOIN "Project" p ON d.project_tmp_id = p.project_tmp_id;


DROP VIEW IF EXISTS ConsultantDeliverable_new;
CREATE VIEW ConsultantDeliverable_new AS
SELECT "recordID",
    "consultantID",
    d."deliverableID",
    cd."date",
    cd.hours, 
    cd.last_update
FROM "ConsultantDeliverable" cd
    LEFT JOIN "Deliverable" d ON cd.deliverable_tmp_id = d.deliverable_tmp_id


DROP VIEW IF EXISTS ProjectExpense_new;
CREATE VIEW ProjectExpense_new AS
SELECT 
    "expenseRecordID",
    p."projectID",
    d."deliverableID",
    pe."date",
    pe.amount,
    pe.description,
    pe.category,
    pe.is_billable
FROM "ProjectExpense" pe
    LEFT JOIN Project p ON p.project_tmp_id = pe.project_tmp_id
    LEFT JOIN "Deliverable" d ON d.deliverable_tmp_id = pe.deliverable_tmp_id
    ;


DROP TABLE IF EXISTS ProjectTeam_new;
CREATE TABLE ProjectTeam_new AS
SELECT p."projectID", pt."consultantID", pt.role, pt.start_date, pt.end_date
FROM "ProjectTeam" pt
    LEFT JOIN "tmp_project" p ON pt.project_tmp_id = p.project_tmp_id;

CREATE TABLE "ProjectTeam" (
  "project_tmp_id" INTEGER, 
  "consultantID" VARCHAR, 
  "role" VARCHAR, 
  "start_date" DATE, 
  "end_date" DATE, 
  PRIMARY KEY(projectID, consultantID)
  FOREIGN KEY("ProjectID") REFERENCES "project" ("ProjectID"), 
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID")
);


DROP VIEW IF EXISTS ProjectBillingRate_new;
CREATE VIEW ProjectBillingRate_new AS
SELECT p."projectID", pbr."titleID", pbr.rate
FROM "ProjectBillingRate" pbr
    LEFT JOIN "Project" p ON pbr.project_tmp_id = p.project_tmp_id;


--------------------------------------------------------------------
DROP TABLE IF EXISTS Project_new;
CREATE TABLE Project_new (
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
    "last_update" DATETIME,
    FOREIGN KEY("clientID") REFERENCES "Client" ("clientID"), 
    FOREIGN KEY("unitID") REFERENCES "BusinessUnit" ("businessUnitID")
);

INSERT INTO Project_new
SELECT "projectID", created_at, "clientID", "unitID", name, type, price, estimated_budget, planned_hours, planned_start_date,
    planned_end_date, status, actual_start_date, actual_end_date, progress, last_update
FROM Project;

-- DROP TABLE Project;

-- ALTER TABLE Project_new RENAME TO Project;


--------------------------------------------------------------------
CREATE TABLE "Deliverable_new" (
  "deliverableID" TEXT PRIMARY KEY,
  "deliverable_tmp_id" INTEGER,
  "project_tmp_id" INTEGER, 
  "name" VARCHAR,
  "created_at" DATETIME,
  "price" FLOAT, 
  "planned_start_date" DATE, 
  "actual_start_date" DATE, 
  "planned_hours" FLOAT, 
  "due_date" DATE, 
  "status" VARCHAR, 
  "progress" INTEGER, 
  "submission_date" DATE, 
  "invoiced_date" DATE,
  "last_update" DATETIME
  FOREIGN KEY("ProjectID") REFERENCES "project" ("ProjectID")
);

