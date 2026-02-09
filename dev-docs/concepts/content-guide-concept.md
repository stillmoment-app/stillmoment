# Loesungskonzept: Content Guide (shared-039)

**Stand:** Februar 2026
**Ticket:** shared-039 (Empty State + Content Guide)
**Autor:** Konzeptphase

---

## 1. Kernfrage: Website, In-App oder beides?

### Empfehlung: Beides — mit unterschiedlichem Zweck

| Aspekt | In-App | Website |
|--------|--------|---------|
| **Primaerer Zweck** | Nutzer innerhalb der App zum Content fuehren | SEO, Auffindbarkeit, App-Store-Verlinkung |
| **Erreichbarkeit** | Empty State CTA + permanenter Einstieg | Suchmaschine, App-Store-Beschreibung, Social |
| **Offline** | Muss funktionieren (keine Netzwerk-Calls) | Nur online |
| **Theming** | Alle 3 Themes x Light/Dark | Website-Design (Warm Desert) |
| **Detailgrad** | Kompakt: Name + 1 Satz + Link | Ausfuehrlicher: Kontext, Tipps, Anleitungen |
| **Sprache** | Geraete-Locale (automatisch) | Manueller Switcher (wie bestehende Seiten) |

**Warum beides?**
- In-App loest das Ticket-Problem: Nutzer sieht leere Library → findet sofort Quellen
- Website bringt SEO-Wert: "free meditation sources" ist ein suchbarer Begriff
- Website ist verlinkbar aus App-Store-Beschreibung, Reddit-Posts, Lehrer-Emails
- Beide koennen die gleiche Datenquelle nutzen (DRY fuer URLs)

---

## 2. In-App Content Guide

### 2.1 Seitenstruktur

```
┌─────────────────────────────────┐
│ ← Zurueck     Meditationen      │  (Navigation)
│                finden            │
├─────────────────────────────────┤
│                                 │
│  Bringe deine eigenen           │  Intro-Text
│  Meditationen mit               │  (2-3 Saetze, BYOM erklaert)
│                                 │
├─────────────────────────────────┤
│  Grosse Archive                 │  Sektion 1
│  ┌─────────────────────────────┐│
│  │ 🎙 Dharma Seed              ││
│  │ Tausende Dharma Talks und   ││  Source Card
│  │ gefuehrte Meditationen      ││
│  │                    ↗ Oeffnen ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ 🎙 Audio Dharma             ││
│  │ Talks von Gil Fronsdal u.a. ││
│  │                    ↗ Oeffnen ││
│  └─────────────────────────────┘│
│  ...                            │
├─────────────────────────────────┤
│  Bekannte Lehrer                │  Sektion 2
│  ┌─────────────────────────────┐│
│  │ 🧘 Tara Brach               ││
│  │ RAIN Practice, Guided       ││
│  │ Meditations                 ││
│  │                    ↗ Oeffnen ││
│  └─────────────────────────────┘│
│  ...                            │
├─────────────────────────────────┤
│  Achtsamkeitskurse              │  Sektion 3
│  ┌─────────────────────────────┐│
│  │ 🎓 UCLA Mindful             ││
│  │ Forschungsbasierte          ││
│  │ Achtsamkeitsuebungen        ││
│  │                    ↗ Oeffnen ││
│  └─────────────────────────────┘│
│  ...                            │
├─────────────────────────────────┤
│  Deutschsprachig                │  Sektion 4
│  ...                            │
├─────────────────────────────────┤
│  Creative Commons               │  Sektion 5
│  ...                            │
├─────────────────────────────────┤
│                                 │
│  💡 So importierst du:          │  Footer-Hinweis
│  Lade eine MP3 herunter,        │
│  oeffne sie und teile sie       │
│  mit Still Moment.              │
│                                 │
└─────────────────────────────────┘
```

### 2.2 Sektionen und Quellen

**Sektion 1: Grosse Archive** (EN: "Large Archives")
- Dharma Seed — Tausende Dharma Talks und gefuehrte Meditationen
- Audio Dharma — Talks von Gil Fronsdal und weiteren Lehrern
- Free Buddhist Audio — Ueber 5.000 buddhistische Aufnahmen

