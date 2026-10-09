"""Prepares bundled first-floor building outlines; never runs inside the app.

Requires Python 3.10+ and Shapely 2.1+: python -m pip install shapely
Fetch and generate: python tool/generate_campus_map_outlines.py --fetch
Regenerate from local captures: python tool/generate_campus_map_outlines.py
Captures stay in ignored tmp/campus_map_outlines and contain no portal data.
Use --insecure only for this GeoServer's incomplete certificate chain.
"""

import argparse
from collections import Counter
from datetime import date
import json
import math
from pathlib import Path
import re
import ssl
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

from shapely import make_valid, transform, union_all
from shapely.geometry import MultiPolygon, Polygon, shape


ROOT = Path(__file__).resolve().parent.parent
CAPTURES = ROOT / "tmp/campus_map_outlines"
OUTPUT = ROOT / "lib/repositories/campus_map_first_floor_outlines.dart"
ENDPOINT = "https://geoserver.oga.ntut.edu.tw/ows"
X_SCALE = 111320 * math.cos(math.radians(25.044))
Y_SCALE = 111320


def local(x, y, z=None):
    return ((x - 121.534) * X_SCALE, (y - 25.044) * Y_SCALE)


def geographic(x, y, z=None):
    return ((x / X_SCALE + 121.534).round(8), (y / Y_SCALE + 25.044).round(8))


def polygons(geometry):
    if geometry.geom_type == "Polygon":
        return [geometry]
    if hasattr(geometry, "geoms"):
        return [polygon for part in geometry.geoms for polygon in polygons(part)]
    return []


def floor_layers(source):
    document = ET.fromstring(source)
    return sorted(
        element.text
        for element in document.iter()
        if element.tag.split("}")[-1] == "Name"
        and element.text
        and re.fullmatch(r"gis_room:[A-Z0-9]+_1F", element.text)
    )


def fetch(insecure):
    context = ssl._create_unverified_context() if insecure else ssl.create_default_context()

    def request(operation, **parameters):
        query = urllib.parse.urlencode(
            {"service": "WFS", "version": "1.1.0", "request": operation, **parameters}
        )
        with urllib.request.urlopen(f"{ENDPOINT}?{query}", context=context, timeout=45) as response:
            return response.read()

    CAPTURES.mkdir(parents=True, exist_ok=True)
    capabilities = request("GetCapabilities")
    (CAPTURES / "capabilities.xml").write_bytes(capabilities)
    for layer in floor_layers(capabilities):
        code = layer.split(":")[-1].removesuffix("_1F")
        source = request("GetFeature", typeName=layer, outputFormat="application/json", SRSNAME="EPSG:4326")
        (CAPTURES / f"{code}_1F.json").write_bytes(source)
        print(f"Captured {code}", flush=True)


