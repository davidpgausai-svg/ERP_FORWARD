---
name: peoplesoft-metadata-reader
description: Read, produce, and analyze PeopleSoft metadata and configuration — from extract-kit CSVs (Packs 0–6), from PS Query downloads, or from screenshots of PeopleSoft pages — to inventory what the system is, what it is configured to do, who can do what, and what is actually used. Use this whenever the user asks anything about the PeopleSoft environment; mentions PSRECDEFN, PSAUTHITEM, PSPRCSRQST or any PS* table; shares extract CSVs, a manifest, or a completeness scorecard; pastes or uploads screenshots of PeopleTools, Set Up HCM, Set Up Financials/Supply Chain, Set Up SACR, Process Monitor, Query Manager, Permission Lists or Roles pages; asks "what's in PeopleSoft", "how big is our footprint", "what do we use", "which setup tables are populated", "who can do X"; or asks how to get the data out — "how do I extract", "what SQL do I run", "I don't have database access", "can I do this from Query Manager", "do we need a consultant for this". Foundational for every conversion-discovery skill; for ANY pillar — HR, payroll, benefits, finance, supply chain, grants, student.
---

# PeopleSoft Metadata Reader

This is the foundational conversion skill. It turns evidence about a PeopleSoft estate — extract CSVs, PS Query downloads, or screenshots of the pages themselves — into ranked, human-readable inventories a functional owner can act on, and it walks people through producing that evidence without hiring anyone to do it. The other discovery skills (snapshot-diff, customization-analysis, security-access-analysis, integration-discovery, report-rationalization, process-map-drafting) assume the habits set here.

Read `../../references/extract-library-guide.md` first. It defines the packs, the file names, the decodes and joins, and the completeness gates. Everything below depends on it.

## Day 1: pick the entry that matches what you have

| You have | Start here | What you can get today |
|---|---|---|
| Extract-kit output — a dated folder of `_P?_` CSVs and a manifest | **Mode A** | Full inventories, usage ranking, who-can-do-what: the census |
| Read access to the PeopleSoft database, or a DBA who will run scripts for you | **Mode B**, then Mode A | The extracts themselves, in an afternoon per instance — plus the two settings to switch on today so next month's extract is better |
| Query Manager in PeopleSoft, no database login | **Mode B (PS Query path)**, then Mode A | Raw table downloads for most of P1, P2, P3 and P3i; usually no telemetry |
| Only the PeopleSoft web pages | **Mode C** | Confirmed facts about specific setup areas, roles and processes; row counts from search headers; the seed of an inventory a later extract completes |

Most programs mix all four. That is fine — the method is the same; only the confidence label changes. What is not fine is presenting sample evidence as a census. Say which mode produced each finding.

## Ground rules

- Metadata, configuration and aggregated telemetry only. If a file or screenshot shows identified employee, student, supplier-bank or payroll rows, stop, do not analyze it, and flag it to the program lead.
- Every output carries instance, snapshot date (or capture date), and source mode. No provenance, no finding.
- Gate on `_P0_COMPLETENESS.csv` when it exists (guide § "Gate on the completeness scorecard"). A FAIL on process-history retention means no usage ranking, full stop — say why rather than rank on thin air.
- Load with Python in the sandbox: pipe-delimited unless the manifest says otherwise, header row, quoted fields may contain newlines. Sample-inspect the large files (`PSPNLFIELD`, `PSAUTHITEM`, `PSTREE*`, `PSPRCSRQST`) before loading whole.
- Vendor documentation interprets; extracts and screenshots prove. When you cite a PeopleBook, match the release (`../../references/peoplesoft-reference-sources.md`).

## Mode A — you have extracts

1. **Provenance first.** Read `_P0_RUN_HEADER.csv` (instance, releases, run time) and `manifest.csv`. Reconcile `row_count_actual` against what you load and against `_P0_EXPECTED_COUNTS.csv`. A mismatch is a failed extract, not a small table.
2. **Gate.** Read `_P0_COMPLETENESS.csv` and apply the guide's gate table. Check LONG truncation on `_P2_PSSQLTEXTDEFN.csv` — a maximum width of 80 characters means truncated.
3. **Open the six first-reads** the guide lists: the SETID map, the payroll → GL account codes, the control budget profile, the access matrix, usage × customization, and the scorecard. They routinely change the question.
4. Run the method below.

Pack names are kit v2: security is `_P3I_` (not `_P3D_`); approvals `_P2C_`; integrations `_P2D_`; reporting `_P2B_`. If a colleague or an older note says P3d, translate.

## Mode B — you need to produce extracts

Follow `references/extract-runbook.md`. In short: establish which of the three access levels the person has — database read-only, Query Manager only, or pages only. If database, hand them the kit at `../../extract-kit/` in the README's run order — `00` discovery first, `04` usage second because process history is being purged right now, `06` §6.1–6.2 before extracting, then the rest — with the two settings that stop SQL*Plus truncating SQL text. If Query Manager, translate the raw `SELECT *` sections into PS Queries and download, and be honest about what does not port: the generators, the discovery probes, and telemetry unless the PeopleTools access group is granted. Either way, get the App Admin started on the three non-SQL deliverables, and switch on Performance Monitor and `PSPRCSRQST` retention today.

