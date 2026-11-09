# Output Conventions (all ERP FORWARD skills)

Every skill in this plugin produces work that must outlive the chat session. Nothing canonical stays in chat — that is the program's founding rule.

## Where outputs land

1. **Record layer connected (preferred).** When the ERP Forward MCP connector is available, write structured outputs there, following the server's own record rules (see "The server is the source of truth" below). Use `business_process_submit_group` for a process and its children. Put source citations in the description (extract file + snapshot date, or document name + section). When the drafts are ready, tell the person they submit each one in Keystone, where they choose the approval route.
2. **Record layer not connected (interim).** Produce the output as a file — markdown for narrative deliverables, CSV for inventories — and save it to the extract library's `/analysis/<topic>/` folder (or the session's working folder if the library isn't connected). Name it `<topic>_<instance>_<snapshot-date>.md|csv`. Structure CSVs so they can be imported into the record layer later without rework.

## The server is the source of truth

The ERP Forward server owns the rules for working with its records, and skills do not repeat them:

- Its **server instructions** hold the rules every conversation needs: drafts only, never claiming an unreturned record id, DRAFT versus APPROVED, citations versus read sources, paging, the glossary before claiming absence, and asking when several records match.
- Its **`guide_get` tool** holds the full rules by topic: `records`, `evidence`, `tool-families`, `operating-model`, `foundation`, `access` and `erp-evaluation`. A skill that works in a module says which topic to read first. If the server instructions look missing or cut off, read `full`.

When a skill and the server disagree, the server wins; propose a fix to the skill.

One rule the server does not state: Claude cannot upload files through MCP. A person uploads files in Keystone; the only authored content Claude can attach is BPMN XML, through `record_bpmn_attach`.

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
