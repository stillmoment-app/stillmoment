---
id: shared-138
title: "Teilen während eines laufenden Imports: erst den laufenden Import abschließen, dann den neu geteilten Eintrag übernehmen"
status:
  ios: in-progress
  android: todo
phase: 4-Polish
priority: hoch
depends_on: [shared-132]
---

# Ticket shared-138: Teilen während eines laufenden Imports: erst den laufenden Import abschließen, dann den neu geteilten Eintrag übernehmen

**Plan**: `dev-docs/tickets/plans/shared-138-ios.md`, `dev-docs/tickets/plans/shared-138-android.md`

## Was

**Beobachtet:**
- **iOS:** Wird an Still Moment geteilt, während die App gerade einen geteilten Link lädt, übernimmt die App den neuen Eintrag nicht. Im besten Fall kommt er erst beim nächsten Öffnen der App. Hat der neue Eintrag denselben Namen wie der gerade geladene (z. B. erst `https://www.audiodharma.org/talks/25401/download`, dann während des Ladens `…/25402/download`), wird er still gelöscht, obwohl die Teilen-Ansicht „Fast geschafft“ gezeigt hat.
- **Android:** Hier gilt „der zuletzt geteilte gewinnt“ aus shared-132 auch während eines Imports. Das widerspricht der neuen Regel:
  - Wird eine Audiodatei geteilt oder per „Öffnen mit“ geöffnet, während ein geteilter Link noch lädt, öffnet sich zunächst das Bearbeiten-Blatt der Datei. Ist der Link fertig geladen, ersetzt dessen Bearbeiten-Blatt das der Datei. Die Datei, also der zuletzt geteilte Eintrag, geht verloren.
  - Wird ein Link geteilt, während ein anderer Link lädt, bricht die App das laufende Laden ab und lädt den neuen Link.
  - Wird etwas geteilt, während ein Bearbeiten-Blatt offen ist, ersetzt das neue Blatt das offene. Begonnene Eingaben gehen verloren.

**Erwartet:** Was die App begonnen hat, führt sie zu Ende. Ein währenddessen geteilter Eintrag wartet und wird danach übernommen. Das gilt auf beiden Plattformen, solange ein Import lädt und solange ein Bearbeiten-Blatt offen ist:

1. Der laufende Import läuft wie bisher weiter: Bearbeiten-Blatt, „Schon da“ oder Fehlermeldung.
2. Ist er abgeschlossen (Blatt gespeichert oder verworfen, Meldung geschlossen, oder „Abbrechen“ im Ladefenster), startet der wartende Eintrag von selbst, ohne dass die App neu geöffnet werden muss.
3. Es wartet höchstens ein Eintrag. Wird während des Wartens mehrmals geteilt, gewinnt der zuletzt geteilte, wie in shared-132.

**Umstände:** Teilen aus dem Browser, der Dateien-App oder Apple Podcasts, während Still Moment einen zuvor geteilten Link oder eine Podcast-Folge lädt oder ein Bearbeiten-Blatt zeigt. Typisch bei langen Vorträgen, langsamem Netz oder wenn jemand mehrere Vorträge hintereinander teilt.

## Warum

shared-132 hat die Regel „der zuletzt geteilte gewinnt“ für den Fall eingeführt, dass die App den ersten Eintrag noch nicht übernommen hat. Für die Zeit danach gibt es keine Regel. Auf iOS kann ein geteilter Eintrag dann still verschwinden, trotz „Fast geschafft“. Das ist genau die Art Verunsicherung, die shared-132 beseitigen sollte.

Den laufenden Import zu Ende zu führen, statt ihn abzulösen oder den neuen Eintrag abzulehnen, hat drei Vorteile: Niemand verliert begonnene Eingaben. „Fast geschafft“ in der Teilen-Ansicht bleibt wahr. Und es braucht keine zusätzliche Meldung. Die iOS-Teilen-Ansicht weiß nicht, ob die App gerade lädt, und könnte ein Ablehnen ohnehin erst später in der App melden.

---

## Akzeptanzkriterien

<!-- Gelten fuer BEIDE Plattformen. -->

