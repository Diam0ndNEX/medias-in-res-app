#!/usr/bin/env python3
"""Converts ContentSrc/LXX.txt (compact text format) into Content/lektion-XX.json.

Format:
  #<nr> <Titel> | <Einheit> | <Klasse>
  == VOKABELN
  latein | formen | deutsch | notiz          (one per line)
  * Fußnote zur Vokabelliste                  (optional)
  == GRAMMATIK
  ## Abschnittstitel
  normaler Text
  - Listenpunkt
  ! Tipp
  ? Nota bene
  | Kopf | Kopf |        (first table row = header; table ends at blank/other line)
  | Zelle | Zelle |
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def guess_pos(la, forms):
    s = la.lower()
    if "(adv" in s:
        return "Adverb"
    if "(m./f./n.)" in la or "(m./f.)" in la or "/ae/a" in la or re.search(r"(is/e|/eris/ere|/acris/acre|/a/um|/a/ud)\b", la):
        return "Adjektiv"
    if re.search(r"\b(m|f|n)\.", la) or "m./f." in s:
        return "Nomen"
    if re.search(r"o, -(as|es)\b", la):
        return "Verb"
    if re.search(r"(is/e|/eris/ere|/acris/acre)\b", la) or "(m./f./n.)" in la or "(m./f.)" in la:
        return "Adjektiv"
    if re.search(r"/ae/a\b", la):
        return "Adjektiv"
    if re.search(r"\w+o(r)? (1|2|3|4|M)\b", forms) or re.search(r"\b(sum|possum|eo|volo|nolo|malo|fero)\b,", forms):
        return "Verb"
    if re.search(r"\b(m|f|n)\.", forms) and "(Pl" not in forms:
        return "Nomen"
    if re.search(r"\b(m|f|n)\.", forms):
        return "Nomen"
    if "/a/um" in s or "/is/e" in s or "(adjektiv" in s or re.search(r"/\w+/\w+$", s) or "(gen" in s:
        return "Adjektiv"
    if "(präp" in s or "(+ akk" in s or "(+ abl" in s or "+ akk" in s or "+ abl" in s:
        return "Präposition"
    if re.search(r"(t|nt|tur|ntur|re|ri)\b", s.split(" ")[0]) and forms and ("," in forms or "sum" in forms):
        return "Verb"
    if re.search(r"(at|et|it|re)$", s.split(" ")[0]) and forms:
        return "Verb"
    return "Sonstiges"


POS_OVERRIDE = {
    **{w: "Verb" for w in ("adesse", "prodesse", "deesse", "interesse", "est", "inquit", "videtur (+ Inf.)", "dicitur (+ Inf.)")},
    **{w: "Adverb" for w in ("iam", "ibi", "tam", "ita", "sic", "tamen", "deinde", "fere", "quoque (nachgestellt)", "etiam", "tandem", "vero", "hodie (Adv.)", "non", "domum", "domi", "quomodo", "quidem", "ecce!", "quasi", "cur?", "ubi?", "quo", "tum (= tunc)", "itaque")},
    **{w: "Konjunktion" for w in ("et", "sed", "-que", "neque (= nec)", "nam", "autem", "at", "aut", "atque (= ac)", "quia", "quod", "quamquam", "etsi", "si", "nisi", "priusquam", "postquam [(+ Perfekt)]", "postquam", "enim [(nachgestellt!)]", "enim", "ut", "dum (+ Präsens)")},
    **{w: "Pronomen" for w in ("quid?", "quis?", "quem?", "nihil", "nemo", "quidquid", "is, ea, id", "idem, eadem, idem", "hic, haec, hoc", "ille, illa, illud", "ipse, ipsa, ipsum", "iste, ista, istud", "qui, quae, quod", "quidam, quaedam, quoddam", "ego / tu", "mihi / tibi / sibi (Dativ)", "me / te / se (Akkusativ)", "nobis / vobis (Dativ)")},
}


def parse(path):
    lines = open(path, encoding="utf-8").read().splitlines()
    m = re.match(r"#(\d+)\s+(.*?)\s*\|\s*(.*?)\s*\|\s*(\d+)", lines[0])
    if not m:
        sys.exit(f"{path}: bad header")
    d = {"number": int(m[1]), "title": m[2], "unit": m[3], "klasse": int(m[4]),
         "vocab": [], "vocabNote": None, "grammar": []}
    mode = None
    section = None
    table = None

    def close_table():
        nonlocal table
        if table and section is not None:
            section["blocks"].append({"type": "table", "headers": table[0], "rows": table[1:]})
        table = None

    for raw in lines[1:]:
        line = raw.strip()
        if line.startswith("== VOKABELN"):
            mode = "v"; continue
        if line.startswith("== GRAMMATIK"):
            mode = "g"; continue
        if mode == "v":
            if not line:
                continue
            if line.startswith("*"):
                d["vocabNote"] = line[1:].strip(); continue
            parts = [p.strip() for p in line.split("|")]
            parts += [""] * (4 - len(parts))
            la, forms, de, note = parts[:4]
            d["vocab"].append({"la": la, "forms": forms, "de": de, "note": note,
                               "pos": POS_OVERRIDE.get(la) if guess_pos(la, forms) == "Sonstiges" and POS_OVERRIDE.get(la) else guess_pos(la, forms)})
        elif mode == "g":
            if line.startswith("|"):
                cells = [c.strip() for c in line.strip("|").split("|")]
                if table is None:
                    table = [cells]
                else:
                    table.append(cells)
                continue
            close_table()
            if not line:
                continue
            if line.startswith("## "):
                section = {"title": line[3:].strip(), "blocks": []}
                d["grammar"].append(section)
            elif section is None:
                sys.exit(f"{path}: grammar text before first section: {line}")
            elif line.startswith("- "):
                blocks = section["blocks"]
                if blocks and blocks[-1]["type"] == "list":
                    blocks[-1]["items"].append(line[2:].strip())
                else:
                    blocks.append({"type": "list", "items": [line[2:].strip()]})
            elif line.startswith("! "):
                section["blocks"].append({"type": "tip", "text": line[2:].strip()})
            elif line.startswith("? "):
                section["blocks"].append({"type": "note", "text": line[2:].strip()})
            else:
                section["blocks"].append({"type": "text", "text": line})
    close_table()
    if d["vocabNote"] is None:
        del d["vocabNote"]
    return d


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "ContentSrc", "L*.txt")))
    for f in files:
        d = parse(f)
        out = os.path.join(ROOT, "Content", f"lektion-{d['number']:02d}.json")
        with open(out, "w", encoding="utf-8") as fh:
            json.dump(d, fh, ensure_ascii=False, indent=1)
    print(f"{len(files)} Lektion(en) erzeugt")


if __name__ == "__main__":
    main()
