# Plan: „Medias in Res!“ Lern-App

iOS-App auf Deutsch, mit der man **alles aus dem Buch** (Lektionen 1–30 plus Anhang) lernen, wiederholen und üben kann. Nur für den eigenen Gebrauch; die IPA wird selbst signiert.

---

## 0. Stand (17.11.2026)

**Fertig und in der IPA:**
- Vokabeln (756) und Grammatik aller 30 Lektionen, Quelle: `ContentSrc/LXX.txt` → `scripts/build_content.py` → `Content/lektion-XX.json`
- Tabs: Lektionen · Üben · Suchen · Statistik · Einstellungen
- Übungsmodi, alle mit freiem Bereich von–bis, Wortart und Richtung:
  - tägliche Wiederholung, Fehlerkiste
  - Karteikarten (wischen), Multiple Choice, Richtig/Falsch, Zuordnen, Hör-Modus, Blitzrunde mit Rekord, Eintippen (optional)
  - Stammformen, Fremdwort-Detektiv
  - Formen bestimmen, Formen bilden (über 1000 Fragen aus den Grammatik-Tabellen), Tabellen aufdecken
  - Schularbeit-Modus mit Zeitlimit und Note 1–5
- Statistik (Serie, Tagesziel, 7-Tage-Verlauf, pro Lektion, schwierigste Wörter, Schularbeiten), Erinnerung, Haptik, Backup (Export/Import)
- App-Icon (Lorbeerkranz „MiR“), Widget „Vokabel des Tages“, Merkliste (★), 13 Abzeichen, Startseite mit Vokabel des Tages und „Weiterlernen“, Zähler für fällige Karten am Üben-Tab, Einführung beim ersten Start

**Noch offen:** Lektionstexte mit Antippen-Analyse, Satz-Puzzle, Satz übersetzen, Buchübungen, Wortfamilien, Grammatik-Regel-Quiz, Wortklauberei, Repetitiones, Formenlehre-Anhang, Autorenlektüre.

## 1. Aufbau der App

Vier Tabs:

| Tab | Inhalt |
|---|---|
| **Lektionen** | Lektion 1–30, jeweils mit Text, Vokabeln, Grammatik, Übungen und Infos |
| **Üben** | alle Trainingsmodi; überall frei wählbar: **Lektion von–bis** (z. B. 5–10) |
| **Nachschlagen** | Suche (Latein/Deutsch), Formenlehre, Grammatik-Register, Wortklauberei |
| **Statistik** | Fortschritt, Streak, schwierigste Wörter, Ergebnisse der Schularbeit-Tests |

### Eine Lektion enthält
1. **Lektionstext**: Latein, Tippen auf ein Wort zeigt Vokabel und Formbestimmung, Übersetzung lässt sich ein- und ausblenden
2. **Vokabeln**: Liste mit Stammformen, Bedeutung und Fremdwörtern, Deutsch verdeckbar
3. **Grammatik**: Regeln, Tabellen, Tipps und Nota bene, übersichtlich wie im Buch
4. **Übungen**: die Übungen aus dem Buch, interaktiv mit Lösungen
5. **De Romanis / De Graecis**: Infotexte zur Antike
6. **Latein im Alltag**: Sprichwörter und Redensarten

Dazu die Bereiche **Wortklauberei** (nach je 5 Lektionen), **Repetitiones** (S. 142 ff.), **Formenlehre** (S. 188 ff.) und **Autorenlektüre** (Kompetenzmodul 4).

---

## 2. Übungsmodi

Bei jedem Modus wählst du: **Lektionen von–bis**, Richtung (Lat→Dt / Dt→Lat), Wortart (alle/Nomen/Verben/Adjektive …), Anzahl oder „alle“.

### Vokabeln
| Modus | So funktioniert's |
|---|---|
| **Ohne Tippen** | Standardmodus: alles nur durch Antippen (Karteikarten, Multiple Choice, Zuordnen, Richtig/Falsch, Wischen). Eintippen ist optional und kann in den Einstellungen ganz ausgeschaltet werden |
| **Richtig oder falsch?** | „amicus = Schülerin?“ → schnell nach links/rechts wischen, auf Zeit |
| **Hör-Modus** | Vokabel wird vorgelesen (iOS-Sprachausgabe), Bedeutung antippen; zum Lernen unterwegs |
| **Wortfamilien** | Wörter mit gleichem Stamm finden (z. B. laudat – Laudatio – laus) |
| **Satz-Puzzle** | lateinischen Satz aus Wort-Kärtchen in die richtige Reihenfolge bringen bzw. deutsche Übersetzung zusammensetzen, ohne Tippen |
| **Blitzrunde** | 60 Sekunden, so viele Vokabeln wie möglich, Highscore pro Lektionsbereich |
| **Karteikarten** | Karte umdrehen, „gewusst“/„nicht gewusst“ antippen; Spaced Repetition (Leitner, 5 Boxen) |
| **Übersetzung erraten (Eintippen, optional)** | Bedeutung eintippen, die Prüfung ist tolerant: Groß-/Kleinschreibung, „er/sie/es“, eine von mehreren Bedeutungen reicht, kleine Tippfehler gehen durch |
| **Multiple Choice** | 4 Antworten zur Auswahl, die falschen kommen aus der gleichen Wortart, damit es nicht zu leicht wird |
| **Zuordnen** | 6 Latein- und 6 Deutsch-Kärtchen paarweise verbinden, auf Zeit |
| **Stammformen** | z. B. „laudat → ? , ?“ ergänzen (laudavi, laudatum); Genitiv bei Nomen |
| **Fremdwort-Detektiv** | „Woher kommt *Laudatio*?“ → laudat; mit den Fremdwörtern und den Wörtern aus anderen Sprachen aus dem Buch |
| **Fehlerkiste** | übt nur die Wörter, die du zuletzt falsch hattest |
| **Tägliche Wiederholung** | die heute fälligen Karten aus allen Lektionen, ca. 5 Minuten |

