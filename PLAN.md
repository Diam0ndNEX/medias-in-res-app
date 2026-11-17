# Plan: „Medias in Res!“ Lern-App

German-language iOS app to learn and re-learn everything in the textbook *Medias in Res!* (Veritas 2018, 5.–6. Klasse): vocabulary, grammar, exercises, repetition.

## 1. What the book contains (scope)

From the table of contents (OCR of the PDF, 211 pages):

| Part | Content |
|---|---|
| Grammatikkurs, 5. Klasse (Lektionen 1–15) | Römischer Alltag, Römische Frühzeit, Aus der griech. Mythologie |
| Grammatikkurs, 6. Klasse (Lektionen 16–30) | Römische Republik, Trojanischer Krieg, Kaiserzeit & Christentum |
| Per lesson ("Vier-Seiten-Prinzip") | 1. Lektionstext + Aufgabe, 2. Vokabel (vocabularium) + Latein im Alltag, 3. Grammatik, 4. Übungen (exercitationes) |
| Wortklauberei | After every 5 lessons: Sprach-Themen (Fremd-/Lehnwörter, Wortfamilien, romanische Sprachen …) |
| Repetitiones | Zusammenfassende Übungen (S. 142 ff.) |
| Formenlehre | Alle Konjugationen & Deklinationen (S. 188 ff.) |
| Kompetenzmodul 4 / Autorenlektüre | Romanisierung Europas, Österreich in lat. Quellen, Christentum als prägende Kraft |

## 2. Features

**MVP**
1. **Vokabeltrainer** – per lesson, spaced repetition (Leitner boxes, later SM‑2), directions Latein→Deutsch and Deutsch→Latein, self-grade or type-in.
2. **Grammatik** – one readable card page per lesson (Formen als Tabellen, Regeln, Merkkästen).
3. **Übungen** – generated from structured data: Lückentext (Endungen einsetzen), Zuordnen, Multiple Choice, Übersetzen mit Selbstkontrolle.
4. **Fortschritt** – Streak, pro Lektion „gelernt / unsicher / offen“.

**Later**
5. **Formentrainer** – Deklination/Konjugation drills (Formenlehre S. 188 ff.), auto-generated.
6. **Lektionstexte** – Latein-Text mit Tap-auf-Wort → Vokabel.
7. **Wiederholungsmodus** – mixed review across chosen lessons ("Schularbeit-Modus": Lektion 1–X, timed).
8. **Wortklauberei** & **Latein im Alltag** (Sprichwörter) as reading/quiz cards.
9. Autorenlektüre-Kapitel.

## 3. Tech decisions

- **SwiftUI + SwiftData**, iOS 17+, no third-party dependencies at first.
- **Content as JSON** (one file per lesson: `vocab`, `grammar`, `exercises`, `text`) bundled in the app – app logic and content are separate.
- **Project generation with XcodeGen** (`project.yml`) so everything can be edited as text, no Mac or Xcode needed.
- **Build in GitHub Actions** (macOS runner): `xcodebuild` with signing disabled → zip `Payload/*.app` into an **unsigned `.ipa`** → upload as workflow artifact → you sign it yourself with your own certificate (same flow as NexHTML).
- Fully offline, no accounts, no tracking.

## 4. Content pipeline (the hard part)

The PDF is scanned images; OCR (Tesseract, German) is only good enough for searching, not for data (Latin words, tables and umlauts get mangled). So:

1. OCR text is stored in the Claude Project (`buch/…`) and in the repo (`book/ocr/`) as a **search reference**.
2. For each lesson, the page images are read directly (vision) and **structured into JSON**, then you spot-check against the book.
3. Order: Lektion 1 → 5 first (end-to-end proof), then batches of 5 lessons (matches the book's colour units and Wortklauberei).
4. A small validator script checks every JSON file (required fields, no empty vocab, unique IDs) in CI.

## 5. Source material in the repo

The repo is private and holds the original book PDF (`book/pdf/`), the OCR text (`book/ocr/`, one file per page in `book/pages/`) and, later, the structured lesson JSON in `Content/`. App code and content are built together; there is no separate content repo. The app is for personal use (sideloaded), not an App Store release.

## 6. Roadmap

| Phase | Result |
|---|---|
| 0 | Repo, plan, XcodeGen skeleton, GitHub Actions builds an unsigned IPA (goal: first green build) |
| 1 | Data model + JSON schema + sample lesson + validator |
| 2 | Vokabeltrainer (Leitner) with Lektion 1–5 content |
| 3 | Grammatik pages + Übungen engine (Lückentext, MC, Zuordnen) |
| 4 | Lektionen 6–30 content batches, Wortklauberei |
| 5 | Formentrainer, Wiederholungsmodus, Fortschrittsansicht |
| 6 | Lektionstexte with tap-to-translate, Autorenlektüre, polish (Dark Mode, Dynamic Type, Haptik) |

## 7. Open questions

1. Which lesson/class are you at right now? → start content extraction there.
2. Should Latein→Deutsch be typed or self-graded by default?
3. App name / icon (placeholder: „Medias in Res“).
