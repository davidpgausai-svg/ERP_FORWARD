---
name: erp-module-build-guide
description: "Produce a stage-by-stage ERP module build guide (Word docx, optionally with an editable Visio swimlane diagram) that tells someone sitting in front of a blank tenant exactly which tasks to run and in what order. Use this whenever someone on ERP FORWARD asks how to set up, configure, build, or stand up any Workday or ERP module or capability — Position Control, Absence, Time Tracking, Payroll, Recruiting, Benefits, Procure-to-Pay, Grants, Expenses, Security, Core HR — or hands over a Huron FSPD, future-state process map, Visio, fit-gap workbook, or design document and wants it turned into something buildable. Also use it when someone says a design doc 'doesn't tell us how to actually do it', asks 'what order do we set this up in', 'where do I start in the tenant', 'what tasks do I run', or asks for a configuration design, build sheet, setup guide, or module design document. Trigger even when the words 'build guide' are never said."
---

# ERP Module Build Guide

## What this produces

A Word document that a person who has never opened Workday can follow from a blank
tenant to a working configuration, plus (when the request involves a process map) an
editable Visio swimlane diagram.

The distinction that matters: **a design document describes the target state, a build
guide tells you what to do on Monday morning.** Most ERP documentation fails by being
the former while claiming to be the latter. The reader is often a functional expert
with deep domain knowledge and zero tenant experience. They do not need the concept
explained. They need to know which task to type into the search bar, in what order,
and how to tell whether it worked.

## Order of work

Getting this wrong wastes the most tokens, so it is worth stating plainly.

1. **Read the source material.** Whatever was attached: process map, FSPD, workbook,
   decision record. Extract every numbered step, swimlane, decision diamond, and note.
2. **Check the program record layer** for existing records on this topic, so you extend
   what exists instead of duplicating it.
3. **Research the vendor documentation** through the MCP. See `references/research-protocol.md`.
   This is where the real task names and sequences come from.
4. **Ask the design decisions** that change the shape of the build. See below.
5. **Only then** build the deliverable.

Researching after drafting produces a document full of plausible-sounding task names
that do not exist in the tenant. That is worse than no document, because someone will
try to follow it.

## Ask before building

Some decisions change the entire configuration, and guessing wastes a full build cycle.
Identify them from the source material and ask them together in one pass, using
AskUserQuestion where available, with a recommendation marked on the option you would
pick and the configuration consequence stated in each option.

Ask about things like: which staffing or costing model applies, whether a control is
advisory or blocking, whether something is delivered configuration or needs an extension,
which populations are in scope, and what deliverable format is wanted. Cap it at four
questions. If the session is unattended, choose the recommended option, say so at the
top of the document, and continue.

Do not ask questions the source material already answers, and do not ask about things
with a conventional default.

## Document anatomy

Full structure, section by section, is in `references/document-structure.md`. Read it
before writing. The shape in brief:

- **The Build Roadmap**, first page, before the table of contents. A table of stages,
  each an internal hyperlink to its section, with owner and what blocks it. This page
  exists because the reader's actual question is "where do I start", and a table of
  contents ordered by topic does not answer it.
- **Stage 0, orientation.** How to navigate the tenant: search bar, tasks versus reports,
  related actions, effective dating, which tenant to build in. Skip this only when the
  audience is stated to be experienced administrators.
- **Stages in dependency order**, each with owner, prerequisite, what it unblocks,
  numbered tasks, a verification step, and callouts for traps.
- **Appendices**: task index, traceability back to the source process map, open decisions
  and risks, cited sources.

The stage numbering is the deliverable's spine. Order stages by what the system will
refuse to let you build, not by module or by workstream convenience. Say so explicitly
in the roadmap, because readers assume documents are meant to be read front to back.

## Writing tasks

Every configuration instruction names the actual task and what to do with it:

> *Search:* **Edit Budget Check Options**  Set per company, plan structure, and fiscal
> year. Complete the Position tab as below.

Not "configure budget check options". The reader is going to type that string into a
search bar. Give them the string.

Where a task has fields worth calling out, follow it with a table of field, value, and
why. The why column is what makes the guide survive a release upgrade: when the field
moves, the reader still knows what they were trying to achieve.

End every stage with how to verify. Usually this is a report to run and a number to
reconcile. A stage without a verification step produces a build nobody trusts.

## Be honest about what does not work

The most valuable thing in these documents is the part that says a step in the ideal
state cannot be configured as drawn. Every process map contains at least one decision
diamond that routes on a value the system has no field for, or a policy that was never
written down precisely enough to become a rule.

When you find one, say so in the stage where it becomes blocking, log it in the open
decisions appendix with a recommended owner, and offer the options for resolving it.
Do not smooth it over with language that implies it is configurable. Someone will plan
a sprint around the smoothed-over version.

Equally, when the source material is missing a step the build genuinely needs, add it
and flag that you added it, so the process owner can put it back on their diagram.

## Citing

Every configuration claim traces to a retrieved vendor document, cited as a link the
reader can open. Claims that come from general knowledge rather than the corpus get
labeled as such, or get cut. Task labels vary by release, so state once that where the
guide and the tenant disagree, the tenant wins.

## Bundled scripts

Do not hand-write document or diagram generation code. Both builders take a JSON spec
and are already debugged for the things that bite: US Letter sizing, dual-width tables,
numbered lists restarting per section, internal hyperlink anchors, and a Visio package
that actually opens.

```bash
node scripts/build_guide_docx.js spec.json out.docx
python3 scripts/build_swimlane_vsdx.py diagram.json out.vsdx
```

Both spec formats are documented in `references/script-specs.md`, with a minimal
working example of each. Write the spec, run the script, then render and look at the
result before delivering:

```bash
soffice --headless --convert-to pdf out.docx --outdir .
pdftoppm -jpeg -r 70 out.pdf page && ls page-*.jpg
```

Read a few of those images. Rendering catches overflowing tables, broken numbering, and
text escaping its shape, none of which are visible in the spec.

## House style

Applies to every deliverable from this skill. Details in `references/house-style.md`.

- No em dashes anywhere in drafted prose.
- Black text only. No colored headings, no blue horizontal rules, no colored hyperlinks.
- Calibri, US Letter, header and footer with page numbers.
- Tables for anything with more than two parallel attributes. Prose for reasoning.
- Blunt and direct. State the finding, then the consequence. No hedging, no throat-clearing.

## Delivering

Save deliverables to the outputs directory and send them. In the reply, lead with the
answer to what the person actually asked, then surface the two or three findings that
change what they should do next: what is not configurable as designed, what decision is
blocking earlier than it looks, what the source material is missing. Do not summarize
the document's table of contents. They have the document.
