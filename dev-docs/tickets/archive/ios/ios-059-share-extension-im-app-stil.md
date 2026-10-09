---
id: ios-059
title: "Teilen-Bestaetigung im Still-Moment-Stil statt System-Alert"
status: done
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket ios-059: Teilen-Bestaetigung im Still-Moment-Stil statt System-Alert

**Plan**: `dev-docs/tickets/plans/ios-059.md`

**Komplexitaet**: Die Bestaetigung selbst ist schlicht. Der Aufwand steckt darin, Farben (dunkle Palette), Schriften, App-Icon und Texte der App auch in der Share-Extension verfuegbar zu machen (eigenes Target). Die Darstellungs-Einstellung wird bewusst nicht durchgereicht (siehe Hinweise). Risiko: das knappe Speicherlimit von Extensions — keine aufwendigen Animationen oder grossen Bilder.

---

## Was

Wer eine Aufnahme oder einen Link an Still Moment teilt, sieht danach eine ruhige Bestaetigung im Stil der App statt eines Standard-System-Alerts. Faelle, in denen das Teilen heute kommentarlos endet, bekommen eine kurze, freundliche Meldung.

## Warum

Der Moment des Teilens ist oft die erste Beruehrung mit der Bibliothek, dem Kernfeature. Heute erscheint dort ein generischer iOS-Alert ("In Still Moment gespeichert" + "OK"), der nicht nach der App aussieht. Schlimmer: Bei einem nicht unterstuetzten Dateiformat, einem Link, der keine Webadresse ist, oder einem unlesbaren Inhalt schliesst sich das Teilen ohne jede Rueckmeldung — der Nutzer tippt auf "Still Moment" und es passiert scheinbar nichts.

---

## Akzeptanzkriterien

### Feature
- [ ] Nach erfolgreichem Teilen erscheint eine Bestaetigung in Farben und Schriften der App, immer in der dunklen Darstellung (unabhaengig von System und Einstellung in der App)
- [ ] Die Bestaetigung erscheint im Teilen-Fenster des Systems (Sheet) auf dem dunklen App-Hintergrund, auf allen iOS-Versionen gleich; Inhalt mittig: Absenderzeile (App-Icon + "Still Moment") ueber Titel, Text und Knopf
- [ ] Titel der Bestaetigung: "Fast geschafft" / "Almost there" (ersetzt "In Still Moment gespeichert" — die Aufnahme ist erst nach dem Oeffnen der App in der Bibliothek, und "Still Moment" steht schon in der Absenderzeile)
- [ ] Die Bestaetigung sagt in einem Satz, was als Naechstes passiert: "Oeffne Still Moment, um die Aufnahme in deine Bibliothek zu uebernehmen."
- [ ] Die Bestaetigung hat genau einen Knopf ("Fertig"), der das Teilen beendet
- [ ] Nicht unterstuetztes Dateiformat: kurze Meldung, dass nur MP3 und M4A uebernommen werden koennen
- [ ] Link, der keine Webadresse ist: kurze Meldung, dass kein passender Link gefunden wurde
- [ ] Unlesbarer oder fehlender Inhalt: kurze Meldung statt kommentarlosem Schliessen
- [ ] Meldungen erscheinen im selben Stil wie die Bestaetigung, ebenfalls mit einem Knopf
- [ ] Texte der Fehlerfaelle entsprechen inhaltlich den bestehenden Meldungen der App (z.B. "Kein Link gefunden"), keine neue Formulierung fuer denselben Sachverhalt
- [ ] VoiceOver liest Titel, Text und Knopf in sinnvoller Reihenfolge; Dynamic Type wird unterstuetzt
- [ ] Lokalisiert (DE + EN)

### Tests
- [ ] Unit Tests fuer die Zuordnung "geteilter Inhalt → Bestaetigung bzw. welche Meldung"

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Geraet auf Hell stellen, in Still Moment Darstellung "Hell" waehlen
2. In der Dateien-App eine MP3 teilen → Still Moment
3. Erwartung: Bestaetigung trotzdem dunkel, Absenderzeile mit App-Icon, ein Knopf "Fertig"; nach dem Oeffnen der App laeuft der Import wie bisher
4. In Safari eine Webseite teilen → Still Moment
5. Erwartung: Bestaetigung wie oben (die Pruefung, ob dort Audio liegt, passiert weiterhin in der App)
6. Eine `.wav`-Datei teilen → Still Moment
7. Erwartung: Meldung "nur MP3 und M4A", kein kommentarloses Schliessen
8. Einen `mailto:`-Link teilen (z.B. aus Kontakte) → Still Moment
9. Erwartung: Meldung "Kein Link gefunden"
10. Schritte 2–3 mit grosser Schrift (Dynamic Type) und VoiceOver wiederholen

---

## Referenz

- iOS: `ios/StillMomentShareExtension/`
- Theme/Typografie: `dev-docs/reference/color-system.md`
- Vorbild in der App: `ios/StillMoment/Presentation/Views/Shared/DownloadOverlayView.swift` (Karte, Masse, Knopf-Stil)
- Entwurf: Claude-Design-Projekt "Still Moment", `prototypen/teilen-bestaetigung/Teilen-Bestaetigung.html` — Runde 3 (Variante 2c) ist die gewaehlte

---

## Hinweise

- Still Moment direkt aus der Extension zu oeffnen ist von Apple fuer Share-Extensions nicht vorgesehen. Keine Umwege ueber die Responder-Chain o.ae. — fragil und ein Risiko im App-Review. Der Hinweis "Still Moment oeffnen" bleibt deshalb noetig.
- Immer dunkel ist eine bewusste Vereinfachung: Dunkel ist die Voreinstellung der App (shared-122) und so erscheint sie auch im Store. Die Darstellungs-Einstellung muesste sonst fuer die Extension lesbar abgelegt werden (App Group + Migration) — der Aufwand lohnt sich fuer diesen kurzen Moment nicht.
- Keine Karte ueber der abgedunkelten fremden App: Ab iOS 26 zeigt das System Share-Extensions immer als undurchsichtiges Sheet, `NSExtensionActionWantsFullScreenPresentation` wird ignoriert (Spike 2026-10-09, iOS 18.4 vs. 26.5). Eine Darstellung fuer alle Versionen statt zwei; Apple raet vom Vollbild-Schalter ohnehin ab.
- Fehler bewusst ohne Warnfarbe: gleicher Aufbau wie die Bestaetigung, nur der Text unterscheidet sich.
- Ob ein Link auf einen ganzen Podcast statt eine Folge zeigt usw. (shared-128), entscheidet weiterhin die App — die Extension prueft nur, ob es eine Webadresse ist.
- Android ist nicht betroffen: Dort gibt es keine Extension, die App oeffnet sich beim Teilen direkt.