### Formen und Grammatik
| Modus | So funktioniert's |
|---|---|
| **Formen bestimmen** | „amicis“ → Fall, Zahl, Geschlecht antippen; bei Verben Person, Zahl, Zeit, Modus, Aktiv/Passiv |
| **Formen bilden** | „bilde 3. P. Pl. Perfekt von laudare“ → eintippen |
| **Tabellen ausfüllen** | ganze Deklinations-/Konjugationstabelle ausfüllen (wie im Buch S. 188 ff.) |
| **Grammatik-Quiz** | Fragen zu den Regeln jeder Lektion (z. B. „Wann steht der AcI?“) |
| **Endungen-Lückentext** | Sätze aus Lektionstext und Übungen, Endungen einsetzen |

### Texte
| Modus | So funktioniert's |
|---|---|
| **Satz übersetzen** | Satz aus dem Lektionstext übersetzen, danach mit der Musterlösung vergleichen und selbst bewerten |
| **Wort-Analyse** | Wort im Text antippen → Grundform, Bedeutung, Form; dazu „Satzglieder finden“ |

### Schularbeit-Modus
- Test aus einem gewählten Bereich (z. B. Lektion 11–15): Vokabeln, Formen, Grammatik und Übersetzung gemischt
- optional mit Zeitlimit; am Ende **Note 1–5** nach österreichischem Schema, Fehleranalyse und „Fehler üben“-Knopf

---

## 3. Motivation und Komfort
- Streak, Tagesziel, Abzeichen (z. B. „Lektion 1–10 komplett“)
- Fortschrittsbalken pro Lektion, Liste der schwierigsten Wörter
- Erinnerung (Notification) zur täglichen Wiederholung
- Widget „Vokabel des Tages“
- Haptik und Animationen, Dark Mode, iPad, Dynamic Type
- Backup: Fortschritt exportieren/importieren (Datei)
- Komplett offline, keine Anmeldung

---

## 4. Technik
- **SwiftUI**, iOS 17+, **SwiftData** für Fortschritt, Statistik und Fehlerkiste
- **Inhalte als JSON** in `Content/`, eine Datei pro Lektion plus Anhang-Dateien
- Pro Vokabel zusätzlich: **Wortart, Deklination/Konjugation, Geschlecht, Stammformen** → daraus erzeugt ein **Formengenerator** automatisch alle Formen für die Formen-Modi
- **XcodeGen** (`project.yml`), daher ist kein Mac nötig
- **GitHub Actions** baut bei jedem Push eine **unsignierte IPA**, die du herunterlädst und selbst signierst
- Ein Prüfskript checkt alle Inhalte bei jedem Build

### Datenformat (pro Lektion)
```
number, title, unit, klasse
text:        Absätze + Übersetzungshilfen + Wortzuordnung
vocab:       la, forms, de, note, pos, class, gender
grammar:     Abschnitte mit Blöcken (text, list, tip, note, table)
exercises:   Typ, Aufgabe, Items, Lösungen
info:        De Romanis/Graecis, Latein im Alltag
```

---

## 5. Inhalte aus dem Buch holen
- Das PDF ist ein Scan. Die OCR-Texte dienen nur zum Suchen. Die eigentlichen Inhalte lese ich **direkt von den Seitenbildern** ab und baue sie als JSON auf.
- Seiten pro Lektion: Text · Vokabeln · Grammatik · Übungen (Lektion 1 = S. 10–13)
- Reihenfolge: zuerst **Vokabeln + Grammatik aller 30 Lektionen**, danach Texte, Übungen und Anhang
- Das Buch hat **keine Lösungen**. Lösungen und Musterübersetzungen erstelle ich selbst und markiere sie, du prüfst stichprobenartig.

---

## 6. Phasen

| Phase | Ergebnis |
|---|---|
| **0 Fundament** | Repo, Build-Pipeline, Grundgerüst ✔ (erster Build schlägt noch fehl, wird behoben) |
| **1 Vokabeln + Grammatik 1–30** | alle Vokabellisten und Grammatikseiten in der App |
| **2 Üben-Kern** | Bereichswahl von–bis, Karteikarten, Eintippen, Multiple Choice, Zuordnen, Fehlerkiste, tägliche Wiederholung |
| **3 Formen** | Wortart-Daten, Formengenerator, Formen bestimmen/bilden, Tabellen, Stammformen |
| **4 Texte + Übungen** | Lektionstexte mit Tipp-Analyse, Buchübungen interaktiv, Lückentexte, Satz übersetzen |
| **5 Schularbeit + Statistik** | Test-Modus mit Note, Grammatik-Quiz, Statistik-Tab |
| **6 Extras** | Nachschlagen/Suche, Formenlehre, Wortklauberei, Fremdwort-Detektiv, Sprichwörter, Widget, Erinnerungen, Backup, Feinschliff |

Jede Phase endet mit einer installierbaren IPA.

---

## 7. Entscheidungen
- App-Name: **Medias in Res**
- Standard ist **ohne Tippen** (alles per Antippen/Wischen); Eintippen nur optional
- Weitere Modi werden laufend ergänzt
