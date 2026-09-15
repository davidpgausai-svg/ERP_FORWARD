# PeopleSoft Reference Sources

Where to look when an extract, a screenshot, or a user's question needs the vendor's definition of a table, page, field or tool. **Match the release first**: `TOOLSREL` and the application release are in `_P0_RUN_HEADER.csv`, or on screen at PeopleTools > Utilities > Administration > PeopleTools Options and the Help > About menu. A 9.2 / PeopleTools 8.59 guide read against an 8.55 instance will mislead you on column names and navigation.

Trust order: Oracle official → community references (validate against the instance) → open-source projects (read the code before trusting the claim) → commercial.

## Oracle official

| Source | URL | Use it for |
|---|---|---|
| PeopleSoft Documentation Home | https://docs.oracle.com/en/applications/peoplesoft/index.html | Entry point for current online help and PeopleBooks across PeopleTools, HCM, FSCM, Campus Solutions, CRM, ELM, EPM |
| PeopleTools Documentation | https://docs.oracle.com/en/applications/peoplesoft/peopletools/index.html | Application Designer, PeopleCode, Integration Broker, security, reporting, lifecycle management. The primary reference for P1 / P2 / P3i / P5 questions |
| HCM Documentation | https://docs.oracle.com/en/applications/peoplesoft/human-capital-management/index.html | Core HR, Payroll NA, Benefits, Time & Labor, Absence, Recruiting setup — the P3 anchors `03a`–`03c` |
| PeopleSoft Query Overview | https://docs.oracle.com/cd/F40609_01/pt859pbr1/eng/pt/tpsq/concept_PeopleSoftQueryOverview-c07506.html | The PS Query path in `../skills/peoplesoft-metadata-reader/references/extract-runbook.md`; validating a direct-SQL result against what Query returns |
| FSCM 9.2 PeopleBooks (virtual library) | https://docs.oracle.com/cd/E40049_01/psft/html/homeset.html | GL, AP, PO, AR, BI, AM, PC, GM, EX, KK setup — the P3 anchors `03d`–`03g`. **Only when the instance is 9.2** |
| Documentation Archive | https://www.oracle.com/documentation/psftarch.html | Earlier releases — legacy PeopleBooks, install and upgrade docs |
| Enterprise Documentation portal | https://www.oracle.com/documentation/psftent.html | Cross-release index when you do not yet know which library you need |

## Community references — validate against the instance

| Source | URL | Use it for |
|---|---|---|
| PSST0101 — PeopleTools Tables | https://psst0101.digitaleagle.net/peopletools-tables/ | When a `PS*` metadata table in an extract is not one the library guide decodes. Catalog of PeopleTools tables for records, fields, pages, components, PeopleCode, SQL, projects |
| Go-Faster — PSRECDEFN reference | https://www2.go-faster.co.uk/peopletools/psrecdefn.htm | Field-level meaning of `PSRECDEFN` columns — `RECTYPE`, `OBJECTOWNERID`, audit flags, `LASTUPDOPRID` / `LASTUPDDTTM` — when designing or checking an inventory query |

## Open source — review before use

| Project | URL | Relevance |
|---|---|---|
| PeopleSoft MCP | https://github.com/rgrz/peoplesoft-mcp | An MCP server that lets an AI assistant query a PeopleSoft HCM database live. A possible *alternative* to file extracts for a technical team — but it bypasses the kit's controls: pure `SELECT`, person-key exclusion, sensitivity classification, the manifest. Review the code and security posture before any deployment; never point it at production without the data-protection review the kit already requires |
| OpenPplSoft (OPS) | https://github.com/tslater2006/OPS | PeopleSoft runtime research. Useful for understanding how PeopleCode and component processing behave; not an extraction or conversion tool |

## Adjacent — not for discovery

| Site | URL | Relevance |
|---|---|---|
| PeopleSoftArchive | https://peoplesoftarchive.com/ | Commercial read-only historical access to HCM/FSCM data after retirement. Belongs to the archive-and-retention decision at cutover, not to metadata reading |

## How skills cite these

A claim sourced from vendor documentation cites the page title and the release it documents, alongside the extract or screenshot evidence: "`PSRECDEFN.RECTYPE = 7` is a temporary table (PeopleTools 8.59 Data Management guide); observed on 1,204 records in `HCM_P1_PSRECDEFN.csv`, snapshot 2026-08-24." Documentation alone is a hypothesis about *this* instance until an extract or a screenshot confirms it.
