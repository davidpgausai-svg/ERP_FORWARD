-- ============================================================
-- 02d_pack2_integration.sql  (KIT v2) — NEW PACK
-- The integration estate: what talks to PeopleSoft, in both directions.
--
-- v1 covered this with two SELECTs (PSNODEDEFN, PSMSGDEFN) plus a
-- generator. That finds the nodes but not the service operations,
-- routings, handlers, queues, connectors, or file-based feeds — and
-- file feeds are typically the majority of a public-sector or
-- higher-ed PeopleSoft integration footprint.
--
-- Sensitivity: LOW for definitions. IB *payloads* are NOT extracted —
-- they contain live business data.
-- ============================================================

-- ------------------------------------------------------------
-- 2d.1 Nodes — the connected-systems list
-- ------------------------------------------------------------
SELECT * FROM PSNODEDEFN;
SELECT * FROM PSNODECONPROP;     -- connector properties (endpoints, URLs)  ** new **
SELECT * FROM PSNODETRX;         -- node transactions (older releases)
SELECT * FROM PSNODEURITEXT;     -- REST URI templates, where present

-- 2d.1b Node inventory, readable — the "who are we integrated with" list
SELECT NODENAME, DESCR, NODETYPE, AUTHOPTN, ACTIVE_FLAG,
       DEFAULT_USERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSNODEDEFN ORDER BY ACTIVE_FLAG DESC, NODENAME;

-- ------------------------------------------------------------
-- 2d.2 Services and service operations — the contracts
-- ------------------------------------------------------------
SELECT * FROM PSSERVICE;          -- ** new in v2 **
SELECT * FROM PSOPERATION;        -- ** new in v2 ** service operations
SELECT * FROM PSOPRVERDFN;        -- ** new in v2 ** operation versions
SELECT * FROM PSOPRHDLR;          -- ** new in v2 ** handlers (the code behind it)
SELECT * FROM PSOPRROUTING;       -- ** new in v2 ** routings — node-to-node bindings
SELECT * FROM PSRTNGDFN;          -- routing definitions
SELECT * FROM PSRTNGDFNPARM;      -- routing parameters / transforms

-- ------------------------------------------------------------
-- 2d.3 Messages, queues, transformations
-- ------------------------------------------------------------
SELECT * FROM PSMSGDEFN;
SELECT * FROM PSMSGRECDEFN;       -- message record structure  ** new in v2 **
SELECT * FROM PSMSGFIELDDEFN;     -- message field structure   ** new in v2 **
SELECT * FROM PSQUEUEDEFN;        -- ** new in v2 ** service operation queues
SELECT * FROM PSTRANSFORM;        -- transform programs, where present

-- ------------------------------------------------------------
-- 2d.4 INTEGRATION INVENTORY  ** the deliverable **
-- One row per service operation with its direction, node bindings and
-- handler. Export as <instance>_P2D_INTEGRATION_INVENTORY.csv.
-- ------------------------------------------------------------
SELECT o.IB_OPERATIONNAME,
       o.IB_OPERATIONTYPE,
       o.DESCR                       AS OPERATION_DESCR,
       o.IB_OPERSTATUS               AS ACTIVE_STATUS,
       s.IB_SERVICENAME,
       r.IB_ROUTINGDEFNNAME,
       r.IB_ROUTINGTYPE              AS DIRECTION,   -- inbound / outbound
       r.SENDERNODENAME,
       r.RECEIVERNODENAME,
       h.IB_HANDLERNAME,
       h.IB_HDLRTYPE,
       o.LASTUPDOPRID, o.LASTUPDDTTM
  FROM PSOPERATION o
  LEFT JOIN PSSERVICE  s ON s.IB_SERVICENAME = o.IB_SERVICENAME
  LEFT JOIN PSRTNGDFN  r ON r.IB_OPERATIONNAME = o.IB_OPERATIONNAME
  LEFT JOIN PSOPRHDLR  h ON h.IB_OPERATIONNAME = o.IB_OPERATIONNAME
 ORDER BY o.IB_OPERATIONNAME;
-- Column names vary by tools release; verify against ALL_TAB_COLUMNS if
-- a column is rejected. The join grain is stable.

-- ------------------------------------------------------------
-- 2d.5 FILE-BASED INTEGRATIONS  ** entirely missing from v1 **
-- In most on-prem PeopleSoft estates, more interfaces run on flat files
-- and scheduled jobs than on Integration Broker. Three evidence sources:
-- ------------------------------------------------------------

