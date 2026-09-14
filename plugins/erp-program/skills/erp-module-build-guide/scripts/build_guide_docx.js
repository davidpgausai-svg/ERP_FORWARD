#!/usr/bin/env node
/*
 * build_guide_docx.js — renders an ERP build guide from a JSON spec.
 *
 *   node build_guide_docx.js spec.json out.docx
 *
 * Spec format is documented in references/script-specs.md.
 * Handles the things that normally go wrong: US Letter sizing, dual-width tables,
 * numbered lists restarting per section, internal hyperlink anchors, black-only text.
 */
const fs = require("fs");
const d = require("docx");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow,
  TableCell, WidthType, ShadingType, BorderStyle, PageBreak, Header, Footer, PageNumber,
  TableOfContents, LevelFormat, convertInchesToTwip, PositionalTab, PositionalTabAlignment,
  PositionalTabLeader, ExternalHyperlink, InternalHyperlink, Bookmark
} = d;

const BLACK = "000000";
const TW = 9360;              // 6.5in usable width, DXA
const FONT = "Calibri";
let inst = 0;                 // numbering instance; bumped per heading so lists restart

const specPath = process.argv[2];
const outPath = process.argv[3];
if (!specPath || !outPath) {
  console.error("usage: node build_guide_docx.js <spec.json> <out.docx>");
  process.exit(1);
}
const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
const meta = spec.meta || {};

// ---------------------------------------------------------------- primitives
const run = (text, o = {}) => new TextRun({
  text, color: BLACK, font: FONT, size: o.size || 21,
  bold: !!o.bold, italics: !!o.italics, underline: o.underline ? {} : undefined,
  characterSpacing: o.spacing
});

function para(text, o = {}) {
  return new Paragraph({
    spacing: { after: o.after === undefined ? 120 : o.after, before: o.before, line: 276 },
    alignment: o.align,
    children: [run(text, o)]
  });
}

function richPara(runs, o = {}) {
  return new Paragraph({
    spacing: { after: 120, line: 276 },
    children: runs.map(r => run(r.t, { bold: r.b, italics: r.i, size: o.size || 21 }))
  });
}

function heading(text, level, anchor) {
  inst += 1;
  const size = { 1: 30, 2: 25, 3: 22 }[level] || 22;
  const r = run(text, { bold: true, size });
  return new Paragraph({
    heading: HeadingLevel["HEADING_" + level],
    spacing: { before: level === 1 ? 320 : 260, after: 140 },
    children: anchor ? [new Bookmark({ id: anchor, children: [r] })] : [r]
  });
}

const bulletPara = (text, level = 0) => new Paragraph({
  numbering: { reference: "bullets", level },
  spacing: { after: level ? 50 : 60, line: 276 },
  children: [run(text, { size: level ? 20 : 21 })]
});

const stepPara = text => new Paragraph({
  numbering: { reference: "steps", level: 0, instance: inst },
  spacing: { after: 80, line: 276 },
  children: [run(text)]
});

const taskPara = (name, instruction) => new Paragraph({
  numbering: { reference: "steps", level: 0, instance: inst },
  spacing: { after: 80, line: 276 },
  children: [
    run("Search: ", { italics: true }),
    run(name, { bold: true }),
    run("  " + (instruction || ""))
  ]
});

function cellPara(text, bold, anchor) {
  if (anchor) {
    return new Paragraph({
      spacing: { before: 40, after: 40, line: 250 },
      children: [new InternalHyperlink({ anchor,
        children: [run(String(text), { bold: true, size: 18, underline: true })] })]
    });
  }
  return new Paragraph({
    spacing: { before: 40, after: 40, line: 250 },
    children: [run(String(text), { bold: !!bold, size: 18 })]
  });
}

