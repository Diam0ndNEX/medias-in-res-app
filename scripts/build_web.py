#!/usr/bin/env python3
"""Baut die Web-App: web/index.html (+ Manifest, Service Worker, Icons) aus Content/*.json.
Mit --single <pfad> zusätzlich eine einzelne HTML-Datei ohne Manifest-Link."""
import base64, glob, hashlib, io, json, os, re, sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "web")
ICON_SRC = os.path.join(ROOT, "Sources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")

lessons = [json.load(open(f, encoding="utf-8")) for f in sorted(glob.glob(os.path.join(ROOT, "Content/lektion-*.json")))]
data = json.dumps(lessons, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")

icon = Image.open(ICON_SRC).convert("RGB")
for size in (180, 192, 512):
    icon.resize((size, size), Image.LANCZOS).save(os.path.join(WEB, f"icon-{size}.png"), optimize=True)
buf = io.BytesIO()
icon.resize((180, 180), Image.LANCZOS).save(buf, "PNG", optimize=True)
icon_uri = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

# Version und Änderungsliste (VERSION + CHANGELOG.md)
VERSION = open(os.path.join(ROOT, "VERSION")).read().strip()
assert re.fullmatch(r"\d+\.\d+\.\d+", VERSION), "VERSION muss MAJOR.MINOR.PATCH sein"
changes, cur = [], None
for line in open(os.path.join(ROOT, "CHANGELOG.md"), encoding="utf-8"):
    m = re.match(r"## (\d+\.\d+\.\d+)(?:\s+[–-]\s+(.+))?", line)
    if m: cur = {"v": m.group(1), "date": (m.group(2) or "").strip(), "items": []}; changes.append(cur)
    elif cur and line.startswith("- "): cur["items"].append(line[2:].strip())
assert changes and changes[0]["v"] == VERSION, f"CHANGELOG.md: oberster Abschnitt muss Version {VERSION} sein"
changelog = json.dumps(changes, ensure_ascii=False).replace("</", "<\\/")

tpl = open(os.path.join(WEB, "app.template.html"), encoding="utf-8").read()
page = (tpl.replace("/*__DATA__*/", data).replace("/*__ICON180__*/", icon_uri)
        .replace("/*__VERSION__*/", VERSION).replace("/*__CHANGELOG__*/", changelog))
hosted = page.replace("<!--__MANIFEST__-->", '<link rel="manifest" href="manifest.webmanifest">')
open(os.path.join(WEB, "index.html"), "w", encoding="utf-8").write(hosted)

json.dump({
    "name": "Medias in Res – Latein", "short_name": "Medias in Res", "lang": "de",
    "start_url": "./", "scope": "./", "display": "standalone",
    "background_color": "#7a1a20", "theme_color": "#7a1a20",
    "icons": [{"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
              {"src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable"}],
}, open(os.path.join(WEB, "manifest.webmanifest"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

version = VERSION + "-" + hashlib.sha1(hosted.encode()).hexdigest()[:8]
open(os.path.join(WEB, "sw.js"), "w").write(f"""const C = "mir-{version}";
const FILES = ["./", "index.html", "manifest.webmanifest", "icon-180.png", "icon-192.png", "icon-512.png"];
self.addEventListener("install", e => {{ e.waitUntil(caches.open(C).then(c => c.addAll(FILES))); self.skipWaiting(); }});
self.addEventListener("activate", e => {{ e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== C).map(k => caches.delete(k))))); self.clients.claim(); }});
self.addEventListener("fetch", e => {{
  if (e.request.method !== "GET") return;
  e.respondWith(fetch(e.request).then(r => {{ const copy = r.clone(); caches.open(C).then(c => c.put(e.request, copy)); return r; }})
    .catch(() => caches.match(e.request).then(r => r || caches.match("index.html"))));
}});
""")

if "--single" in sys.argv:
    out = sys.argv[sys.argv.index("--single") + 1]
    open(out, "w", encoding="utf-8").write(page.replace("<!--__MANIFEST__-->", ""))
print("Web-App", VERSION, "gebaut:", round(len(hosted) / 1024), "KB")
