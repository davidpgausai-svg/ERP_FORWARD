# Output Conventions (all ERP FORWARD skills)

Every skill in this plugin produces work that must outlive the chat session. Nothing canonical stays in chat — that is the program's founding rule.

## Where outputs land

1. **Record layer connected (preferred).** When the ERP Record Layer MCP connector is available, write structured outputs there: call `schema_get` with the target `recordType` first (never guess field names — the schema registry is authoritative), create records as DRAFT, attach source citations (extract file + snapshot date, or document name + section), and submit for review when the human confirms. Never attempt to approve anything; approvals are human-only by design.
2. **Record layer not connected (interim).** Produce the output as a file — markdown for narrative deliverables, CSV for inventories — and save it to the extract library's `/analysis/<topic>/` folder (or the session's working folder if the library isn't connected). Name it `<topic>_<instance>_<snapshot-date>.md|csv`. Structure CSVs so they can be imported into the record layer later without rework.

## Standard finding format

When a skill produces findings (issues, risks, anomalies, candidates), use this shape whether writing records or CSV rows:

- title (short, specific)
- description (what was observed, with numbers)
- evidence (source file, snapshot date, instance; example object names or rows)
- proposed disposition or action (a suggestion, clearly labeled as such)
- confidence: HIGH / MEDIUM / LOW, with one line on why
- owner_suggestion (role, not a named person, unless the human names one)

## Attribution and honesty

- Cite every factual claim to an extract file or document. An uncited claim is a hypothesis — label it as one.
- List what you could NOT determine and why (missing pack, telemetry gap, ambiguous data). The unknowns list is often the most valuable part of the output — it becomes the interview agenda for SMEs.
- Round numbers honestly; never present a sampled result as a full-population result.

## Tone for human-facing deliverables

Executive-ready: plain language, lead with the conclusion, keep internal object names in appendices with navigation breadcrumbs alongside. Black font, no horizontal divider bars in documents.
