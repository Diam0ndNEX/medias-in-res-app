#!/usr/bin/env python3
"""Validates Content/lektion-XX.json files. Exit code 1 on any problem."""
import glob
import json
import sys

BLOCK_TYPES = {"text", "list", "tip", "note", "table"}
errors = []


def err(f, msg):
    errors.append(f"{f}: {msg}")


files = sorted(glob.glob("Content/lektion-*.json"))
if not files:
    err("Content", "no lesson files found")

seen = set()
for f in files:
    try:
        d = json.load(open(f, encoding="utf-8"))
    except Exception as e:
        err(f, f"invalid JSON: {e}")
        continue
    for k in ("number", "title", "unit", "klasse", "vocab", "grammar"):
        if k not in d:
            err(f, f"missing key '{k}'")
    n = d.get("number")
    if n in seen:
        err(f, f"duplicate lesson number {n}")
    seen.add(n)
    if f"lektion-{n:02d}.json" not in f:
        err(f, f"file name does not match number {n}")
    las = set()
    for v in d.get("vocab", []):
        if not v.get("la") or not v.get("de"):
            err(f, f"vocab entry without la/de: {v}")
        if v.get("la") in las:
            err(f, f"duplicate vocab '{v.get('la')}'")
        las.add(v.get("la"))
    for s in d.get("grammar", []):
        if not s.get("title") or not s.get("blocks"):
            err(f, f"grammar section without title/blocks: {s.get('title')}")
        for b in s.get("blocks", []):
            t = b.get("type")
            if t not in BLOCK_TYPES:
                err(f, f"unknown block type '{t}' in '{s.get('title')}'")
            elif t == "table":
                width = len(b.get("headers", []))
                for r in b.get("rows", []):
                    if width and len(r) != width:
                        err(f, f"table row width {len(r)} != {width} in '{s.get('title')}'")
            elif t == "list":
                if not b.get("items"):
                    err(f, f"empty list in '{s.get('title')}'")
            elif not b.get("text"):
                err(f, f"empty {t} block in '{s.get('title')}'")

print(f"{len(files)} lesson file(s) checked, {len(errors)} problem(s)")
for e in errors:
    print(" -", e)
sys.exit(1 if errors else 0)
