# Ticket shared-123: Bibliothek beim Geraetewechsel — Backup-Verhalten klaeren

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Komplexitaet**: Der Backup-Ausschluss regenerierbarer Daten ist klein. Das Risiko liegt im zweiten Teil: Der Fehlerfall entsteht erst bei einer echten Wiederherstellung auf einem zweiten Geraet und laesst sich nicht im Simulator nachstellen. Verifikation braucht zwei physische Geraete oder einen echten Backup-Restore-Durchlauf pro Plattform.
**Phase**: 3-Feature

---

## Was

Beim Wechsel auf ein neues Geraet soll nachvollziehbar sein, was mit der eigenen Bibliothek passiert. Zwei Dinge gehoeren dazu: Daten, die die App jederzeit neu berechnen kann, sollen das Backup des Nutzers nicht belasten. Und wenn nach einer Wiederherstellung Meditationen ohne ihre Audiodatei ankommen, muss die App das verstaendlich erklaeren statt eine stille kaputte Liste zu zeigen.

## Warum

Die Bibliothek ist das Kernfeature — eine ueber Monate aufgebaute Sammlung ist das Wertvollste, was ein Nutzer in dieser App hat. Aktuell ist ungeklaert, was beim Geraetewechsel davon ankommt, und das Verhalten unterscheidet sich zwischen den Plattformen.

Der wahrscheinliche Fehlerfall ist besonders unschoen: Die Verwaltungsdaten der Bibliothek sind klein und werden mitgesichert, die Audiodateien selbst sind gross und bleiben je nach Uebertragungsweg zurueck. Das Ergebnis ist eine Bibliothek, die vollstaendig aussieht, in der aber kein Antippen zu einer Meditation fuehrt. Wer sein neues Handy einrichtet und das erlebt, haelt seine Sammlung fuer verloren — ohne zu erfahren, ob und wie sie zurueckzuholen ist.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Regenerierbare Daten (die vorberechneten Wellenformen) sind vom Geraete-Backup ausgenommen und belasten den Speicherplatz des Nutzers nicht
- [ ] Nach einer Wiederherstellung ohne diese Daten baut die App sie selbsttaetig neu auf; der Nutzer merkt davon nichts ausser einer kurzen Ladezeit beim ersten Oeffnen
- [ ] Eine Meditation, deren Audiodatei nach der Wiederherstellung fehlt, ist in der Bibliothek als nicht abspielbar erkennbar — ohne dass man sie erst antippen muss
- [ ] Antippen einer solchen Meditation fuehrt weder zum Absturz noch zu einem endlosen Ladezustand, sondern zu einer Erklaerung in nicht-technischer Sprache
- [ ] Die Erklaerung sagt, was zu tun ist: die Datei erneut importieren oder den Eintrag entfernen
- [ ] Betroffene Eintraege lassen sich einzeln entfernen
- [ ] Ein erneuter Import derselben Aufnahme stellt den Eintrag samt seiner Einstellungen (Wiedergabe-Bereich, Gongs) wieder her, statt ein Duplikat anzulegen
- [ ] Sind alle Meditationen betroffen, erklaert die Bibliothek die Lage einmal zusammenhaengend statt sie pro Zeile zu wiederholen
- [ ] Ist die Bibliothek unversehrt wiederhergestellt, erscheint kein Hinweis
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS fuer den Zustand "Eintrag ohne Audiodatei" — Erkennung, Entfernen, Wiederherstellung durch erneuten Import
- [ ] Unit Tests Android fuer dieselben Faelle

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (falls fuer den Zustand ein neuer Begriff eingefuehrt wird)

---

## Manueller Test

1. Auf Geraet A mehrere Meditationen importieren, bei einer davon Wiedergabe-Bereich und Gongs anpassen
2. Ein vollstaendiges Geraete-Backup anlegen
3. Die App auf Geraet B aus diesem Backup wiederherstellen
4. Bibliothek oeffnen
5. Erwartung: Entweder sind alle Meditationen samt Audio da und es erscheint kein Hinweis — oder die betroffenen Eintraege sind sofort als nicht abspielbar erkennbar und die App erklaert verstaendlich, wie man sie zurueckholt. Kein Absturz, kein Endlos-Laden, keine Liste die vollstaendig aussieht aber nirgends hinfuehrt
6. Eine betroffene Aufnahme erneut importieren — Erwartung: der alte Eintrag lebt mit seinen Einstellungen wieder auf, es entsteht kein zweiter
7. Identisch auf iOS und Android durchspielen

---

## Hinweise

- Die beiden Uebertragungswege verhalten sich unterschiedlich: Der direkte Geraet-zu-Geraet-Transfer kennt keine Groessenbegrenzung, das Cloud-Backup auf Android ist pro App auf 25 MB begrenzt. Eine MP3-Sammlung ueberschreitet das praktisch immer. Genau daraus entsteht der Fall "Verwaltungsdaten da, Audio fehlt". Auf iOS gibt es keine harte Grenze, dort geht die Sammlung stattdessen auf die iCloud-Quota des Nutzers.
- Es geht ausschliesslich um die Backup- und Transfer-Mechanismen der Betriebssysteme und darum, was der Nutzer davon zu sehen bekommt. Eine eigene Cloud-Sync-Loesung ist keine Option — keine Server, keine Konten. Das ist nicht verhandelbar.
- Der Fall tritt nicht nur beim Geraetewechsel auf: Auch wenn iOS Audiodateien aus dem Speicher entfernt oder ein Nutzer die App-Daten teilweise loescht, entsteht derselbe Zustand. Die Loesung sollte den Zustand behandeln, nicht seine Ursache.
- Aufgefallen beim Sichten der Backup-Konfiguration, nicht durch eine Nutzermeldung. Die Google-Play-Anforderung zur Geraetemigration (Zero-Tap-Credential-Restore, ab April 2027) betrifft die App nicht — sie hat keine Konten und keine Zugangsdaten. Dieses Ticket ist davon unabhaengig.

---

## Referenz

- iOS: `ios/StillMoment/Infrastructure/Services/`
- Android: `android/app/src/main/kotlin/com/stillmoment/data/repositories/`
