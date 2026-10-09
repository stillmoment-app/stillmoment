# Implementierungsplan: shared-137 (iOS + Android)

Ticket: shared-137
Erstellt: 2026-10-09

Gemeinsamer Vertrag für beide Plattformen. Jede Plattform setzt ihn 1:1 um; Abweichungen nur dort, wo das Ticket sie vorsieht (Melissa Gein öffnet auf iOS die App Podcasts, auf Android den Browser — das passiert durch das System, nicht durch Code).

## Annahmen und Entscheidungen

- **Reihenfolge innerhalb einer Sprache** bleibt die aus `meditation_sources.json` (Kriterium "bleibt die bisherige Reihenfolge"). Englisch also: Audio Dharma, Tara Brach, UCLA Mindful, Free Mindfulness Project. Der Design-Entwurf (Tara Brach zuerst) weicht hier ab, das Ticket gilt.
- **Eigene Sprache** wie bisher: der Sprachcode, mit dem `openGuideSheet(languageCode:)` heute aufgerufen wird; gibt es dafür keine Liste im Katalog, gilt `en`. Die Ermittlung des Codes in der View bleibt unverändert.
- **Sprachnamen** kommen vom System, nicht aus eigenen Strings: Name der anderen Sprache, dargestellt *in der eigenen Sprache* (`Locale(identifier: own).localizedString(forLanguageCode: other)` bzw. `Locale.forLanguageTag(other).getDisplayLanguage(Locale.forLanguageTag(own))`), erster Buchstabe groß. So steht auf einem französischen Gerät "Also in German", nicht "Also in allemand". Die App ist nur de/en lokalisiert, die eigene Sprache ist also immer die Sprache der Oberfläche.
- **Auf-/Zugeklappt** ist flüchtiger View-Zustand. Jedes Öffnen von "Wo finde ich Meditationen?" beginnt eingeklappt. Nichts wird gespeichert.
- **Antippen einer Quelle** verhält sich wie heute (öffnet die Adresse, schließt das Blatt) — auch in aufgeklappten anderen Sprachen.
- Keine neuen Farb- oder Typo-Tokens.

## 1. Daten: `meditation_sources.json`

Zwei Kopien, `ios/StillMoment/Resources/MeditationSources/meditation_sources.json` und `android/app/src/main/assets/meditation_sources.json`. **Beide byte-identisch** (wird nach dem Merge per `diff` geprüft). Feld `author` entfällt, neues Feld `offer` (nullable). IDs bleiben.

```json
{
  "de": [
    {
      "id": "koeln",
      "name": "Kirsten Tofahrn",
      "offer": "Zentrum für Achtsamkeit Köln",
      "description": "Mini-Übungen für den Einstieg. MBSR, MSC, Alltagsachtsamkeit.",
      "host": "zentrum-fuer-achtsamkeit.koeln",
      "url": "https://zentrum-fuer-achtsamkeit.koeln/gratis-downloads-gefuehrte-meditationen/"
    },
    {
      "id": "braehler",
      "name": "Christine Brähler",
      "offer": null,
      "description": "Selbstmitgefühl mit Tiefe: MSC, Internal Family Systems, Herzmeditationen.",
      "host": "christinebraehler.com",
      "url": "https://www.christinebraehler.com/de/meditationen/"
    },
    {
      "id": "mangold",
      "name": "Jörg Mangold",
      "offer": "Achtsamkeit & Selbstmitgefühl",
      "description": "Achtsamkeit und Selbstmitgefühl als Ressourcen. MBSR, MSC, MCP — kurz bis lang.",
      "host": "achtsamkeitundselbstmitgefuehl.de",
      "url": "https://achtsamkeitundselbstmitgefuehl.de/downloads/"
    },
    {
      "id": "gein",
      "name": "Melissa Gein",
      "offer": "Podcast „Einfach meditieren“",
      "description": "Großes Archiv mit kurzen und langen Übungen. Achtsamkeit, Selbstmitgefühl, MBSR, Entspannung.",
      "host": "podcasts.apple.com",
      "url": "https://podcasts.apple.com/de/podcast/einfach-meditieren-einfach-achtsam-leben/id1588419775"
    }
  ],
  "en": [
    {
      "id": "audio-dharma",
      "name": "Audio Dharma",
      "offer": "Insight Meditation Center",
      "description": "Guided meditations library, multiple teachers. Vipassana tradition.",
      "host": "audiodharma.org",
      "url": "https://www.audiodharma.org/playables/search?query=guided+meditation&title=Guided+Meditations"
    },
    {
      "id": "tara-brach",
      "name": "Tara Brach",
      "offer": null,
      "description": "Guided meditations, RAIN practice. Compassion, presence, sleep.",
      "host": "tarabrach.com",
      "url": "https://www.tarabrach.com/guided-meditations/"
    },
    {
      "id": "ucla-mindful",
      "name": "UCLA Mindful",
      "offer": "UCLA Health",
      "description": "Research-based mindfulness. Available in many languages.",
      "host": "uclahealth.org",
      "url": "https://www.uclahealth.org/uclamindful/free-guided-meditations"
    },
    {
      "id": "free-mindfulness",
      "name": "Free Mindfulness Project",
      "offer": null,
      "description": "Body scans, breathing, sitting meditations. Creative-commons licensed.",
      "host": "freemindfulness.org",
      "url": "https://www.freemindfulness.org/download"
    }
  ]
}
```

