# Medias in Res – Lern-App

iOS-App (Deutsch) zum Lernen und Wiederholen von Vokabeln, Grammatik und Formen aus dem Lateinbuch *Medias in Res!* (Lektion 1–30).

## IPA herunterladen
1. Im Repo auf **Actions** gehen und den neuesten grünen Lauf von „Build IPA“ öffnen.
2. Unten bei **Artifacts** `MediasInRes-unsigned-ipa` laden (ZIP mit der IPA).
3. IPA mit deinem Zertifikat signieren und installieren.

## Inhalte bearbeiten
- Quelltexte: `ContentSrc/LXX.txt` (kompaktes Format, siehe Kopf von `scripts/build_content.py`)
- `python3 scripts/build_content.py` erzeugt `Content/lektion-XX.json`, `scripts/validate_content.py` prüft sie (läuft auch im Build).
- Buch: `book/pdf/`, OCR-Text: `book/ocr/`

Siehe [PLAN.md](PLAN.md) für Umfang und Stand.

## Web-Version (für alle ohne Sideloading)
`web/` enthält dieselbe App als Web-App (PWA): `index.html` + Manifest + Offline-Cache + Icons.
- Neu bauen: `python3 scripts/build_web.py` (nach jeder Inhaltsänderung)
- Zum Hosten den Ordner `web/` auf einen statischen Webspace legen (z. B. GitHub Pages, Netlify, Cloudflare Pages).
- iPhone: Seite in Safari öffnen → Teilen → „Zum Home-Bildschirm“. Android: Chrome → „App installieren“.
- Der Fortschritt bleibt im Browser des jeweiligen Geräts (Backup über „Mehr“ → Fortschritt sichern).