**Sektion 2: Bekannte Lehrer** (EN: "Popular Teachers")
- Tara Brach — RAIN Practice, Guided Meditations
- Jack Kornfield — Lovingkindness, Forgiveness Meditations
- Plum Village (Thich Nhat Hanh) — Deep Relaxation, Guided Meditations

**Sektion 3: Achtsamkeitskurse** (EN: "Mindfulness Courses")
- UCLA Mindful — Forschungsbasierte Achtsamkeit (14+ Sprachen)
- Palouse Mindfulness — Kompletter 8-Wochen MBSR-Kurs (kostenlos)

**Sektion 4: Deutschsprachig** (EN: "German Language")
- Meditation-Download.de — Gefuehrte Meditationen, kein Account noetig
- Zentrum fuer Achtsamkeit Koeln — MBSR Body Scan, Sitzmeditation

**Sektion 5: Creative Commons** (EN: "Free & Open")
- Free Mindfulness Project — Achtsamkeitsuebungen (CC-lizenziert)
- Internet Archive — Diverse Meditationen (Public Domain)

### 2.3 Einstiegspunkte

```
Einstieg 1: Empty State (primaer)
  Library leer → "Wo finde ich Meditationen?" → Content Guide

Einstieg 2: Permanent (sekundaer)
  Option A: Info-Icon (ℹ️) in Library-Navigation
  Option B: Eintrag in Settings/Ueber
  Option C: Footer-Link in Library (immer sichtbar, auch wenn gefuellt)
```

**Empfehlung:** Option A (Info-Icon in Library-Nav). Gruende:
- Immer erreichbar, auch wenn Library gefuellt ist
- Nutzer koennten spaeter neue Quellen suchen
- Unauffaellig, stoert nicht bei taeglicher Nutzung
- Standard iOS/Android Pattern (ℹ️ oder ? in NavBar)

### 2.4 Sprache (In-App)

Folgt automatisch dem Geraete-Locale — kein manueller Switcher noetig.

| Locale | Verhalten |
|--------|-----------|
| `de` | Deutsche Texte, Sektion "Deutschsprachig" prominent |
| `en` (oder alles andere) | Englische Texte, Sektion "German Language" weiter unten |

**Ueberlegung:** Sektions-Reihenfolge anpassen je nach Sprache?
- DE: Deutschsprachig als Sektion 2 (nach Archiven), dann internationale Lehrer
- EN: Popular Teachers als Sektion 2, German Language ganz unten

**Empfehlung:** Reihenfolge fix lassen. Deutschsprachige Quellen sind nur 2 Eintraege — eine Umordnung waere Over-Engineering. Stattdessen: In der deutschen Version den Intro-Text leicht anpassen, um die deutschsprachigen Quellen zu erwaehnen.

---

## 3. Website Content Guide

### 3.1 Neue Seite: `docs/guide.html`

Fuegt sich in bestehende Website-Struktur ein:

```
index.html          → Marketing/Landing
support.html        → FAQ/Hilfe
guide.html    [NEU] → "Finde kostenlose Meditationen"
privacy.html        → Datenschutz
impressum.html      → Impressum
```

### 3.2 Inhalt (ausfuehrlicher als In-App)

```
┌─────────────────────────────────────┐
│  Finde kostenlose Meditationen      │  Hero
│                                     │
│  Still Moment spielt deine eigenen  │
│  Meditationen. Hier findest du      │
│  hochwertige Quellen — kostenlos    │
│  und ohne Registrierung.            │
├─────────────────────────────────────┤
│                                     │
│  Was ist "Bring Your Own            │  Erklaer-Sektion
│  Meditation"?                       │  (fehlt In-App aus Platzgruenden)
│                                     │
│  Die meisten Meditations-Apps       │
│  verkaufen dir Inhalte. Still       │
│  Moment laesst dich deine eigenen   │
│  mitbringen — von Lehrern, die du   │
│  kennst und schaetzt.               │
│                                     │
│  Wie ein Plattenspieler: Nur        │
│  deine Platten, aber eine viel      │
│  persoenlichere Erfahrung.          │
├─────────────────────────────────────┤
│                                     │
│  [Gleiche Sektionen wie In-App,     │  Quellen-Sektionen
│   aber mit laengeren Beschreibungen │
│   und ggf. Screenshots/Icons]       │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  So importierst du in 3 Schritten   │  How-To Sektion
│                                     │
│  1. Lade eine MP3 von einer der     │
│     Quellen oben herunter           │
│  2. Oeffne die Datei und waehle     │
│     "Teilen" → "Still Moment"       │
│  3. Fertig! Die Meditation          │
│     erscheint in deiner Bibliothek  │
│                                     │
│  [App Store Badge] [Google Play]    │
├─────────────────────────────────────┤
│  Footer (wie bestehende Seiten)     │
└─────────────────────────────────────┘
```

