# Ticket android-083: Fuenf Composables folgen dem Geraet statt der App-Darstellung

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Komplexitaet**: Klein und ueberschaubar — fuenf Stellen, ein einheitlicher Mechanismus. Die einzige Falle ist, dabei versehentlich auch die eine Stelle mitzuaendern, die das Geraete-Flag zu Recht liest (siehe Hinweise).
**Abhaengigkeiten**: shared-122 (abgeschlossen — hat die Abweichung vom Randfall zum Normalfall gemacht)
**Phase**: 4-Polish

---

## Was

Fuenf Stellen der Android-App bestimmen ihre Farben danach, ob das *Geraet* auf dunkel steht — nicht danach, welche Darstellung die *App* gerade zeigt. Sie sollen der App-Darstellung folgen wie alles andere auch.

Betroffen sind der Mond auf dem laufenden Timer, die Gluehscheibe in der Mitte des Player-Rings, die Suchleiste der Bibliothek sowie zwei Elemente der Bibliotheksliste.

## Warum

Wer die App dunkel benutzt und sein Geraet hell eingestellt hat, sieht an diesen fuenf Stellen helle Farben auf dunklem Grund. Seit die dunkle Darstellung der Standard ist, ist das der Normalfall statt einer Ausnahme: Nach einer Neuinstallation auf einem hell eingestellten Geraet trifft es jeden.

Auf iPhone tritt das nicht auf — dort folgt jede Stelle der App-Darstellung. Die App sieht in derselben Einstellung auf Android also stellenweise anders aus als auf iPhone, und das soll sie nicht.

---

## Akzeptanzkriterien

### Feature
- [ ] Bei App-Darstellung „Dunkel" auf einem hell eingestellten Geraet: der Mond auf dem laufenden Timer zeigt seine dunklen Farben
- [ ] Bei App-Darstellung „Dunkel" auf einem hell eingestellten Geraet: die Gluehscheibe hinter dem Pause-Knopf im Player zeigt ihre dunkle Variante
- [ ] Bei App-Darstellung „Dunkel" auf einem hell eingestellten Geraet: die angetippte Suchleiste der Bibliothek zeigt ihren dunklen Rahmen
- [ ] Umgekehrt genauso: bei App-Darstellung „Hell" auf einem dunkel eingestellten Geraet zeigen alle fuenf Stellen ihre helle Variante
- [ ] Bei App-Darstellung „System" bleibt alles wie bisher — die App folgt dem Geraet, und diese fuenf Stellen tun es mit
- [ ] Ein Wechsel der Darstellung in den Einstellungen wirkt an diesen Stellen sofort, ohne App-Neustart
- [ ] Die Farben selbst aendern sich nicht — es wird nur die richtige der beiden bestehenden Paletten gewaehlt
- [ ] Auf iPhone aendert sich nichts

### Tests
- [ ] Ein Test belegt, dass diese Stellen der App-Darstellung folgen und nicht der Geraeteeinstellung — inklusive des Falls, in dem beide auseinanderliegen
- [ ] Die Compose-Vorschauen dieser fuenf Bausteine zeigen weiterhin beide Darstellungen korrekt

### Dokumentation
- [ ] Kein CHANGELOG-Eintrag noetig, solange nur die falsche Farbquelle korrigiert wird — der Unterschied ist zu klein, um ihn Nutzern anzukuendigen

---

## Manueller Test

1. Geraet auf helle Darstellung stellen, in der App „Dunkel" waehlen
2. Timer auf 1 Minute stellen und starten
3. Erwartung: Der Mond passt farblich zum dunklen Hintergrund, nicht heller als seine Umgebung
4. Eine gefuehrte Meditation starten und den Player betrachten
5. Erwartung: Die Gluehscheibe in der Ringmitte wirkt warm und dunkel, nicht wie ein heller Fleck
6. In die Bibliothek wechseln und die Suchleiste antippen
7. Erwartung: Der Rahmen der fokussierten Suchleiste passt zur dunklen Darstellung
8. Ohne die App zu verlassen in den Einstellungen auf „Hell" und zurueck auf „Dunkel" wechseln
9. Erwartung: Die drei Stellen wechseln sofort mit
10. Geraet auf dunkle Darstellung stellen, in der App „Hell" waehlen, Schritte 2 bis 7 wiederholen
11. Erwartung: Alle drei Stellen zeigen ihre helle Variante

---

## Referenz

- shared-122 — Dunkel als Standard; die Abschlussnotiz dort beschreibt den Fund
- shared-032 / shared-033 — Theme-Architektur und Paletten, in deren Vokabular diese Stellen gehoeren
- shared-094 — Karten-Lift in hell vs. Rahmen-Strategie in dunkel; Ursprung der drei Schatten-Aufrufe
- Android, die fuenf Stellen:
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/components/MoonPhase.kt:65`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/components/PlayerCenterDisc.kt:41`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/LibrarySearchBar.kt:70`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt:83`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/LibraryActionPill.kt:44`
- Android, ausdruecklich **nicht** anfassen: `android/app/src/main/kotlin/com/stillmoment/MainActivity.kt:93`
- iOS als Vorbild: `ios/StillMoment/Presentation/Views/Timer/Components/MoonPhaseView.swift`, `ios/StillMoment/Presentation/Views/GuidedMeditations/LibraryActionPill.swift`

---

## Hinweise

**`MainActivity.kt:93` ist korrekt und bleibt.** Dort wird die Geraeteeinstellung abgefragt, um die Auswahl „System" ueberhaupt erst in hell oder dunkel aufzuloesen. Das ist die eine Stelle, an der die Geraeteeinstellung die richtige Quelle ist. Wer sie „mitrepariert", zerstoert die Option „System". Bitte diesen Hinweis nicht wegkuerzen — er ist der Grund, warum das Ticket Dateien und Zeilen nennt.

**Zwei der fuenf Stellen sind heute schon folgenlos.** In `MeditationListItem` und `LibraryActionPill` speist das Flag nur den Karten-Schatten, und der ist in der dunklen Darstellung ohnehin abgeschaltet (der Schatten-Modifier prueft zusaetzlich, ob eine Schattenfarbe gesetzt ist, und in dunkel ist sie transparent). Sie lesen trotzdem die falsche Quelle und sollen mitwandern, damit im Code kein Muster stehen bleibt, das jemand als Vorbild kopiert. `LibrarySearchBar` nutzt das Flag doppelt — fuer den folgenlosen Schatten *und* fuer den Fokus-Rahmen, der sehr wohl sichtbar ist.

**Auswirkung ehrlich eingeordnet:** subtile Unterschiede in Deckkraft und Farbwaerme. Kein gebrochenes Layout, kein unlesbarer Text, keine unbedienbare Stelle. Das ist Feinschliff, nicht Schmerz — deshalb NIEDRIG und 4-Polish. Wer dieses Ticket anfasst, soll es klein halten.

**Loesungsrichtung, nicht Vorschrift:** Der richtige Boolean liegt bereits an einer Stelle vor — die Theme-Funktion bekommt ihn als Parameter herein und stellt daneben schon die Farbtabelle der App fuer alle Composables bereit. Es liegt nahe, ihn auf demselben Weg mitzugeben und die fuenf Stellen darauf umzustellen, statt an jeder einzelnen etwas Eigenes zu bauen. Ob das die einfachste Loesung ist, gehoert vor der Umsetzung geprueft.

**Kein Anlass fuer eine Theme-Umbaurunde.** Nur diese fuenf Stellen, nur die Farbquelle. Kein Nachziehen von Paletten, keine neuen Farbrollen, keine Angleichung an iOS ueber die Farbquelle hinaus.
