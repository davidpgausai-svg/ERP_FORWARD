-- ============================================================
-- 01_pack1_structure.sql — WHAT THE SYSTEM IS (pillar-agnostic)
-- Sensitivity: none (no business data). Export each SELECT to
-- <instance>_P1_<table>.csv
-- ============================================================

-- 1.1 Records (tables/views) and fields — the data dictionary
SELECT * FROM PSRECDEFN;      -- every record; RECTYPE 0=table 1=view; note RECDESCR, SQLTABLENAME, LASTUPDOPRID
SELECT * FROM PSRECFIELDDB;   -- fields on each record incl. inherited; USEEDIT bit 1 = key field
SELECT * FROM PSDBFIELD;      -- field-level definitions (type, length, labels)

-- 1.2 Pages, components, menus — the UI surface
SELECT * FROM PSPNLDEFN;      -- pages
SELECT * FROM PSPNLFIELD;     -- fields placed on pages (large; still fine)
SELECT * FROM PSPNLGRPDEFN;   -- components (the "screens" users open)
SELECT * FROM PSMENUDEFN;
SELECT * FROM PSMENUITEM;

-- 1.3 Portal registry — the navigation users actually see
SELECT * FROM PSPRSMDEFN;     -- hierarchical: PORTAL_OBJNAME / PORTAL_PRNTOBJNAME

-- 1.3b OPTIONAL readable navigation paths (Oracle hierarchical query;
-- convenience only — the raw table above is sufficient for Databricks)
SELECT PORTAL_NAME, PORTAL_OBJNAME, PORTAL_LABEL, PORTAL_URI_SEG2,
       SYS_CONNECT_BY_PATH(PORTAL_LABEL, ' > ') AS NAV_PATH
  FROM PSPRSMDEFN
 WHERE PORTAL_NAME IN ('EMPLOYEE')          -- adjust per 0.5 results
 START WITH PORTAL_PRNTOBJNAME = ' '
 CONNECT BY PRIOR PORTAL_OBJNAME = PORTAL_PRNTOBJNAME
        AND PORTAL_NAME = PRIOR PORTAL_NAME;

-- 1.4 Translate (dropdown) values — every coded value in the system
SELECT * FROM PSXLATITEM WHERE EFF_STATUS = 'A';

-- 1.5 Field labels (useful for making extracts human-readable downstream)
SELECT * FROM PSDBFLDLABL;
