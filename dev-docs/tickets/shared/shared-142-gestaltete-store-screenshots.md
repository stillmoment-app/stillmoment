---
id: shared-142
title: "Gestaltete Store-Screenshots mit Headline statt roher Screenshots"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: mittel
depends_on: []
---

# Ticket shared-142: Gestaltete Store-Screenshots mit Headline statt roher Screenshots

## Was

App Store und Play Store zeigen statt der rohen App-Screenshots gestaltete Bilder: oben
ein kurzes Eyebrow-Label und eine zweizeilige Headline, darunter der echte Screenshot im
warmen Dark-Hintergrund der App. Die Bilder entstehen automatisch beim Erzeugen der
Store-Screenshots, in Deutsch und Englisch, ohne Handarbeit pro Release.

Reihenfolge und Texte (verbindlich):

| # | Screen | Eyebrow DE / EN | Headline DE | Headline EN |
|---|--------|-----------------|-------------|-------------|
| 1 | Bibliothek | Deine Bibliothek / Your library | Deine Meditationen. / An einem Ort. | Your meditations. / All in one place. |
| 2 | Player (Guided Meditation läuft) | Geführte Meditation / Guided meditation | Starten. Weglegen. / Da sein. | Press play. Put it down. / Be here. |
| 3 | Import-Anleitung mit Quellenliste | Eigene Aufnahmen / Your own recordings | Aus Browser, Dateien / und Podcasts. | From your browser, / files and podcasts. |
| 4 | Timer läuft | Stille Meditation / Silent meditation | Nur du / und die Stille. | Just you / and the silence. |
| 5 | Start-/End-Gong-Auswahl | Klänge / Sounds | Ein sanfter Gong / holt dich zurück. | A gentle gong / brings you back. |
| 6 | Zuschnitt-Editor | Zuschneiden / Trim | Nur der Teil, / den du brauchst. | Keep only / the part you need. |
| 7 | Abschluss-Bildschirm | Privat / Private | Kein Tracking. / Keine Werbung. | No tracking. / No ads. |

(`/` = Zeilenumbruch in der Headline.)

## Warum

Heute landen rohe Screenshots ohne Text im Store. In den Suchergebnissen sieht man nur die
ersten drei Bilder — wer die App nicht kennt, muss erraten, wofür sie da ist. Die
Headlines erzählen in drei Bildern die Kerngeschichte (eigene Bibliothek → anhören → woher
die Aufnahmen kommen) und folgen Apples Asset Best Practices: echte Oberfläche zeigen,
stärkstes Feature zuerst, kurzer Text, der das Bild ergänzt.

---

## Akzeptanzkriterien

- [ ] Ein Durchlauf der Screenshot-Erzeugung liefert für beide Stores und beide Sprachen je 7 gestaltete Bilder in der Reihenfolge der Tabelle
- [ ] Headlines und Eyebrows stehen wörtlich wie in der Tabelle, inkl. Zeilenumbruch; keine Headline läuft auf eine dritte Zeile oder überlappt den Screenshot
- [ ] Der Screenshot im Bild ist vollständig sichtbar (Statusleiste bis Tab-Leiste bzw. unterer Rand) und stammt aus demselben Durchlauf, nicht aus einer Kopie
- [ ] Gestaltung entspricht dem Referenzentwurf: Newsreader Light für die Headline, Geist in Versalien für das Eyebrow, Farben aus der Dark-Palette (Hintergrund-Verlauf, Text, Akzent), Screenshot mit abgerundeten Ecken und feinem Rahmen
- [ ] App Store: Bilder haben exakt 1320×2868 px, PNG ohne Alphakanal, und werden beim Store-Upload statt der rohen Screenshots hochgeladen
- [ ] Play Store: Bilder erfüllen die Play-Vorgaben für Smartphone-Screenshots und werden beim Store-Upload statt der rohen Screenshots hochgeladen
- [ ] Android liefert für Bild 7 einen Abschluss-Bildschirm-Screenshot (fehlt heute im Android-Screenshot-Set)
- [ ] Die Screenshots auf der Website (`docs/images/screenshots/`) bleiben rohe Screenshots ohne Headline
- [ ] Das veraltete, abgeschaltete frameit-Setup ist entfernt

---

## Manueller Test

1. `make screenshots-all` ausführen
2. Die gestalteten Bilder für iOS (de-DE, en-GB) und Android (de-DE, en-US bzw. die vorhandenen Sprachen) öffnen
3. Erwartung: je 7 Bilder in Tabellen-Reihenfolge, Texte wie in der Tabelle, Screenshot vollständig sichtbar, Aussehen wie `dev-docs/assets/store-screenshots/entwurf-uebersicht-de.jpg`
4. Store-Upload mit `DRY_RUN` bzw. Upload-Vorschau prüfen
5. Erwartung: hochgeladen würden die gestalteten Bilder, nicht die rohen; Website-Screenshots unverändert

---

## Nicht Teil dieses Tickets

- iPad-Screenshots
- App-Preview-Videos
- Play-Store-Feature-Grafik, Product-Page-Header, In-App-Events, Custom Product Pages
- Light-Mode-Varianten der Bilder
- Weitere Sprachen über Deutsch und Englisch hinaus

---

## Hinweise

- **Referenzentwurf:** `dev-docs/assets/store-screenshots/` (Übersicht DE + EN, Bild 1 in Originalgröße). Gebaut als HTML-Vorlage, gerendert mit Headless Chrome aus den aktuellen Fastlane-Screenshots.
- **Entscheidung — eigene HTML-Vorlage statt Fastlane frameit:** frameit erlaubt kaum eigene Gestaltung (Hintergrund, Titel, Apple-Gerätrahmen); die eigene Vorlage nutzt die App-Schriften und -Farben und funktioniert für beide Plattformen. Chrome als Abhängigkeit ist vertretbar, weil Releases lokal laufen (`make release-prepare`).
- **Texte pro Sprache außerhalb der Vorlage halten**, damit neue Sprachen oder geänderte Headlines nur eine Textänderung sind.
- **Apple-Vorgaben für Store-Bilder** (Asset Best Practices, Guideline 2.3): keine Preise, keine URLs, keine Auszeichnungen, keine Verweise auf andere Plattformen — deshalb „Kein Tracking. Keine Werbung." statt Aussagen zu Kosten. Dasselbe gilt sinngemäß für Google Play.
- **Auswahl:** Suche, Timer-Startansicht und Hintergrundklang sind bewusst nicht mehr im Store-Set (bisher 10 iOS-Bilder); sie dürfen weiter für die Website erzeugt werden.
- Quelle: https://developer.apple.com/app-store/asset-best-practices/
