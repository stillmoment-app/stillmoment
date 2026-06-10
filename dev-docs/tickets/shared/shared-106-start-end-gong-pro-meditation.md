# Ticket shared-106: Start- und End-Gong pro Meditation

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. UI und Persistenz sind einfach; das Risiko liegt in der Audio-Koordination am Ende der Wiedergabe — der End-Gong muss auf dem Lock Screen vollstaendig ausklingen, bevor die Audio-Wiedergabe freigegeben wird.
**Phase**: 3-Feature

---

## Was

User koennen pro Meditation einstellen, dass ein Gong den Anfang und das Ende der Wiedergabe markiert — wie beim Meditationstimer. Die Einstellung ist standardmaessig aus.

## Warum

Der Gong rahmt die Meditation rituell, egal ob still oder gefuehrt. Besonders bei getrimmten Meditationen (shared-105) ersetzt der End-Gong einen abgeschnittenen Abschluss durch ein sanftes, bewusstes Ende statt eines abrupten Stopps.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Edit-Sheet bietet einen Schalter "Gong am Anfang und Ende" (Standard: aus)
- [ ] Bei aktiviertem Schalter: Beim Start spielt der Gong, gefolgt von einer kurzen Atempause, dann beginnt das Audio
- [ ] Am Ende der Wiedergabe (Endpunkt bzw. Dateiende) spielt der End-Gong
- [ ] Der End-Gong spielt vollstaendig aus — auch bei gesperrtem Bildschirm
- [ ] Gong-Klang und -Lautstaerke folgen der bestehenden Gong-Auswahl aus den Timer-Einstellungen (keine eigene Klangauswahl)
- [ ] Funktioniert auch fuer Meditationen ohne Trim-Punkte
- [ ] Einstellung bleibt nach App-Neustart erhalten
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (falls neuer Begriff eingefuehrt wird)

---

## Manueller Test

1. Bei einer Meditation im Edit-Sheet "Gong am Anfang und Ende" aktivieren
2. Meditation abspielen, Handy sperren und weglegen
3. Erwartung: Gong → kurze Pause → Audio beginnt; am Ende der Wiedergabe spielt der End-Gong vollstaendig aus (auch auf dem Lock Screen), danach erscheint der regulaere Abschluss-Screen — identisch auf beiden Plattformen

---

## Referenz

- Gong-Infrastruktur des Meditationstimers (Start-/End-Gong, shared-016) inkl. Klang- und Lautstaerke-Einstellungen
- Bestehendes Edit-Sheet fuer Meditations-Metadaten als Ort fuer den Schalter
- shared-105 (Trim-Punkte): End-Gong spielt am dort definierten Endpunkt

---

## Hinweise

- **Lock-Screen-Fallstrick (Praezedenzfall Lock-Screen-Gong-Bug):** Die Audio-Wiedergabe darf erst freigegeben werden, nachdem der End-Gong vollstaendig gespielt hat. Reihenfolge: Audio endet → Gong spielt aus → erst dann Session beenden. Auf beiden Plattformen sauber koordinieren.
- Fachlich unabhaengig von shared-105 nutzbar (funktioniert auch ohne Trim-Punkte); bei gesetztem Endpunkt markiert der End-Gong diesen Punkt.
