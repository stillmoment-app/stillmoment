# Ticket shared-081: Filter nach Dauer in der Meditationsliste

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. Die Filterlogik selbst ist trivial, aber der Filter greift in die bestehenden vier Suchzustaende der Bibliothek ein (gruppiert / Historie / Treffer / kein Treffer). Der Kern des Tickets ist das Zusammenspiel von Filter und Suche, nicht das Filtern.
**Phase**: 3-Feature
**Plan**: [iOS](../plans/shared-081-ios.md) · [Android](../plans/shared-081-android.md)

---

## Was

Die Meditationsliste wird nach Dauer filterbar. Unter dem Suchfeld erscheint eine Zeile mit festen Dauer-Stufen als Einzelauswahl. Ein gesetzter Filter bleibt auch waehrend der Suche sichtbar und wirkt mit ihr zusammen.

## Warum

User waehlen Meditationen nach der Zeit, die sie gerade haben. Wer acht Minuten hat, soll nicht an halbstuendigen Meditationen vorbeiscrollen muessen.

Der zweite, weniger offensichtliche Grund: Sobald Suche und Filter gleichzeitig wirken, muss der User jederzeit sehen koennen, *warum* eine Meditation fehlt, die er erwartet. Ein unsichtbarer Filter erzeugt genau das Gegenteil von Ruhe.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Dauer-Stufen

- [ ] Die Filterzeile sitzt unter dem Suchfeld und enthaelt: `Alle` · `bis 5 Min` · `5–15 Min` · `15–30 Min` · `über 30 Min`
- [ ] Grenzen: unter 5 Min → `bis 5 Min`; ab 5 bis unter 15 → `5–15 Min`; ab 15 bis unter 30 → `15–30 Min`; ab 30 → `über 30 Min`. Eine Meditation von genau 5:00 faellt in `5–15 Min`, eine von 4:59 in `bis 5 Min`
- [ ] `Alle` ist im Ausgangszustand aktiv
- [ ] Einzelauswahl: nur eine Stufe gleichzeitig aktiv, die aktive Stufe ist visuell hervorgehoben
- [ ] Erneutes Tippen auf die aktive Stufe kehrt zu `Alle` zurueck
- [ ] Stufen ohne passende Meditation sind blass dargestellt und reagieren nicht auf Antippen. Sie bleiben sichtbar, damit die Zeile ihre Breite nie aendert
- [ ] Ob eine Stufe leer ist, richtet sich nach dem aktuellen Suchtext: waehrend einer Suche zaehlen nur die Treffer dieser Suche
- [ ] Bei leerer Bibliothek erscheint keine Filterzeile (der Empty State der Bibliothek bleibt unveraendert)
- [ ] Die Filterzeile ist horizontal scrollbar, damit alle fuenf Stufen auch bei grossen Schriftgroessen erreichbar bleiben

### Wirkung auf die Liste

- [ ] Ohne Filter bleibt die Liste nach Lehrer:in gruppiert — unveraendert zum heutigen Verhalten
- [ ] Mit gesetztem Filter entfaellt die Gruppierung: eine flache Liste, in der Lehrer:in und Dauer gemeinsam in der Unterzeile stehen
- [ ] Ueber der flachen Liste steht eine Zaehlzeile im Format „2 von 7 Meditationen" — die zweite Zahl ist der Gesamtbestand der Bibliothek
- [ ] Die Zaehlzeile erscheint auch bei einer Suche ohne Filter (ersetzt die heutige Trefferzeile)
- [ ] Die Zaehlzeile ist grammatisch korrekt bei genau einer Meditation

### Zusammenspiel mit der Suche

- [ ] Sobald das Suchfeld den Fokus hat, weicht die vollstaendige Filterzeile
- [ ] Ein gesetzter Filter bleibt in diesem Zustand als einzelner Chip mit Schliess-Symbol sichtbar; Antippen entfernt den Filter
- [ ] Ohne gesetzten Filter erscheint im Suchmodus kein Chip — die Trefferliste erhaelt die volle Hoehe
- [ ] Der Filter-Chip ist auch sichtbar, solange das Suchfeld fokussiert und leer ist (waehrend die Suchhistorie angezeigt wird)
- [ ] Suche und Filter wirken zusammen: die Liste zeigt nur Meditationen, die beide Bedingungen erfuellen
- [ ] „Abbrechen" verwirft den Suchtext, behaelt aber den Filter — die vollstaendige Filterzeile kehrt zurueck
- [ ] Der Filter wird nur durch `Alle`, durch den Chip oder durch Verlassen der Bibliothek zurueckgesetzt. Ein Ausflug in den Player und zurueck laesst ihn bestehen

