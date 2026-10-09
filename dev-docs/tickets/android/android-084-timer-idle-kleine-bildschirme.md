---
id: android-084
title: "Timer-Startbildschirm auf kleinen Bildschirmen abgeschnitten"
status: todo
phase: 4-Polish
priority: hoch
depends_on: []
---

# Ticket android-084: Timer-Startbildschirm auf kleinen Bildschirmen abgeschnitten

**Komplexitaet**: Layout-Arbeit ohne Logik. Das Risiko liegt in der Abwaegung: Atemkreis, Einstellungsliste und Start-Knopf muessen auf kleinen Bildschirmen gemeinsam Platz finden, ohne dass der Bildschirm auf normalen Geraeten unruhiger oder anders aussieht als auf iOS.

---

## Was

Auf kleinen Android-Bildschirmen (etwa 360×740dp und kleiner) passt der Timer-Startbildschirm nicht auf den Bildschirm: Die Einstellungsliste wird gestaucht, und der Start-Knopf ist gar nicht sichtbar. Der Bildschirm soll auch dort vollstaendig nutzbar sein.

## Warum

Ohne sichtbaren Start-Knopf laesst sich auf diesen Geraeten keine Timer-Meditation beginnen — ein Kernablauf der App ist dort kaputt. Das Problem bestand schon vor shared-126 (auch der alte beschriftete Knopf war unsichtbar) und wurde dabei festgestellt. Auf iOS passt der Bildschirm bis zum iPhone SE.

---

## Akzeptanzkriterien

### Feature
- [ ] Bei 360×740dp und 360×640dp sind Ueberschrift, Atemkreis, alle vier Einstellungszeilen und der Start-Knopf vollstaendig sichtbar und bedienbar
- [ ] Der Start-Knopf wird von der Tab-Leiste nicht ueberdeckt
- [ ] Die Einstellungszeilen behalten ihre normale Hoehe und Lesbarkeit (kein Stauchen, keine abgeschnittenen Texte)
- [ ] Auf grossen und mittleren Bildschirmen (z.B. Pixel 8, 393×851dp) sieht der Bildschirm unveraendert aus
- [ ] Bei vergroesserter Systemschrift bleibt der Start-Knopf erreichbar (notfalls per Scrollen)

### Tests
- [ ] Bestehende UI- und Screenshot-Tests laufen weiterhin durch

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Emulator oder Geraet mit kleinem Bildschirm (z.B. 360×640dp) verwenden
2. Timer-Tab oeffnen
3. Erwartung: Atemkreis, alle vier Einstellungen und der runde Start-Knopf sind ohne Ueberlappung sichtbar; Antippen des Knopfs startet die Meditation
4. Dasselbe mit groesster Systemschrift wiederholen

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/` (Timer-Startbildschirm)
- iOS als Vergleich: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` — passt auf iPhone SE

---

## Hinweise

- Kleine Bildschirme lassen sich ohne zweites AVD simulieren: `adb shell wm size 720x1480` + `adb shell wm density 320` (= 360×740dp), danach `wm size reset` / `wm density reset`.
- shared-126 hat im kompakten Layout den Abstand zwischen Liste und Start-Knopf verringert, damit der hoehere runde Knopf bei 393×851dp passt. Das loest die kleineren Groessen nicht.
