#!/usr/bin/env python3
"""Baut Content/anhang.json aus ContentSrc/anhang/*.txt (Buchanhang nach Lektion 30).

Enthält Formenlehre, Stammformen, Vor-/Nachsilben, Stilmittel, Sprichwörter und die
Wortklauberei 26–30 – jeweils als Grammatik-Abschnitte (gleiches Format wie die Lektionen)
plus strukturierte Listen für die Übungsmodi der App."""
import json, os, re, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "ContentSrc", "anhang")
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from build_content import parse  # noqa: E402


def grammar(text):
    """Grammatik-Text (## Abschnitte, | Tabellen, - Listen, ! Tipps, ? Notizen) -> Abschnitte."""
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as fh:
        fh.write("#99 x | x | 5\n== VOKABELN\n== GRAMMATIK\n" + text)
    try:
        return parse(fh.name)["grammar"]
    finally:
        os.unlink(fh.name)


def rows(name, n):
    out = []
    for line in open(os.path.join(SRC, name), encoding="utf-8"):
        line = line.strip()
        if line.startswith("## "):
            out.append(("##", line[3:].strip()))
            continue
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < n:
            sys.exit(f"{name}: zu wenige Spalten: {line}")
        out.append(tuple(parts[:n]))
    return out


def table(headers, body):
    return "| " + " | ".join(headers) + " |\n" + "".join("| " + " | ".join(r) + " |\n" for r in body)


