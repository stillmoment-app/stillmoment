---
id: shared-010
title: Stille-Option umbenennen
status:
  ios: done
  android: done
phase: 4-Polish
priority: niedrig
---

# Ticket shared-010: Stille-Option umbenennen

**Aufwand**: iOS ~5min | Android ~5min

---

## Was

Die Hintergrundgeräusch-Option "Minimale Atmosphäre" soll in "Stille" umbenannt werden.

## Warum

User finden die aktuelle Bezeichnung "Minimale Atmosphäre" verwirrend. Sie erwarten bei dieser Option Stille, nicht einen minimalen Klang. "Stille" ist klarer und entspricht der User-Erwartung.

---

## Akzeptanzkriterien

- [x] Name geändert: "Stille" (DE) / "Silence" (EN)
- [x] Description geändert: "Meditiere in Stille." (DE) / "Meditate in silence." (EN)
- [x] Lokalisiert (DE + EN)
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. App öffnen, Timer-Tab
2. Einstellungen öffnen (Zahnrad)
3. Hintergrund-Audio Picker antippen
4. Erwartung: Option zeigt "Stille" mit Beschreibung "Meditiere in Stille."

---

## Referenz

- iOS: `ios/StillMoment/Resources/BackgroundAudio/sounds.json` (DE + EN eingebettet)
- Android: `android/app/src/main/res/values/strings.xml` (EN) + `values-de/strings.xml` (DE)

---

## Hinweise

iOS und Android haben unterschiedliche Lokalisierungs-Architekturen:
- iOS: Zentrale `sounds.json` mit eingebetteten Übersetzungen
- Android: Standard Android-Lokalisierung via `strings.xml`

Der technische Sound (silence.m4a) bleibt unverändert.