function buildTable(headers, rows, widths) {
  const w = widths && widths.length === headers.length
    ? widths : headers.map(() => 1);
  const total = w.reduce((a, b) => a + b, 0);
  const scaled = w.map(x => Math.round(x / total * TW));
  scaled[0] += TW - scaled.reduce((a, b) => a + b, 0);
  const bd = { style: BorderStyle.SINGLE, size: 4, color: "808080" };
  const borders = { top: bd, bottom: bd, left: bd, right: bd };

  const headRow = new TableRow({
    tableHeader: true,
    children: headers.map((t, i) => new TableCell({
      width: { size: scaled[i], type: WidthType.DXA },
      shading: { type: ShadingType.CLEAR, fill: "D9D9D9", color: "auto" },
      borders, children: [cellPara(t, true)]
    }))
  });

  const bodyRows = rows.map(r => new TableRow({
    children: r.map((cv, i) => {
      let txt = cv, anchor = null;
      if (cv && typeof cv === "object") { txt = cv.t; anchor = cv.link || cv.anchor; }
      return new TableCell({
        width: { size: scaled[i], type: WidthType.DXA }, borders,
        children: anchor ? [cellPara(txt, true, anchor)]
                         : String(txt).split("\n").map(l => cellPara(l))
      });
    })
  }));

  return new Table({ columnWidths: scaled, width: { size: TW, type: WidthType.DXA },
                     rows: [headRow, ...bodyRows] });
}

function calloutBox(title, body) {
  const bd = { style: BorderStyle.SINGLE, size: 4, color: "808080" };
  return new Table({
    columnWidths: [TW], width: { size: TW, type: WidthType.DXA },
    rows: [new TableRow({ children: [new TableCell({
      width: { size: TW, type: WidthType.DXA },
      borders: { top: bd, bottom: bd, left: bd, right: bd },
      shading: { type: ShadingType.CLEAR, fill: "F2F2F2", color: "auto" },
      children: [new Paragraph({
        spacing: { before: 80, after: 80, line: 260 },
        children: [run(title + "  ", { bold: true, size: 19 }), run(body, { size: 19 })]
      })]
    })] })]
  });
}

const srcPara = (label, url) => new Paragraph({
  spacing: { after: 80, line: 276 },
  children: [
    run(label + ": ", { size: 19 }),
    new ExternalHyperlink({ link: url,
      children: [run(url, { size: 16, underline: true })] })
  ]
});

const metaLine = m => richPara([
  { t: "Owner: ", b: true }, { t: (m.owner || "") + ".  " },
  ...(m.prereq ? [{ t: "Prerequisite: ", b: true }, { t: m.prereq + ".  " }] : []),
  ...(m.unblocks ? [{ t: "Unblocks: ", b: true }, { t: m.unblocks + "." }] : [])
]);

const pageBreak = () => new Paragraph({ children: [new PageBreak()] });
const gap = () => new Paragraph({ spacing: { after: 100 }, children: [] });

// ---------------------------------------------------------------- block render
function renderBlock(b, out) {
  if (b.pagebreak) return out.push(pageBreak());
  if (b.gap) return out.push(gap());
  if (b.h2 !== undefined) return out.push(heading(b.h2, 2, b.anchor));
  if (b.h3 !== undefined) return out.push(heading(b.h3, 3, b.anchor));
  if (b.p !== undefined) return out.push(para(b.p, b));
  if (b.rich) return out.push(richPara(b.rich));
  if (b.meta) return out.push(metaLine(b.meta));
  if (b.bullet !== undefined) return out.push(bulletPara(b.bullet, b.level || 0));
  if (b.sub !== undefined) return out.push(bulletPara(b.sub, 1));
  if (b.step !== undefined) return out.push(stepPara(b.step));
  if (b.task) return out.push(taskPara(b.task[0], b.task[1]));
  if (b.table) return out.push(buildTable(b.table.headers, b.table.rows, b.table.widths));
  if (b.callout) return out.push(calloutBox(b.callout[0], b.callout[1]));
  if (b.src) return out.push(srcPara(b.src[0], b.src[1]));
  throw new Error("unknown block: " + JSON.stringify(b).slice(0, 120));
}

// ---------------------------------------------------------------- assemble
const children = [];

// Cover
if (meta.program) children.push(new Paragraph({
  spacing: { before: 2000, after: 200 }, alignment: AlignmentType.CENTER,
  children: [run(meta.program, { bold: true, size: 28, spacing: 60 })] }));
children.push(new Paragraph({ spacing: { after: 120 }, alignment: AlignmentType.CENTER,
  children: [run(meta.title || "Build Guide", { bold: true, size: 52 })] }));
if (meta.subtitle) children.push(new Paragraph({ spacing: { after: 360 }, alignment: AlignmentType.CENTER,
  children: [run(meta.subtitle, { size: 32 })] }));
