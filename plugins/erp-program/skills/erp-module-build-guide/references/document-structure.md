# Document structure

The anatomy of a build guide, in order. Adapt proportions to the module, keep the spine.

## 1. Cover

Program name, module, "Build Guide and Configuration Design", a one-line statement of
what it is for ("Step-by-step setup order for a new Workday tenant"), organization,
version, date, named owners.

## 2. The Build Roadmap

**Before the table of contents.** This is the most important page and it answers the
question the reader actually has.

Open by saying the order explicitly, including that it is not the order the document
happens to be written in. If the reader has asked something like "do I just work
through 1 to 9", answer that sentence directly in the text. Then a table:

| Column | Content |
|---|---|
| Stage | Number and short name, as an internal hyperlink to the section |
| What you build | One line, concrete |
| Who owns it | Workstream or role, resolved against `workstream_list` |
| You cannot start until | The blocking prerequisite, named as a stage |

Close with a callout setting time expectations, especially where early stages are
platform work owned by other workstreams. Readers otherwise assume every stage is
theirs and panic at the scope.

## 3. Contents

Standard field-driven table of contents with a line telling the reader to right-click
and update the field, because it renders empty until they do and that reads as a defect.

## 4. Stage 0, orientation

For readers new to the platform. Include:

- How search works, and that tasks change things while reports only show things
- The related actions menu, since a large share of configuration is reachable nowhere else
- Any search shortcuts worth knowing, such as the `bp:` prefix for business processes
- The handful of objects this module actually runs on, in plain English, in a table
- Which tenant to build in, and that production is never configured first
- Two or three rules that prevent lost days: effective dating, security changes needing
  activation, and build-before-reference

Skip this stage only when the audience is stated to be experienced administrators.

## 5. The stages

One section each, in dependency order. Every stage opens with a single line:

> **Owner:** X.  **Prerequisite:** Stage N.  **Unblocks:** what this makes possible.

Then a short paragraph on what this stage is and why it sits here. Then:

**Tasks in order.** Numbered. Each names the real task:

> *Search:* **Task Name**  What to do with it.

Sub-bullets under a task for fields that need explanation. A field table where there
are more than three fields worth calling out, with a why column.

**Verify before moving on.** A report to run, a reconciliation to perform, or a
specific thing to look at. Concrete enough to fail.

**Callout** where a trap exists: a one-way door, a value that cannot be changed later,
a constraint that shapes a decision elsewhere.

A stage that is entirely owned by another workstream is still a stage. Say what it is,
say who owns it, say that the job here is to confirm it is complete, and move on.

## 6. Testing and training stage

End-to-end scenarios as a table of scenario and what it proves. Scenarios must cover
the conditional paths, not just the happy path, because conditional routing is where
these builds break. Data validation checklist. Training needs by audience, expressed as
what each audience must be able to do rather than what they must be told.

## 7. Phasing stage, where a phased control was chosen

What changes at cutover, exit criteria expressed as evidence rather than dates, and the
instrumentation needed during phase one to produce that evidence. Name the behavioral
risk of the soft phase honestly.

## 8. Appendix A, task index

Every task and report named anywhere in the guide, alphabetically, with the stage it
belongs to and a one-line purpose. This is how the guide gets used after the first read:
someone hits a task in the tenant and works backward.

## 9. Appendix B, traceability

Every numbered step of the source process map mapped to the stage that builds it, the
object that delivers it, and an honest assessment column. The assessment column is the
point. Values like "direct match", "not in the source map, this design adds it", or
"blocked on a decision" are what make this table worth reading.

## 10. Appendix C, open decisions and risks

Decisions as ID, decision, the stage it blocks, and a recommended owner. Number them
so the rest of the document can reference them inline, and reference them from the
stage where they bite. Risks as risk, impact, mitigation.

## 11. Appendix D, sources

Grouped by topic. Every link opens the vendor page. One sentence noting that task
labels vary by release and the tenant wins where they disagree. Program inputs listed
separately: the source process map with its date, related program records, companion
diagrams.

## Length

A substantial module lands around 25 to 35 pages. Shorter than 15 usually means the
research was thin. Much longer usually means design discussion has crept in that
belongs in a decision record.
