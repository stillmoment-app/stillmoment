# Ticket shared-039: Empty State + In-App Content Guide

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Komplexitaet**: Gering — UI-only, keine Business-Logik. Hauptarbeit ist Lokalisierung und Theme-Konsistenz.
**Phase**: 4-Polish

---

## Was

Zwei zusammenhaengende Massnahmen:

1. **Empty State ueberarbeiten** — Von "No meditations yet" zu einer einladenden Willkommensbotschaft mit Waveform-Icon und zwei CTAs.
2. **"Wo finde ich Meditationen?" Sheet** — Kompaktes In-App-Sheet mit kuratierten Links zu kostenlosen Meditations-Quellen, nach Sprache getrennt (DE / EN).

## Warum

Das groesste Problem fuer neue Nutzer: Sie oeffnen die Library, sehen eine leere Liste, und denken "diese App hat keinen Content". Der Empty State muss einladend sein und den Weg zu Content zeigen — ohne dass die App selbst Content produzieren muss.

Das Sheet loest das "leere App"-Problem ohne externen Server: statisch, offline-faehig, wartbar ueber Lokalisierungsdateien.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## UX-Design

### Empty State (finalisiert)

```
┌─────────────────────────────────┐
│  ≡  Meditationen            + ⓘ │
├─────────────────────────────────┤
│                                 │
│           〜〜〜〜〜            │
│          〜〜〜〜〜〜           │  ← Waveform-Icon (SF Symbol: waveform)
│           〜〜〜〜〜            │
│                                 │
│   Dein persönlicher             │
│   Meditationsraum               │  ← Titel
│                                 │
│   Importiere Meditationen von   │
│   deinen Lieblingslehrern und   │  ← Body
│   erstelle so deine persönliche │
│   Bibliothek.                   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  + Meditation importieren│   │  ← Primärer CTA (warmPrimaryButton)
│  └─────────────────────────┘   │
│                                 │
│    Wo finde ich Meditationen?   │  ← Sekundärer CTA (Link-Style, kein Button-Rahmen)
│                                 │
└─────────────────────────────────┘
```

Kein Hinweis auf den Timer — der Tab-Bar macht ihn sichtbar.

### Content Guide Sheet (finalisiert)

Kompaktes Sheet (kein Full-Screen), zwei Sektionen nach App-Locale:

**DE-Locale:**
| Quelle | Beschreibung |
|--------|-------------|
| Achtsamkeit & Selbstmitgefuehl (Joerg Mangold) | MBSR, MSC, Koerperscans. 3–49 Min. Als Arzt und Psychotherapeut zertifiziert. |
| Einfach meditieren (Melissa Gein) | Achtsamkeit, Selbstliebe, Schlaf. 6–19 Min. Direkt-Download via podcast.de. |
| Meditation-Download.de | Gefuehrte Meditationen, kein Account noetig. |
| Zentrum fuer Achtsamkeit Koeln | MBSR Body Scan, Sitzmeditation. |

**EN-Locale:**
| Quelle | Beschreibung |
|--------|-------------|
| Dharma Seed | Tausende Dharma Talks & Guided Meditations. Direkt-MP3. |
| Audio Dharma (Gil Fronsdal) | Vipassana-Tradition. Direkt-MP3. |
| Tara Brach | Guided Meditations, RAIN Practice. Direkt-MP3. |
| Jack Kornfield | Lovingkindness, Forgiveness. Direkt-MP3. |
| UCLA Mindful | Forschungsbasierte Achtsamkeit. Auch deutsche Uebersetzungen verfuegbar. |
| Free Mindfulness Project | CC-lizenziert, frei verteilbar. |

Einstiegspunkt: `ⓘ`-Icon in der Library-Nav-Bar (neben `+`) — dauerhaft erreichbar, auch wenn Library gefuellt ist.

---

## Akzeptanzkriterien

### Empty State (beide Plattformen)

- [ ] Waveform-Icon ueber dem Titel (SF Symbol `waveform` / Material equivalent)
- [ ] Titel: "Dein persoenlicher Meditationsraum" (DE) / "Your Personal Meditation Space" (EN)
- [ ] Body: "Importiere Meditationen von deinen Lieblingslehrern und erstelle so deine persoenliche Bibliothek." (DE) / entsprechend EN
- [ ] Primaerer CTA: "Meditation importieren" — oeffnet Document Picker (bestehende Logik)
- [ ] Sekundaerer CTA: "Wo finde ich Meditationen?" — oeffnet Content Guide Sheet
- [ ] Kein Hinweis auf Timer-Tab
- [ ] Design passt zu allen 3 Themes, Light + Dark

### Content Guide Sheet (beide Plattformen)

- [ ] Erreichbar ueber Empty State (sekundaerer CTA) UND ueber `ⓘ`-Icon in der Nav-Bar
- [ ] Zeigt DE-Quellen bei DE-Locale, EN-Quellen bei EN-Locale
- [ ] Jede Quelle: Name, Kurzbeschreibung (1 Satz), Link
- [ ] Links oeffnen System-Browser (Safari / Chrome), keinen In-App-Browser
- [ ] Kein Tracking welche Links geklickt werden
- [ ] Sheet scrollbar
- [ ] Alle URLs zentral in Lokalisierungsdateien — nicht hardcoded in Views

### Qualitaet

- [ ] Lokalisiert (DE + EN) — Texte und Quellen-Listen
- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Accessibility: Links semantisch korrekt markiert, Section Headers

### Tests

- [ ] Unit Tests: Sheet rendert korrekt (DE + EN Locale)
- [ ] Snapshot/Screenshot fuer Empty State (mindestens 1 Theme, Light + Dark)

### Dokumentation

- [ ] CHANGELOG.md

---

## Manueller Test

### Empty State

1. Alle Meditationen loeschen (oder Neuinstallation)
2. Library Tab oeffnen
3. Erwartung: Waveform-Icon, Einladungstext, zwei CTAs sichtbar
4. Primaeren CTA tippen → Document Picker oeffnet sich
5. Sekundaeren CTA tippen → Content Guide Sheet oeffnet sich

### Content Guide Sheet

1. Sheet oeffnen (via Empty State oder `ⓘ`-Icon)
2. Durch Quellen scrollen
3. Einen Link antippen
4. Erwartung: Safari/Chrome oeffnet sich, App bleibt im Hintergrund
5. Zurueck zur App: Sheet ist geschlossen, Library unveraendert

### Permanenter Zugang

1. Meditation importieren (Library nicht mehr leer)
2. `ⓘ`-Icon in der Nav-Bar ist weiterhin sichtbar
3. Tippen → Content Guide Sheet oeffnet sich

### Locale-Trennung

1. Geraet auf DE stellen → nur deutsche Quellen sichtbar
2. Geraet auf EN stellen → nur englische Quellen sichtbar

---

## Referenz

- iOS Empty State: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Android Empty State: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/EmptyLibraryState.kt`
- BYOM-Strategie: `dev-docs/concepts/byom-strategy.md`

---

## Hinweise

- URLs in Lokalisierungsdateien ablegen (z.B. `guided_meditations_source_dharma_seed_url`), damit sie ohne Code-Aenderung aktualisierbar sind.
- Der Content Guide ist rein statisch — kein dynamischer Content, keine API-Calls.
- Die Quellen-Auswahl ist bewusst klein gehalten. Qualitaet > Quantitaet.
