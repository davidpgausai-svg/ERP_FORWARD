---
name: security-access-analysis
description: Analyze PeopleSoft security from Pack 3i extracts (`_P3I_` files — roles, permission lists, page access, user assignments, trees) or from screenshots of Roles and Permission List pages, to answer who-can-do-what, find segregation-of-duties conflicts, and inform target-ERP role design. Use this whenever the user mentions security roles, access, permissions, SoD, "who can do X", "who does X", role design, supervisory orgs, or asks how work is actually distributed across departments.
---

# Security Access Analysis

Security data is a process-discovery instrument disguised as an access list. Who *can* transact on a page, by department, is the closest thing the system has to an org-chart of who *does* the work — and it's exactly what target-ERP role design and supervisory-org design need as input. It's also where SoD risk hides.

Read `../../references/extract-library-guide.md`; the access chain is PSROLEUSER → PSROLECLASS → PSAUTHITEM, and it's the backbone of everything here.

## Method

1. **Build the access matrix**: user → role → permission list → component, joined to human-readable breadcrumbs (via PSPRSMDEFN) and to departments (via PSOPRDEFN/job data references in P3i where present). The kit pre-builds this join as `_P3I_ACCESS_MATRIX.csv` (§3i.3) — start there if it landed; otherwise build it from the P3i tables and cache it as a CSV. Every question below reads from it.
2. **Answer the design questions**:
   - Who can perform [transaction]? Ranked by department — this reveals centralized vs distributed operating models per process, which is a top design decision for the new ERP.
   - Role hygiene: roles with one user, users with dozens of roles, permission lists granting unused components (join P4 telemetry), orphaned roles. Each is a cleanup candidate BEFORE role mapping — migrating messy security reproduces messy security.
   - Access vs use: people who can but never do (over-provisioning), heavy users of components their role barely covers (workaround smell).
3. **Draft SoD conflict candidates.** Flag users/roles combining conflicting capabilities — the classics: create vendor + pay vendor; hire + approve payroll; modify own security; enter + approve the same transaction family. Present as candidates with evidence, not verdicts: real SoD determination needs compensating-control context only humans have. Payroll- and finance-touching conflicts get HIGH severity flags for prioritized review.
4. **Feed supervisory-org design.** Summarize, per department: who transacts (vs who manages), transaction mix, and volume — the peer-institution lesson is to design supervisory orgs around who actually performs transactions, not the formal org chart. Chairs and PIs generally don't transact; the data will show who does.

## Deliverable

# Security & access analysis — [instance], snapshot [date]
## Headline (role counts, hygiene issues, SoD candidates by severity)
## Who-does-what by department (the org-design input)
## Role hygiene findings
## SoD conflict candidates (evidence, severity, suggested reviewer)
## Unknowns
## Appendix: access-matrix CSV

## Landing the output

Per `../../references/output-conventions.md`: security_role, sod_conflict, and finding records as DRAFT via MCP when connected. This skill reads user IDs — treat outputs as INTERNAL; aggregate by role/department in anything widely shared, and never include the raw user-level matrix in an executive deliverable.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
