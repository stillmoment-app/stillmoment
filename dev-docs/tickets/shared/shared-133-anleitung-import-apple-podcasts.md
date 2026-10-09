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

**Plan iOS**: `dev-docs/tickets/plans/shared-133-ios.md`
**Plan Android**: `dev-docs/tickets/plans/shared-133-android.md`

## Was

"Wo finde ich Meditationen?" bekommt neben den Anleitungen für Browser und Dateien eine dritte: "So importierst du aus Apple Podcasts". Sie zeigt in drei Schritten, wie man eine einzelne Folge aus Apple Podcasts per Teilen in die Bibliothek übernimmt. Ausgangspunkt ist auf iOS die vorinstallierte App Podcasts, auf Android podcasts.apple.com im Browser (die App gibt es dort nicht).

## Warum

Der Podcast-Import (shared-128) funktioniert auf beiden Plattformen, beginnt aber außerhalb von Still Moment, im Teilen-Menü einer anderen App. Ohne Hinweis entdeckt ihn kaum jemand. Auf Android ahnt man ohne Anleitung erst recht nicht, dass Apple Podcasts überhaupt eine Quelle ist. Die Anleitung macht Podcasts als Quelle für die Bibliothek sichtbar.

---

## Akzeptanzkriterien

- [ ] "Wo finde ich Meditationen?" zeigt einen dritten Kasten "So importierst du aus Apple Podcasts", unter den Kästen für Browser und Dateien, gestaltet und vorgelesen wie diese (Symbol, Titel, kurze Pfeilzeile)
- [ ] Antippen öffnet eine Anleitung mit Einleitung und genau drei Schritten, aufgebaut wie die Anleitungen für Browser und Dateien
- [ ] Die Schritte folgen auf beiden Plattformen demselben Weg: Apple Podcasts öffnen und eine Folge suchen → Folge teilen und Still Moment wählen → in Still Moment die Angaben im Bearbeiten-Blatt bei Bedarf anpassen. Auf iOS beginnt Schritt 1 in der App Podcasts, auf Android bei podcasts.apple.com im Browser
- [ ] Die Schritte entsprechen auf jeder Plattform dem tatsächlichen Ablauf auf einem echten Gerät. Plattformeigene Zwischenschritte stehen nur dort, wo es sie gibt (z.B. auf iOS die Bestätigung "Fast geschafft" mit "Fertig" und das anschließende Öffnen von Still Moment)
- [ ] Die Anleitung sagt, dass nur einzelne Folgen übernommen werden können, keine ganzen Podcasts
- [ ] Der Einleitungstext von "Wo finde ich Meditationen?" passt auch zu Podcasts (spricht nicht mehr nur von "Seiten zum Download")
- [ ] Ton und Sprache wie in den bestehenden Anleitungen: du-Form, ruhig, keine technischen Begriffe
- [ ] Die Anleitungen für Browser und Dateien stimmen wieder mit dem Gerät überein: Kein „OK“ mehr nach dem Teilen (iOS: „Fertig“ in der Bestätigung „Fast geschafft“; Android: keine Bestätigung, Still Moment öffnet sich von selbst) und kein „Typ“ mehr in Schritt 3 (eine Typ-Auswahl gibt es nicht mehr)
- [ ] Die Anleitungen für Browser und Dateien und die Quellenliste bleiben unverändert erreichbar; die Quellenliste bleibt inhaltlich gleich
- [ ] Die Marketing-Screenshots von "Wo finde ich Meditationen?" sind neu aufgenommen und zeigen alle drei Kästen

---

## Manueller Test

1. Bibliothek → "Wo finde ich Meditationen?" öffnen
2. Erwartung: drei Kästen (Browser, Dateien, Apple Podcasts), darunter die Quellenliste
3. Kasten "Apple Podcasts" antippen, die drei Schritte auf einem echten Gerät mit einer aktuellen Folge nachspielen (z.B. "Achtsam", Deutschlandfunk Nova), auf iOS beginnend in der App Podcasts, auf Android bei podcasts.apple.com
4. Erwartung: Jeder Schritt stimmt mit dem, was Apple Podcasts und Still Moment zeigen; die Folge landet im Bearbeiten-Blatt und nach dem Speichern in der Bibliothek
5. Mit VoiceOver bzw. TalkBack den neuen Kasten ansteuern
6. Erwartung: wird wie die anderen Kästen als ein Button mit Titel und Pfeilzeile vorgelesen

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Ausgangspunkt Schritt 1 | die App Podcasts (vorinstalliert) | podcasts.apple.com im Browser (die App gibt es auf Android nicht) |
| Zwischenschritte nach dem Teilen | Bestätigung "Fast geschafft" mit "Fertig" (seit ios-059), dann Still Moment selbst öffnen | keine: Still Moment öffnet sich von selbst mit dem Bearbeiten-Blatt |
| Kasten, Titel, Einleitungstext, Weg der Schritte, Hinweis "nur einzelne Folgen" | gleich | gleich |

