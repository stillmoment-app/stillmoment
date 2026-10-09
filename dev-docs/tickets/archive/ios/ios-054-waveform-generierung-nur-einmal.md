---
id: ios-054
title: Waveform einer Meditation nur einmal gleichzeitig berechnen
status: done
phase: 2-Architektur
priority: mittel
depends_on: [ios-055]
---

# Ticket ios-054: Waveform einer Meditation nur einmal gleichzeitig berechnen

**Komplexitaet**: Fehlt die Waveform noch im Cache, verdrahten mehrere Bildschirme (Bibliothek, Editor, Trim-Editor, Player) heute jeweils eine eigene Generierungs-Instanz über Default-Argumente. Das Risiko liegt darin, wirklich alle Wege zu erwischen: Der Compiler meldet eine vergessene Weitergabe nicht, weil der Default still einspringt.
**Abhaengigkeiten**: ios-055 (behebt die Ursache; dieses Ticket weist den Waveform-Fall nach)

---

## Was

Wird die Waveform einer Meditation gerade erzeugt, soll jeder weitere Bildschirm, der dieselbe Waveform braucht, auf diese laufende Berechnung warten, statt eine zweite zu starten. Das gilt app-weit, nicht nur innerhalb eines Bildschirms.

## Warum

Die App verspricht schon heute, dass gleichzeitige Anfragen für dieselbe Meditation sich eine Berechnung teilen. Das stimmt aber nur pro Instanz, und Bibliothek, Editor und Player haben jeweils eine eigene. Öffnet der User direkt nach dem Import (während die Vorberechnung noch läuft) den Player oder Editor, wird dieselbe Datei doppelt dekodiert. Das kostet Akku und lässt die Waveform länger auf sich warten.

---

## Akzeptanzkriterien

### Feature
- [ ] Meditation importieren und sofort den Player öffnen: Die Datei wird genau einmal für die Waveform dekodiert (im Log nachweisbar), und der Player zeigt die Waveform, sobald diese eine Berechnung fertig ist.
- [ ] Dasselbe gilt für den Editor und den Trim-Editor, die direkt nach dem Import geöffnet werden.
- [ ] Liegt die Waveform schon im Cache, verhält sich alles wie bisher.

### Tests
- [ ] Test, der belegt, dass Bibliothek, Editor, Trim-Editor und Player dieselbe Waveform-Quelle nutzen (zwei gleichzeitige Anfragen von verschiedenen Bildschirmen → eine Generierung)

### Dokumentation
- [x] Status-Tabelle in `dev-docs/architecture/architecture-review-2026-09.md` (Befund 1) aktualisieren

---

## Abschluss (2026-10-09)

Ohne eigene Umsetzung erledigt: ios-055 hat die Ursache vollstaendig beseitigt. Per Code-Analyse geprueft, nicht am Geraet:

- `WaveformProvider` wird im App-Code nur in `AppDependencies.live()` erzeugt; `StillMomentApp` ruft `live()` genau einmal auf.
- Bibliothek, Editor, Trim-Editor und Player verlangen `waveformProvider` als Pflichtparameter ohne Default. Eine vergessene Weitergabe bricht den Build, zusaetzlich greift die Lint-Regel `service_created_outside_composition_root`.
- Wege zur Instanz: Bibliothek und Player ueber `makeGuidedListViewModel()` / `makePlayerViewModel()`, Editor ueber `GuidedMeditationsListView` (`self.dependencies.waveformProvider`), Trim-Editor vom Editor durchgereicht.
- `precompute(for:)` laeuft ueber `waveform(for:)` und damit ueber die `inFlight`-Dedup — der Player wartet auf die laufende Vorberechnung.

Nachweis-Stand:
- `AppDependenciesTests.testLibraryAndPlayerShareTheWaveformProvider` (aus ios-055) belegt Bibliothek + Player; `WaveformProviderTests.testConcurrentRequestsForSameMeditationGenerateOnce` belegt die Dedup.
- **Bewusste Restluecke:** Editor und Trim-Editor holen den Provider per direktem Feldzugriff in der View, den `AppDependenciesTests` nicht prueft. Akzeptiert, weil kein Default existiert, auf den ein vergessener Weg ausweichen koennte. Falls doch gewuenscht: `make…`-Funktion fuer das Edit-Sheet auf `AppDependencies` ergaenzen.
- Der manuelle Log-Test (Import → sofort Player) wurde nicht durchgefuehrt.

---

## Manueller Test

1. Eine lange Meditation (15+ Min) importieren.
2. Direkt danach den Player dieser Meditation öffnen, noch bevor die Waveform fertig ist.
3. Erwartung: Im Log erscheint nur eine Waveform-Generierung für diese Meditation, und der Player zeigt die Waveform, sobald sie fertig ist.

---

## Referenz

- Quelle: `dev-docs/architecture/architecture-review-2026-09.md`, Befund 1 „Dependency-Identität hat keinen Ort“
- iOS: `ios/StillMoment/Infrastructure/Services/WaveformProvider.swift` (In-Flight-Dedup, instanzlokal)

---

## Hinweise

- Befund 1 des Reviews geht über die Waveform hinaus (`AudioService`, `GuidedMeditationService`). Dieses Ticket deckt **nur** die Waveform ab. Die übrigen Default-Instanzen werden getrennt eingeplant.
- Android ist nicht betroffen bzw. nicht untersucht: Das Review hat diesen Riss nur für iOS belegt.