### Kein Treffer

- [ ] Wenn Suche und Filter gemeinsam keinen Treffer liefern, nennt der Text beide Ursachen — den Suchbegriff und die Dauer-Stufe
- [ ] Wenn nur der Filter greift und keine Meditation dieser Laenge existiert, nennt der Text die Dauer-Stufe als Ursache
- [ ] Ein einzelner Tap setzt Suchtext und Filter gemeinsam zurueck

### Accessibility

- [ ] Jede Stufe traegt einen Namen und ihren Auswahl-Zustand, sodass Screenreader „ausgewaehlt" ansagen
- [ ] Blasse Stufen werden als nicht verfuegbar angesagt
- [ ] Der Filter-Chip im Suchmodus sagt an, dass Antippen den Filter entfernt
- [ ] Alle Bedienelemente erreichen die Mindest-Tapflaeche

### Feature-Rahmen

- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests

- [ ] Unit Tests iOS: Zuordnung Dauer → Stufe inklusive der Grenzwerte 4:59 / 5:00 / 14:59 / 15:00 / 29:59 / 30:00
- [ ] Unit Tests iOS: Suche und Filter gemeinsam — Treffermenge, leere Treffermenge, Belegung der Stufen unter aktivem Suchtext
- [ ] Unit Tests iOS: Filter bleibt nach „Abbrechen", Filter faellt beim Verlassen der Bibliothek
- [ ] Unit Tests iOS: gruppierte Darstellung ohne Filter, flache Darstellung mit Filter
- [ ] Unit Tests Android: identische Faelle

### Dokumentation

- [ ] CHANGELOG.md

---

## Manueller Test

1. Bibliothek mit Meditationen unterschiedlicher Laenge oeffnen (z.B. 3, 7, 12, 19, 25, 42 Min)
2. Filterzeile erscheint unter dem Suchfeld, `Alle` ist aktiv, Liste ist nach Lehrer:in gruppiert
3. `5–15 Min` tippen → Gruppierung verschwindet, flache Liste mit Lehrer:in in der Unterzeile, Zaehlzeile nennt zwei von sechs
4. `5–15 Min` erneut tippen → zurueck zu `Alle`, Gruppierung ist wieder da
5. `5–15 Min` setzen, dann ins Suchfeld tippen → Filterzeile weicht, der Filter bleibt als Chip mit ✕ stehen
6. Einen Buchstaben eingeben, der auch auf eine 25-Minuten-Meditation passt → diese fehlt in der Liste, der Chip erklaert warum
7. Chip antippen → die 25-Minuten-Meditation erscheint
8. Filter erneut setzen, dann „Abbrechen" → Suchtext ist weg, Filter steht noch, vollstaendige Filterzeile ist zurueck
9. `über 30 Min` setzen und nach einem Begriff suchen, der nur auf kurze Meditationen passt → Text nennt Begriff und Dauer, ein Tap raeumt beides ab
10. Filter setzen, eine Meditation im Player oeffnen, zurueckgehen → Filter steht noch
11. Filter setzen, Tab wechseln, zurueckkommen → `Alle` ist aktiv
12. Bibliothek, in der keine Meditation unter 5 Minuten liegt → `bis 5 Min` ist blass und reagiert nicht

---

## Mockup

