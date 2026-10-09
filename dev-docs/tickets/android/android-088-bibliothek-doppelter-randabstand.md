---
id: android-088
title: "Bibliothek und Bearbeiten-Blatt verschenken Höhe an doppelte Randabstände"
status: todo
phase: 4-Polish
priority: mittel
depends_on: []
---

# Ticket android-088: Bibliothek und Bearbeiten-Blatt verschenken Höhe an doppelte Randabstände

## Was

**Beobachtet:** In der Bibliothek liegt die Kopfzeile um etwa eine Statusleistenhöhe zu tief; darunter entsteht eine leere Zone. Unten endet die Liste deutlich über der Tab-Leiste, dazwischen bleibt ein breiter leerer Streifen. Dadurch passen weniger Meditationen auf den Bildschirm. Das Bearbeiten-Blatt einer Meditation zeigt sehr wahrscheinlich dieselben zu großen Abstände; möglicherweise bleibt darunter sogar die Tab-Leiste sichtbar (noch nicht am Gerät geprüft).

**Erwartet:** Kopfzeile direkt unter der Statusleiste, Liste reicht bis an die Tab-Leiste heran — wie auf dem Timer-Startbildschirm seit android-084 und wie auf iOS. Das Bearbeiten-Blatt nutzt die volle Höhe ohne doppelte Abstände.

**Umstände:** Alle Android-Geräte; auf kleinen Bildschirmen am auffälligsten. Ursache ist dieselbe wie beim Timer-Startbildschirm in android-084: Statusleiste und Systemnavigation werden zweimal freigehalten (rund 65–70 dp zusammen).

## Warum

Die Bibliothek ist das Kernfeature. Verschenkte Höhe heißt weniger sichtbare Meditationen und ein unruhiges, „verrutschtes“ Erscheinungsbild gegenüber iOS.

---

## Akzeptanzkriterien

- [ ] Die Kopfzeile der Bibliothek beginnt direkt unter der Statusleiste, ohne zusätzliche leere Zone
- [ ] Die Bibliotheksliste und die Suchergebnisse lassen sich bis an die Tab-Leiste scrollen; das letzte Element ist vollständig sichtbar und nicht von der Tab-Leiste verdeckt
- [ ] Das Bearbeiten-Blatt einer Meditation nutzt die volle Höhe ohne doppelten Abstand oben und unten; sein Speichern-Knopf und alle Felder sind erreichbar
- [ ] Ist beim geöffneten Bearbeiten-Blatt die Tab-Leiste sichtbar, wird das am Gerät festgestellt und behoben oder als eigenes Ticket festgehalten
- [ ] Hinweis-Meldungen der Bibliothek (z. B. Importfehler) erscheinen weiterhin vollständig über der Tab-Leiste
- [ ] Timer-Startbildschirm, Einstellungen, Player und laufende Timer-Sitzung sehen unverändert aus

---

## Manueller Test

1. Android-Gerät oder Emulator, Bibliothek mit mehreren Meditationen öffnen
2. Abstand zwischen Statusleiste und Kopfzeile sowie zwischen letztem Listenelement und Tab-Leiste ansehen (ganz nach unten scrollen)
3. Eine Meditation bearbeiten: Abstände oben/unten und Sichtbarkeit der Tab-Leiste prüfen
4. Erwartung: keine leeren Zonen unter der Statusleiste oder über der Tab-Leiste; Bearbeiten-Blatt ohne doppelten Rand
5. Dasselbe bei 360×640 dp (`adb shell wm size 720x1280` + `adb shell wm density 320`, danach `wm size reset` / `wm density reset`)

---

## Hinweise

- Ursache und Lösungsmuster sind in android-084 dokumentiert (Timer-Startbildschirm, archiviert).
- Bildschirme, die ihre Ränder selbst verwalten (Player, laufende Timer-Sitzung), brauchen ihre bisherigen Abstände — dort bekommen sie keinen Rand von außen.
- Einstellungen und deren Unterbildschirme sind laut Recherche nicht betroffen.
- Der Endabstand der Liste und die Ausblendung am unteren Rand sind auf die heutige (zu hohe) Unterkante abgestimmt und müssen nach der Korrektur neu angesehen werden.
- Play-Store-Screenshots der Bibliothek ändern sich dadurch.
