# Ticket android-052: Pure Content Pattern fuer Screenshot-Tests

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Content-Composables sollen "pure" sein - ohne `stringResource()` Aufrufe - damit Screenshot-Tests dieselben Composables wie die Production-App verwenden koennen.

## Warum

Aktuell duplizieren Screenshot-Tests Layout-Code in separaten Composables (z.B. `LibraryScreenshotContent`). Das fuehrt zu:
- Out-of-sync zwischen Screenshots und App (z.B. "Bibliothek" statt "Geführte Meditationen")
- Doppelter Wartungsaufwand
- Fehler werden erst spaet entdeckt

---

## Akzeptanzkriterien

- [ ] `TimerScreenContent` bekommt alle UI-Strings als Parameter
- [ ] `GuidedMeditationsListScreenContent` bekommt alle UI-Strings als Parameter
- [ ] `GuidedMeditationPlayerScreenContent` bekommt alle UI-Strings als Parameter
- [ ] Production-Screens (Wrapper) rufen `stringResource()` auf und uebergeben Strings
- [ ] Screenshot-Tests verwenden dieselben Content-Composables mit hardcodierten Strings
- [ ] Keine duplizierten Screenshot-Composables mehr
- [ ] Screenshots generieren erfolgreich fuer DE und EN
- [ ] Screenshots zeigen korrekten Text (z.B. "Gefuehrte Meditationen" nicht "Bibliothek")

---

## Manueller Test

1. `make screenshots-android` ausfuehren
2. Screenshots pruefen: Titel, Labels, Buttons muessen dem App-Layout entsprechen
3. DE und EN Screenshots vergleichen - beide muessen korrekt lokalisiert sein

---

## Referenz

- Analyse: Die Exploration hat gezeigt, dass ~30 Strings ueber 3 Screens als Parameter uebergeben werden muessen
- iOS: Nutzt aehnliches Pattern mit View/Content Trennung
- Android: `PlayStoreScreenshotTests.kt` zeigt aktuelles Problem

---

## Hinweise

**Pattern:**
```
Screen (mit ViewModel + stringResource)
    |
    v
ScreenContent (PURE - alle Strings als Parameter)
    ^
    |
Screenshot Tests (hardcodierte Strings)
```

**Migration:** Bestehende Signatur als Wrapper behalten (ruft stringResource auf), neue `*ContentPure` Version erstellen fuer Tests.

---
