---
id: android-099
title: "Beim Import gewählter Wiedergabe-Bereich geht verloren"
status: in-progress
phase: 1-Quick Fix
priority: hoch
depends_on: []
---

# Ticket android-099: Beim Import gewählter Wiedergabe-Bereich geht verloren

## Was

**Beobachtet:** Im Bearbeiten-Blatt nach einem Import lässt sich über „Bereich wählen“ ein Wiedergabe-Bereich festlegen; das Blatt zeigt ihn danach auch an (z.B. „0:05 – 15:39 · 15:34 hörbar“). Nach „Importieren“ zeigt die Bibliothek aber die volle Länge, und beim erneuten Bearbeiten steht dort „Ganze Datei“. Der gewählte Bereich ist verloren. Wird der Bereich später über das Bearbeiten einer vorhandenen Meditation gesetzt, bleibt er erhalten.
**Erwartet:** Ein beim Import gewählter Wiedergabe-Bereich wird mit der Meditation gespeichert.
**Umstände:** Emulator API 36, Dev-Build von main, 2026-10-10, reproduzierbar bei jedem Versuch (Import per „Öffnen mit“). Laut Code betrifft es jeden Import-Weg (Plus-Knopf, „Öffnen mit“, Link- und Podcast-Import), weil alle über denselben Speicherweg laufen. Die Gong-Einstellungen aus demselben Blatt werden dagegen gespeichert.

## Warum

Das Blatt bietet den Bereich beim Import an und zeigt ihn als gewählt an – dass er dann still verschwindet, ist ein Datenverlust, den man erst beim Abspielen merkt.

---

## Akzeptanzkriterien

- [ ] Ein beim Import gewählter Wiedergabe-Bereich ist nach dem Speichern in Bibliothek (gekürzte Dauer), Player und beim erneuten Bearbeiten vorhanden
- [ ] Gilt für alle Import-Wege: Plus-Knopf, „Öffnen mit“/Teilen einer Datei, Link- und Podcast-Import
- [ ] Ohne gewählten Bereich wird wie bisher die ganze Datei gespeichert
- [ ] Lehrer:in, Name und Gong-Einstellungen beim Import bleiben wie bisher erhalten

---

## Manueller Test

1. Eine MP3 importieren, im Bearbeiten-Blatt „Bereich wählen“, Anfang und Ende verschieben, zurück
2. Lehrer:in eintragen, „Importieren“
3. Erwartung: Die Bibliothek zeigt die gekürzte Dauer, der Player spielt nur den Bereich, erneutes Bearbeiten zeigt den Bereich

---

## Hinweise

- iOS zeigt den Wiedergabe-Bereich beim Import gar nicht an, nur beim Bearbeiten. Android bietet ihn seit shared-107/108/112 auch beim Import an, speichert ihn dort aber nicht. Entscheidung (2026-10-10, Orchestrator): Den angebotenen Bereich speichern, statt ihn auszublenden – das Angebot ist für Nutzer sinnvoll, nur die Speicherung fehlt. Ob iOS nachzieht, ist eine eigene Frage.
- Gefunden 2026-10-10 bei der Emulator-Prüfung von android-094.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
