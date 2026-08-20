-- ============================================================
-- 02_pack2_logic_process.sql — WHAT THE SYSTEM DOES (pillar-agnostic)
-- Sensitivity: low (business logic, no person data)
-- ============================================================

-- 2.1 PeopleCode INVENTORY (where code lives, how big, who touched it)
-- Source text is tokenized in PSPCMPROG; export the inventory here,
-- and pull source via App Designer "Copy Project to File" (see README).
SELECT OBJECTVALUE1, OBJECTVALUE2, OBJECTVALUE3, OBJECTVALUE4,
       OBJECTID1, OBJECTID2, OBJECTID3, OBJECTID4,
       PROGLEN, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPCMPROG;

-- 2.2 SQL objects (views, AE SQL, SQL definitions) — full text
SELECT * FROM PSSQLDEFN;
SELECT * FROM PSSQLTEXTDEFN;   -- the SQL text itself, chunked; reassemble on SQLID+SEQNUM

-- 2.3 Application Engine programs (batch logic)
SELECT * FROM PSAEAPPLDEFN;    -- programs
SELECT * FROM PSAESECTDEFN;    -- sections
SELECT * FROM PSAESTEPDEFN;    -- steps
SELECT * FROM PSAESTMTDEFN;    -- step statements (join text via PSSQLTEXTDEFN)

-- 2.4 Process Scheduler definitions (every batch process & job)
SELECT * FROM PSPRCSDEFN;      -- processes (SQR, AE, COBOL, XMLP...)
SELECT * FROM PSJOBDEFN;       -- jobs (chains of processes)
SELECT * FROM PS_PRCSDEFNPNL;  -- process-to-component linkage, if present (existence-guard: skip if absent)

-- 2.5 Queries (the shadow reporting estate)
SELECT * FROM PSQRYDEFN;       -- all queries, public and private, incl. owner
SELECT * FROM PSQRYRECORD;     -- records each query reads
SELECT * FROM PSQRYFIELD;
SELECT * FROM PSQRYCRITERIA;

-- 2.6 Approval Workflow Engine — CONFIGURED APPROVAL ROUTES
-- Table names vary slightly by release: export EVERY table found by the
-- 00_discovery EOAW family scan. Typical members include process
-- definitions, stages, paths, steps, criteria, and user lists.
-- Generator (Oracle) — produces one extract statement per family table:
SELECT 'SELECT * FROM ' || TABLE_NAME || ';' AS EXTRACT_STMT
  FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PS_EOAW%' OR TABLE_NAME LIKE 'EOAW%'
 ORDER BY TABLE_NAME;

-- 2.7 Legacy workflow & business process objects (often stale but cheap)
SELECT * FROM PSEVENTDEFN;
SELECT * FROM PSACTIVITYDEFN;
SELECT * FROM PSBUSPROCDEFN;   -- old App Designer "business process" maps

-- 2.8 Integration Broker — definitions (the integration estate)
SELECT * FROM PSNODEDEFN;      -- nodes (connected systems!)
SELECT * FROM PSMSGDEFN;       -- messages
-- Export remaining IB definition tables found by the 00_discovery scan:
SELECT 'SELECT * FROM ' || TABLE_NAME || ';' AS EXTRACT_STMT
  FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PSIB%'
 ORDER BY TABLE_NAME;
