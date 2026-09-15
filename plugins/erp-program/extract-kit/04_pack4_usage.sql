-- ============================================================
-- 04_pack4_usage.sql  (KIT v2) — WHAT ACTUALLY GETS USED
-- Pillar-agnostic. Sensitivity: MODERATE (user IDs) — classify INTERNAL.
--
-- ** EXTRACT THIS PACK FIRST. ** PSPRCSRQST is purged on a schedule and
-- is the single best evidence of what runs. Everything else in the kit
-- can be re-extracted next month; this cannot.
--
-- v2 changes vs v1:
--   + explicit capture-window CTE, so "never run" means "never run in
--     the window we actually hold" rather than an unqualified claim.
--     v1's dead-process query said "never run in captured history" in a
--     comment but produced a column-less result that reads as absolute.
--   + run duration and failure-rate columns (v1 counted runs only) —
--     runtime is what determines the batch window in the target ERP
--   + OPRID pseudonymisation option
--   + component/page usage from Performance Monitor, written out
--   + portal/navigation usage where PSACCESSLOG is thin
--   + usage joined to customization flag, so you can see whether the
--     things people use are the things you modified
-- ============================================================

-- ------------------------------------------------------------
-- 4.0 Capture window — run this first and record it in the manifest.
-- Every "unused" claim in this pack is relative to this window.
-- ------------------------------------------------------------
SELECT MIN(RQSTDTTM) AS WINDOW_START, MAX(RQSTDTTM) AS WINDOW_END,
       ROUND(MAX(RQSTDTTM) - MIN(RQSTDTTM)) AS DAYS_CAPTURED,
       COUNT(*) AS TOTAL_REQUESTS
  FROM PSPRCSRQST;
-- SQL Server: DATEDIFF(day, MIN(RQSTDTTM), MAX(RQSTDTTM))

-- ------------------------------------------------------------
-- 4.1 Process usage — what runs, how often, how long, how reliably
-- ------------------------------------------------------------
SELECT r.PRCSNAME, r.PRCSTYPE, d.DESCR, d.OBJECTOWNERID,
       TRUNC(r.RQSTDTTM,'MM') AS RUN_MONTH,
       r.OPRID,
       COUNT(*) AS RUNS,
       SUM(CASE WHEN r.RUNSTATUS = '9' THEN 1 ELSE 0 END) AS SUCCESS_RUNS,
       SUM(CASE WHEN r.RUNSTATUS = '3' THEN 1 ELSE 0 END) AS ERROR_RUNS,
       SUM(CASE WHEN r.RUNSTATUS = '8' THEN 1 ELSE 0 END) AS CANCELLED_RUNS,
       ROUND(AVG((r.ENDDTTM - r.BEGINDTTM) * 1440), 2) AS AVG_MINUTES,
       ROUND(MAX((r.ENDDTTM - r.BEGINDTTM) * 1440), 2) AS MAX_MINUTES
  FROM PSPRCSRQST r
  LEFT JOIN PSPRCSDEFN d ON d.PRCSNAME = r.PRCSNAME AND d.PRCSTYPE = r.PRCSTYPE
 GROUP BY r.PRCSNAME, r.PRCSTYPE, d.DESCR, d.OBJECTOWNERID,
          TRUNC(r.RQSTDTTM,'MM'), r.OPRID
 ORDER BY RUNS DESC;
-- SQL Server: TRUNC(x,'MM') → DATEFROMPARTS(YEAR(x),MONTH(x),1)
--             (ENDDTTM-BEGINDTTM)*1440 → DATEDIFF(minute,BEGINDTTM,ENDDTTM)

-- 4.1b PSEUDONYMISATION OPTION  ** new in v2 **
-- If your data-protection review prefers not to land raw OPRIDs, use
-- this form instead of 4.1. Analysis by distinct-operator counts is
-- almost always sufficient for discovery.
SELECT r.PRCSNAME, r.PRCSTYPE, d.DESCR,
       TRUNC(r.RQSTDTTM,'MM') AS RUN_MONTH,
       COUNT(*) AS RUNS,
       COUNT(DISTINCT r.OPRID) AS DISTINCT_OPERATORS
  FROM PSPRCSRQST r
  LEFT JOIN PSPRCSDEFN d ON d.PRCSNAME = r.PRCSNAME AND d.PRCSTYPE = r.PRCSTYPE
 GROUP BY r.PRCSNAME, r.PRCSTYPE, d.DESCR, TRUNC(r.RQSTDTTM,'MM')
 ORDER BY RUNS DESC;

