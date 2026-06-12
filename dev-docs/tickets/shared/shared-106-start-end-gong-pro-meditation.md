# Ticket shared-106: Start- und End-Gong pro Meditation

**Status**: [~] IN PROGRESS (iOS done, Android offen)
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. UI und Persistenz sind einfach; das Risiko liegt in der Audio-Koordination am Ende der Wiedergabe — der End-Gong muss auf dem Lock Screen vollstaendig ausklingen, bevor die Audio-Wiedergabe freigegeben wird.
**Phase**: 3-Feature

---

## Was

User koennen pro Meditation einstellen, dass ein Gong den Anfang und/oder das Ende der Wiedergabe markiert — Start- und End-Gong sind unabhaengig voneinander schaltbar (Standard: beide aus). Der Gong-Klang ist pro Meditation individuell waehlbar und nicht an die Timer-Einstellungen gekoppelt; zur Auswahl stehen dieselben Gong-Klaenge wie beim Timer (ohne Vibrations-Option), ein gemeinsamer Klang fuer Anfang und Ende.

## Warum

Der Gong rahmt die Meditation rituell, egal ob still oder gefuehrt. Besonders bei getrimmten Meditationen (shared-105) ersetzt der End-Gong einen abgeschnittenen Abschluss durch ein sanftes, bewusstes Ende statt eines abrupten Stopps.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | inkl. Aenderungsrequests 1+2 (2026-06-12) |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Edit-Sheet bietet zwei unabhaengige Schalter "Gong am Anfang" und "Gong am Ende" (Standard: beide aus)
- [ ] Bei aktiviertem Start-Gong: Beim Start spielt der Gong, gefolgt von einer kurzen Atempause, dann beginnt das Audio
- [ ] Bei aktiviertem End-Gong: Am Ende der Wiedergabe (Endpunkt bzw. Dateiende) spielt der End-Gong
- [ ] Der End-Gong spielt vollstaendig aus — auch bei gesperrtem Bildschirm
- [ ] Edit-Sheet bietet bei mindestens einem aktivierten Schalter eine Klangauswahl pro Meditation: dieselben Gong-Klaenge wie beim Timer, jedoch ohne Vibrations-Option (Standard: Standard-Gong); ein gemeinsamer Klang fuer Anfang und Ende
- [ ] Die Klangauswahl ist unabhaengig von den Timer-Einstellungen (Aenderungen dort beeinflussen die Meditation nicht)
- [ ] Die Gong-Lautstaerke folgt weiterhin der Gong-Lautstaerke aus den Timer-Einstellungen (kein eigener Regler pro Meditation)
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

1. Bei einer Meditation im Edit-Sheet "Gong am Anfang" und "Gong am Ende" aktivieren und einen anderen Klang als den Standard waehlen
2. Meditation abspielen, Handy sperren und weglegen
3. Erwartung: Gewaehlter Gong → kurze Pause → Audio beginnt; am Ende der Wiedergabe spielt der End-Gong vollstaendig aus (auch auf dem Lock Screen), danach erscheint der regulaere Abschluss-Screen — identisch auf beiden Plattformen
4. In den Timer-Einstellungen einen anderen Gong-Klang waehlen, Meditation erneut abspielen
5. Erwartung: Die Meditation spielt weiterhin ihren eigenen, pro Meditation gewaehlten Klang
6. Nur "Gong am Ende" aktivieren ("Gong am Anfang" aus), Meditation abspielen
7. Erwartung: Audio beginnt sofort ohne Start-Gong; am Ende spielt der End-Gong — und umgekehrt bei nur aktiviertem Start-Gong

---

## Referenz

- Gong-Infrastruktur des Meditationstimers (Start-/End-Gong, shared-016) inkl. Klang- und Lautstaerke-Einstellungen
- Bestehendes Edit-Sheet fuer Meditations-Metadaten als Ort fuer den Schalter
- shared-105 (Trim-Punkte): End-Gong spielt am dort definierten Endpunkt

---

## Hinweise

- **Lock-Screen-Fallstrick (Praezedenzfall Lock-Screen-Gong-Bug):** Die Audio-Wiedergabe darf erst freigegeben werden, nachdem der End-Gong vollstaendig gespielt hat. Reihenfolge: Audio endet → Gong spielt aus → erst dann Session beenden. Auf beiden Plattformen sauber koordinieren.
- Fachlich unabhaengig von shared-105 nutzbar (funktioniert auch ohne Trim-Punkte); bei gesetztem Endpunkt markiert der End-Gong diesen Punkt.

## Aenderungsrequest 1 (2026-06-12): Klangauswahl pro Meditation

- Der Gong-Klang ist pro Meditation individuell waehlbar, nicht mehr an die Timer-Einstellungen gekoppelt.
- Zur Auswahl stehen dieselben Gong-Klaenge wie beim Timer (iOS: `GongSound.allSounds` ohne Vibration); die Vibrations-Option entfaellt bewusst (Vereinfachung).
- Standard-Klang: der Default-Gong des Timers (Tempelglocke).
- Die Gong-Lautstaerke folgt weiterhin der globalen Gong-Lautstaerke aus den Timer-Einstellungen.
- iOS-Basis-Implementierung (Klang aus Timer-Einstellungen) ist bereits gemergt — iOS muss auf die Klangauswahl pro Meditation umgebaut werden.

## Aenderungsrequest 2 (2026-06-12): Start- und End-Gong unabhaengig schaltbar

- Statt eines gemeinsamen Schalters "Gong am Anfang und Ende" gibt es zwei unabhaengige Schalter "Gong am Anfang" und "Gong am Ende" (Standard: beide aus).
- Der gewaehlte Klang gilt gemeinsam fuer beide Gongs (eine Klangauswahl, sichtbar sobald mindestens ein Schalter aktiv ist).
- Bestandsdaten mit dem alten `gongEnabled`-Flag laden mit beiden Schaltern aktiviert.
