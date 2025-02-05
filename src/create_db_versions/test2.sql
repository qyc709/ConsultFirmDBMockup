-- Active: 1738621468737@@127.0.0.1@3306

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

SELECT *
FROM "ProjectTeam" pt
    LEFT JOIN "Project" p ON pt.project_tmp_id = p.project_tmp_id;