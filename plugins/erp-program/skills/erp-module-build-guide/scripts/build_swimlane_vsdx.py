#!/usr/bin/env python3
"""
build_swimlane_vsdx.py — renders an editable Visio 2013+ (.vsdx) swimlane flowchart
from a JSON spec.

    python3 build_swimlane_vsdx.py diagram.json out.vsdx

Spec format is documented in references/script-specs.md. Produces masterless shapes
with inline geometry, which is what makes the file open cleanly in Visio while every
shape stays individually editable.
"""
import json
import os
import sys
import zipfile
from xml.sax.saxutils import escape

NS = "http://schemas.microsoft.com/office/visio/2012/main"

NODE_SIZE = {
    "start":    (3.3, 1.5),
    "end":      (3.3, 1.5),
    "task":     (3.5, 1.7),
    "sub":      (3.5, 1.9),
    "decision": (3.6, 2.3),
}
NODE_FILL = {
    "start": "#FFFFFF", "end": "#FFFFFF", "task": "#FFFFFF",
    "sub": "#E8E8E8", "decision": "#FFFFFF",
}


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: build_swimlane_vsdx.py <diagram.json> <out.vsdx>")
    spec = json.load(open(sys.argv[1]))
    out_path = sys.argv[2]

    page = spec.get("page", {})
    PAGE_W = page.get("width", 62.0)
    PAGE_H = page.get("height", 32.0)
    LANE_X = 0.4
    LANE_W = PAGE_W - 0.8
    LABEL_W = page.get("laneLabelWidth", 2.6)
    TITLE_H = 1.4 if page.get("title") else 0.3

    lanes = spec.get("lanes", [])
    lane_top, lane_bot = {}, {}
    y = PAGE_H - TITLE_H
    for lane in lanes:
        lane_top[lane["name"]] = y
        y -= lane.get("height", 3.0)
        lane_bot[lane["name"]] = y
    LANE_BOTTOM = y

    grid = spec.get("grid", {})
    COL0 = grid.get("x0", 3.9)
    COLW = grid.get("width", 4.35)
    cx = lambda c: COL0 + c * COLW

    def lane_mid(name, off=0.0):
        return (lane_top[name] + lane_bot[name]) / 2.0 + off

    pos = {}
    for n in spec.get("nodes", []):
        kind = n.get("kind", "task")
        w, h = NODE_SIZE.get(kind, NODE_SIZE["task"])
        pos[n["id"]] = (cx(n["col"]), lane_mid(n["lane"], n.get("offset", 0.0)), w, h, kind)

    def port(nid, side):
        x, yy, w, h, _ = pos[nid]
        return {"r": (x + w / 2, yy), "l": (x - w / 2, yy),
                "t": (x, yy + h / 2), "b": (x, yy - h / 2)}[side]

    # ------------------------------------------------------------ XML helpers
    counter = [0]

    def new_id():
        counter[0] += 1
        return counter[0]

    def cell(n, v):
        return f'<Cell N="{n}" V="{v}"/>'

    def txt_cells(w, h):
        return (cell("TxtWidth", round(w, 4)) + cell("TxtHeight", round(h, 4))
                + cell("TxtPinX", round(w / 2, 4)) + cell("TxtPinY", round(h / 2, 4))
                + cell("TxtLocPinX", round(w / 2, 4)) + cell("TxtLocPinY", round(h / 2, 4))
                + cell("TxtAngle", 0))

    def text_el(label):
        if not label:
            return "<Text/>"
        return "<Text>" + "\n".join(escape(l) for l in label.split("\n")) + "</Text>"

    def char_para(size=11, bold=False, align=1):
        c = (f'<Section N="Character"><Row IX="0">{cell("Size", size / 72.0)}'
             f'{cell("Style", 1 if bold else 0)}{cell("Color", "#000000")}'
             f'{cell("Font", "Arial")}</Row></Section>')
        p = (f'<Section N="Paragraph"><Row IX="0">{cell("HorzAlign", align)}'
             f'{cell("SpLine", -1.2)}</Row></Section>')
        return c + p

    def geom(rows, nofill=0):
        out = [f'<Section N="Geometry" IX="0">{cell("NoFill", nofill)}{cell("NoLine", 0)}']
        for i, (t, x, yy) in enumerate(rows, start=1):
            out.append(f'<Row T="{t}" IX="{i}">{cell("X", x)}{cell("Y", yy)}</Row>')
        out.append("</Section>")
        return "".join(out)

    RECT = [("RelMoveTo", 0, 0), ("RelLineTo", 1, 0), ("RelLineTo", 1, 1),
            ("RelLineTo", 0, 1), ("RelLineTo", 0, 0)]
    DIAMOND = [("RelMoveTo", 0.5, 0), ("RelLineTo", 1, 0.5), ("RelLineTo", 0.5, 1),
               ("RelLineTo", 0, 0.5), ("RelLineTo", 0.5, 0)]

    def shape_box(x, yy, w, h, label, kind, fill, font=11, bold=False, valign=1):
        i = new_id()
        g = geom(DIAMOND if kind == "decision" else RECT)
        dash = cell("LinePattern", 2) if kind == "sub" else cell("LinePattern", 1)
        rounding = 0.12 if kind in ("task", "sub", "start", "end") else 0
        return (f'<Shape ID="{i}" NameU="{kind}.{i}" Type="Shape" LineStyle="0" '
                f'FillStyle="0" TextStyle="0">'
                f'{cell("PinX", round(x, 4))}{cell("PinY", round(yy, 4))}'
                f'{cell("Width", w)}{cell("Height", h)}'
                f'{cell("LocPinX", w / 2)}{cell("LocPinY", h / 2)}{cell("Angle", 0)}'
                f'{cell("FillForegnd", fill)}{cell("FillPattern", 1)}'
                f'{cell("LineColor", "#000000")}{cell("LineWeight", 0.0104)}{dash}'
                f'{cell("Rounding", rounding)}{cell("VerticalAlign", valign)}'
                f'{txt_cells(w, h)}{char_para(font, bold)}{g}{text_el(label)}</Shape>')

    def shape_band(x, yy, w, h, fill, label=None, font=12):
        i = new_id()
        extra = (f'{cell("VerticalAlign", 1)}{txt_cells(w, h)}{char_para(font, True)}'
                 if label else "")
        return (f'<Shape ID="{i}" NameU="Lane.{i}" Type="Shape" LineStyle="0" '
                f'FillStyle="0" TextStyle="0">'
                f'{cell("PinX", x + w / 2)}{cell("PinY", yy + h / 2)}'
                f'{cell("Width", w)}{cell("Height", h)}'
                f'{cell("LocPinX", w / 2)}{cell("LocPinY", h / 2)}'
                f'{cell("FillForegnd", fill)}{cell("FillPattern", 1)}'
                f'{cell("LineColor", "#7F7F7F")}{cell("LineWeight", 0.0104)}'
                f'{extra}{geom(RECT)}{text_el(label)}</Shape>')

    def shape_line(points, arrow=True, dashed=False):
        i = new_id()
        rows = []
        for j, (px, py) in enumerate(points, start=1):
            rows.append(("MoveTo" if j == 1 else "LineTo", round(px, 4), round(py, 4)))
        return (f'<Shape ID="{i}" NameU="Connector.{i}" Type="Shape" LineStyle="0" '
                f'FillStyle="0" TextStyle="0">'
                f'{cell("PinX", 0)}{cell("PinY", 0)}{cell("Width", 1)}{cell("Height", 1)}'
                f'{cell("LocPinX", 0)}{cell("LocPinY", 0)}'
                f'{cell("LineColor", "#000000")}{cell("LineWeight", 0.0104)}'
                f'{cell("LinePattern", 3 if dashed else 1)}'
                f'{cell("EndArrow", 4 if arrow else 0)}{cell("EndArrowSize", 2)}'
                f'{geom(rows, nofill=1)}<Text/></Shape>')

    def shape_label(x, yy, label, font=10, w=2.6, h=0.62, border=False, valign=1, align=1):
        i = new_id()
        return (f'<Shape ID="{i}" NameU="Label.{i}" Type="Shape" LineStyle="0" '
                f'FillStyle="0" TextStyle="0">'
                f'{cell("PinX", round(x, 4))}{cell("PinY", round(yy, 4))}'
                f'{cell("Width", w)}{cell("Height", h)}'
                f'{cell("LocPinX", w / 2)}{cell("LocPinY", h / 2)}'
                f'{cell("FillForegnd", "#FFFFFF")}{cell("FillPattern", 1)}'
                f'{cell("LineColor", "#000000" if border else "#FFFFFF")}'
                f'{cell("LinePattern", 1 if border else 0)}'
                f'{cell("VerticalAlign", valign)}{txt_cells(w, h)}'
                f'{char_para(font, False, align)}{geom(RECT)}{text_el(label)}</Shape>')

    # ------------------------------------------------------------ routing
    def route(a, sa, b, sb, style, track=0):
        p1, p2 = port(a, sa), port(b, sb)
        if style == "direct" or abs(p1[1] - p2[1]) < 0.02:
            return [p1, p2]
        if style == "below":
            yb = LANE_BOTTOM + 0.55 + track * 0.8
            return [p1, (p1[0], yb), (p2[0], yb), p2]
        if style == "overlane":
            yt = lane_top[next(n["lane"] for n in spec["nodes"] if n["id"] == a)] + 0.5 + track * 0.7
            return [p1, (p1[0], yt), (p2[0], yt), p2]
        mid = (p1[0] + p2[0]) / 2.0
        return [p1, (mid, p1[1]), (mid, p2[1]), p2]

    # ------------------------------------------------------------ assemble
    shapes = []
    if page.get("title"):
        shapes.append(shape_label(PAGE_W / 2, PAGE_H - 0.55, page["title"],
                                  font=24, w=min(40, LANE_W), h=0.8))
    if page.get("subtitle"):
        shapes.append(shape_label(PAGE_W / 2, PAGE_H - 1.05, page["subtitle"],
                                  font=13, w=min(40, LANE_W), h=0.55))

    fills = ["#F2F2F2", "#FFFFFF"]
    for idx, lane in enumerate(lanes):
        name, h = lane["name"], lane.get("height", 3.0)
        shapes.append(shape_band(LANE_X + LABEL_W, lane_bot[name], LANE_W - LABEL_W, h,
                                 fills[idx % 2]))
        shapes.append(shape_band(LANE_X, lane_bot[name], LABEL_W, h, "#D9D9D9", name))

    for n in spec.get("nodes", []):
        x, yy, w, h, kind = pos[n["id"]]
        shapes.append(shape_box(x, yy, w, h, n.get("label", ""), kind,
                                NODE_FILL.get(kind, "#FFFFFF")))

    for e in spec.get("edges", []):
        pts = route(e["from"], e.get("fromSide", "r"), e["to"], e.get("toSide", "l"),
                    e.get("style", "elbow"), e.get("track", 0))
        shapes.append(shape_line(pts, dashed=e.get("dashed", False)))
        if e.get("label"):
            if e.get("labelAt"):
                lx, ly = e["labelAt"]
            elif e.get("style") == "below":
                lx = (pts[0][0] + pts[-1][0]) / 2.0
                ly = LANE_BOTTOM + 0.55 + e.get("track", 0) * 0.8 + 0.26
            else:
                lx = (pts[0][0] + pts[-1][0]) / 2.0
                ly = (pts[0][1] + pts[-1][1]) / 2.0 + 0.32
            shapes.append(shape_label(lx, ly, e["label"], 10, 3.0, 0.7))

    if spec.get("notes"):
        nh = spec.get("notesHeight", 1.9)
        shapes.append(shape_label(PAGE_W / 2, LANE_BOTTOM - 0.5 - nh / 2, spec["notes"],
                                  font=10, w=LANE_W, h=nh, border=True, valign=0, align=0))

    page_xml = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                f'<PageContents xmlns="{NS}" xml:space="preserve"><Shapes>'
                + "".join(shapes) + "</Shapes></PageContents>")

    page_name = escape(page.get("name", "Process"))
    pages_xml = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                 f'<Pages xmlns="{NS}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xml:space="preserve">'
                 f'<Page ID="0" NameU="{page_name}" Name="{page_name}" ViewScale="-1" '
                 f'ViewCenterX="{PAGE_W/2}" ViewCenterY="{PAGE_H/2}">'
                 f'<PageSheet LineStyle="0" FillStyle="0" TextStyle="0">'
                 f'{cell("PageWidth", PAGE_W)}{cell("PageHeight", PAGE_H)}'
                 f'{cell("PageScale", 1)}{cell("DrawingScale", 1)}'
                 f'{cell("DrawingSizeType", 3)}{cell("DrawingScaleType", 0)}'
                 f'{cell("ShdwOffsetX", 0)}{cell("ShdwOffsetY", 0)}'
                 f'</PageSheet><Rel r:id="rId1"/></Page></Pages>')

    document_xml = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                    f'<VisioDocument xmlns="{NS}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xml:space="preserve">'
                    f'<DocumentSettings TopPage="0" DefaultTextStyle="0" DefaultLineStyle="0" '
                    f'DefaultFillStyle="0" DefaultGuideStyle="0">'
                    f'<GlueSettings>9</GlueSettings><SnapSettings>65847</SnapSettings>'
                    f'<SnapExtensions>34</SnapExtensions><SnapAngles/>'
                    f'<DynamicGridEnabled>1</DynamicGridEnabled><ProtectStyles>0</ProtectStyles>'
                    f'<ProtectShapes>0</ProtectShapes><ProtectMasters>0</ProtectMasters>'
                    f'<ProtectBkgnds>0</ProtectBkgnds></DocumentSettings>'
                    f'<StyleSheets><StyleSheet ID="0" NameU="No Style" Name="No Style">'
                    f'{cell("LineWeight", 0.0104)}{cell("LineColor", "#000000")}'
                    f'{cell("LinePattern", 1)}{cell("FillForegnd", "#FFFFFF")}'
                    f'{cell("FillPattern", 1)}</StyleSheet></StyleSheets>'
                    f'<DocumentSheet NameU="{escape(page.get("title", "Diagram"))[:60]}"/>'
                    f'</VisioDocument>')

    parts = {
        "[Content_Types].xml": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Override PartName="/visio/document.xml" ContentType="application/vnd.ms-visio.drawing.main+xml"/>'
            '<Override PartName="/visio/pages/pages.xml" ContentType="application/vnd.ms-visio.pages+xml"/>'
            '<Override PartName="/visio/pages/page1.xml" ContentType="application/vnd.ms-visio.page+xml"/>'
            '<Override PartName="/visio/windows.xml" ContentType="application/vnd.ms-visio.windows+xml"/>'
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
            '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
            '</Types>',
        "_rels/.rels": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/document" Target="visio/document.xml"/>'
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
            '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
            '</Relationships>',
        "docProps/core.xml": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
            'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
            f'<dc:title>{escape(page.get("title", "Process Diagram"))}</dc:title>'
            f'<dc:creator>{escape(spec.get("creator", "ERP Forward Program"))}</dc:creator>'
            '</cp:coreProperties>',
        "docProps/app.xml": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">'
            '<Application>Microsoft Visio</Application><AppVersion>15.0000</AppVersion></Properties>',
        "visio/document.xml": document_xml,
        "visio/_rels/document.xml.rels": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/pages" Target="pages/pages.xml"/>'
            '<Relationship Id="rId2" Type="http://schemas.microsoft.com/visio/2010/relationships/windows" Target="windows.xml"/>'
            '</Relationships>',
        "visio/windows.xml": f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            f'<Windows xmlns="{NS}" ClientWidth="1600" ClientHeight="900">'
            f'<Window ID="0" WindowType="Drawing" WindowState="1073741824" '
            f'Document="../visio/document.xml" WindowLeft="0" WindowTop="0" '
            f'WindowWidth="1600" WindowHeight="900" ContainerType="Page" Page="0" '
            f'ViewScale="-1" ViewCenterX="{PAGE_W/2}" ViewCenterY="{PAGE_H/2}"/></Windows>',
        "visio/pages/pages.xml": pages_xml,
        "visio/pages/_rels/pages.xml.rels": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/page" Target="page1.xml"/>'
            '</Relationships>',
        "visio/pages/page1.xml": page_xml,
    }

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in parts.items():
            z.writestr(name, data)
    print(f"wrote {out_path} ({os.path.getsize(out_path)} bytes, {len(shapes)} shapes)")


if __name__ == "__main__":
    main()
