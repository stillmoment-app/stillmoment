---
id: ios-059
title: "Teilen-Bestaetigung im Still-Moment-Stil statt System-Alert"
status: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket ios-059: Teilen-Bestaetigung im Still-Moment-Stil statt System-Alert

**Komplexitaet**: Die Bestaetigung selbst ist schlicht. Der Aufwand steckt darin, Theme-Farben, Schriften und Texte der App auch in der Share-Extension verfuegbar zu machen (eigenes Target) und das vom Nutzer gewaehlte Theme dorthin durchzureichen. Risiko: das knappe Speicherlimit von Extensions — keine aufwendigen Animationen oder grossen Bilder.

---

## Was

Wer eine Aufnahme oder einen Link an Still Moment teilt, sieht danach eine ruhige Bestaetigung im Stil der App statt eines Standard-System-Alerts. Faelle, in denen das Teilen heute kommentarlos endet, bekommen eine kurze, freundliche Meldung.

## Warum

Der Moment des Teilens ist oft die erste Beruehrung mit der Bibliothek, dem Kernfeature. Heute erscheint dort ein generischer iOS-Alert ("In Still Moment gespeichert" + "OK"), der nicht nach der App aussieht. Schlimmer: Bei einem nicht unterstuetzten Dateiformat, einem Link, der keine Webadresse ist, oder einem unlesbaren Inhalt schliesst sich das Teilen ohne jede Rueckmeldung — der Nutzer tippt auf "Still Moment" und es passiert scheinbar nichts.

---

## Akzeptanzkriterien

### Feature
- [ ] Nach erfolgreichem Teilen erscheint eine Bestaetigung in Farben und Schriften der App, im vom Nutzer gewaehlten Theme und passend zu Hell/Dunkel
- [ ] Die Bestaetigung sagt in einem Satz, was als Naechstes passiert (Still Moment oeffnen, um die Aufnahme in die Bibliothek zu uebernehmen)
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

1. Gewaehltes Theme in Still Moment notieren, Geraet auf Dunkel stellen
2. In der Dateien-App eine MP3 teilen → Still Moment
3. Erwartung: Bestaetigung im gewaehlten Theme (dunkel), ein Knopf "Fertig"; nach dem Oeffnen der App laeuft der Import wie bisher
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

---

## Hinweise

- Still Moment direkt aus der Extension zu oeffnen ist von Apple fuer Share-Extensions nicht vorgesehen. Keine Umwege ueber die Responder-Chain o.ae. — fragil und ein Risiko im App-Review. Der Hinweis "Still Moment oeffnen" bleibt deshalb noetig.
- Das gewaehlte Theme liegt heute nur in den Einstellungen der App, auf die die Extension keinen Zugriff hat. Es muss fuer die Extension lesbar abgelegt werden (App Group). Ohne gespeicherte Wahl gilt das Standard-Theme.
- Ob ein Link auf einen ganzen Podcast statt eine Folge zeigt usw. (shared-128), entscheidet weiterhin die App — die Extension prueft nur, ob es eine Webadresse ist.
- Android ist nicht betroffen: Dort gibt es keine Extension, die App oeffnet sich beim Teilen direkt.
- Visueller Entwurf kann vorab im Claude-Design-Projekt entstehen.
