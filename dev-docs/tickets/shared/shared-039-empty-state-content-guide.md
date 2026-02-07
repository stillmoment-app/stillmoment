# Ticket shared-039: Empty State + In-App Content Guide

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~2d | Android ~2d
**Phase**: 3-Feature

---

## Was

Zwei zusammenhaengende Massnahmen:

1. **Empty State ueberarbeiten** - Von "hier ist nichts" zu "dein persoenlicher Meditationsraum wartet"
2. **"Wo finde ich Meditationen?" Guide** - In-App-Seite mit kuratierten Links zu kostenlosen Meditations-Quellen

## Warum

Das groesste Problem fuer neue Nutzer: Sie oeffnen die Library, sehen eine leere Liste, und denken "diese App hat keinen Content". Das fruehzeitige Abspringen ist vorprogrammiert. Der Empty State muss einladend sein und den Weg zu Content zeigen - ohne dass die App selbst Content produzieren muss.

Der In-App Guide verwandelt "leere App" in "App voller Moeglichkeiten". Es gibt Tausende kostenlose Meditationen im Internet (Dharma Seed, Tara Brach, UCLA Mindful, etc.) - die Nutzer wissen nur nicht wo.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Empty State (beide Plattformen)

- [ ] Neuer Empty State Text: einladend, nicht nach Mangel klingend
- [ ] Zwei CTAs: "Meditation importieren" (primaer) + "Wo finde ich Meditationen?" (sekundaer)
- [ ] Sekundaerer CTA oeffnet den Content Guide (In-App-Seite, kein externer Link)
- [ ] Design passt zu den bestehenden Themes (alle 3 Themes, Light + Dark)
- [ ] Lokalisiert (DE + EN)

### Content Guide (beide Plattformen)

- [ ] Eigene Seite/View erreichbar ueber Empty State UND ueber einen dauerhaften Einstiegspunkt (z.B. Info-Icon in Library-Nav oder Footer-Link)
- [ ] Kuratierte Sektionen mit Quellen-Links:
  - Grosse Archive (Dharma Seed, Audio Dharma, Free Buddhist Audio)
  - Bekannte Lehrer (Tara Brach, Jack Kornfield)
  - Universitaeten (UCLA Mindful, Palouse Mindfulness / MBSR)
  - Deutschsprachig (Meditation-Download.de, Zentrum fuer Achtsamkeit Koeln)
- [ ] Jede Quelle: Name, kurze Beschreibung (1 Satz), externer Link
- [ ] Links oeffnen den System-Browser (Safari/Chrome), keinen In-App-Browser
- [ ] Kein Tracking welche Links geklickt werden
- [ ] Seite scrollbar, nicht ueberladen
- [ ] Einfuehrungstext oben: erklaert kurz das Konzept "Bring Your Own Meditation"

### Qualitaet

- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Accessibility: Alle Links als Links markiert, Section Headers semantisch korrekt
- [ ] Links regelmaessig pruefbar (Liste der URLs zentral an einer Stelle)

### Tests
- [ ] Unit Tests iOS (Guide-View rendert korrekt)
- [ ] Unit Tests Android (Guide-View rendert korrekt)
- [ ] Snapshot/Screenshot fuer Empty State (beide Themes)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Empty State
1. Deinstalliere App / loesche alle Meditationen
2. Oeffne Library Tab
3. Erwartung: Einladender Empty State mit zwei Buttons
4. Tippe "Wo finde ich Meditationen?"
5. Erwartung: Content Guide oeffnet sich

### Content Guide
1. Oeffne Content Guide
2. Scrolle durch alle Sektionen
3. Tippe auf einen Link (z.B. "Tara Brach")
4. Erwartung: Safari/Chrome oeffnet sich mit der Zielseite
5. Zurueck zur App: Guide ist noch da, kein Zustandsverlust

### Guide nach Import erreichbar
1. Importiere eine Meditation (Library nicht mehr leer)
2. Pruefe: Content Guide ist weiterhin erreichbar (ueber Nav-Icon oder Settings)

---

## Referenz

- iOS Empty State: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` (Zeilen 195-215)
- Android Empty State: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/EmptyLibraryState.kt`
- Quellen-Liste: `dev-docs/concepts/byom-strategy.md` (Abschnitt "Kostenlose Quellen")

---

## Hinweise

- Die Quellen-URLs sollten zentral in einer Datei liegen (nicht hardcoded in Views), damit sie einfach aktualisiert werden koennen.
- Der Content Guide ist eine reine Informationsseite - kein dynamischer Content, keine API-Calls. Rein statisch, rein lokal.
- Die Quellen-Auswahl ist bewusst kuratiert (nicht erschlagend). Qualitaet > Quantitaet. ~15-20 Links maximal.
- Ueberlege ob der Guide auch ueber Settings oder einen Info-Button in der Library-Navigation erreichbar sein soll, wenn die Library nicht mehr leer ist.
