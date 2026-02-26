# Ticket shared-070: Guided-Meditation-Einstellungen in globale Settings

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Die Vorbereitungszeit für geführte Meditationen wird aus dem eigenen Settings-Sheet entfernt und in den globalen Einstellungen-Tab integriert. Der Settings-Button in der Navigationsleiste der Meditationsliste entfällt.

## Warum

Die Guided-Meditations-Liste hat aktuell zwei konkurrierende Einstiegspunkte für "Einstellungen": einen Settings-Button in der Navigationsleiste und den globalen Settings-Tab in der Tab-Bar. Das verwirrt. Die Vorbereitungszeit ist eine seltene "Set and forget"-Einstellung — sie gehört in die globalen Settings, nicht als prominenter Button in die Navigationsleiste. Der freigewordene Platz in der Navigationsleiste wird genutzt, um den Import-Button wieder an die rechte Seite zu rücken.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] In den globalen Settings gibt es eine neue Section "Geführte Meditationen" mit der Vorbereitungszeit (Toggle + Dauer-Picker)
- [x] Das Tab-Bar-Icon des globalen Settings-Tabs wird durch das Icon der Guided Meditations ersetzt
- [x] Die Vorbereitungszeit-Einstellung verhält sich identisch wie bisher (Aus / 5s / 10s / 15s / 20s / 30s / 45s)
- [x] Der Settings-Button in der Navigationsleiste der Meditationsliste ist entfernt
- [x] Der Import-Button (Plus) ist wieder rechtsbündig in der Navigationsleiste
- [x] Das bisherige GuidedMeditationSettingsView / entsprechende Sheet ist entfernt
- [x] Lokalisiert (DE + EN)

### Tests
- [x] Unit Tests iOS (Settings-Persistenz)
- [ ] Unit Tests Android (Settings-Persistenz)

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. App öffnen → Tab "Einstellungen" → Section "Geführte Meditationen" ist sichtbar
2. Vorbereitungszeit aktivieren und Dauer wählen
3. Tab "Bibliothek" öffnen → kein Settings-Icon in der Navigationsleiste, Plus-Button ist rechts
4. Meditation starten → Vorbereitungszeit greift wie konfiguriert
5. App neu starten → Einstellung bleibt erhalten

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`
- iOS: `ios/StillMoment/Presentation/Views/Settings/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/`
