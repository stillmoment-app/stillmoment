---
id: shared-138
title: "Teilen während eines laufenden Imports: der zuletzt geteilte Eintrag gewinnt, nichts geht still verloren"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: hoch
depends_on: [shared-132]
---

# Ticket shared-138: Teilen während eines laufenden Imports: der zuletzt geteilte Eintrag gewinnt, nichts geht still verloren

## Was

**Beobachtet:**
- **iOS:** Wird an Still Moment geteilt, während die App gerade einen geteilten Link lädt, übernimmt die App den neuen Eintrag nicht. Im besten Fall kommt er erst beim nächsten Öffnen der App. Hat der neue Eintrag denselben Namen wie der gerade geladene (z. B. erst `https://www.audiodharma.org/talks/25401/download`, dann während des Ladens `…/25402/download`), wird er still gelöscht, obwohl die Teilen-Ansicht „Fast geschafft“ gezeigt hat.
- **Android:** Wird eine Audiodatei geteilt oder per „Öffnen mit“ geöffnet, während ein geteilter Link noch lädt, öffnet sich zunächst das Bearbeiten-Blatt der Datei. Ist der Link fertig geladen, ersetzt dessen Bearbeiten-Blatt das der Datei. Die Datei, also der zuletzt geteilte Eintrag, geht verloren.

**Erwartet:** Es gilt auf beiden Plattformen die Regel aus shared-132 auch während eines laufenden Imports: Der zuletzt geteilte Eintrag wird importiert, ein noch ladender früherer Import endet still ohne Meldung. Ist bereits ein Bearbeiten-Blatt offen, bleibt es unangetastet. Der neue Eintrag wird übernommen, sobald das Blatt gespeichert oder verworfen ist.

**Umstände:** Teilen aus dem Browser, der Dateien-App oder Apple Podcasts, während Still Moment einen zuvor geteilten Link oder eine Podcast-Folge lädt. Typisch bei langen Vorträgen oder langsamem Netz.

## Warum

shared-132 hat die Regel „der zuletzt geteilte gewinnt“ für den Fall eingeführt, dass die App den ersten Eintrag noch nicht übernommen hat. Während eines laufenden Imports gilt sie noch nicht. Auf iOS kann ein geteilter Eintrag dann sogar still verschwinden, trotz Erfolgsmeldung. Das ist genau die Art Verunsicherung, die shared-132 beseitigen sollte.

---

## Akzeptanzkriterien

<!-- Gelten fuer BEIDE Plattformen. -->

- [ ] Lädt 25401 und wird währenddessen 25402 geteilt, erscheint das Bearbeiten-Blatt für 25402. 25401 wird nicht importiert, es erscheint keine Meldung zu 25401.
- [ ] Lädt ein geteilter Link und wird währenddessen eine Audiodatei geteilt, erscheint das Bearbeiten-Blatt der Datei und bleibt stehen. Der Link wird nicht importiert.
- [ ] Ein geteilter Eintrag, für den „Fast geschafft“ erschien, geht nie still verloren: Er wird importiert, oder es erscheint eine Meldung.
- [ ] Ist ein Bearbeiten-Blatt offen (auch mit begonnenen Eingaben) und wird etwas Neues geteilt, bleibt das Blatt mit allen Eingaben stehen. Nach Speichern oder Verwerfen erscheint das Bearbeiten-Blatt des neu geteilten Eintrags.
- [ ] Erhalt: Ein einzelner geteilter Link, eine Podcast-Folge oder eine Audiodatei wird wie bisher importiert, einschließlich „Schon da“, der Fehlermeldungen und „Erneut versuchen“.
- [ ] Erhalt: „Abbrechen“ im Ladefenster beendet den Import still, auch nach einem Ablösen.
- [ ] Erhalt (Android): Ein Wechsel von Dunkelmodus oder Schriftgröße während des Ladens unterbricht den Import nicht.

---

## Manueller Test

1. Netz drosseln bzw. einen langen Vortrag wählen, damit das Laden einige Sekunden dauert.
2. `https://www.audiodharma.org/talks/25401/download` an Still Moment teilen. iOS: App öffnen, damit das Laden beginnt.
3. Während des Ladens `https://www.audiodharma.org/talks/25402/download` teilen, dann zurück in die App.
4. Erwartung: Bearbeiten-Blatt für 25402 („Dharmette: The Heart of Practice (1 of 5)“), keine Meldung zu 25401. Nach dem Speichern steht nur 25402 neu in der Bibliothek.
5. Wieder 25401 teilen und während des Ladens eine MP3 aus der Dateien-App teilen.
6. Erwartung: Bearbeiten-Blatt der MP3 bleibt stehen, 25401 wird nicht importiert.
7. Bei offenem Bearbeiten-Blatt einen Lehrer eintippen, dann 25402 teilen. Erwartung: Blatt mit Eingabe bleibt. Nach „Abbrechen“ erscheint das Blatt für 25402.

---

## Nicht Teil dieses Tickets

- Eine Warteschlange, die mehrere geteilte Einträge nacheinander importiert. Wie in shared-132 gewinnt der zuletzt geteilte.

---

## Hinweise

- **Offenes Bearbeiten-Blatt hat Vorrang (Entscheidung des Users):** Wer schon Angaben eintippt, soll nichts verlieren. „Der zuletzt geteilte gewinnt“ gilt nur, solange noch kein Blatt offen ist.
- Testpaar 25401 (`audio/mp3`) und 25402 (`binary/octet-stream`): gleiches Adress-Ende „download“, verschiedene Meditationen. Gerade der gleiche Name löst auf iOS den stillen Verlust aus.
- Android: Teilen und „Öffnen mit“ zählen gleich.