### 3.3 SEO-Wert

Die Website-Seite bringt organischen Traffic fuer Suchbegriffe wie:
- "kostenlose Meditationen Download"
- "free guided meditation mp3 download"
- "Tara Brach Meditation herunterladen"
- "MBSR Meditation kostenlos"

Jeder dieser Suchenden ist ein potenzieller App-Nutzer.

### 3.4 Sprache (Website)

Gleicher Mechanismus wie bestehende Seiten:
- Client-side `localStorage` Toggle (EN/DE)
- Beide Sprachen im HTML, CSS-Klassen `.lang-en` / `.lang-de`
- Bestehender Language-Switcher in Header

---

## 4. Datenarchitektur: Eine Quelle der Wahrheit

### Problem
URLs und Beschreibungen tauchen an 3 Stellen auf:
1. iOS In-App Guide
2. Android In-App Guide
3. Website

Das Ticket fordert: "URLs zentralisiert an einer Stelle".

### Optionen

#### Option A: Plattform-nativ, manuell synchron halten
```
iOS:     ContentGuideSources.swift    (struct mit allen URLs)
Android: ContentGuideSources.kt       (data class mit allen URLs)
Website: guide.html                    (hardcoded im HTML)
```
- **Pro:** Einfach, keine Build-Komplexitaet, passt zu "kein Overengineering"
- **Contra:** 3 Stellen manuell synchron halten

#### Option B: Shared JSON als Single Source of Truth
```
dev-docs/data/meditation-sources.json   ← die eine Wahrheit
ios/     → Swift codegen oder Laufzeit-Parse
android/ → Kotlin codegen oder Laufzeit-Parse
docs/    → Jekyll Include oder Build-Script
```
- **Pro:** Eine Datei, drei Consumer
- **Contra:** Build-Komplexitaet, Codegen noetig, Over-Engineering fuer ~12 Eintraege

#### Option C: Plattform-nativ mit Validierungs-Script
```
iOS:     ContentGuideSources.swift
Android: ContentGuideSources.kt
Website: guide.html
Script:  scripts/validate-guide-urls.sh  ← prueft Konsistenz + Erreichbarkeit
```
- **Pro:** Einfacher Code, aber automatische Pruefung
- **Contra:** URLs noch an 3 Stellen, aber Drift wird erkannt

### Empfehlung: Option A (mit Option C als Erweiterung)

12 Eintraege sind kein Synchronisierungs-Albtraum. Die URLs aendern sich selten (hoechstens jaehrlich). Ein gemeinsames JSON mit Codegen waere Over-Engineering.

Pragmatischer Ansatz:
1. URLs pro Plattform nativ definieren (gut lesbar, gut testbar)
2. Spaeter optional: Validierungs-Script das alle 3 Quellen vergleicht
3. Die byom-strategy.md bleibt die konzeptionelle Referenz

---

## 5. Architektur (In-App)

### 5.1 Domain Layer

```
Domain/Models/MeditationSource.swift  (bzw. .kt)

struct MeditationSource {
    let name: String              // "Dharma Seed"
    let descriptionKey: String    // Localization Key
    let url: URL                  // https://dharmaseed.org
    let category: SourceCategory  // .archive, .teacher, ...
}

enum SourceCategory: CaseIterable {
    case archive         // Grosse Archive
    case teacher         // Bekannte Lehrer
    case course          // Achtsamkeitskurse
    case germanLanguage  // Deutschsprachig
    case creativeCommons // Creative Commons
}
```

### 5.2 Presentation Layer

```
Presentation/Views/ContentGuide/
    ContentGuideView.swift       — Haupt-View (ScrollView mit Sektionen)
    ContentGuideSourceRow.swift  — Einzelne Quellen-Karte
```