def prepare():
    outlines = {}
    names = {}
    for layer in floor_layers((CAPTURES / "capabilities.xml").read_bytes()):
        code = layer.split(":")[-1].removesuffix("_1F")
        source = (CAPTURES / f"{code}_1F.json").read_bytes()
        if source.lstrip().startswith(b"<"):
            document = ET.fromstring(source)
            missing = any(
                element.tag.split("}")[-1] == "ExceptionText"
                and re.search(rf"Schema '{re.escape(code)}_1F' does not exist\.", element.text or "")
                for element in document.iter()
            )
            if missing:
                continue
            raise ValueError(f"Unexpected WFS exception for {layer}")
        data = json.loads(source)
        if data.get("type") != "FeatureCollection":
            raise ValueError(f"Expected a FeatureCollection for {layer}")
        features = data["features"]
        spaces = [
            make_valid(transform(shape(feature["geometry"]), local, interleaved=False))
            for feature in features
            if feature.get("geometry")
        ]
        merged = union_all(spaces, grid_size=0.01)
        # Microscopic holes result from mismatched room vertices, not courtyards.
        parts = [
            Polygon(part.exterior, [ring for ring in part.interiors if Polygon(ring).area >= 0.01])
            for part in polygons(merged)
        ]
        outline = union_all(parts).simplify(0.05, preserve_topology=True)
        if outline.is_empty:
            continue
        outlines[code] = outline
        counts = Counter(
            str(feature["properties"]["build_name"]).strip()
            for feature in features
            if str(feature["properties"].get("build_name") or "").strip()
        )
        names[code] = counts.most_common(1)[0][0] if counts else code

    # Keep the established HR/A6T boundary. Otherwise smaller footprints own
    # shared areas, so a large footprint cannot swallow an adjacent building.
    assigned = []
    for code in sorted(outlines, key=lambda key: (key != "HR", outlines[key].area, key)):
        outline = outlines[code]
        overlaps = [other for other in assigned if outline.intersection(other).area > 0]
        if overlaps:
            outline = outline.difference(union_all(overlaps).buffer(0.01))
        if outline.is_empty:
            raise ValueError(f"Overlap correction removed all of {code}")
        outlines[code] = outline
        assigned.append(outline)

    converted = {}
    for code, outline in outlines.items():
        parts = sorted(polygons(outline), key=lambda polygon: polygon.area, reverse=True)
        geometry = transform(MultiPolygon(parts), geographic, interleaved=False)
        if not geometry.is_valid:
            raise ValueError(f"Invalid rounded outline for {code}")
        converted[code] = geometry
    for code, geometry in converted.items():
        for other_code, other in converted.items():
            if code < other_code and geometry.intersection(other).area > 0:
                raise ValueError(f"Rounded outlines overlap: {code}, {other_code}")
    names["HR"] = "宏裕科技大樓"
    return names, converted


def write(names, outlines):
    lines = [
        "// Generated by tool/generate_campus_map_outlines.py. Do not edit coordinates by hand.\n",
        f"// Source: {ENDPOINT}, gis_room:<building>_1F; prepared {date.today().isoformat()}.\n\n",
        "/// Bundled building names and WGS84 outlines merged from first-floor spaces.\n",
        "///\n",
        "/// Geometry uses the JSON encoding of `encodeCampusMapGeometry`. Buildings\n",
        "/// without usable first-floor geometry are absent. Components are ordered\n",
        "/// by area, largest first; real holes and detached components are retained.\n",
        "/// Generation repairs topology, unions on a local 1 cm grid, drops holes\n",
        "/// below 0.01 square meters, and simplifies with a 5 cm tolerance. Shared\n",
        "/// areas belong to the smaller footprint, except HR has priority; a 1 cm\n",
        "/// clearance prevents coordinate rounding from restoring overlaps.\n",
        "const campusMapFirstFloorOutlines = <String, ({String name, String geometry})>{\n",
    ]
    for code in sorted(outlines):
        name = names[code].replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
        lines.append(f"  '{code}': (\n    name: '{name}',\n    geometry: '''\n[\n")
        coordinates = outlines[code].__geo_interface__["coordinates"]
        for i, polygon in enumerate(coordinates):
            lines.append("  [\n")
            for j, ring in enumerate(polygon):
                lines.append("    [\n")
                for k, point in enumerate(ring):
                    lines.append("      " + json.dumps(point) + ("," if k < len(ring) - 1 else "") + "\n")
                lines.append("    ]" + ("," if j < len(polygon) - 1 else "") + "\n")
            lines.append("  ]" + ("," if i < len(coordinates) - 1 else "") + "\n")
        lines.append("]\n''',\n  ),\n")
    lines.append("};\n")
    OUTPUT.write_text("".join(lines), encoding="utf-8")
    print(f"Prepared {len(outlines)} first-floor outlines: {OUTPUT}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch", action="store_true", help="Refresh public first-floor captures")
    parser.add_argument("--insecure", action="store_true", help="Bypass TLS verification for the fixed GeoServer endpoint")
    arguments = parser.parse_args()
    if arguments.fetch:
        fetch(arguments.insecure)
    write(*prepare())