-- ------------------------------------------------------------
-- 4.2 Batch window profile  ** new in v2 **
-- When the load actually falls. Drives the target-ERP batch schedule
-- and the cutover rehearsal plan.
-- ------------------------------------------------------------
SELECT TO_CHAR(BEGINDTTM,'D')  AS DAY_OF_WEEK,
       TO_CHAR(BEGINDTTM,'HH24') AS HOUR_OF_DAY,
       COUNT(*) AS RUNS,
       ROUND(SUM((ENDDTTM - BEGINDTTM) * 1440), 0) AS TOTAL_MINUTES
  FROM PSPRCSRQST
 WHERE BEGINDTTM IS NOT NULL AND ENDDTTM IS NOT NULL
 GROUP BY TO_CHAR(BEGINDTTM,'D'), TO_CHAR(BEGINDTTM,'HH24')
 ORDER BY 1,2;

-- 4.2b The long pole — processes that dominate the batch window
SELECT PRCSNAME, PRCSTYPE, COUNT(*) AS RUNS,
       ROUND(SUM((ENDDTTM - BEGINDTTM) * 1440),0) AS TOTAL_MINUTES,
       ROUND(AVG((ENDDTTM - BEGINDTTM) * 1440),1) AS AVG_MINUTES
  FROM PSPRCSRQST
 WHERE BEGINDTTM IS NOT NULL AND ENDDTTM IS NOT NULL
 GROUP BY PRCSNAME, PRCSTYPE ORDER BY TOTAL_MINUTES DESC;

-- ------------------------------------------------------------
-- 4.3 Dead-process list — defined but not run WITHIN THE WINDOW
-- The window columns are part of the result so the claim travels with
-- its own caveat.
-- ------------------------------------------------------------
SELECT d.PRCSNAME, d.PRCSTYPE, d.DESCR, d.OBJECTOWNERID,
       d.LASTUPDOPRID, d.LASTUPDDTTM,
       (SELECT MIN(RQSTDTTM) FROM PSPRCSRQST) AS WINDOW_START,
       (SELECT MAX(RQSTDTTM) FROM PSPRCSRQST) AS WINDOW_END,
       CASE WHEN d.LASTUPDOPRID NOT IN ('PPLSOFT',' ') THEN 'CUSTOM'
            ELSE 'DELIVERED' END AS ORIGIN
  FROM PSPRCSDEFN d
 WHERE NOT EXISTS (SELECT 1 FROM PSPRCSRQST r
                    WHERE r.PRCSNAME = d.PRCSNAME AND r.PRCSTYPE = d.PRCSTYPE)
 ORDER BY ORIGIN DESC, d.OBJECTOWNERID, d.PRCSNAME;
-- Custom processes that have never run in the window are the most
-- interesting rows in the whole kit: build cost was paid, value was not.

-- ------------------------------------------------------------
-- 4.4 Query usage — only if PSQRYEXECLOG exists (00_discovery §0.7)
-- ------------------------------------------------------------
SELECT OPRID, QRYNAME, TRUNC(EXECDTTM,'MM') AS RUN_MONTH, COUNT(*) AS RUNS
  FROM PSQRYEXECLOG
 GROUP BY OPRID, QRYNAME, TRUNC(EXECDTTM,'MM') ORDER BY RUNS DESC;

-- 4.4b Query estate triage — used vs dormant, public vs private
SELECT q.QRYNAME,
       CASE WHEN q.OPRID = ' ' THEN 'PUBLIC' ELSE 'PRIVATE' END AS VISIBILITY,
       q.OPRID AS OWNER,
       NVL(e.RUNS,0) AS RUNS_IN_WINDOW,
       q.LASTUPDDTTM
  FROM PSQRYDEFN q
  LEFT JOIN (SELECT QRYNAME, COUNT(*) AS RUNS FROM PSQRYEXECLOG GROUP BY QRYNAME) e
    ON e.QRYNAME = q.QRYNAME
 ORDER BY RUNS_IN_WINDOW DESC, q.QRYNAME;
-- If PSQRYEXECLOG is absent, this returns the estate with RUNS_IN_WINDOW
-- = 0 throughout; report that clearly rather than as evidence of disuse.

-- ------------------------------------------------------------
-- 4.5 Login activity — population sizing per pillar
-- ------------------------------------------------------------
SELECT TRUNC(LOGINDTTM,'MM') AS LOGIN_MONTH,
       COUNT(DISTINCT OPRID) AS ACTIVE_USERS, COUNT(*) AS LOGINS
  FROM PSACCESSLOG GROUP BY TRUNC(LOGINDTTM,'MM') ORDER BY 1;

