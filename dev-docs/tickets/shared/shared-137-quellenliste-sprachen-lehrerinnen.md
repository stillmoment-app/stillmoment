---
id: shared-137
title: "Quellenliste: Lehrer:innen vorne, alle Sprachen sichtbar"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: mittel
depends_on: []
---

# Ticket shared-137: Quellenliste: Lehrer:innen vorne, alle Sprachen sichtbar

## Was

Die Quellenliste in "Wo finde ich Meditationen?" zeigt künftig jede Quelle in der Reihenfolge Name (meist die Lehrerin oder der Lehrer) → Angebot → Beschreibung → Adresse. Die Quellen der eigenen Sprache stehen aufgeklappt da, jede andere Sprache erscheint als eingeklappte Zeile, z.B. "Auch auf Englisch · 4 weitere Quellen". Melissa Gein verweist auf ihren Podcast bei Apple Podcasts.

## Warum

- Heute sieht man nur die Quellen der eigenen Sprache. Wer Deutsch eingestellt hat, erfährt nicht, dass es gute englische Quellen gibt, und umgekehrt.
- Die Person hinter einer Quelle steht heute teils nur im "Von …" am Ende der Beschreibung oder als Anhängsel am Namen. Meditationen wählt man aber meist nach der Lehrerin oder dem Lehrer.
- Mit der Anleitung für Apple Podcasts (shared-133) ist ein Podcast-Link für Melissa Gein der naheliegende Weg zu ihren Folgen, nicht podcast.de.

---

## Akzeptanzkriterien

- [ ] Jede Quelle zeigt untereinander: Name, Angebot (nur wenn es einen eigenen Namen hat), Beschreibung, Adresse
- [ ] Name und Angebot je Quelle:

  | Name | Angebot |
  |------|---------|
  | Kirsten Tofahrn | Zentrum für Achtsamkeit Köln |
  | Christine Brähler | — |
  | Jörg Mangold | Achtsamkeit & Selbstmitgefühl |
  | Melissa Gein | Podcast „Einfach meditieren“ |
  | Tara Brach | — |
  | Audio Dharma | Insight Meditation Center |
  | UCLA Mindful | UCLA Health |
  | Free Mindfulness Project | — |

- [ ] Keine Beschreibung enthält mehr ein "Von …"; Beschreibungen stehen in der Sprache der Quelle
- [ ] Die Quellen der eigenen Sprache stehen aufgeklappt oben. Eigene Sprache ist die Sprache der App: Deutsch bei deutscher Einstellung, sonst Englisch
- [ ] Jede andere Sprache erscheint darunter als eingeklappte Zeile mit Sprachname und Anzahl, z.B. "Auch auf Englisch · 4 weitere Quellen" bzw. "Also in German · 4 more sources". Antippen klappt die Quellen dieser Sprache auf und wieder zu
- [ ] Reihenfolge der Sprachen: eigene Sprache, dann Englisch, dann übrige alphabetisch nach angezeigtem Sprachnamen. Innerhalb einer Sprache bleibt die bisherige Reihenfolge der Quellen
- [ ] Melissa Gein verlinkt auf https://podcasts.apple.com/de/podcast/einfach-meditieren-einfach-achtsam-leben/id1588419775 und zeigt als Adresse "podcasts.apple.com"
- [ ] Antippen einer Quelle öffnet sie weiterhin außerhalb der App, auch in aufgeklappten anderen Sprachen. Antippen der eingeklappten Zeile klappt nur auf und verlässt "Wo finde ich Meditationen?" nicht
- [ ] Screenreader lesen jede Quelle in derselben Reihenfolge vor, wie sie angezeigt wird; die eingeklappte Zeile wird als Button mit Zustand (eingeklappt/aufgeklappt) vorgelesen
- [ ] Die Marketing-Screenshots von "Wo finde ich Meditationen?" sind neu aufgenommen, falls die Quellenliste darin zu sehen ist

---

## Manueller Test

1. Gerät auf Deutsch, Bibliothek → "Wo finde ich Meditationen?" öffnen
2. Erwartung: vier deutsche Quellen aufgeklappt, jede mit Name, ggf. Angebot, Beschreibung ohne "Von …", Adresse; darunter "Auch auf Englisch · 4 weitere Quellen"
3. Die Zeile antippen, dann noch einmal
4. Erwartung: die englischen Quellen klappen auf und wieder zu; "Wo finde ich Meditationen?" bleibt offen
5. Melissa Gein antippen
6. Erwartung: ihr Podcast bei Apple Podcasts öffnet sich (iOS: App Podcasts, Android: Browser)
7. Gerät auf Englisch und auf Französisch stellen, erneut öffnen
8. Erwartung: jeweils englische Quellen aufgeklappt, darunter "Also in German · 4 more sources"

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Link zu Melissa Gein öffnet | die App Podcasts | podcasts.apple.com im Browser |

---

## Nicht Teil dieses Tickets

- Initialen oder Fotos der Lehrer:innen (verworfen: Freigaben, Pflege, und die App lädt nichts von fremden Servern nach)
- Neue Quellen oder neue Sprachen
- Die Anleitungen und Kästen oberhalb der Quellenliste (shared-133)

---

## Hinweise

- Design-Entwurf (Claude Design, Projekt "Still Moment"): `prototypen/import-anleitung-podcasts/Anleitung Apple Podcasts.html`, Bild A. Dort stehen auch die gekürzten Beschreibungen ohne "Von …".
- Heute zeigt die Liste nur die Quellen der eigenen Sprache; bei jeder Sprache außer Deutsch Englisch. Diese Bestimmung der eigenen Sprache bleibt (Entscheidung 2026-10-09), neu ist, dass die übrigen Sprachen eingeklappt sichtbar sind.
- Die Quellen liegen auf beiden Plattformen in derselben Datei; sie bleibt auf beiden Plattformen gleich.
