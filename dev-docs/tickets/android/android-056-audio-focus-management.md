# Ticket android-056: AudioFocus Management implementieren

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

AudioFocus-Management im AudioService implementieren, sodass die App korrekt auf Audio-Unterbrechungen (Anrufe, andere Apps) reagiert und Systemressourcen effizient nutzt.

## Warum

Aktuell fehlt das Android AudioFocus-Management. Ohne AudioFocus:
- Spielt die App weiter wenn ein Anruf eingeht
- Reagiert die App nicht wenn eine andere Audio-App startet
- Wird unnoetig Batterie verbraucht wenn Audio im Hintergrund laeuft obwohl der User etwas anderes hoert
- Entspricht das Verhalten nicht den Android Audio-Guidelines

---

## Entscheidungen

| Frage | Entscheidung |
|-------|--------------|
| Scope | Beide Services (`AudioService` + `AudioPlayerService`) |
| Bei Unterbrechung | Pausieren (kein Ducking) |
| Nach Unterbrechung | Kein Auto-Resume (User muss manuell fortsetzen) |

## Akzeptanzkriterien

- [x] AudioFocusRequest beim Start von Audio angefordert (beide Services)
- [x] Audio pausiert bei transientem Focus-Verlust (z.B. Navigation, Anruf)
- [x] Audio pausiert bei permanentem Focus-Verlust (z.B. andere Musik-App)
- [x] Kein Auto-Resume nach Focus-Wiederherstellung
- [x] Focus wird bei Stop/Pause freigegeben
- [x] Kein Absturz bei Focus-Denial

---

## Manueller Test

1. Meditation starten
2. Waehrend Audio laeuft: Telefon anrufen lassen
3. Erwartung: Audio pausiert/stoppt bei Anruf
4. Nach Anruf beenden: Audio bleibt pausiert (oder resumed - je nach Design-Entscheidung)

5. Meditation starten
6. Andere Musik-App oeffnen und abspielen
7. Erwartung: Still Moment Audio stoppt

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerService.kt`
- iOS-Referenz: `AudioSessionCoordinator` zeigt das erwartete Verhalten

---

## Hinweise

- `AudioFocusRequest.Builder()` mit `AUDIOFOCUS_GAIN` oder `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`
- `OnAudioFocusChangeListener` fuer Focus-Aenderungen implementieren
- Bei Meditation ist "Resume nach Focus-Verlust" evtl. nicht gewuenscht (User muss bewusst neu starten)