Kein ViewModel noetig — die Daten sind statisch. Direkt aus einem
statischen Array rendern. Das haelt die Architektur schlank.

### 5.3 Navigation

```
GuidedMeditationsListView
  └─ emptyStateView
       ├─ "Meditation importieren"  → DocumentPicker (besteht)
       └─ "Meditationen finden"     → ContentGuideView [NEU]

LibraryNavigationBar
  └─ ℹ️ Info-Button               → ContentGuideView [NEU]
```

---

## 6. Empty State Redesign

### Aktuell (beide Plattformen)
```
Keine Meditationen
Fuege deine erste Meditation hinzu, indem du eine MP3-Datei importierst.
[Meditation importieren]
```

### Neu
```
Dein persoenlicher Meditationsraum

Importiere Meditationen von deinen Lieblingslehrern —
oder entdecke kostenlose Quellen im Internet.

[Meditation importieren]        ← Primaer-Button
[Meditationen finden]           ← Sekundaer-Link/Button → Content Guide
```

**Design-Prinzipien:**
- Kein "hier ist nichts"-Gefuehl
- Positiv formuliert ("wartet auf dich" statt "ist leer")
- Zwei klare Handlungsoptionen
- Primaer-CTA = Import (Nutzer hat schon MP3s)
- Sekundaer-CTA = Guide (Nutzer braucht erst Content)

---

## 7. Offene Entscheidungen

### E1: Sektions-Reihenfolge sprachabhaengig?
- **Option:** DE zeigt "Deutschsprachig" weiter oben
- **Empfehlung:** Nein, fix lassen. Nur 2 deutsche Quellen.

### E2: Icons pro Quelle oder pro Sektion?
- **Option A:** SF Symbols pro Sektion (🎙 Archive, 🧘 Lehrer, 🎓 Kurse)
- **Option B:** Favicons/Logos der Quellen laden (Netzwerk-Call!)
- **Empfehlung:** Option A. Keine Netzwerk-Calls, konsistentes Design.

### E3: Permanenter Einstieg — wo genau?
- **Option A:** Info-Icon in Library-NavBar
- **Option B:** Eintrag in Settings
- **Option C:** Subtiler Link am Ende der Library-Liste
- **Empfehlung:** Option A. Immer sichtbar, kontextuell passend.

### E4: Website-Seite sofort oder spaeter?
- **Option A:** Website + In-App gleichzeitig im Ticket
- **Option B:** In-App zuerst (Ticket-Scope), Website als Follow-up
- **Empfehlung:** Option B. In-App hat Prioritaet (loest das Churn-Problem).
  Website kann als separates Ticket kommen und bringt vor allem SEO-Wert.

### E5: Import-Hinweis am Ende des Guides?
- **Option A:** Kurzer Hinweis "So importierst du" mit 2-3 Schritten
- **Option B:** Link zur Support-Seite/FAQ
- **Option C:** Kein Hinweis (Import-Button ist ja ueberall)
- **Empfehlung:** Option A. Der Guide ist der Moment wo Nutzer motiviert sind —
  da sollte der naechste Schritt klar sein.

---

## 8. Zusammenfassung

| Was | Entscheidung |
|-----|-------------|
| **Wo** | In-App (Pflicht) + Website (optional, spaeter) |
| **Sektionen** | 5: Archive, Lehrer, Kurse, Deutsch, CC |
| **Quellen** | ~12 Eintraege (aus BYOM-Strategie) |
| **Sprache In-App** | Automatisch via Geraete-Locale |
| **Sprache Website** | Client-side Toggle (bestehendes Pattern) |
| **Datenquelle** | Plattform-nativ (kein Shared JSON) |
| **Einstieg** | Empty State CTA + Info-Icon in Library-Nav |
| **Architektur** | Statische Daten, kein ViewModel noetig |
| **Links** | System-Browser (Safari/Chrome), kein In-App-Browser |
| **Tracking** | Keines (Privacy-Prinzip) |

---

## Verwandte Dokumente

- [BYOM-Strategie](byom-strategy.md) — Quellen-Liste, Positionierung
- [Ticket shared-039](../tickets/shared/shared-039-empty-state-content-guide.md) — Akzeptanzkriterien