Die Anführungszeichen in `Podcast „Einfach meditieren“` sind typografisch (U+201E / U+201C).

## 2. Domain

- `MeditationSource`: `author` → `offer: String?` (leerer/whitespace-String wird beim Mapping zu `null`, wie heute bei `author`).
- Neu: `MeditationSourceGroup` (Value Object): `languageCode`, `sources`.
- Neu: `MeditationSourceCatalog` (Value Object, immutable) mit den Listen je Sprachcode und einer reinen Funktion
  `groups(ownLanguageCode, displayName: (code) -> String) -> [MeditationSourceGroup]`:
  1. eigene Sprache auflösen (vorhanden → sie, sonst `en`),
  2. eigene Gruppe zuerst,
  3. dann `en` (falls nicht eigene),
  4. dann übrige, sortiert nach `displayName(code)` (locale-bewusster Vergleich),
  5. leere Listen fallen weg.
  Die erste Gruppe ist die eigene Sprache. `displayName` wird injiziert, damit Domain frei von Locale-Logik und testbar bleibt.
- Repository-Protokoll: `sources(for:)` wird ersetzt durch `catalog() -> MeditationSourceCatalog`. Fallback-Logik wandert vom Repository in den Katalog.

Tests (fachlich, Domain): eigene Sprache de → [de, en]; eigene en → [en, de]; unbekannte Sprache (fr) → [en, de]; drei Sprachen mit `displayName`-Stub → eigene, en, Rest alphabetisch; Reihenfolge innerhalb einer Gruppe bleibt; leerer Katalog → []. Repository-Test: echte JSON liefert 4+4, Melissa Gein mit `offer`, Apple-Podcasts-URL und Host; keine Beschreibung enthält "Von "; Quellen ohne `offer` haben `null`.

## 3. Application (ViewModel)

- `guideSources` → `guideSourceGroups` (Liste von `MeditationSourceGroup`).
- `openGuideSheet(languageCode:)` holt den Katalog und ruft `groups(...)` mit einem `displayName`, der den Sprachnamen in der aufgelösten eigenen Sprache liefert (siehe Annahmen, erster Buchstabe groß).
- ViewModel-Tests über die bestehenden Mocks: Reihenfolge der Gruppen für de und für fr.

## 4. Presentation: Quellenliste in "Wo finde ich Meditationen?"

Vorbild: Design-Entwurf Bild A (`prototypen/import-anleitung-podcasts/Anleitung Apple Podcasts.html`). Werte aus dem Entwurf, Tokens aus dem bestehenden System.

