---
id: android-090
title: "Release-Build auf die R8-Standards von AGP 9 umstellen"
status: todo
phase: 2-Architektur
priority: niedrig
depends_on: []
---

# Ticket android-090: Release-Build auf die R8-Standards von AGP 9 umstellen

## Was

Der Release-Build nutzt die neuen R8-Standardeinstellungen von AGP 9 für Keep-Regeln und Resource Shrinking. Die App funktioniert in der Store-Version weiterhin vollständig.

## Warum

Beim Upgrade auf AGP 9 hat der Upgrade-Assistent zwei Opt-outs gesetzt, die R8 auf dem alten Verhalten halten: `android.r8.strictFullModeForKeepRules=false` und `android.r8.optimizedResourceShrinking=false`. AGP meldet beide als veraltet, mit AGP 10 fallen sie weg. Dann ändert sich das Verhalten der Store-Version erzwungen und ungeplant. Besser ist es, kontrolliert umzustellen, solange man noch zurück kann.

Das Risiko liegt allein in der Store-Version: Entfernt R8 etwas, das zur Laufzeit gebraucht wird, stürzt die App erst beim Aufruf ab. Debug-Builds und Unit-Tests merken davon nichts.

---

## Akzeptanzkriterien

- [ ] Der Release-Build setzt keine der beiden R8-Opt-outs mehr und baut ohne R8-Warnungen
- [ ] In der Release-Version lassen sich MP3s in die Bibliothek importieren, per Datei und per Link
- [ ] In der Release-Version spielt eine geführte Meditation im Player, auch bei gesperrtem Bildschirm
- [ ] In der Release-Version läuft der Timer mit Vorbereitungszeit, Start-Gong, Intervall-Gongs, Hintergrundklang und End-Gong, auch bei gesperrtem Bildschirm
- [ ] In der Release-Version bleiben Praxis-Einstellungen und Bibliothek nach einem App-Neustart erhalten
- [ ] Die Release-Version zeigt alle Texte lokalisiert und alle Icons korrekt (keine fehlenden Ressourcen)

---

## Manueller Test

1. Release-Build bauen und auf einem echten Gerät installieren
2. Eine MP3 importieren und abspielen, dann den Bildschirm sperren
3. Einen Timer mit Intervall-Gongs und Hintergrundklang starten und den Bildschirm sperren
4. Die App beenden und neu starten
5. Erwartung: Kein Absturz, alle Gongs und Klänge spielen bei gesperrtem Bildschirm, Bibliothek und Einstellungen sind nach dem Neustart noch da

---

## Hinweise

- Kürzlich gab es schon einen R8-Fix (Commit `0a231515`, pauschale Keep-Regeln für Compose und Hilt entfernt). Die Keep-Regeln wurden also gerade erst bewusst zurückgestutzt. Bei Problemen sollten gezielte Regeln her, kein pauschales Keep.
- Ein grüner Build und grüne Unit-Tests reichen als Nachweis nicht. Den Ausschlag gibt der Durchlauf der Release-Version auf dem Gerät.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
