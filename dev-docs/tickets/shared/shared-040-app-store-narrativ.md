# Ticket shared-040: App Store Screenshots und Visuals

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~2d | Android ~2d
**Phase**: 4-Polish
**Abhaengigkeit**: shared-078 (Texte und Ton) liefert Subtitle, Description, Promotional Text

---

## Was

App Store (iOS) und Play Store (Android) Screenshots und visuelle Metadaten ueberarbeiten. Jedes Bild transportiert eine Botschaft — die App-UI ist Beiwerk, nicht Hauptdarsteller. Dazu Keywords und Store-Metadaten optimieren.

## Warum

Der App Store ist der erste Kontaktpunkt. Die meisten User lesen keinen Text — sie swipen durch die Screenshots. Klassische UI-Screenshots ("so sieht der Timer aus") sind verschenkte Flaeche. Jedes Bild muss eine Botschaft transportieren, die auch ohne Antippen der Description funktioniert.

**Wettbewerbskontext:** Die grossen Apps (Calm, Headspace) haben professionelle Botschaften-Screenshots. Nischen-Apps haben oft nur UI-Screenshots. Die Bilder sind die Chance, mit kleinem Budget professionell zu wirken.

**Abgrenzung zu shared-078:** Dieses Ticket kuemmert sich um Visuals, Keywords und Store-Metadaten. Texte (Subtitle, Description, Promotional Text) werden in shared-078 definiert.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-078 (Texte) |
| Android   | [ ]    | shared-078 (Texte) |

---

## Screenshot-Konzept

### Prinzip

Jedes Bild besteht aus zwei Ebenen:

```
┌─────────────┐
│             │
│  HEADLINE   │  ← gross, lesbar, transportiert Botschaft
│  (2-4 Wort) │
│             │
│   ┌─────┐   │
│   │ UI  │   │  ← kleiner, liefert Kontext/Beweis
│   │     │   │
│   └─────┘   │
│             │
└─────────────┘
```

Die Headlines erzaehlen beim Durchswipen eine Geschichte: USP → Sympathie → Feature → Vertrauen → Emotion.

### Bild 1 — "Deine MP3s. Deine Praxis."

- **Botschaft:** Du bringst deine eigenen Meditationen mit
- **UI:** Gefuellte Library mit echten Lehrer-Namen (Tara Brach, Jack Kornfield, Gil Fronsdal), verschiedene Dauern
- **Warum Bild 1:** Das ist der USP, das muss zuerst kommen
- **WICHTIGSTES BILD** — entscheidet ob der User weiterschaut

### Bild 2 — "Kein Abo. Keine Werbung."

- **Botschaft:** Das nervt alle, sofort Sympathie
- **UI:** Timer laeuft in Candlelight Dark Theme — die App sieht hochwertig aus UND kostet nichts
- **Warum Bild 2:** Nach dem USP sofort das zweitwichtigste Kaufargument

### Bild 3 — "Stiller Timer mit Gongs."

- **Botschaft:** Zweites Kernfeature fuer stille Meditation
- **UI:** Timer mit sichtbarem Gong-Setup (Intervall-Gongs, Start/Ende-Klangschale)
- **Warum Bild 3:** Fuer User die keine MP3s haben, sondern still meditieren

### Bild 4 — "Kein Tracking. Keine Cloud."

- **Botschaft:** Vertrauenssignal, beilaeufig
- **UI:** Minimalistisch — evtl. "No Data Collected"-Badge nachgestellt, oder Settings-Screen der zeigt wie wenig die App braucht
- **Warum Bild 4:** Privacy als Differenzierung fuer die, die bis hierhin swipen

### Bild 5 — Das Zitat (ohne UI)

- **Botschaft:** Emotionaler Abschluss
- **Visual:** Dunkler Hintergrund, Zitat-Text gross, kein Screenshot
  > Meditiere nicht, um dich zu verbessern.
  > Tue es als Akt der Liebe —
  > der tiefen, warmen Freundschaft mit dir selbst.
- **Warum Bild 5:** Wer bis hierhin swipt, ist interessiert. Das Zitat gibt den letzten Impuls

### EN-Varianten der Headlines

1. "Your MP3s. Your practice."
2. "No subscription. No ads."
3. "Silent timer with gongs."
4. "No tracking. No cloud."
5. Zitat EN

---

## Akzeptanzkriterien

### Screenshots (beide Plattformen, je 5 Bilder)

- [ ] Jedes Bild hat eine Headline die ohne UI-Kontext funktioniert
- [ ] Headlines beim Durchswipen erzaehlen eine kohaerente Geschichte
- [ ] UI-Elemente sind Beiwerk (kleiner), Headlines dominieren (gross)
- [ ] Bild 1 zeigt gefuellte Library mit realistischen Daten (echte Lehrer-Namen, verschiedene Dauern)
- [ ] Bild 5 ist rein typografisch (kein UI-Screenshot)
- [ ] Dark Mode als Basis (wirkt hochwertiger im Store)
- [ ] DE + EN Varianten
- [ ] Screenshots auf aktuellen Geraeten (iPhone 16 Pro, Pixel 8)

### Store-Metadaten

- [ ] iOS Keywords (max 100 Zeichen): optimiert auf Long-Tail ("own mp3 meditation", "private meditation app", "meditation timer gong")
- [ ] iOS App Store Kategorie: Health & Fitness
- [ ] Android Feature Graphic aktualisiert (falls noetig)

### Qualitaet

- [ ] Texte auf Screenshots gegenlesen (kein Denglisch, keine Rechtschreibfehler)
- [ ] Screenshots im Store-Preview pruefen (Lesbarkeit auf kleinen Geraeten)
- [ ] Konsistente Typografie und Farbgebung ueber alle 5 Bilder

### Dokumentation

- [ ] Screenshot-Konzept in Fastlane-Struktur abgelegt
- [ ] Screenshot-Fixtures mit realistischen Testdaten fuer Library (Bild 1)

---

## Manueller Test

1. App Store Connect / Google Play Console → Screenshot-Preview
2. Pruefe: Kann man die Headlines lesen ohne zu zoomen?
3. Pruefe: Erzaehlen die 5 Bilder beim Swipen eine Geschichte?
4. Pruefe: Ist Bild 1 (Library) mit realistischen Daten gefuellt?
5. Pruefe: Ist Bild 5 rein typografisch (kein UI-Screenshot)?
6. DE + EN wechseln — beide Varianten konsistent?

---

## Referenz

- iOS Fastlane Metadaten: `ios/fastlane/metadata/`
- iOS Screenshots: `ios/fastlane/screenshots/`
- Android Store Listing: `android/fastlane/metadata/` (falls vorhanden)
- Texte und Ton: shared-078

---

## Hinweise

- Bild 1 (Library) braucht Test-Fixtures mit realistischen Daten. Bestehende Screenshot-Infrastruktur (Fastlane + UI Tests) kann das liefern.
- Keywords: "meditation" allein ist zu kompetitiv. Long-Tail Keywords wie "own mp3 meditation" oder "private meditation app" haben weniger Konkurrenz.
- Die Reihenfolge der Bilder ist bewusst gewaehlt: USP → Sympathie → Feature → Vertrauen → Emotion. Nicht aendern ohne guten Grund.
- "Kostenlos" bewusst nicht als Screenshot-Headline — zieht die falsche Zielgruppe an. "Kein Abo" kommuniziert dasselbe, aber positiver.
- Store-Beschreibung sollte NICHT "kostenlos" als erstes Wort verwenden — fuehre mit dem USP, erwaehne "kostenlos" weiter unten.