- [ ] Lädt 25401 und wird währenddessen 25402 geteilt, erscheint zuerst das Bearbeiten-Blatt für 25401. Nach Speichern oder Verwerfen erscheint das Bearbeiten-Blatt für 25402.
- [ ] Lädt ein geteilter Link und wird währenddessen eine Audiodatei geteilt, erscheint zuerst das Bearbeiten-Blatt des Links, danach das der Datei. Kein Blatt ersetzt ein anderes.
- [ ] Ist ein Bearbeiten-Blatt offen (auch mit begonnenen Eingaben) und wird etwas Neues geteilt, bleibt das Blatt mit allen Eingaben stehen. Nach Speichern oder Verwerfen erscheint das Bearbeiten-Blatt des neu geteilten Eintrags.
- [ ] Endet der laufende Import mit „Schon da“ oder einer Fehlermeldung, startet der wartende Eintrag, sobald die Meldung geschlossen ist.
- [ ] „Abbrechen“ im Ladefenster beendet den laufenden Import still. Danach startet der wartende Eintrag.
- [ ] Werden während eines laufenden Imports mehrere Einträge geteilt, wird danach nur der zuletzt geteilte übernommen.
- [ ] Ein geteilter Eintrag, für den „Fast geschafft“ erschien, geht nie still verloren, auch bei gleichem Namen wie der laufende: Er wird importiert, oder es erscheint eine Meldung. Ausnahme: Er wurde von einem später geteilten Eintrag abgelöst.
- [ ] Wird derselbe Eintrag erneut geteilt, solange er lädt, sein Blatt offen ist oder seine Meldung steht, passiert nichts: kein zweiter Import, kein nachgeschobenes „Schon da“. Wird er erst danach erneut geteilt, erscheint wie bisher „Schon da“.
- [ ] Der wartende Eintrag startet, ohne dass die App verlassen und neu geöffnet werden muss.
- [ ] Erhalt: Ein einzelner geteilter Link, eine Podcast-Folge oder eine Audiodatei wird wie bisher importiert, einschließlich „Schon da“, der Fehlermeldungen und „Erneut versuchen“.
- [ ] Erhalt (Android): Ein Wechsel von Dunkelmodus oder Schriftgröße während des Ladens oder Wartens unterbricht den Import nicht und verliert den wartenden Eintrag nicht.

---

## Manueller Test

1. Netz drosseln bzw. einen langen Vortrag wählen, damit das Laden einige Sekunden dauert.
2. `https://www.audiodharma.org/talks/25401/download` an Still Moment teilen. iOS: App öffnen, damit das Laden beginnt.
3. Während des Ladens `https://www.audiodharma.org/talks/25402/download` teilen, dann zurück in die App.
4. Erwartung: Bearbeiten-Blatt für 25401. Nach dem Speichern erscheint von selbst das Blatt für 25402 („Dharmette: The Heart of Practice (1 of 5)“). Nach dem Speichern stehen beide neu in der Bibliothek.
5. Wieder einen Link teilen und während des Ladens eine MP3 aus der Dateien-App teilen.
6. Erwartung: erst das Blatt des Links, nach Verwerfen das Blatt der MP3.
7. Bei offenem Bearbeiten-Blatt einen Lehrer eintippen, dann 25402 teilen. Erwartung: Blatt mit Eingabe bleibt. Nach „Abbrechen“ erscheint das Blatt für 25402.
8. 25401 teilen, während des Ladens 25402 teilen, dann im Ladefenster „Abbrechen“. Erwartung: Keine Meldung, danach lädt 25402.
9. 25401 teilen, während des Ladens erst 25402, dann eine MP3 teilen. Erwartung: Nach 25401 erscheint nur das Blatt der MP3.

---

## Nicht Teil dieses Tickets

- Eine Warteschlange, die mehrere geteilte Einträge nacheinander importiert. Es wartet höchstens ein Eintrag, unter den wartenden gewinnt der zuletzt geteilte.
- Eine Anzeige in der Teilen-Ansicht, dass die App gerade lädt.

---

## Hinweise

- **Offenes Bearbeiten-Blatt hat Vorrang (Entscheidung des Users):** Wer schon Angaben eintippt, soll nichts verlieren. Dieselbe Regel gilt jetzt auch für einen laufenden Import: Begonnenes wird zu Ende geführt.
- **Jedes Bearbeiten-Blatt zählt**, auch das einer vorhandenen Meditation. „Öffnen mit“ / „Öffnen in“ zählt wie Teilen.
- **Verworfene Alternativen:** Den laufenden Import abzulösen, verwirft womöglich Gewolltes. Den neuen Eintrag abzulehnen, ginge auf iOS nur mit einer Meldung, die erst nach „Fast geschafft“ erscheint, denn die Teilen-Ansicht weiß nicht, ob die App gerade lädt.
- **iOS:** Der wartende Eintrag liegt bereits heute in der Ablage der Teilen-Ansicht; die App schaut aber erst beim nächsten Aktivwerden wieder nach. Der stille Verlust entsteht, weil der abgearbeitete Eintrag erst am Ende des Imports über seinen Namen entfernt wird. Ein gleichnamiger neuer Eintrag hat ihn bis dahin ersetzt und wird mitgelöscht.
- Testpaar 25401 (`audio/mp3`) und 25402 (`binary/octet-stream`): gleiches Adress-Ende „download“, verschiedene Meditationen. Gerade der gleiche Name löst auf iOS den stillen Verlust aus.
- **Android:** Das Ablösen eines laufenden Imports und eines offenen Blatts ist dort bewusst gebaut (shared-132) und muss umgedreht werden. Die bestehenden Tests dazu prüfen das alte Verhalten. Ein zurückgestellter und dann von einem neueren Eintrag abgelöster Download darf nicht auf dem Gerät liegen bleiben (wie android-087).
- Android: Teilen und „Öffnen mit“ zählen gleich.
