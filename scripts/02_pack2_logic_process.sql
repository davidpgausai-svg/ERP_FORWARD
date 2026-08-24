-- ============================================================
-- 02_pack2_logic_process.sql  (KIT v2) — WHAT THE SYSTEM DOES
-- Pillar-agnostic. Sensitivity: LOW (business logic; no person data).
--
-- v2 changes vs v1:
--   + PSPRCSDEFNPNL name corrected (v1 wrote PS_PRCSDEFNPNL — no such table)
--   + PSPRCSJOBITEM, PSRECURDEFN, PSPRCSTYPEDEFN, PSPRCSPRFL added
--     (v1 extracted jobs but not the steps inside them — the chains were lost)
--   + full PS Query object set so query SQL can be reassembled
--     (v1 took 4 of the 8 tables; the SQL could not be rebuilt)
--   + AE step/statement reassembly join written out
--   + LONG-column handling called out where it bites
--   Reporting engines, approvals and Integration Broker moved to
--   02b / 02c / 02d — they were one-liners in v1 and each is a
--   workstream in its own right.
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 PeopleCode INVENTORY
-- Source is tokenised in PSPCMPROG.PROGTXT (LONG RAW) — it does NOT
-- export usefully as CSV. Extract the inventory here; get the source
-- via App Designer > Copy Project to File (README §PeopleCode).
-- ------------------------------------------------------------
SELECT OBJECTID1, OBJECTVALUE1, OBJECTID2, OBJECTVALUE2,
       OBJECTID3, OBJECTVALUE3, OBJECTID4, OBJECTVALUE4,
       OBJECTID5, OBJECTVALUE5, OBJECTID6, OBJECTVALUE6,
       OBJECTID7, OBJECTVALUE7,
       PROGSEQ, PROGLEN, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPCMPROG;

-- 2.1b Decoded PeopleCode inventory — event type + owning object,
-- aggregated to one row per program instead of one row per 8KB chunk.
SELECT OBJECTVALUE1 AS OBJ1, OBJECTVALUE2 AS OBJ2,
       OBJECTVALUE3 AS OBJ3, OBJECTVALUE4 AS EVENT_OR_METHOD,
       COUNT(*) AS CHUNKS, SUM(PROGLEN) AS TOTAL_BYTES,
       MAX(LASTUPDOPRID) AS LASTUPDOPRID, MAX(LASTUPDDTTM) AS LASTUPDDTTM
  FROM PSPCMPROG
 GROUP BY OBJECTVALUE1, OBJECTVALUE2, OBJECTVALUE3, OBJECTVALUE4
 ORDER BY TOTAL_BYTES DESC;

-- 2.1c PeopleCode reference index — which programs touch which records
-- and fields. This is how you find "what breaks if we retire X".
SELECT * FROM PSPCMNAME;        -- ** new in v2 ** name/reference table

-- ------------------------------------------------------------
-- 2.2 SQL objects — definitions and full text
-- SQLTEXT is LONG on many releases. See 00_discovery §0.4 before running.
-- ------------------------------------------------------------
SELECT * FROM PSSQLDEFN;
SELECT SQLID, SQLTYPE, SEQNUM, SQLTEXT FROM PSSQLTEXTDEFN ORDER BY SQLID, SQLTYPE, SEQNUM;

-- 2.2b Reassembled SQL text (Oracle; requires SQLTEXT be CLOB or converted)
--   SELECT SQLID, SQLTYPE, LISTAGG(SQLTEXT, '') WITHIN GROUP (ORDER BY SEQNUM) AS FULL_SQL
--     FROM PSSQLTEXTDEFN GROUP BY SQLID, SQLTYPE;
-- LISTAGG caps at 4000 chars on VARCHAR2 — for long text use XMLAGG or
-- reassemble in Databricks on SQLID + SEQNUM. Reassembling downstream is
-- the recommended path: extract raw chunks, concatenate in the lakehouse.

-- 2.2c Record-level SQL: view text for every view in the estate
SELECT RECNAME, SQLTEXT FROM PSSQLTEXTDEFN t
  JOIN PSRECDEFN d ON d.RECNAME = t.SQLID
 WHERE d.RECTYPE IN (1,5,6)
 ORDER BY RECNAME, SEQNUM;

-- ------------------------------------------------------------
-- 2.3 Application Engine — batch logic
-- ------------------------------------------------------------
SELECT * FROM PSAEAPPLDEFN;     -- programs
SELECT * FROM PSAEAPPLSTATE;    -- state records  ** new in v2 **
SELECT * FROM PSAESECTDEFN;     -- sections
SELECT * FROM PSAESTEPDEFN;     -- steps
SELECT * FROM PSAESTMTDEFN;     -- statements (SQL / PeopleCode / Call / Do)

