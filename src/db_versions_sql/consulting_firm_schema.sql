-- TABLE DEFINITION ORDER according to foreign key relationship
-- Location
-- Client
-- BusinessUnit
-- Project
-- Deliverable
-- Consultant
-- Title
-- ConsultantTitleHistory
-- ConsultantDeliverable
-- ProjectExpense
-- ProjectTeam
-- Payroll
-- ProjectBillingRate


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Location";
CREATE TABLE "Location" (
  "locationID" INTEGER PRIMARY KEY, 
  "state" VARCHAR, 
  "city" VARCHAR
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Client";
CREATE TABLE "Client" (
  "clientID" INTEGER PRIMARY KEY, 
  "client_name" VARCHAR, 
  "locationID" INTEGER, 
  "phone_number" VARCHAR, 
  "email" VARCHAR,
  "last_update" DATETIME,
  FOREIGN KEY("locationID") REFERENCES "Location" ("locationID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "BusinessUnit";
CREATE TABLE "BusinessUnit" (
  "businessUnitID" INTEGER PRIMARY KEY, 
  "business_unit_name" VARCHAR
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Project";
CREATE TABLE "Project" (
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


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Deliverable";
CREATE TABLE "Deliverable" (
  "deliverableID" TEXT PRIMARY KEY,
  "projectID" TEXT,
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
  "last_update" DATETIME,
  FOREIGN KEY("ProjectID") REFERENCES "Project" ("ProjectID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Consultant";
CREATE TABLE "Consultant" (
  "consultantID" VARCHAR PRIMARY KEY, 
  "businessUnitID" INTEGER, 
  "first_name" VARCHAR, 
  "last_name" VARCHAR, 
  "email" VARCHAR, 
  "contact" VARCHAR, 
  "hire_year" INTEGER,
  "last_update" DATETIME,
  FOREIGN KEY("businessUnitID") REFERENCES "BusinessUnit" ("businessUnitID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Title";
CREATE TABLE "Title" (
"titleID" VARCHAR PRIMARY KEY, 
"title_name" VARCHAR
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "ConsultantTitleHistory";
CREATE TABLE "ConsultantTitleHistory" (
  "recordID" TEXT PRIMARY KEY, 
  "consultantID" VARCHAR, 
  "titleID" INTEGER, 
  "start_date" DATE, 
  "event_type" VARCHAR, 
  "salary" INTEGER, 
  "last_update" DATETIME,
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID"), 
  FOREIGN KEY("titleID") REFERENCES "Title" ("titleID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "ConsultantDeliverable";
CREATE TABLE "ConsultantDeliverable" (
  "recordID" TEXT PRIMARY KEY, 
  "consultantID" VARCHAR, 
  "deliverableID" TEXT, 
  "date" DATE, 
  "hours" INTEGER,
  "last_update" DATETIME,
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID"),
  FOREIGN KEY("deliverableID") REFERENCES "Deliverable" ("deliverableID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "ProjectExpense";
CREATE TABLE "ProjectExpense" (
  "recordID" TEXT PRIMARY KEY, 
  "projectID" TEXT, 
  "deliverableID" TEXT,
  "date" DATE, 
  "amount" FLOAT, 
  "description" VARCHAR, 
  "category" VARCHAR, 
  "is_billable" BOOLEAN,
  FOREIGN KEY("projectID") REFERENCES "Project" ("projectID"), 
  FOREIGN KEY("deliverableID") REFERENCES "Deliverable" ("deliverableID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "ProjectTeam";
CREATE TABLE "ProjectTeam" (
  "projectID" INTEGER, 
  "consultantID" VARCHAR, 
  "role" VARCHAR, 
  "start_date" DATE, 
  "end_date" DATE, 
  PRIMARY KEY(projectID, consultantID, role)
  FOREIGN KEY("projectID") REFERENCES "Project" ("projectID"), 
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "Payroll";
CREATE TABLE "Payroll" (
  "recordID" TEXT PRIMARY KEY, 
  "consultantID" VARCHAR, 
  "amount" FLOAT, 
  "payment_date" DATE, 
  FOREIGN KEY("consultantID") REFERENCES "Consultant" ("consultantID")
);


--------------------------------------------------------------------
DROP TABLE IF EXISTS "ProjectBillingRate";

CREATE TABLE "ProjectBillingRate" (
  "projectID" TEXT, 
  "titleID" VARCHAR, 
  "rate" FLOAT,  
  PRIMARY KEY(projectID, titleID),
  FOREIGN KEY("ProjectID") REFERENCES "Project" ("ProjectID"), 
  FOREIGN KEY("titleID") REFERENCES "Title" ("titleID")
);