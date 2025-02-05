-- Active: 1738621468737@@127.0.0.1@3306

--------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_project;
CREATE TABLE tmp_project AS
SELECT * FROM Project;


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

DROP TABLE Project;

ALTER TABLE Project_new RENAME TO Project;


--------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_deilverable;
CREATE TABLE tmp_deliverable AS
SELECT * FROM "Deliverable";

DROP TABLE IF EXISTS Deliverable_new;

CREATE TABLE Deliverable_new (
  "deliverableID" TEXT PRIMARY KEY,
  "projectID" INTEGER, 
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
  FOREIGN KEY("projectID") REFERENCES "Project" ("projectID")
);

INSERT INTO Deliverable_new
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

DROP TABLE "Deliverable";

ALTER TABLE Deliverable_new RENAME TO "Deliverable";


--------------------------------------------------------------------
DROP TABLE IF EXISTS ConsultantDeliverable_new;

CREATE TABLE ConsultantDeliverable_new (
  "recordID" TEXT PRIMARY KEY, 
  "consultantID" VARCHAR, 
  "deliverableID" TEXT, 
  "date" DATE, 
  "hours" INTEGER,
  "last_update" DATETIME,
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID")
  FOREIGN KEY("deliverableID") REFERENCES "Deliverable" ("deliverableID")
);

INSERT INTO ConsultantDeliverable_new
SELECT "recordID",
    "consultantID",
    d."deliverableID",
    cd."date",
    cd.hours, 
    cd.last_update
FROM "ConsultantDeliverable" cd
    LEFT JOIN tmp_deilverable d ON cd.deliverable_tmp_id = d.deliverable_tmp_id

DROP TABLE ConsultantDeliverable;

ALTER TABLE ConsultantDeliverable_new RENAME TO ConsultantDeliverable;


--------------------------------------------------------------------
DROP TABLE IF EXISTS ProjectExpense_new;

CREATE TABLE ProjectExpense_new (
  "expenseRecordID" TEXT PRIMARY KEY, 
  "projecID" TEXT, 
  "deliverableID" TEXT, 
  "date" DATE, 
  "amount" FLOAT, 
  "description" VARCHAR, 
  "category" VARCHAR, 
  "is_billable" BOOLEAN
  FOREIGN KEY("projectID") REFERENCES "Project" ("projectID"), 
  FOREIGN KEY("deliverableID") REFERENCES "Deliverable" ("deliverableID")
);

INSERT INTO ProjectExpense_new
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
    LEFT JOIN tmp_project p ON p.project_tmp_id = pe.project_tmp_id
    LEFT JOIN tmp_deilverable d ON d.deliverable_tmp_id = pe.deliverable_tmp_id
;

DROP TABLE ProjectExpense;

ALTER TABLE ProjectExpense_new RENAME TO ProjectExpense;


--------------------------------------------------------------------
DROP TABLE IF EXISTS ProjectTeam_new;

CREATE TABLE "ProjectTeam_new" (
  "projectID" INTEGER, 
  "consultantID" VARCHAR, 
  "role" VARCHAR, 
  "start_date" DATE, 
  "end_date" DATE, 
  PRIMARY KEY(projectID, consultantID, role)
  FOREIGN KEY("projectID") REFERENCES "Project" ("projectID"), 
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID")
);

INSERT INTO ProjectTeam_new
SELECT p."projectID", pt."consultantID", pt.role, pt.start_date, pt.end_date
FROM "ProjectTeam" pt
    LEFT JOIN "tmp_project" p ON pt.project_tmp_id = p.project_tmp_id;

DROP TABLE ProjectTeam;

ALTER TABLE ProjectTeam_new RENAME TO ProjectTeam;


--------------------------------------------------------------------
DROP TABLE IF EXISTS ProjectBillingRate_new;

CREATE TABLE ProjectBillingRate_new (
  "projectID" TEXT, 
  "titleID" VARCHAR, 
  "rate" FLOAT,  
  PRIMARY(projectID, titleID)
  FOREIGN KEY("ProjectID") REFERENCES "Project" ("ProjectID"), 
  FOREIGN KEY("titleID") REFERENCES "Title" ("titleID")
);

INSERT INTO ProjectBillingRate_new
SELECT p."projectID", pbr."titleID", pbr.rate
FROM "ProjectBillingRate" pbr
    LEFT JOIN tmp_project p ON pbr.project_tmp_id = p.project_tmp_id;

DROP TABLE ProjectBillingRate;

ALTER TABLE ProjectBillingRate_new RENAME TO ProjectBillingRate;