if (meta.tagline) children.push(new Paragraph({ spacing: { after: 60 }, alignment: AlignmentType.CENTER,
  children: [run(meta.tagline, { size: 24 })] }));
if (meta.scope) children.push(new Paragraph({ spacing: { after: 800 }, alignment: AlignmentType.CENTER,
  children: [run(meta.scope, { size: 24 })] }));
if (meta.org) children.push(new Paragraph({ spacing: { after: 60 }, alignment: AlignmentType.CENTER,
  children: [run(meta.org, { size: 22 })] }));
if (meta.version) children.push(new Paragraph({ spacing: { after: 60 }, alignment: AlignmentType.CENTER,
  children: [run(meta.version, { size: 20 })] }));
if (meta.owners) children.push(new Paragraph({ alignment: AlignmentType.CENTER,
  children: [run(meta.owners, { size: 20 })] }));
children.push(pageBreak());

// Roadmap
if (spec.roadmap) {
  const r = spec.roadmap;
  children.push(heading(r.title || "The Build Roadmap", 1, r.anchor || "roadmap"));
  (r.intro || []).forEach(t => children.push(para(t)));
  if (r.directAnswer) children.push(richPara([
    { t: r.directAnswer.lead, b: true }, { t: r.directAnswer.body }
  ]));
  children.push(gap());
  children.push(buildTable(
    r.columns || ["Stage", "What you build", "Who owns it", "You cannot start until"],
    (r.stages || []).map(s => [
      { t: s.label, link: s.anchor }, s.build, s.owner, s.blocked
    ]),
    r.widths || [17, 37, 16, 30]
  ));
  if (r.callout) { children.push(gap()); children.push(calloutBox(r.callout[0], r.callout[1])); }
  children.push(pageBreak());
}

// Contents
if (spec.toc !== false) {
  children.push(heading("Contents", 1));
  children.push(para("Right-click the table below and choose Update Field to populate page numbers.",
    { italics: true, size: 19 }));
  children.push(new TableOfContents("Contents", { hyperlink: true, headingStyleRange: "1-2" }));
  children.push(pageBreak());
}

// Sections
(spec.sections || []).forEach((sec, i) => {
  children.push(heading(sec.text, sec.h || 1, sec.anchor));
  (sec.blocks || []).forEach(b => renderBlock(b, children));
  if (sec.pagebreakAfter !== false && i < spec.sections.length - 1) children.push(pageBreak());
});

// ---------------------------------------------------------------- document
const doc = new Document({
  creator: meta.program || "ERP Forward",
  title: meta.title || "Build Guide",
  description: meta.subtitle || "",
  numbering: { config: [
    { reference: "bullets", levels: [
      { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: convertInchesToTwip(0.32), hanging: convertInchesToTwip(0.2) } } } },
      { level: 1, format: LevelFormat.BULLET, text: "◦", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: convertInchesToTwip(0.68), hanging: convertInchesToTwip(0.2) } } } }
    ]},
    { reference: "steps", levels: [
      { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: convertInchesToTwip(0.38), hanging: convertInchesToTwip(0.26) } } } }
    ]}
  ]},
  styles: { default: { document: { run: { font: FONT, size: 21, color: BLACK } } } },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 },
      margin: { top: 1080, bottom: 1080, left: 1080, right: 1080 } } },
    headers: { default: new Header({ children: [new Paragraph({
      alignment: AlignmentType.RIGHT,
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "808080", space: 6 } },
      children: [run(meta.headerText || meta.title || "", { size: 16 })]
    })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ children: [
      run(meta.footerText || "", { size: 16 }),
      new TextRun({ children: [new PositionalTab({
        alignment: PositionalTabAlignment.RIGHT, relativeTo: "margin",
        leader: PositionalTabLeader.NONE })], color: BLACK, size: 16 }),
      new TextRun({ children: ["Page ", PageNumber.CURRENT, " of ", PageNumber.TOTAL_PAGES],
        color: BLACK, size: 16, font: FONT })
    ] })] }) },
    children
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(outPath, buf);
  console.log(`wrote ${outPath} (${buf.length} bytes, ${children.length} blocks)`);
}).catch(e => { console.error(e); process.exit(1); });