-- (a) File Layout definitions — the declared inbound/outbound formats
SELECT * FROM PSFLDDEFN;          -- file layout definitions
SELECT * FROM PSFLDSEGDEFN;       -- segments
SELECT * FROM PSFLDFIELDDEFN;     -- fields

-- (b) Interface-shaped batch processes — heuristic name scan
SELECT PRCSNAME, PRCSTYPE, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPRCSDEFN
 WHERE UPPER(DESCR) LIKE '%INTERFACE%' OR UPPER(DESCR) LIKE '%EXTRACT%'
    OR UPPER(DESCR) LIKE '%IMPORT%'    OR UPPER(DESCR) LIKE '%EXPORT%'
    OR UPPER(DESCR) LIKE '%FEED%'      OR UPPER(DESCR) LIKE '%INBOUND%'
    OR UPPER(DESCR) LIKE '%OUTBOUND%'  OR UPPER(DESCR) LIKE '%LOAD%'
    OR UPPER(DESCR) LIKE '%TRANSMIT%'  OR UPPER(DESCR) LIKE '%FTP%'
    OR UPPER(DESCR) LIKE '%SFTP%'
 ORDER BY PRCSNAME;

-- (c) URL / file-path definitions — where those files are written and read
SELECT * FROM PSURLDEFN;          -- ** new in v2 ** named URLs and directory paths
-- NOTE: PSURLDEFN can contain credentials embedded in URL strings on
-- badly-configured systems. Review before landing; redact if needed.

-- ------------------------------------------------------------
-- 2d.6 JOURNAL SOURCES — the finance integration fingerprint
-- Every feeder system that posts to the GL leaves a journal source.
-- This is the fastest inventory of "what feeds finance".
-- ------------------------------------------------------------
SELECT * FROM PS_JRNL_SOURCE_TBL;
SELECT * FROM PS_JRNLGEN_APPL_ID;    -- journal generator templates  ** new in v2 **
SELECT * FROM PS_ACCT_ENTRY_TMPL;    -- accounting entry templates, where present

-- 2d.6b Which journal sources are alive — volume by source and period.
-- Aggregate only; no journal lines are extracted.
SELECT SOURCE, FISCAL_YEAR, ACCOUNTING_PERIOD, COUNT(*) AS JRNL_HEADERS
  FROM PS_JRNL_HEADER
 GROUP BY SOURCE, FISCAL_YEAR, ACCOUNTING_PERIOD
 ORDER BY FISCAL_YEAR DESC, ACCOUNTING_PERIOD DESC, JRNL_HEADERS DESC;

-- ------------------------------------------------------------
-- 2d.7 IB RUNTIME TRAFFIC — which integrations actually fire
-- Aggregates ONLY. Never bulk-export PSAPMSGPUBHDR/SUBHDR detail or
-- any PSAPMSGxxxCON table: payloads carry business data.
-- ------------------------------------------------------------
SELECT PUBNODE AS NODE, IB_OPERATIONNAME,
       TRUNC(LASTUPDDTTM,'MM') AS TRAFFIC_MONTH,
       COUNT(*) AS MESSAGES
  FROM PSAPMSGPUBHDR
 GROUP BY PUBNODE, IB_OPERATIONNAME, TRUNC(LASTUPDDTTM,'MM')
 ORDER BY 3 DESC, 4 DESC;

SELECT PUBNODE AS NODE, IB_OPERATIONNAME,
       TRUNC(LASTUPDDTTM,'MM') AS TRAFFIC_MONTH,
       COUNT(*) AS MESSAGES
  FROM PSAPMSGSUBHDR
 GROUP BY PUBNODE, IB_OPERATIONNAME, TRUNC(LASTUPDDTTM,'MM')
 ORDER BY 3 DESC, 4 DESC;
-- Adjust table/column names to the PSAPMSG% list found in 00_discovery §0.5.

-- ------------------------------------------------------------
-- 2d.8 Defined-but-silent integrations — decommission candidates
-- ------------------------------------------------------------
SELECT o.IB_OPERATIONNAME, o.DESCR, o.IB_OPERSTATUS, o.LASTUPDDTTM
  FROM PSOPERATION o
 WHERE NOT EXISTS (SELECT 1 FROM PSAPMSGPUBHDR p WHERE p.IB_OPERATIONNAME = o.IB_OPERATIONNAME)
   AND NOT EXISTS (SELECT 1 FROM PSAPMSGSUBHDR s WHERE s.IB_OPERATIONNAME = o.IB_OPERATIONNAME)
 ORDER BY o.IB_OPERATIONNAME;
