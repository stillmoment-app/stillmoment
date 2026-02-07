# Ticket shared-040: App Store Narrativ und Screenshots

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~2d | Android ~2d
**Phase**: 4-Polish

---

## Was

App Store (iOS) und Play Store (Android) Praesenz ueberarbeiten mit Fokus auf das BYOM-Alleinstellungsmerkmal:

1. **Beschreibungstexte** neu schreiben (Titel, Untertitel, Beschreibung, Keywords)
2. **Screenshot-Konzepte** definieren und umsetzen (5 Screenshots pro Plattform)
3. **Promotional Text** (iOS) fuer saisonale/aktuelle Botschaften

## Warum

Der App Store ist der erste Kontaktpunkt. Wenn das USP dort nicht sofort sichtbar ist, wird es nie entdeckt. Aktuell kommuniziert die Store-Praesenz das Alleinstellungsmerkmal "eigene MP3s importieren" nicht prominent genug. Die Screenshots muessen das Konzept visuell greifbar machen - insbesondere eine gefuellte Library mit echten Lehrer-Namen.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md) | [Marktrecherche](../../reference/market-research.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Beschreibungstexte (beide Plattformen)

- [ ] App-Titel: "Still Moment - Meditation Timer" (beide Stores)
- [ ] Untertitel/Kurzbeschreibung kommuniziert den USP direkt
- [ ] Langbeschreibung: fuehrt mit BYOM-USP, dann Timer, dann Privacy
- [ ] Keywords (iOS): optimiert auf "meditation timer", "mp3 import", "no subscription", etc.
- [ ] Beide Sprachen: DE + EN
- [ ] Kein Marketing-Sprech das nicht eingeloest wird - authentisch und ehrlich

### Screenshot-Konzepte (beide Plattformen, je 5 Bilder)

- [ ] Screenshot 1: Timer in Aktion (Candlelight Dark) - "Finde deine Stille" / "Find your stillness"
- [ ] Screenshot 2: Gefuellte Library mit echten Lehrer-Namen - "Deine Lehrer. Deine Bibliothek." / "Your teachers. Your library."
- [ ] Screenshot 3: Import-Flow visualisiert - "Importiere deine Meditationen" / "Import your meditations"
- [ ] Screenshot 4: Drei Themes nebeneinander - "Drei handverlesene Themes" / "Three curated themes"
- [ ] Screenshot 5: Privacy-Statement - "Keine Abos. Kein Tracking. Keine Werbung." / "No subscriptions. No tracking. No ads."
- [ ] Screenshots nutzen bestehende Fastlane/Screenshot-Infrastruktur wo moeglich
- [ ] Screenshot 2 zeigt realistische Daten: verschiedene Lehrer (z.B. "Tara Brach", "Jack Kornfield", "Gil Fronsdal"), verschiedene Dauern

### Store-Metadaten

- [ ] iOS Promotional Text (kann jederzeit ohne Review geaendert werden)
- [ ] iOS App Store Keywords (max 100 Zeichen)
- [ ] Android Feature Graphic (falls noetig aktualisiert)
- [ ] Beide Stores: Kategorie korrekt (Health & Fitness)

### Qualitaet

- [ ] Texte gegenlesen (kein Denglisch, keine Rechtschreibfehler)
- [ ] Screenshots auf aktuellen Geraeten (iPhone 15 Pro, Pixel 8)
- [ ] Dark Mode Screenshot als Hauptbild (wirkt hochwertiger im Store)

### Dokumentation
- [ ] Texte in `dev-docs/release/` oder Fastlane-Metadaten ablegen
- [ ] Screenshot-Fixtures aktualisieren falls noetig

---

## Manueller Test

1. Oeffne App Store Connect / Google Play Console im Preview-Modus
2. Pruefe: Ist der USP "eigene Meditationen importieren" in den ersten 2 Zeilen sichtbar?
3. Pruefe: Zeigt Screenshot 2 eine gefuellte Library? (Nicht den Empty State!)
4. Pruefe: Sind alle Texte in DE und EN vorhanden und konsistent?

---

## Screenshot-Konzept Detail

### Bild 1 - Timer (Hero Shot)
- Candlelight Theme, Dark Mode
- Timer laeuft bei ca. 14:32 von 20:00
- Progress Ring gut sichtbar
- Text-Overlay: "Finde deine Stille"

### Bild 2 - Library (USP Shot) - WICHTIGSTES BILD
- Library mit 6-8 Meditationen
- Gruppiert nach 2-3 Lehrern
- Realistische Namen und Dauern
- Text-Overlay: "Deine Lehrer. Deine Bibliothek."
- Zeigt das Konzept sofort: "Ah, ICH bringe die Meditationen mit"

### Bild 3 - Import Flow
- Split-Screen oder Sequenz: Files-Picker → Meditation erscheint in Library
- Text-Overlay: "Importiere deine Meditationen"
- Macht den technischen Flow verstaendlich

### Bild 4 - Themes
- Drei Phones nebeneinander (Candlelight, Forest, Moon)
- Jeweils Timer-Screen
- Text-Overlay: "Drei handverlesene Themes"

### Bild 5 - Privacy (Closer)
- Dunkler Hintergrund, minimalistisch
- Bullet Points:
  - Keine Abos
  - Kein Tracking
  - Keine Werbung
  - Keine Accounts
- Text-Overlay: "Privatsphaere ist nicht verhandelbar."

---

## Referenz

- iOS Fastlane Metadaten: `ios/fastlane/metadata/`
- iOS Screenshots: `ios/fastlane/screenshots/`
- Android Store Listing: `android/fastlane/metadata/` (falls vorhanden)
- Beschreibungstexte: `dev-docs/concepts/byom-strategy.md` (Abschnitt "App Store Strategie")

---

## Hinweise

- Screenshot 2 (Library) braucht Test-Fixtures mit realistischen Daten. Die bestehende Screenshot-Infrastruktur (Fastlane + UI Tests) kann das liefern.
- Promotional Text (iOS) kann ohne App Review Update geaendert werden - ideal fuer saisonale Botschaften oder A/B-Testing von Formulierungen.
- Keywords: "meditation" allein ist zu kompetitiv. Long-Tail Keywords wie "own mp3 meditation" oder "private meditation app" haben weniger Konkurrenz.
- Die Store-Beschreibung sollte NICHT "kostenlos" als erstes Wort verwenden - das zieht die falsche Zielgruppe an. Fuehre mit dem USP, erwaehne "kostenlos" weiter unten.
