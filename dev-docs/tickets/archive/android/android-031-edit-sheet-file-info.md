---
id: android-031
title: Edit Sheet File-Info Section
status: done
phase: 4-Polish
priority: niedrig
---

# Ticket android-031: Edit Sheet File-Info Section

**Aufwand**: Klein
**Abhaengigkeiten**: Keine

---

## Was

Vollstaendige File-Info Section im Edit Sheet mit Dateiname und Dauer.

## Warum

iOS zeigt eine separate Section mit Dateiname und Dauer. Android zeigt nur die Dauer inline. Der Dateiname hilft dem User zu identifizieren, welche Datei bearbeitet wird.

---

## Akzeptanzkriterien

- [x] Dateiname wird angezeigt (read-only)
- [x] Dauer wird angezeigt (read-only)
- [x] Optisch als separate Info-Section erkennbar
- [x] Lokalisiert (DE + EN)

---

## Manueller Test

1. Edit Sheet oeffnen
2. Erwartung: Dateiname und Dauer sind sichtbar

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` - Zeilen 93-117

---

<!-- Erstellt via View Quality Review -->