---

## Nicht Teil dieses Tickets

- Podcast-Einträge in der Quellenliste (eigene Kuratierungsaufgabe, siehe `dev-docs/concepts/podcast-import.md`)
- Anleitungen für andere Podcast-Apps (z.B. AntennaPod)

---

## Hinweise

- Entscheidung: Das Ticket kann vor shared-129 umgesetzt werden. Die Anleitung erwähnt **nicht**, dass ältere Folgen (außerhalb der etwa 200 neuesten) bis dahin mit "Diese Folge kann leider nicht übernommen werden" scheitern, damit der Text mit shared-129 nicht veraltet.
- Drei Schritte wie bei den bestehenden Anleitungen. Der Hinweis "nur einzelne Folgen" ist daher kein vierter Schritt.
- Belegt ist nur, dass Still Moment auf iOS im Teilen-Menü einer Folge in Apple Podcasts erscheint (shared-128, Prüfung vom 2026-10-09). Auf iOS ist das Teilen-Symbol auf der Seite der Folge direkt sichtbar, ohne "•••" (am Gerät geprüft, 2026-10-09). Auf Android sieht podcasts.apple.com aus wie die App, das Teilen-Symbol sitzt ebenfalls auf der Seite der Folge (am Gerät geprüft, 2026-10-09). Chrome übergibt beim Teilen den Folgenlink mit `?i=<Folgen-ID>`, Still Moment öffnet sich danach von selbst und zeigt direkt das Bearbeiten-Blatt, ohne Bestätigung dazwischen (Emulator, Chrome, 2026-10-09).
- Bereits vorhandene Meldung beim Teilen eines ganzen Podcasts: "Bitte eine einzelne Folge teilen". Der Wortlaut der Anleitung sollte dazu passen.
- Ersetzt ios-053 (nur iOS), weil der Podcast-Import auf beiden Plattformen funktioniert.
- Recherche und Entscheidungen zum Podcast-Import: `dev-docs/concepts/podcast-import.md`
- Design-Entwurf (Claude Design, Projekt "Still Moment"): `prototypen/import-anleitung-podcasts/Anleitung Apple Podcasts.html`. Abweichend vom Entwurf endet Schritt 3 nicht mit "prüfe Titel, Lehrer:in und Typ", sondern mit "passe die Angaben an, wenn du möchtest" (Entscheidung 2026-10-09, weil es keine Typ-Auswahl mehr gibt).
- Entschiedene Texte (Deutsch; Englisch sinngemäß, "adjust the details if you like"):
  - Einleitung "Wo finde ich Meditationen?": "Gute Meditationen gibt es frei verfügbar auf Webseiten und in Podcasts. Ein paar Empfehlungen findest du unten."
  - Kasten: "So importierst du aus Apple Podcasts" / "Folge → Teilen → Still Moment.", Symbol Podcast-Wellen (SF Symbol bzw. Material "podcasts")
  - Einleitung der Anleitung: "Viele Lehrer:innen veröffentlichen ihre Meditationen als Podcast. So übernimmst du eine Folge in deine Bibliothek."
  - iOS: 1. "Öffne die App „Podcasts“ und suche die Folge, die du hören möchtest." 2. "Öffne die Folge und tippe auf das Teilen-Symbol. Wähle Still Moment und tippe in der kurzen Bestätigung auf „Fertig“." 3. "Öffne Still Moment. Die Folge wird geladen — passe die Angaben an, wenn du möchtest."
  - Android: 1. "Öffne podcasts.apple.com im Browser und suche die Folge, die du hören möchtest." 2. "Öffne die Folge und tippe auf das Teilen-Symbol. Wähle Still Moment." 3. "Still Moment öffnet sich und lädt die Folge — passe die Angaben an, wenn du möchtest."
  - Hinweis unter den Schritten: "Du kannst nur einzelne Folgen übernehmen, keine ganzen Podcasts."
  - Browser-Anleitung Schritt 2: iOS "Wähle Still Moment aus den vorgeschlagenen Apps und tippe in der kurzen Bestätigung auf „Fertig“.", Android "Wähle Still Moment aus den vorgeschlagenen Apps." Schritt 3: iOS "Öffne Still Moment. Der Import beginnt automatisch — passe die Angaben an, wenn du möchtest.", Android "Still Moment öffnet sich und der Import beginnt — passe die Angaben an, wenn du möchtest."
  - Dateien-Anleitung Schritt 3: "Der Import beginnt automatisch — passe die Angaben an, wenn du möchtest."
