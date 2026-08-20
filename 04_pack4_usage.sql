-- ============================================================
-- 04_pack4_usage.sql — WHAT ACTUALLY GETS USED (pillar-agnostic)
-- The scale unlock: with ~40k+ objects per instance, usage ranking
-- defines discovery scope. Aggregates by default; user IDs included
-- at monthly grain — classify INTERNAL.
-- EXTRACT THIS PACK FIRST-est: PSPRCSRQST is routinely purged.
-- ============================================================

-- 4.1 Process usage — what batch actually runs, how often, by whom
SELECT r.PRCSNAME, r.PRCSTYPE, d.DESCR,
       TRUNC(r.RQSTDTTM,'MM') AS RUN_MONTH,
       r.OPRID, COUNT(*) AS RUNS,
       SUM(CASE WHEN r.RUNSTATUS = '9' THEN 1 ELSE 0 END) AS SUCCESS_RUNS
  FROM PSPRCSRQST r
  LEFT JOIN PSPRCSDEFN d ON d.PRCSNAME = r.PRCSNAME AND d.PRCSTYPE = r.PRCSTYPE
 GROUP BY r.PRCSNAME, r.PRCSTYPE, d.DESCR, TRUNC(r.RQSTDTTM,'MM'), r.OPRID
 ORDER BY RUNS DESC;

-- 4.2 Dead-process list — defined but never run in captured history
SELECT d.PRCSNAME, d.PRCSTYPE, d.DESCR, d.LASTUPDDTTM
  FROM PSPRCSDEFN d
 WHERE NOT EXISTS (SELECT 1 FROM PSPRCSRQST r
                    WHERE r.PRCSNAME = d.PRCSNAME AND r.PRCSTYPE = d.PRCSTYPE);

-- 4.3 Query usage (only if PSQRYEXECLOG exists per 00_discovery)
SELECT OPRID, QRYNAME, TRUNC(EXECDTTM,'MM') AS RUN_MONTH, COUNT(*) AS RUNS
  FROM PSQRYEXECLOG
 GROUP BY OPRID, QRYNAME, TRUNC(EXECDTTM,'MM')
 ORDER BY RUNS DESC;

-- 4.4 Login activity — monthly active users (population sizing per pillar)
SELECT TRUNC(LOGINDTTM,'MM') AS LOGIN_MONTH,
       COUNT(DISTINCT OPRID) AS ACTIVE_USERS, COUNT(*) AS LOGINS
  FROM PSACCESSLOG
 GROUP BY TRUNC(LOGINDTTM,'MM') ORDER BY 1;

-- 4.5 Integration Broker traffic — which integrations actually fire.
-- Monitor table names vary by release: use the header tables found by
-- the 00_discovery PSAPMSG% scan and aggregate with this pattern:
--   SELECT <node_col>, <service_operation_col>,
--          TRUNC(<created_dttm_col>,'MM') AS TRAFFIC_MONTH, COUNT(*)
--     FROM <PSAPMSG_header_table>
--    GROUP BY <node_col>, <service_operation_col>,
--          TRUNC(<created_dttm_col>,'MM');
-- Do NOT bulk-export IB monitor detail — payloads can contain business
-- data. Aggregates only from this family.

-- 4.6 Performance Monitor page usage (only if PSPM% tables populated):
--   component/page-level usage — the truest "what screens do people use."
--   Adapt: SELECT <component_col>, TRUNC(<dttm_col>,'MM'), COUNT(*)
--          FROM PSPMTRANSHIST GROUP BY 1,2;
-- If PPM is off, ENABLE IT NOW prospectively — 60 days of page telemetry
-- before design workshops is worth more than any interview schedule.
