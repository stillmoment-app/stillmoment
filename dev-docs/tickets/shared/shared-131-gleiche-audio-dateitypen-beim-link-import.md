---
id: shared-131
title: "Gleiche Audio-Dateitypen beim Link- und Podcast-Import"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: niedrig
depends_on: [shared-128]
---

# Ticket shared-131: Gleiche Audio-Dateitypen beim Link- und Podcast-Import

**Komplexitaet**: Android gering (Liste um zwei Typen ergaenzen). iOS mittel: iOS prueft den Dateityp heute erst, wenn die Datei schon vollstaendig geladen ist — fuer "ablehnen, bevor die Datei vollstaendig geladen ist" muss iOS frueher pruefen, ohne Abbrechen und den Import langer Folgen (shared-128) zu brechen. Risiko: iOS wird strenger — Dateien, die heute (zufaellig) klappen, koennten abgelehnt werden.

---

## Was

Beim Laden einer Audiodatei ueber einen geteilten Link entscheiden iOS und Android anhand derselben festen Liste von Dateitypen (Content-Type des Servers), ob die Datei als Audio angenommen wird.

## Warum

Heute nimmt iOS jeden Audio-Typ an, Android nur eine feste Liste. Eine echte MP3, die der Server z.B. als `audio/x-mpeg` meldet, landet auf iOS in der Bibliothek, Android lehnt sie ab. Umgekehrt laedt iOS z.B. eine Ogg-Datei, speichert sie als MP3 und scheitert erst danach mit einer allgemeinen Fehlermeldung statt der passenden. Der Unterschied besteht seit shared-091 und fiel im Review von shared-128 auf — beim Podcast-Import waehlt der Nutzer den Server nicht selbst, daher wiegt er dort schwerer.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Angenommen werden genau: `audio/mpeg`, `audio/mp3`, `audio/x-mpeg`, `audio/mpeg3`, `audio/mp4`, `audio/x-m4a`, `audio/m4a`, `application/octet-stream`
- [ ] Gross-/Kleinschreibung und Zusaetze nach `;` (z.B. `audio/mpeg; charset=…`) spielen keine Rolle
- [ ] Meldet der Server keinen Dateityp, wird die Datei weiterhin angenommen
- [ ] Jeder andere Dateityp (z.B. `audio/ogg`) wird abgelehnt, bevor die Datei vollstaendig geladen ist, mit der bestehenden Meldung des jeweiligen Importwegs: Link-Import „kein Audio“, Podcast-Import „Folge nicht verfuegbar“
- [ ] Abgelehnt wird auch ein Typ, der nur mit einem erlaubten beginnt, z.B. `audio/mpegurl` / `audio/x-mpegurl` (Wiedergabelisten, keine Audiodatei)
- [ ] Link-Import und Podcast-Import verhalten sich gleich
- [ ] Abbrechen im Ladefenster beendet den Download weiterhin sofort
- [ ] Lange Podcast-Folgen (mehrere Stunden) lassen sich weiterhin importieren
- [ ] Keine neuen Texte

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Link auf eine MP3 teilen, deren Server `audio/mpeg` meldet (z.B. Folge von audiodharma.org)
2. Erwartung: Import klappt auf beiden Plattformen wie bisher
3. Link auf eine Datei teilen, deren Server `audio/ogg` meldet
4. Erwartung: Auf beiden Plattformen erscheint dieselbe Meldung, kein Eintrag in der Bibliothek

---

## Referenz

- iOS: `ios/StillMoment/Infrastructure/Services/AudioDownloadService.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/network/UrlAudioDownloaderImpl.kt`

---

## Hinweise

- Die Liste ist eine Annahme-Liste fuer den Download; welche Formate die Bibliothek abspielen kann (MP3, M4A), bleibt unveraendert.
- iOS-Befund (geprueft 2026-10-09): iOS laedt die Datei heute vollstaendig und prueft den Dateityp erst danach, und zwar nur auf den Anfang (`audio/…`). Android prueft schon nach der Server-Antwort und vor dem Laden, mit exaktem Vergleich. Der Aufwand liegt daher vor allem auf iOS.
- Der iOS-Zusatzcheck nach dem Download (`rejectedFileError` im InboxHandler) kann danach bleiben, greift aber praktisch nicht mehr.
