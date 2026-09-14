# Script specs

Both builders take JSON and write a file. Write the spec, run the script, render the
result, look at it.

## build_guide_docx.js

```bash
node scripts/build_guide_docx.js spec.json ERP_Forward_<Module>_Build_Guide.docx
```

### Top level

```json
{
  "meta": {
    "program": "ERP FORWARD",
    "title": "Workday Position Control",
    "subtitle": "Build Guide and Configuration Design",
    "tagline": "Step-by-step setup order for a new Workday tenant",
    "scope": "HR, Finance, and IT Integrations",
    "org": "University of Missouri System and MU Health Care",
    "version": "Version 0.2  |  Draft for Workstream Review  |  September 14, 2026",
    "owners": "Owners: HR Core Workstream and FIN Accounting Record-to-Report",
    "headerText": "ERP Forward  |  Workday Position Control Build Guide",
    "footerText": "Draft 0.2  |  September 14, 2026"
  },
  "roadmap": { "...": "see below" },
  "toc": true,
  "sections": [ { "...": "see below" } ]
}
```

### Roadmap

```json
"roadmap": {
  "title": "The Build Roadmap",
  "anchor": "roadmap",
  "intro": ["Start here. This is the order to build..."],
  "directAnswer": {
    "lead": "Answering the question directly: ",
    "body": "no, you do not work through sections 1 to 9 in order."
  },
  "stages": [
    {"label": "0. Orientation", "anchor": "s0", "build": "Learn how to navigate Workday",
     "owner": "Everyone", "blocked": "Nothing. Read this first."}
  ],
  "callout": ["Time expectation.", "Stages 1 through 6 are platform work..."],
  "widths": [17, 37, 16, 30]
}
```

Each stage's `anchor` must match the `anchor` on the matching section, or the hyperlink
goes nowhere.

### Sections and blocks

```json
"sections": [
  {
    "text": "Stage 2. Tenant Setup",
    "anchor": "s2",
    "h": 1,
    "blocks": [
      {"meta": {"owner": "HR Core", "prereq": "Staffing model decision",
                "unblocks": "Everything in HCM"}},
      {"p": "These settings are tenant-wide."},
      {"h2": "2.1 The Task"},
      {"task": ["Edit Tenant Setup - HCM", "This one task holds all the settings below."]},
      {"table": {"headers": ["Setting", "Set it to", "Why"],
                 "rows": [["Position Management", "Enabled", "Prerequisite for..."]],
                 "widths": [30, 22, 48]}},
      {"gap": true},
      {"callout": ["One-way door.", "Once commitments have been generated..."]}
    ]
  }
]
```

Block types:

| Block | Renders |
|---|---|
| `{"p": "text"}` | Paragraph. Add `"italics": true`, `"bold": true`, `"size": 19` |
| `{"rich": [{"t": "Lead. ", "b": true}, {"t": "rest"}]}` | Mixed bold and plain in one paragraph |
| `{"h2": "text"}` / `{"h3": "text"}` | Sub-headings. Optional `"anchor"` |
| `{"meta": {"owner", "prereq", "unblocks"}}` | The bolded stage header line |
| `{"bullet": "text"}` | Bulleted item. `"level": 1` for a sub-bullet |
| `{"sub": "text"}` | Sub-bullet, shorthand for level 1 |
| `{"step": "text"}` | Numbered item, restarts each heading |
| `{"task": ["Task Name", "instruction"]}` | Numbered *Search:* **Task Name** instruction |
| `{"table": {headers, rows, widths}}` | Table. `widths` are relative, any scale |
| `{"callout": ["Title.", "body"]}` | Grey bordered box |
| `{"src": ["Label", "https://..."]}` | Source citation line |
| `{"gap": true}` / `{"pagebreak": true}` | Spacing and page breaks |

Table cells accept `"text"`, `"line one\nline two"` for multi-paragraph cells, or
`{"t": "Label", "link": "anchor"}` for an internal hyperlink.

A page break is inserted automatically between sections. Set `"pagebreakAfter": false`
on a section to suppress it.

## build_swimlane_vsdx.py

```bash
python3 scripts/build_swimlane_vsdx.py diagram.json ERP_Forward_<Module>_Future_State.vsdx
```

```json
{
  "page": {
    "width": 62.0, "height": 32.0, "name": "Create or Edit Position",
    "title": "ERP Forward | Future State: Create or Edit Position",
    "subtitle": "Hybrid staffing model | Budget check phased Warn to Control",
    "laneLabelWidth": 2.6
  },
  "grid": {"x0": 3.9, "width": 4.35},
  "lanes": [
    {"name": "Hiring Manager", "height": 4.2},
    {"name": "Workday (Automated)", "height": 4.6}
  ],
  "nodes": [
    {"id": "n1", "lane": "Hiring Manager", "col": 0, "kind": "start",
     "label": "1a\nDetermine need for\nnew position", "offset": 1.05}
  ],
  "edges": [
    {"from": "n1", "to": "n2", "fromSide": "r", "toSide": "l",
     "style": "elbow", "label": "Yes"}
  ],
  "notes": "NOTES:  Step 3 defaults worktags from...",
  "notesHeight": 1.9
}
```

- `kind`: `start`, `end`, `task`, `sub` (dashed grey, for subprocesses), `decision` (diamond).
- `col` is a grid column index; `offset` shifts a node vertically within its lane, which
  is how two shapes share one lane without colliding. Keep the gap between offsets larger
  than the node height or they overlap.
- `style`: `direct` (straight), `elbow` (orthogonal via midpoint), `below` (routes under
  all lanes, for send-backs), `overlane` (routes above the source lane, for bypasses).
  `track` (0, 1, 2) separates multiple `below` or `overlane` routes so they do not overlap.
- `dashed: true` for exception and send-back paths.
- `labelAt: [x, y]` overrides automatic label placement in page inches.

### Sizing

Nodes are fixed sizes, so a lane shorter than its tallest node lets the shape overflow
into the lane below and collide with whatever routes through there. Minimum lane height:

| Tallest node kind in the lane | Node height | Minimum lane height |
|---|---|---|
| `start`, `end` | 1.5 | 2.1 |
| `task` | 1.7 | 2.3 |
| `sub` | 1.9 | 2.5 |
| `decision` | 2.3 | 2.9 |

Two nodes stacked in one lane need `height >= nodeHeight * 2 + 0.8`, with their offsets
at least `nodeHeight + 0.2` apart. Two tasks stacked means a lane of 4.2 and offsets of
plus and minus 1.0.

Page height must exceed the sum of lane heights plus the title band plus the notes box,
or content falls off the page. Add them up before setting `height`. If lanes total 27.2,
title is 1.4 and notes are 1.9, the page needs at least 31. Leave 0.8 of clearance below
the last lane for every `below` routing track you use.

### Verifying

LibreOffice imports vsdx, so rendering it proves the package is valid and shows the
layout:

```bash
soffice --headless --convert-to pdf out.vsdx --outdir .
pdftoppm -jpeg -r 55 out.pdf vis && ls vis*
```

Read the image. Look for shapes overlapping, text escaping its box, and content cut off
at the page edge.