You may read the kit's SQL and adapt a single query to a specific question ("just the custom records in FSCM") — the kit is pure `SELECT`, and the person runs it, not you. You may not invent table or column names. If you are unsure a column exists on their release, hand them the kit's `PSRECFIELDDB` probe and ask them to list the real columns.

## Mode C — you have screenshots, or page access only

Use `references/pia-navigation-map.md` to translate what is on screen into the pack and table it corresponds to, and to tell the person which pages to capture next.

1. **Read the breadcrumb.** The navigation path at the top of the page is the provenance. If it is cropped out, ask for it again — a screenshot without a path is an anecdote.
2. **Prefer list pages to detail pages.** A search-results grid with no criteria shows the first rows *and* a header such as "First 1–100 of 843." That count is real — it is the table's cardinality for that SETID or business unit — and it is the one thing a screenshot gives you at census confidence. Capture it.
3. **Effective-dated pages:** ask whether "Include History" was checked. Without it, you are seeing current rows only.
4. **Extract the structured values** from the image into the field names the pack would use (the map gives them). Tag every row `source=SCREENSHOT`, `captured=<date>`, `nav_path=<breadcrumb>`, `setid_or_bu=<what was on screen>`.
5. **Say what you can and cannot claim.** Confirmed: the objects shown exist, with the values shown. Not confirmed: anything about objects not shown; any ranking by usage unless Process Monitor screenshots with a stated date window are in the set. Never call a screenshot set an inventory.
6. **Redact before it travels.** Process Monitor, Role Members and User Profile pages show user IDs and names — the same Internal Restricted rule as P3i / P4. Supplier and bank pages are not captured at all.

Screenshots are how a functional analyst gets started on day one and how a specific fact gets confirmed in five minutes. They are not how a program gets its inventory. When someone is on their fourth screenshot of the same setup area, point them at Mode B.

## The method — inventory → rank → translate → land

1. **Inventory** the object type in question — records, components, queries, processes, setup tables, roles — from P1 / P2 / P3 / P3i, or from screenshots, labeled. Attribute each object to its owning product via `OBJECTOWNERID` (decode with `PSOBJGROUP`), so one answer serves HR, payroll, finance, student and supply chain separately. For setup tables, resolve SETID through `SET_CNTRL_REC` before counting anything per business unit.
2. **Rank by reality** using P4: runs per month, distinct users, last used, failure rate. Objects with no telemetry go in "no observed use in *N* months of telemetry" — never "dead" — and the capture window from `_P4_` is quoted in the bucket name. If the scorecard says telemetry is missing, skip this step and say so in the deliverable's first paragraph.
3. **Translate for humans.** Join to `RECDESCR` / `DESCR` / `PSDBFLDLABL`, and build navigation breadcrumbs from `PSPRSMDEFN` so every component reads as "Workforce Administration > Job Information > Job Data." Deliverables lead with the human name; object names go in appendix columns.
4. **Land it** per `../../references/output-conventions.md`: CSV inventories, findings in the standard format, DRAFT records to the record layer when connected (`legacy_object` and data-quality findings especially). End with the unknowns list — what the evidence could not tell you, and which pack, page or person could.

## Questions this skill should answer without being walked through it

- "How many custom tables do we have in FSCM?" → P1 `RECTYPE=0` + P5 sweep (patch-noise controlled, §5.0) + `_P5_APPDESIGNER_COMPARE.csv` if landed; by `OBJECTOWNERID`.
- "What are our most-used components?" → P1 components + breadcrumbs, joined to P4 page telemetry; fall back to process and query usage if Performance Monitor is off, and say so.
- "Which setup tables are populated, per business unit?" → `_P3_SETUP_INVENTORY.csv` + per-table row counts, resolved through `SET_CNTRL_REC`.
- "Who can run payroll / post journals / change a vendor?" → `_P3I_ACCESS_MATRIX.csv` (role → permission list → component) joined to breadcrumbs; then P4 for who actually does.
- "What would we lose if we retired *Y*?" → P2 dependencies (queries reading it, App Engine steps touching it, pages exposing it, IB operations carrying it) + P2c routes + P4 liveness.
- "What feeds the GL?" → journal sources from `03d` (FSCM P3) cross-checked against `_P2D_INTEGRATION_INVENTORY.csv`; a source with no node is a file feed to hunt down.
- "I only have Query Manager — what can I get you?" → runbook § PS Query path: the raw-dump sections, minus the generators; ask for the PeopleTools access group if telemetry is needed.
- "Here's a screenshot of our Department table — what does it tell you?" → map row → `PS_DEPT_TBL` (P3, `03a`); read the "of N" count, the SETID on screen, the effective-date status; confirm existence and values; decline to infer completeness.

## When to reach for other skills

- Two snapshots, "what changed" → `snapshot-diff`.
- Customizations and their dispositions → `customization-analysis` (it assumes this skill's P5 handling).
- SoD, role design, org design from access data → `security-access-analysis`.
- What talks to PeopleSoft → `integration-discovery`.
- The reporting estate → `report-rationalization`.
- Turning evidence into a current-state process map → `process-map-drafting`.
- A design document, Visio or fit-gap workbook rather than an extract → `source-to-import-workbooks` first.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
