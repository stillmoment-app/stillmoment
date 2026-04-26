# Ticket shared-080: Danke-Screen ueberlebt App-Termination

**Status**: [~] IN PROGRESS (iOS)
**Plan iOS**: [Implementierungsplan](../plans/shared-080-ios.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Beide Plattformen bieten Standard-Mechanismen fuer State-Restoration (iOS `@SceneStorage`, Android `SavedStateHandle`/persistiertes Repository). Heikel ist das Zusammenspiel mit dem bestehenden in-place Danke-Screen im Player-Stack: keine doppelte Anzeige, sauberes Loeschen des Markers nur bei natuerlichem Ende (nicht bei Abbruch / Audio-Konflikt / Schliessen).
**Phase**: 4-Polish

---

## Was

Der Danke-Screen am Ende einer gefuehrten Meditation soll auch dann erscheinen, wenn der User das Telefon waehrend der Meditation gesperrt hat und das Betriebssystem die App in der Zwischenzeit suspendiert oder terminiert hat. Beim erneuten Oeffnen der App sieht der User den Danke-Screen — auch wenn der Navigation- oder ViewModel-State zwischenzeitlich verworfen wurde.

## Warum

Der Standard-Use-Case ist: User startet die Meditation und legt das Telefon weg. Auf beiden Plattformen wird der App-Lifecycle-Anker (iOS Audio Session, Android Foreground Service) direkt nach dem natuerlichen Ende der Meditation freigegeben — ab diesem Moment kann das System die App suspendieren und terminieren. Genau in dem Moment, in dem der Abschluss spuerbar werden sollte, bricht die UX ab: auf iOS landet der User auf der Bibliotheksliste, auf Android sieht er den Player erneut im Loading-/Idle-State (ggf. startet die Meditation sogar von vorne).

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [~]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Wenn die Meditation natuerlich endet, sieht der User beim naechsten Oeffnen der App den Danke-Screen — unabhaengig davon, ob die App im Hintergrund war, suspendiert wurde oder neu gestartet werden musste.
- [ ] Tippt der User auf "Zurueck" auf dem Danke-Screen, kehrt er zur Meditationsliste zurueck und der Danke-Screen erscheint nicht erneut.
- [ ] Wenn der User direkt im Anschluss eine neue Meditation startet, erscheint der alte Danke-Screen nicht mehr.
- [ ] Der Danke-Screen erscheint nicht mehr, wenn seit dem Ende der Meditation laengere Zeit (Groessenordnung Stunden) vergangen ist.
- [ ] Bricht der User die Meditation aktiv ab (Schliessen-Button, Tab-Wechsel, Audio-Interruption ohne Resume), erscheint kein Danke-Screen.
- [ ] Lokalisiert (DE + EN) — die `MeditationCompletionView` / `MeditationCompletionScreen` ist bereits lokalisiert, keine neuen Texte noetig.
- [ ] Visuell konsistent zwischen iOS und Android — gleiches Verhalten, gleiches Erscheinungsbild wie der heutige in-place Danke-Screen.

### Tests
- [ ] Unit Tests iOS fuer den Persistenz-/Restoration-Mechanismus (Speichern, Laden, Ablauf-Logik, Loeschen bei aktivem Dismiss).
- [ ] Unit Tests Android analog.
- [ ] Unit Test pro Plattform: Danke-Screen wird nicht doppelt angezeigt, wenn der Player-View nach `finished` noch im Vordergrund steht und der persistierte Marker ebenfalls vorhanden ist.

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Verbesserung)

---

## Manueller Test

1. Eine gefuehrte Meditation starten, deren Restzeit kurz ist (z.B. eine Test-MP3 mit 30 Sekunden).
2. Telefon sperren und liegenlassen.
3. Warten, bis die Meditation durchgelaufen ist, dann mehrere Minuten warten — idealerweise mit anderer App im Vordergrund, um Memory-Druck zu erzeugen, sodass das System die App suspendiert oder terminiert.
4. Telefon entsperren und Still Moment oeffnen.
5. Erwartung (auf iOS und Android identisch): Der Danke-Screen erscheint. Tap auf "Zurueck" fuehrt zur Meditationsliste, und der Danke-Screen erscheint danach nicht erneut.

Negativ-Test:
1. Eine gefuehrte Meditation starten und nach wenigen Sekunden ueber den Schliessen-/Zurueck-Button beenden.
2. App schliessen und neu oeffnen.
3. Erwartung: Kein Danke-Screen.

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Shared/MeditationCompletionView.swift`
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` (heutige in-place Anzeige bei `playbackState == .finished`)
- iOS: `ios/StillMoment/Infrastructure/Services/AudioPlayerService.swift` (`handlePlaybackFinished` gibt die Audio Session frei → ab hier kann iOS suspendieren)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` (heutiges `isCompleted`-Feld im UiState, lebt nur im RAM)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerService.kt` (`setOnCompletionListener` stoppt den Foreground Service → ab hier kann Android terminieren)
- Verwandt: shared-052 (Timer Completion), shared-053 (Guided Meditation Completion)

---

## UX-Konsistenz

Verhalten ist plattform-identisch. Die Mechanismen unterscheiden sich, das User-sichtbare Resultat nicht.

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Wo erscheint der Danke-Screen nach Cold Launch? | Top-Level der App, ueberlagert die TabView | Top-Level der App, ueberlagert die NavHost-Tabs |
| Wann wird der persistierte Marker geloescht? | Bei Dismiss, Start einer neuen Meditation, oder nach Ablauf der Expiry | Identisch |

---

## Hinweise

- iOS bietet mit `@SceneStorage` einen Standard-Mechanismus fuer genau diesen Fall (State, der eine Scene-Discard/Termination ueberlebt). Apple's Doku formuliert die Garantie als "best-effort, limited time" — fuer einen Danke-Screen, der typischerweise innerhalb von Minuten bis wenigen Stunden gesehen wird, ist das ausreichend.
- Android bietet `SavedStateHandle` im ViewModel als analoges Standard-Mittel. Alternativ ein persistiertes Marker-Repository via DataStore — vor allem wenn der Marker auch ueberlebt, falls der NavBackStack nach laengerem Process Death verworfen wird.
- Wichtig auf beiden Plattformen: ein persistierter Marker muss eindeutig erkennen, ob die Meditation **natuerlich** geendet hat. Aktive Dismissals (User bricht ab, Schliessen/Zurueck-Button, Audio-Konflikt durch andere App, Stop-Signal aus File-Open-Flow) duerfen keinen Marker hinterlassen.
- Auch fuer Timer-Sessions (siehe shared-052) gilt grundsaetzlich dasselbe Problem. Dieses Ticket beschraenkt sich auf gefuehrte Meditationen, weil dort der Lock-Screen-Use-Case dominiert. Falls der Timer-Fall ebenfalls auftritt, lohnt ein eigenes Ticket — oder die Loesung wird so allgemein gehalten, dass sie wiederverwendbar ist.
- Heutige Anzeige im Player-Stack (in-place beim `playbackState == .finished`) bleibt funktional erhalten — der neue Marker-basierte Pfad greift nur, wenn der Stack/State verloren ging. Doppelte Anzeige ist ein Bug, der explizit getestet wird.
