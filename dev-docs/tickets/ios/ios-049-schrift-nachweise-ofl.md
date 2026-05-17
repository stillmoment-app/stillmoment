# Ticket ios-049: Schrift-Nachweise (OFL-Lizenz) im Einstellungen-Bereich

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Compliance-Aufgabe ohne neue Domain-Logik. Risiko liegt in Bundle-Zugriff (`OFL.txt` aus dem Bundle lesen, nicht hartkodierter String) und einer barrierefreien Darstellung des Lizenztextes.
**Abhaengigkeiten**: ios-048
**Phase**: 5-QA

---

## Was

Im Einstellungen-Bereich einen Eintrag "Schrift-Nachweise" ergaenzen, der die verwendeten Schrift-Familien (Newsreader, Geist) nennt und den vollstaendigen OFL-1.1-Lizenztext anzeigt — analog zum bestehenden Eintrag "Klang-Nachweise".

## Warum

Mit ios-048 wurden Newsreader und Geist statisch ins App-Bundle aufgenommen. Beide Fonts stehen unter der SIL Open Font License 1.1. Die OFL verlangt in §2, dass der Lizenztext "leicht einsehbar" mit der Software ausgeliefert wird. Aktuell liegt `OFL.txt` zwar im Bundle, ist aus der App heraus aber nicht sichtbar — das ist Compliance-mass nicht sauber und sollte vor dem naechsten Store-Release nachgezogen werden.

---

## Akzeptanzkriterien

### Feature

- [ ] In der Einstellungen-Liste erscheint unter "Info & Rechtliches" ein neuer Eintrag "Schrift-Nachweise" (direkt vor oder nach "Klang-Nachweise")
- [ ] Tap auf den Eintrag oeffnet eine neue Detail-View, die beide Schrift-Familien (Newsreader von Production Type, Geist von Vercel) und die Lizenz (SIL Open Font License 1.1) nennt
- [ ] Der vollstaendige Lizenztext aus `Resources/Fonts/OFL.txt` ist in dieser View vollstaendig lesbar (scrollbar)
- [ ] Lokalisiert (DE + EN) fuer Labels und Beschreibungstexte; der OFL-Lizenztext selbst bleibt englisch (Original)

### Tests

- [ ] Unit-Test: `OFL.txt` ist im App-Bundle vorhanden und ueber `Bundle.main` ladbar (nicht-leerer String)
- [ ] UI-Test (oder Snapshot): die neue Schrift-Nachweise-Detail-View rendert ohne Layout-Bruch in Light + Dark Mode

### Dokumentation

- [ ] CHANGELOG.md ("Schrift-Nachweise in den Einstellungen erreichbar")

---

## Manueller Test

1. App starten, Einstellungen-Tab oeffnen
2. Bis zum Block "Info & Rechtliches" scrollen
3. Auf "Schrift-Nachweise" tippen
4. Erwartung: Detail-View zeigt eine kurze Erlaeuterung (Familie + Designer + Lizenz) und darunter den vollstaendigen OFL-1.1-Text. Beide Modi (Light/Dark) lesbar, keine abgeschnittenen Zeilen, scrollbar.

---

## Referenz

- Bestehende Lizenz-View: `ios/StillMoment/Presentation/Views/Settings/` — der Eintrag "Klang-Nachweise" zeigt heute schon das Muster (Settings-Row → Detail-View mit Lizenz-Inhalt)
- OFL-Quelle im Bundle: `ios/StillMoment/Resources/Fonts/OFL.txt`
- Voriges Ticket: ios-048 (Newsreader + Geist eingefuehrt)

---

## Hinweise

- Lizenztext **nicht** als Swift-String hartkodieren — bei jedem Font-Update im Bundle koennte er sich aendern. Aus `Bundle.main.url(forResource: "OFL", withExtension: "txt")` laden.
- OFL §2 erlaubt die Auslieferung als "stand-alone text file, human-readable header, or in machine-readable metadata". Eine In-App-View, die den Text rendert, deckt "human-readable" sauber ab.
- OFL §4 verbietet, die Autoren-Namen zur Bewerbung der App zu nutzen — die Detail-View nennt sie nur als Quellen-Angabe, das ist OK.
- Android nutzt diese Fonts nicht — wenn der Font-Wechsel spaeter portiert wird, kommt ein analoges Android-Ticket dazu.
