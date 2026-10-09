---
id: shared-133
title: "Anleitung \"So importierst du aus Apple Podcasts\""
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: mittel
depends_on: [shared-128]
---

# Ticket shared-133: Anleitung "So importierst du aus Apple Podcasts"

## Was

"Wo finde ich Meditationen?" bekommt neben den Anleitungen für Browser und Dateien eine dritte: "So importierst du aus Apple Podcasts". Sie zeigt in drei Schritten, wie man eine einzelne Folge aus Apple Podcasts per Teilen in die Bibliothek übernimmt. Ausgangspunkt ist auf beiden Plattformen podcasts.apple.com: Auf iOS öffnet sich dann die App Apple Podcasts, auf Android die Website im Browser.

## Warum

Der Podcast-Import (shared-128) funktioniert auf beiden Plattformen, beginnt aber außerhalb von Still Moment, im Teilen-Menü einer anderen App. Ohne Hinweis entdeckt ihn kaum jemand. Auf Android ahnt man ohne Anleitung erst recht nicht, dass Apple Podcasts überhaupt eine Quelle ist. Die Anleitung macht Podcasts als Quelle für die Bibliothek sichtbar.

---

## Akzeptanzkriterien

- [ ] "Wo finde ich Meditationen?" zeigt einen dritten Kasten "So importierst du aus Apple Podcasts", unter den Kästen für Browser und Dateien, gestaltet und vorgelesen wie diese (Symbol, Titel, kurze Pfeilzeile)
- [ ] Antippen öffnet eine Anleitung mit Einleitung und genau drei Schritten, aufgebaut wie die Anleitungen für Browser und Dateien
- [ ] Die Schritte folgen auf beiden Plattformen demselben Weg: Apple Podcasts über podcasts.apple.com öffnen und eine Folge suchen → Folge teilen und Still Moment wählen → in Still Moment Titel, Lehrer:in und Typ im Bearbeiten-Blatt prüfen
- [ ] Die Schritte entsprechen auf jeder Plattform dem tatsächlichen Ablauf auf einem echten Gerät. Plattformeigene Zwischenschritte stehen nur dort, wo es sie gibt (z.B. auf iOS die Bestätigung mit "OK" und das anschließende Öffnen von Still Moment)
- [ ] Die Anleitung sagt, dass nur einzelne Folgen übernommen werden können, keine ganzen Podcasts
- [ ] Der Einleitungstext von "Wo finde ich Meditationen?" passt auch zu Podcasts (spricht nicht mehr nur von "Seiten zum Download")
- [ ] Ton und Sprache wie in den bestehenden Anleitungen: du-Form, ruhig, keine technischen Begriffe
- [ ] Die Anleitungen für Browser und Dateien und die Quellenliste bleiben unverändert erreichbar und inhaltlich gleich
- [ ] Die Marketing-Screenshots von "Wo finde ich Meditationen?" sind neu aufgenommen und zeigen alle drei Kästen

---

## Manueller Test

1. Bibliothek → "Wo finde ich Meditationen?" öffnen
2. Erwartung: drei Kästen (Browser, Dateien, Apple Podcasts), darunter die Quellenliste
3. Kasten "Apple Podcasts" antippen, die drei Schritte auf einem echten Gerät mit einer aktuellen Folge nachspielen (z.B. "Achtsam", Deutschlandfunk Nova), beginnend bei podcasts.apple.com
4. Erwartung: Auf iOS öffnet sich die App Apple Podcasts, auf Android die Website. Jeder Schritt stimmt mit dem, was Apple Podcasts und Still Moment zeigen; die Folge landet im Bearbeiten-Blatt und nach dem Speichern in der Bibliothek
5. Mit VoiceOver bzw. TalkBack den neuen Kasten ansteuern
6. Erwartung: wird wie die anderen Kästen als ein Button mit Titel und Pfeilzeile vorgelesen

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| podcasts.apple.com öffnet | die App Apple Podcasts | die Website im Browser (die App gibt es auf Android nicht) |
| Zwischenschritte nach dem Teilen | Bestätigung mit "OK", dann Still Moment selbst öffnen | so, wie das Gerät es zeigt |
| Kasten, Titel, Einleitungstext, Weg der Schritte, Hinweis "nur einzelne Folgen" | gleich | gleich |

---

## Nicht Teil dieses Tickets

- Podcast-Einträge in der Quellenliste (eigene Kuratierungsaufgabe, siehe `dev-docs/concepts/podcast-import.md`)
- Anleitungen für andere Podcast-Apps (z.B. AntennaPod)

---

## Hinweise

- Entscheidung: Das Ticket kann vor shared-129 umgesetzt werden. Die Anleitung erwähnt **nicht**, dass ältere Folgen (außerhalb der etwa 200 neuesten) bis dahin mit "Diese Folge kann leider nicht übernommen werden" scheitern, damit der Text mit shared-129 nicht veraltet.
- Drei Schritte wie bei den bestehenden Anleitungen. Der Hinweis "nur einzelne Folgen" ist daher kein vierter Schritt.
- Belegt ist nur, dass Still Moment auf iOS im Teilen-Menü einer Folge in Apple Podcasts erscheint (shared-128, Prüfung vom 2026-10-09). Wie man in Apple Podcasts zum Teilen kommt, ist nicht dokumentiert. Auf Android ist das Teilen von der Website noch gar nicht am Gerät geprüft (shared-128 hat dort mit einem per Messenger geteilten Link getestet) — u.a. ob der Browser beim Teilen den Folgenlink (mit `?i=<Folgen-ID>`) übergibt und nicht nur den Link zum ganzen Podcast. Beides muss am Gerät nachvollzogen werden, bevor die Texte stehen.
- Bereits vorhandene Meldung beim Teilen eines ganzen Podcasts: "Bitte eine einzelne Folge teilen". Der Wortlaut der Anleitung sollte dazu passen.
- Ersetzt ios-053 (nur iOS), weil der Podcast-Import auf beiden Plattformen funktioniert.
- Recherche und Entscheidungen zum Podcast-Import: `dev-docs/concepts/podcast-import.md`
