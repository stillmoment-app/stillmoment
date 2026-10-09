---
id: shared-135
title: "Eigener Abschnitt Rückmeldung in den Einstellungen"
status:
  ios: done
  android: done
phase: 4-Polish
priority: niedrig
depends_on: [shared-134]
---

# Ticket shared-135: Eigener Abschnitt Rückmeldung in den Einstellungen

## Was

„App bewerten“ und „Schreib uns“ (seit shared-134 im Abschnitt „Info & Rechtliches“) bekommen in den Einstellungen einen eigenen Abschnitt **„Rückmeldung“** (EN: „Feedback“). Er steht zwischen „Geführte Meditationen“ und „Info & Rechtliches“. Beide Einträge haben einen Untertitel:

| Eintrag DE | Untertitel DE | Eintrag EN | Untertitel EN |
|---|---|---|---|
| App bewerten | Damit andere Still Moment finden | Rate the App | So others can find Still Moment |
| Schreib uns | Ideen, Wünsche oder einfach ein Gruß | Write to Us | Ideas, wishes, or just a hello |

„Info & Rechtliches“ enthält danach nur noch Klang-Nachweise, Datenschutz und Version.

## Warum

„Schreib uns“ wirkt unter der Überschrift „Info & Rechtliches“ fehl am Platz: Eine Einladung zu schreiben steht dort zwischen Datenschutz und Versionsnummer. Außerdem hat dort sonst kein Eintrag einen Untertitel. Mit eigener Überschrift sind die beiden Einträge leichter zu finden, und „Info & Rechtliches“ enthält wieder nur, was die Überschrift verspricht.

Ziel der beiden Einträge: Bewertungen in den Stores, Nachrichten mit Ideen und Wünschen und einfache Grüße, die zeigen, dass die App Menschen erreicht.

---

## Akzeptanzkriterien

- [ ] Die Einstellungen zeigen die Abschnitte in dieser Reihenfolge: Erscheinungsbild, Geführte Meditationen, Rückmeldung, Info & Rechtliches
- [ ] Der Abschnitt „Rückmeldung“ (EN „Feedback“) enthält „App bewerten“ und dann „Schreib uns“, jeweils mit Titel und Untertitel aus der Tabelle oben, auf Deutsch und Englisch
- [ ] Der bisherige Untertitel „Hallo sagen, danke sagen, Feedback geben“ erscheint nirgends mehr
- [ ] „Info & Rechtliches“ enthält genau Klang-Nachweise, Datenschutz und Version, in dieser Reihenfolge
- [ ] Screenreader lesen bei beiden Einträgen Titel und Untertitel vor; die Hinweise, dass die App verlassen wird, bleiben erhalten
- [ ] „App bewerten“ und „Schreib uns“ verhalten sich weiterhin wie in shared-134: Store-Seite, neue Mail, und ohne Mail-Programm der Dialog mit „Adresse kopieren“

---

## Manueller Test

1. Einstellungen öffnen
2. Abschnitte von oben nach unten prüfen: Erscheinungsbild, Geführte Meditationen, Rückmeldung, Info & Rechtliches
3. Unter „Rückmeldung“: „App bewerten“ mit „Damit andere Still Moment finden“, „Schreib uns“ mit „Ideen, Wünsche oder einfach ein Gruß“
4. Beide Einträge antippen → Store-Seite bzw. Mail (im Simulator/Emulator ohne Mail-Programm: Dialog mit Adresse)
5. Sprache auf Englisch → Überschrift „Feedback“, „So others can find Still Moment“, „Ideas, wishes, or just a hello“
6. Erwartung: auf beiden Plattformen identisch

---

## Nicht Teil dieses Tickets

- Ein eigener Unterbildschirm für Rückmeldung (für zwei Einträge ein zusätzlicher Tipp ohne Gewinn)
- Untertitel für die Einträge in „Info & Rechtliches“
- Automatische Bewertungsanfrage (bleibt ausgeschlossen, siehe shared-134)

---

## Hinweise

- **Wortlaut ist abgestimmt, bitte nicht umformulieren:**
  - „Damit andere Still Moment finden“ nennt einen Grund für die Bewertung, ohne zu drängen.
  - „Ideen, Wünsche oder einfach ein Gruß“ lädt zu Rückmeldung ein, ohne einen Anlass vorauszusetzen. „Gruß“ ist bewusst gewählt (niedrige Hürde) statt „Danke“. Ohne „nur“, damit der Gruß nicht kleiner wirkt als eine Idee.
  - Das Wort „Feedback“ steht nur in der englischen Überschrift, nicht zusätzlich in einem Untertitel, damit es sich nicht doppelt.
- Die Überschrift „Rückmeldung“ entspricht dem Glossar-Begriff (Rückmeldung, `FeedbackLinks`). Den Glossar-Eintrag an den neuen Ort in den Einstellungen anpassen.
- Untertitel wie bei „Vorbereitungszeit“ im Abschnitt „Geführte Meditationen“ (dasselbe Muster gibt es schon).
