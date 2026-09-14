# House style

These are program conventions. They are not aesthetic preferences, they exist so that
documents from different authors read as one program.

## Typography and color

- Calibri throughout. Body 10.5pt, H1 15pt, H2 12.5pt, H3 11pt, table text 9pt.
- US Letter, one inch margins. Page size must be set explicitly, because the default
  in most document libraries is A4 and it silently reflows everything.
- **Black text only.** Headings, links, table headers, everything. Hyperlinks are
  underlined, not blue. Colored text reads as a different template and reviewers
  comment on it instead of on the content.
- Table header shading is light grey. Never use solid shading, which renders black.
- No horizontal rules as decoration, and never a colored one. The header border line
  is the only rule in the document.

## Prose

- **No em dashes.** Use a comma, a colon, a full stop, or restructure the sentence.
  This one gets checked.
- Blunt and direct. State the finding, then its consequence. Cut hedging: "it may be
  worth considering" becomes "do this" or gets deleted.
- No throat-clearing openers. The first sentence of a section carries information.
- Explain why, not just what. A reader who understands the reason can adapt when the
  tenant does not match the guide. A reader following rote steps cannot.
- Second person for instructions. "You cannot change this after the position is filled"
  lands harder than "this cannot be changed".

## Structure

- Tables for anything with three or more parallel attributes. Prose for reasoning and
  for anything with a causal chain.
- Bullets for unordered sets. Numbered lists only for genuine sequences, and numbering
  restarts in each section, which the bundled script handles.
- Callout boxes for traps, one-way doors, and constraints that surprise people mid-build.
  Used sparingly, roughly one per stage at most, or they stop registering.
- Every table gets a header row that repeats across page breaks.

## Naming

- Workday task and report names in bold, spelled exactly as they appear in the tenant.
- Object names in plain text using the tenant's vocabulary, not a paraphrase. If the
  tenant says position restriction, the document says position restriction.
- Program vocabulary as the program uses it: ERP FORWARD, workstream names, PCC, FSPD.

## Deliverable naming

`ERP_Forward_<Module>_<Artifact>.<ext>`, for example
`ERP_Forward_Position_Control_Build_Guide.docx`. No dates or version numbers in
filenames, because those live in the document and filenames with dates end up stale
in someone's downloads folder.

## Front matter

Cover page, then the roadmap, then contents. Version, date, and named owners on the
cover. Draft status stated plainly when it is a draft: reviewers treat an unlabeled
document as final and route it onward.