-- 4.5b Active users by role — who the change audience actually is.
-- Joins login activity to role membership: the difference between
-- "3,400 people have this role" and "180 people used it last quarter".
SELECT ru.ROLENAME, COUNT(DISTINCT a.OPRID) AS ACTIVE_USERS_90D
  FROM PSROLEUSER ru
  JOIN PSACCESSLOG a ON a.OPRID = ru.ROLEUSER
 WHERE a.LOGINDTTM > SYSDATE - 90
 GROUP BY ru.ROLENAME ORDER BY 2 DESC;

-- ------------------------------------------------------------
-- 4.6 COMPONENT / PAGE USAGE from Performance Monitor  ** written out **
-- v1 left this as a commented sketch. If PPM is on, this is the truest
-- answer to "what screens do people actually use" and it outranks every
-- other usage source for process mapping.
-- ------------------------------------------------------------
SELECT PM_TOP_INSTANCE_ID, PM_CONTEXT_VALUE1 AS COMPONENT,
       PM_CONTEXT_VALUE2 AS PAGE, PM_CONTEXT_VALUE3 AS ACTION,
       TRUNC(PM_MON_STRT_DTTM,'MM') AS USAGE_MONTH,
       COUNT(*) AS HITS,
       ROUND(AVG(PM_DURATION),3) AS AVG_SECONDS
  FROM PSPMTRANSHIST
 GROUP BY PM_TOP_INSTANCE_ID, PM_CONTEXT_VALUE1, PM_CONTEXT_VALUE2,
          PM_CONTEXT_VALUE3, TRUNC(PM_MON_STRT_DTTM,'MM')
 ORDER BY HITS DESC;
-- Context column semantics vary by PM transaction type; confirm against
-- your release before interpreting. The simpler, always-safe form:
SELECT PM_CONTEXT_VALUE1 AS COMPONENT, COUNT(*) AS HITS
  FROM PSPMTRANSHIST GROUP BY PM_CONTEXT_VALUE1 ORDER BY 2 DESC;
-- If PPM is OFF: enable it now. Sixty days of page telemetry collected
-- before design workshops is worth more than any interview schedule,
-- and it cannot be collected retrospectively.

-- ------------------------------------------------------------
-- 4.7 USAGE × CUSTOMIZATION  ** new in v2 — the cross-tab that matters **
-- Are the things people use the things you modified? Four quadrants:
--   used + customised   → migrate the requirement, not the code
--   used + delivered    → standard functionality, lowest risk
--   unused + customised → sunk cost; retire, do not rebuild
--   unused + delivered  → scope reduction
-- ------------------------------------------------------------
SELECT CASE WHEN d.LASTUPDOPRID NOT IN ('PPLSOFT',' ') THEN 'CUSTOMISED'
            ELSE 'DELIVERED' END AS ORIGIN,
       CASE WHEN r.RUNS > 0 THEN 'USED' ELSE 'UNUSED' END AS USAGE,
       COUNT(*) AS PROCESSES
  FROM PSPRCSDEFN d
  LEFT JOIN (SELECT PRCSNAME, PRCSTYPE, COUNT(*) AS RUNS
               FROM PSPRCSRQST GROUP BY PRCSNAME, PRCSTYPE) r
    ON r.PRCSNAME = d.PRCSNAME AND r.PRCSTYPE = d.PRCSTYPE
 GROUP BY CASE WHEN d.LASTUPDOPRID NOT IN ('PPLSOFT',' ') THEN 'CUSTOMISED'
               ELSE 'DELIVERED' END,
          CASE WHEN r.RUNS > 0 THEN 'USED' ELSE 'UNUSED' END;

-- 4.7b The named list behind the "used + customised" quadrant —
-- the highest-value requirements in the estate.
SELECT d.PRCSNAME, d.PRCSTYPE, d.DESCR, d.OBJECTOWNERID,
       d.LASTUPDOPRID, d.LASTUPDDTTM, r.RUNS
  FROM PSPRCSDEFN d
  JOIN (SELECT PRCSNAME, PRCSTYPE, COUNT(*) AS RUNS
          FROM PSPRCSRQST GROUP BY PRCSNAME, PRCSTYPE) r
    ON r.PRCSNAME = d.PRCSNAME AND r.PRCSTYPE = d.PRCSTYPE
 WHERE d.LASTUPDOPRID NOT IN ('PPLSOFT',' ')
 ORDER BY r.RUNS DESC;

-- ------------------------------------------------------------
-- 4.8 Integration Broker traffic — see 02d §2d.7 (moved there in v2 so
-- the whole integration picture sits in one file).
-- Reminder: aggregates only. Never bulk-export IB monitor detail —
-- payloads contain live business data.
-- ------------------------------------------------------------
