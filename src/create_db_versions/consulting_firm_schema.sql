-- Active: 1738621468737@@127.0.0.1@3306
-- TABLE DEFINITION ORDER due to foreign key relationship
-- Location
-- Client
-- BusinessUnit
-- Project
-- Deliverable
-- ProjectExpense
-- Consultant
-- Consultant_Deliverable
-- ProjectTeam
-- Title
-- Consultant_Title_History
-- Payroll
-- ProjectBillingRate


DROP TABLE IF EXISTS "Location";

CREATE TABLE "Location" (
  "locationID" INTEGER PRIMARY KEY, 
  "state" VARCHAR, 
  "city" VARCHAR
);

DROP TABLE IF EXISTS "Client";
CREATE TABLE "Client" (
  "clientID" INTEGER PRIMARY KEY, 
  "client_name" VARCHAR, 
  "locationID" INTEGER, 
  "phone_number" VARCHAR, 
  "email" VARCHAR
  -- FOREIGN KEY("LocationID") REFERENCES "Location" ("LocationID")
);

DROP TABLE IF EXISTS "BusinessUnit";
CREATE TABLE "BusinessUnit" (
  "businessUnitID" INTEGER PRIMARY KEY, 
  "business_unit_name" VARCHAR
);

DROP TABLE IF EXISTS "Project";
CREATE TABLE "Project" (
  "projectID" TEXT PRIMARY KEY, 
  "project_tmp_id" INTEGER,
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

DROP TABLE IF EXISTS "Deliverable";
CREATE TABLE "Deliverable" (
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
  -- FOREIGN KEY("ProjectID") REFERENCES "Project" ("ProjectID")
);

CREATE TRIGGER generate_deliverable_id
AFTER INSERT ON deliverable
FOR EACH ROW
WHEN NEW.deliverableID IS NULL
BEGIN
    UPDATE deliverable
    SET deliverableID = 'DEL-' || substr(hex(randomblob(4)), 1, 4)
    WHERE rowid = NEW.rowid;
END;