def main():
    # Stammformen
    stems, group, gtext = [], None, ""
    for r in rows("stammformen.txt", 5):
        if r[0] == "##":
            group = r[1]
            gtext += f"## {group}\n| Infinitiv | Perfekt | PPP | Bedeutung | L. |\n"
            continue
        inf, perf, ppp, de, les = r
        m = re.match(r"(.+?)\s+([1234M])$", inf)
        stems.append({"group": group, "inf": m.group(1) if m else inf, "cls": m.group(2) if m else "",
                      "perf": perf, "ppp": ppp, "de": de, "lesson": int(les)})
        gtext += f"| {inf} | {perf} | {ppp} | {de} | {les} |\n"
    intro = ("## Stammformen der Verba inkl. PPP, Lec. 1–30\n"
             "Die Liste umfasst alle Verba im Buch mit unregelmäßiger Perfektbildung, geordnet nach der Art der Perfektbildung "
             "und innerhalb davon nach Konjugation: a-Konjugation (1), e-Konjugation (2), konsonantische Konjugation (3), "
             "Mischkonjugation (M), i-Konjugation (4). Die Verba bis Lektion 19 solltest du ab Lektion 19 beherrschen.\n"
             "? Nicht angeführt sind die Verba der a-/e-/i-Konjugation mit regelmäßiger Perfektbildung (z. B. laudare, laudavi, laudatum).\n")

    proverbs = [{"la": la, "de": de, "lesson": int(l) if l else 0} for la, de, l in rows("sprichwoerter.txt", 3)]
    prefixes = [{"p": p, "m": m, "ex": ex} for p, m, ex in rows("vorsilben.txt", 3)]
    suffixes = [{"s": s, "m": m, "ex": ex, "g": g} for s, m, ex, g in rows("nachsilben.txt", 4)]
    figures = [{"name": n, "desc": d, "ex": e} for n, d, e in rows("stilmittel.txt", 3)]

    pre = ("## Die Bedeutung lateinischer Vorsilben (Präfixe)\n"
           "Viele lateinische Präpositionen werden auch für zusammengesetzte Wörter (besonders Verba) verwendet. "
           "Wenn du die Bedeutung dieser Vorsilben weißt, ergeben sich die Bedeutungen solcher Komposita oft von selbst: "
           "ire = „gehen“ → ab-ire = „weg-gehen“, ex-ire = „hinaus-gehen“, ad-ire = „hin-gehen“.\n"
           "? Manche Vorsilben passen sich an den nachfolgenden Buchstaben an (Assimilation), besonders oft ad-: afferre (aus ad-ferre), Perfekt attuli (aus ad-tuli), PPP allatum (aus ad-latum).\n"
           "? Gelegentlich ändert sich bei Komposita auch der Vokal (Vokalschwächung): facere → conficere, tenere → continere, capere → accipere.\n"
           + table(["Präfix", "Bedeutung", "Beispiele"], [(x["p"], x["m"], x["ex"]) for x in prefixes])
           + "! Unter den Beispielen stehen zuerst die Wörter aus dem Buch; die übrigen kannst du dir leicht selbst erschließen.\n")
    suf = ("## Die Bedeutung lateinischer Nachsilben (Suffixe)\n"
           "Ein Suffix ist eine Silbe, die hinten an einen Wortstamm angefügt ist und dem Wort eine bestimmte Bedeutung gibt.\n"
           + table(["Suffix beim Nomen", "Bedeutung", "Beispiele"], [(x["s"], x["m"], x["ex"]) for x in suffixes if x["g"] == "Nomen"])
           + "\n" + table(["Suffix beim Adjektiv", "Bedeutung", "Beispiele"], [(x["s"], x["m"], x["ex"]) for x in suffixes if x["g"] == "Adjektiv"]))
    fig = ("## Die wichtigsten Stilmittel\n"
           + table(["Stilmittel", "Erklärung", "Beispiel"], [(x["name"], x["desc"], x["ex"]) for x in figures]))
    prov = ("## Lateinische Sprichwörter und Redewendungen\n"
            "Die lateinische Sprache begegnet dir auch im Alltag auf Schritt und Tritt. Hier die häufigsten Redensarten – "
            "so hast du für jede Gelegenheit den passenden Spruch auf Lager!\n"
            + table(["Latein", "Bedeutung", "L."], [(x["la"], x["de"], str(x["lesson"]) if x["lesson"] else "") for x in proverbs])
            + "? Im Buch ist die Bedeutung nur bei den Sprichwörtern aus den Lektionen erklärt – die übrigen Übersetzungen hat die App ergänzt.\n")

    read = lambda n: open(os.path.join(SRC, n), encoding="utf-8").read()
    sections = [
        {"id": "formen", "icon": "📐", "title": "Formenlehre", "sub": "Alle Deklinationen und Konjugationen auf einen Blick (S. 188 ff.)", "grammar": grammar(read("formenlehre.txt"))},
        {"id": "stamm", "icon": "🔤", "title": "Stammformen der Verba", "sub": "Unregelmäßige Perfektbildung, Lec. 1–30 (S. 200 ff.)", "grammar": grammar(intro + gtext)},
        {"id": "praefix", "icon": "🧱", "title": "Vorsilben (Präfixe)", "sub": "ab-, ad-, con-, ex- … und was sie bedeuten (S. 197)", "grammar": grammar(pre)},
        {"id": "suffix", "icon": "🧩", "title": "Nachsilben (Suffixe)", "sub": "-tor, -tas, -io, -bilis … (S. 198)", "grammar": grammar(suf)},
        {"id": "stil", "icon": "🎭", "title": "Stilmittel", "sub": "Alliteration, Chiasmus, Klimax … (S. 198)", "grammar": grammar(fig)},
        {"id": "spruch", "icon": "💬", "title": "Sprichwörter & Redewendungen", "sub": f"{len(proverbs)} lateinische Sprüche (S. 196)", "grammar": grammar(prov)},
        {"id": "wk2630", "icon": "🔍", "title": "Wortklauberei 26–30", "sub": "Romanische Sprachen, Medium, Wortfelder, Metapher (S. 140 f.)", "grammar": grammar(read("wortklauberei-26-30.txt"))},
    ]
    for s in sections:
        assert s["grammar"], s["id"]
    assert len(stems) >= 140 and len(proverbs) >= 35 and len(prefixes) >= 20 and len(figures) >= 14
    data = {"sections": sections, "stems": stems, "proverbs": proverbs, "prefixes": prefixes, "suffixes": suffixes, "figures": figures}
    with open(os.path.join(ROOT, "Content", "anhang.json"), "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
    print(f"Anhang: {len(sections)} Kapitel, {len(stems)} Stammformen, {len(proverbs)} Sprichwörter, "
          f"{len(prefixes)} Präfixe, {len(suffixes)} Suffixe, {len(figures)} Stilmittel")


if __name__ == "__main__":
    main()