**Quellen-Zeile** (ersetzt `SourceRow`): untereinander, linksbündig
1. Name — `body`, textPrimary
2. Angebot (nur wenn vorhanden) — `caption`, textPrimary mit sekundärer Deckkraft (Entwurf: 0.75; bestehende Opacity-Konstante nehmen, keine neue)
3. Beschreibung — `caption`, textSecondary, ~4pt Abstand nach oben
4. Adresse — `micro` in `interactive`-Farbe mit kleinem Pfeil-Symbol (iOS `arrow.up.right`, Android `Icons.AutoMirrored…`/vergleichbares Material-Symbol, ~11pt) direkt hinter dem Text, ~6pt Abstand nach oben
Das bisherige Symbol rechts in der Zeile entfällt. Karte, Trennlinien, Paddings (16/14) wie heute.

**Andere Sprache** (je eine pro weiterer Gruppe, unter der eigenen Karte):
- Eingeklappte Zeile als eigene Karte (Radius 18, 14pt Abstand nach oben, Rand wie Quellenkarte, Hintergrund schwächer als die Quellenkarte): links zwei Zeilen "Auch auf Englisch" (`body`) und "4 weitere Quellen" (`caption`), rechts Chevron nach unten, der beim Aufklappen um 180° dreht.
- Aufgeklappt: darunter (12pt Abstand) eine Quellenkarte wie oben mit den Quellen dieser Sprache.
- Antippen schaltet um; "Wo finde ich Meditationen?" bleibt offen, nichts öffnet sich extern.

**Texte** (neu, DE + EN; Anzahl als Plural):

| Key (iOS / Android sinngemäß) | DE | EN |
|---|---|---|
| `guided_meditations.guide.otherLanguage.title` (`%@` = Sprachname) | Auch auf %@ | Also in %@ |
| `guided_meditations.guide.otherLanguage.count` (Plural) | one: %d weitere Quelle · other: %d weitere Quellen | one: %d more source · other: %d more sources |
| `guided_meditations.guide.otherLanguage.collapsed` | eingeklappt | collapsed |
| `guided_meditations.guide.otherLanguage.expanded` | aufgeklappt | expanded |

iOS: Plural über das bestehende `Localizable.stringsdict`. Android: `plurals`-Resource. Kein String-Interpolieren in lokalisierten Texten.

**Barrierefreiheit**
- Quellen-Zeile: ein Element, Label = Name, Angebot (falls vorhanden), Beschreibung, Adresse — in dieser Reihenfolge. Link-Rolle und der bestehende Hinweis "öffnet …" bleiben.
- Sprach-Zeile: ein Element mit Button-Rolle, Label "Auch auf Englisch, 4 weitere Quellen", Zustand eingeklappt/aufgeklappt (iOS: `accessibilityValue`; Android: `stateDescription` + `Role.Button`, ggf. expand/collapse-Semantik).
- Identifier: Zeilen weiter `library.guideSheet.row.<id>`; Sprach-Zeile `library.guideSheet.language.<code>` (Android testTag analog).

## 5. Tests auf UI-Ebene

- iOS `LibraryFlowUITests` / Android `ContentGuideSheetTest`: deutsche Quellen sichtbar, englische nicht; Sprach-Zeile antippen → `library.guideSheet.row.tara-brach` erscheint; erneut → verschwindet; Blatt bleibt offen.
- Bestehende Tests, die `author` oder die alten Namen ("Zentrum für Achtsamkeit Köln", "Einfach meditieren", "podcast.de") erwarten, anpassen.

## 6. Screenshots

Der Store-Screenshot "ImportGuide" zeigt die Quellenliste (iOS `testScreenshot13_importGuide`, Android `screenshot08_importGuide`). Neu aufnehmen nach dem jeweils etablierten Weg der Plattform; Ergebnis-PNG ansehen, nicht nur auf grün vertrauen.

## 7. Doku

- `dev-docs/reference/glossary.md`: falls "Quelle"/MeditationSource erwähnt, um "Angebot (offer)" und die Sprachgruppen ergänzen.
- CHANGELOG-Eintrag erst beim Abschluss (close-ticket).
