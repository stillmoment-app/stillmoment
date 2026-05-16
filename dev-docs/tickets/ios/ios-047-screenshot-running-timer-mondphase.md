# Ticket ios-047: Running-Timer-Screenshot mit sichtbarer Mondphase

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Niedrig — Configurer analog zu `PreparationTimeConfigurer` und Wartezeit im UI-Test. Risiko: Test wird flaky, wenn die Wartezeit zu knapp gegen den Snapshot-Trigger faellt.
**Abhaengigkeiten**: shared-095
**Phase**: 4-Polish
**Plan**: [Implementierungsplan](../plans/ios-047.md)

---

## Was

Der App-Store-Screenshot der laufenden Sitzung (`02_TimerRunning`) zeigt einen klar erkennbaren Mondphasen-Fortschritt — kein reiner Neumond direkt nach Start.

## Warum

Mit shared-095 ist die laufende Sitzung als wandernde Mondphase visualisiert. Der aktuelle Screenshot-Test startet den Timer (Default 10 min) und macht sofort den Screenshot — der Mond steht praktisch komplett im Neumond, vom neuen Visual ist auf dem App-Store-Bild nichts zu sehen. Die charakteristische Mondphasen-Stimmung kommt im Marketing-Material so nicht rueber.

---

## Akzeptanzkriterien

### Screenshot
- [ ] Auf `02_TimerRunning` ist der Schatten klar gewandert: ein sichtbarer Teil des Mondes ist beleuchtet (zwischen ~25 % und ~50 % der Sitzung)
- [ ] Halo ist entsprechend dem Fortschritt sichtbar (nicht Maximum, nicht unsichtbar)
- [ ] Light- und Dark-Variante zeigen denselben Fortschritts-Zustand

### Test
- [ ] `02_TimerRunning` laeuft deterministisch (nicht flaky durch Animation-Timing)
- [ ] Restliche Screenshot-Tests laufen unveraendert durch
- [ ] Test-Laufzeit-Zuwachs liegt im Sekundenbereich, nicht Minutenbereich

### Dokumentation
- [ ] CHANGELOG.md unter "Unreleased" (interner Hinweis, keine User-Auswirkung — optional, falls Konvention das nicht verlangt: weglassen)

---

## Manueller Test

1. `make screenshots` ausfuehren (Light)
2. `02_TimerRunning_de.png` und `02_TimerRunning_en.png` oeffnen — Mond zeigt sichtbar Halbmond-artigen Fortschritt
3. `make screenshots MODE=dark` ausfuehren
4. Dark-Variante zeigt denselben Fortschritts-Zustand mit warmem Disc-Verlauf

---

## Referenz

- iOS: `ios/StillMomentUITests/ScreenshotTests.swift` → `testScreenshot02_timerRunning`
- iOS: `ios/StillMoment/Infrastructure/Configuration/PreparationTimeConfigurer.swift` — Muster fuer Launch-Argument-Configurer
- shared-095: Mondphasen-Visualisierung

---

## Hinweise

- Die Sitzungsdauer im Test sollte kurz genug sein, damit eine Wartezeit von wenigen Sekunden bereits einen messbaren Fortschritt erzeugt — sonst dauert der Test unnoetig lange.
- Wartezeit deterministisch loesen: lieber auf einen konkreten Anzeigezustand (`timer.display.time`) warten als auf eine feste Wallclock-Zeit, sonst flaky bei langsamer CI.
- Android: Mondphase ist dort noch nicht umgesetzt (shared-095 Android offen). Wenn Android nachzieht, wird ein paralleles Ticket fuer Screengrab faellig — hier explizit iOS-only.
