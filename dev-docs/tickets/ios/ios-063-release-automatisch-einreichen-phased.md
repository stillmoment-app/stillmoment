---
id: ios-063
title: "iOS-Release ohne App Store Connect: automatisch einreichen, gestaffelt veröffentlichen"
status: in-progress
phase: 2-Architektur
priority: mittel
depends_on: []
---

# Ticket ios-063: iOS-Release ohne App Store Connect: automatisch einreichen, gestaffelt veröffentlichen

## Was

`make release` für iOS reicht die Version mit dem gerade hochgeladenen Build selbst zur Prüfung bei Apple ein.
Niemand muss mehr in App Store Connect den Build auswählen und auf „Zur Prüfung einreichen“ drücken.
Nach Apples Freigabe wird die Version gestaffelt an die Nutzer verteilt (Phased Release über 7 Tage) statt
sofort an alle.

## Warum

Das Einreichen ist heute der einzige Schritt im Release, der im Browser passieren muss. Er verhindert,
dass Claude das Release durchgehend ausführt (Release Guide → „Release durch Claude“). Weil vor dem
Einreichen kein langer manueller Testplan mehr steht, dient die gestaffelte Veröffentlichung als
Sicherheitsnetz: Ein durchgerutschter Fehler erreicht zuerst wenige Nutzer, und die Veröffentlichung lässt
sich in App Store Connect anhalten.

---

## Akzeptanzkriterien

- [ ] Nach `make -C ios release VERSION=x.y.z` ist die Version in App Store Connect mit dem neuen Build „Zur Prüfung eingereicht“, ohne Schritt im Browser
- [x] Release Notes, Metadaten und Screenshots werden weiterhin mit der Version hochgeladen
- [ ] Die Version ist für die gestaffelte Veröffentlichung eingestellt und wird nach Apples Freigabe automatisch gestartet
- [x] Scheitert das Einreichen (z. B. Build noch nicht verarbeitet, offene Apple-Vereinbarung), endet der Befehl mit Fehler und einer Meldung, die den nächsten Schritt nennt
- [x] Erhalt: `SKIP_BUILD=1` lädt weiterhin nur Metadaten und Screenshots hoch und reicht nichts ein
- [x] Erhalt: Der Release-Guard läuft weiterhin vor jedem Upload und verhindert ihn bei fehlgeschlagener Prüfung
- [x] Release Guide beschreibt den neuen Ablauf; der Abschnitt „Nach dem Upload → iOS“ mit Build-Auswahl und Einreichen entfällt bzw. beschreibt nur noch das Anhalten der gestaffelten Veröffentlichung im Notfall

Kriterien 1 und 3 sind im Code umgesetzt (Lane `release`: `submit_for_review` mit Build, `phased_release: true`,
`automatic_release: true`), lassen sich aber erst beim nächsten echten iOS-Release prüfen (siehe Manueller Test).

---

## Manueller Test

1. Nächstes echtes iOS-Release mit `make -C ios release VERSION=x.y.z` hochladen
2. App Store Connect öffnen
3. Erwartung: Version steht auf „Zur Prüfung eingereicht“ mit dem neuen Build, „Gestaffelte Veröffentlichung“ ist aktiv.

---

## Nicht Teil dieses Tickets

- Gestaffelte Auslieferung auf Android (bewusst verworfen)
- Automatisches Anhalten der Veröffentlichung bei Abstürzen

---

## Hinweise

- Heutiger Stand: Hochladen ohne Einreichen, automatische Veröffentlichung nach Freigabe, keine gestaffelte Veröffentlichung. Die Build-Zuordnung zur Version passiert in fastlane nur beim Einreichen; deshalb musste sie bisher manuell erfolgen.
- Apples Phased Release betrifft nur automatische Updates; Nutzer, die im App Store selbst aktualisieren, bekommen die Version sofort. Das ist gewollt.
- Fehler beim Upload mit 403 / „Unable to find Apple ID for Bundle ID“ bedeuten eine offene Apple-Vereinbarung — der Nutzer muss sie akzeptieren, die Konfiguration ist dann nicht schuld.