-- 2.3b AE program shape — step counts and where the logic concentrates
SELECT s.AE_APPLID, COUNT(DISTINCT s.AE_SECTION) AS SECTIONS,
       COUNT(*) AS STEPS
  FROM PSAESTEPDEFN s
 GROUP BY s.AE_APPLID ORDER BY STEPS DESC;

-- ------------------------------------------------------------
-- 2.4 Process Scheduler — every batch process, job and schedule
-- ------------------------------------------------------------
SELECT * FROM PSPRCSDEFN;       -- processes (SQR, AE, COBOL, XMLP, nVision...)
SELECT * FROM PSPRCSDEFNXFER;   -- process-to-component navigation, if present
SELECT * FROM PSPRCSDEFNPNL;    -- ** v1 wrote PS_PRCSDEFNPNL — wrong name **
SELECT * FROM PSJOBDEFN;        -- jobs
SELECT * FROM PSPRCSJOBITEM;    -- ** new in v2 ** the steps inside each job
SELECT * FROM PSPRCSJOBDIST;    -- job output distribution, where present
SELECT * FROM PSRECURDEFN;      -- ** new in v2 ** recurrence definitions =
                                --   the batch calendar. Without it you know
                                --   what runs but not when it is scheduled to.
SELECT * FROM PSPRCSTYPEDEFN;   -- process types → executables/run locations
SELECT * FROM PSPRCSPRFL;       -- process profile permissions
SELECT * FROM PSPRCSRUNCNTL;    -- run controls (parameters operators actually use)

-- 2.4b Scheduled-batch calendar, human readable
SELECT r.RECURNAME, r.DESCR, r.RECURTYPE, r.STARTTIME, r.ENDTIME,
       r.INTERVAL_TIME, r.DAYSOFWEEK
  FROM PSRECURDEFN r ORDER BY r.RECURNAME;

-- ------------------------------------------------------------
-- 2.5 PS Query — the shadow reporting estate
-- v1 took 4 tables. All eight are needed to rebuild query SQL.
-- ------------------------------------------------------------
SELECT * FROM PSQRYDEFN;        -- header, owner, public/private
SELECT * FROM PSQRYRECORD;      -- records read
SELECT * FROM PSQRYFIELD;       -- selected fields
SELECT * FROM PSQRYCRITERIA;    -- where-clause criteria
SELECT * FROM PSQRYEXPR;        -- ** new ** expressions
SELECT * FROM PSQRYSELECT;      -- ** new ** select-list structure / unions
SELECT * FROM PSQRYBIND;        -- ** new ** runtime prompts
SELECT * FROM PSQRYLINK;        -- ** new ** subquery links
SELECT * FROM PSQRYFLDSEL;      -- ** new ** field ordering / sort
-- Query security (which access group tree a query may read):
SELECT * FROM PSQRYFAVORITES;   -- optional; shows what users kept
SELECT * FROM PSTREEDEFN WHERE TREE_NAME LIKE 'QUERY%';

-- 2.5b Query estate profile — feeds report rationalisation
SELECT CASE WHEN OPRID = ' ' THEN 'PUBLIC' ELSE 'PRIVATE' END AS VISIBILITY,
       QRYTYPE, COUNT(*) AS QUERIES
  FROM PSQRYDEFN GROUP BY CASE WHEN OPRID = ' ' THEN 'PUBLIC' ELSE 'PRIVATE' END, QRYTYPE;

-- ------------------------------------------------------------
-- 2.6 Legacy workflow & App Designer business processes
-- Usually stale, always cheap, occasionally the only documentation
-- of a process nobody remembers configuring.
-- ------------------------------------------------------------
SELECT * FROM PSEVENTDEFN;
SELECT * FROM PSACTIVITYDEFN;
SELECT * FROM PSBUSPROCDEFN;
SELECT * FROM PSWORKLISTDEFN;   -- ** new in v2 ** worklist definitions
SELECT * FROM PSROLEDEFN WHERE ROLETYPE <> ' ';   -- query/PeopleCode roles used by routing

-- ------------------------------------------------------------
-- 2.7 Message catalogue — the system's own error/prompt text
-- Undervalued: message sets carry business rules ("cannot exceed
-- annual limit") that exist nowhere else in writing.
-- ------------------------------------------------------------
SELECT * FROM PSMSGSETDEFN;     -- ** new in v2 **
SELECT * FROM PSMSGCATDEFN;     -- ** new in v2 **