```
Ausgangszustand                        Filter „5–15 Min" gesetzt
┌─────────────────────────────┐        ┌─────────────────────────────┐
│  🔍 Suchen           [+][i] │        │  🔍 Suchen           [+][i] │
│                             │        │                             │
│ (Alle) bis 5  5–15  15–30 → │        │  Alle  bis 5 (5–15) 15–30 → │
│                             │        │                             │
│  Sarah Kornfield            │        │  2 VON 7 MEDITATIONEN       │
│  ┌───────────────────────┐  │        │  ┌───────────────────────┐  │
│  │ Body Scan      15:42 ▶│  │        │  │ Mindful Breathing     │  │
│  │ Mindful Bre…    7:33 ▶│  │        │  │ Sarah Kornf… · 7:33 ▶ │  │
│  └───────────────────────┘  │        │  │ Loving Kindness       │  │
│  Tara Goldstein             │        │  │ Tara Golds… · 12:17 ▶ │  │
│  ┌───────────────────────┐  │        │  └───────────────────────┘  │
│  │ Evening Wind   19:05 ▶│  │        │                             │
│  └───────────────────────┘  │        │                             │
└─────────────────────────────┘        └─────────────────────────────┘

Suche aktiv, Filter bleibt             Kein Treffer
┌─────────────────────────────┐        ┌─────────────────────────────┐
│  🔍 b       ✕   Abbrechen   │        │  🔍 b       ✕   Abbrechen   │
│                             │        │                             │
│ (5–15 Min ✕)                │        │ (über 30 Min ✕)             │
│                             │        │                             │
│  1 VON 7 MEDITATIONEN       │        │           ( 🔍 )            │
│  ┌───────────────────────┐  │        │      Nichts gefunden        │
│  │ Mindful Breathing     │  │        │   Keine Meditation passt    │
│  │ Sarah Kornf… · 7:33 ▶ │  │        │   zu „b" in dieser Länge.   │
│  └───────────────────────┘  │        │                             │
│  ┌───── Tastatur ───────┐   │        │   ( Filter zurücksetzen )   │
└─────────────────────────────┘        └─────────────────────────────┘

„Body Scan" (15:42) fehlt — der Chip erklärt, warum.
```

---

## Referenz

- Design-Prototyp: Claude Design Projekt `019de814-768e-7f26-a63a-0a4ad225a65a`, Datei `prototypen/library-dauerfilter/Variante A - Zustände.html` — zeigt alle sechs Zustaende nebeneinander
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`, Suchzustaende in `ios/StillMoment/Domain/Services/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/`, Suchzustaende in `android/app/src/main/kotlin/com/stillmoment/domain/`

---

## Hinweise

**Vieles ist schon da.** Die flache Trefferliste mit Lehrer:in und Dauer in der Unterzeile, das Match-Highlight und eine Zaehlzeile existieren bereits aus der Suche (ios-041). Neu sind die Filterzeile, der Filter-Chip im Suchmodus und die flache Darstellung *ohne* Suche. Die Zaehlzeile bekommt nur einen neuen Text — kein neuer Baustein.

**Der Text der Zaehlzeile aendert sich.** Heute lautet er „%d Treffer". Der bestehende Schluessel wird umformuliert statt einen zweiten daneben zu legen, sonst driften Suche und Filter auseinander.

**Die Suchhistorie kollidiert mit dem Prototyp.** Der Prototyp kennt keine Historie; die App zeigt sie, wenn das Suchfeld fokussiert und leer ist. Der Filter-Chip muss deshalb ueber allen Suchzustaenden liegen, auch ueber der Historie — nicht nur ueber der Trefferliste.

**„Verlassen der Bibliothek" ist zweideutig.** Heute wird die Suche zurueckgesetzt, sobald die Bibliotheksansicht verschwindet — das passiert auch beim Oeffnen einer Meditation. Fuer den Filter waere das aergerlich: Wer nach kurzen Meditationen filtert, eine hoert und zurueckkommt, will seinen Filter wiederfinden. Nur der Tab-Wechsel soll zuruecksetzen.

**Plural in der Zaehlzeile.** „1 von 7 Meditationen" muss grammatisch aufgehen. iOS hat bereits eine `Localizable.stringsdict`; Android braucht einen Plural-Eintrag.

**Bewusst nicht Teil dieses Tickets.** Der Prototyp enthaelt zwei weitere Varianten, die verworfen wurden: ein einzelner aufklappender „Dauer"-Chip (Variante B) und Kurzlabels mit Trefferzahl plus Sortierung kurz→lang (Variante C). **Sortierung gehoert nicht in dieses Ticket** — sie ist ein eigenes Thema und wuerde die Filterzeile ueberladen.
