# Ticket shared-110: Meditation-Editor als Vollbild-Screen mit Discard-Schutz

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE → **[x] DONE**
**Prioritaet**: MITTEL
**Komplexitaet**: Navigations-Umbau (Sheet/BottomSheet → Vollbild-Screen) auf beiden Plattformen; Risiko liegt im Zusammenspiel mit dem bestehenden Trim-Editor (heute fullScreenCover) und im Import-Flow, der dieselbe Komponente nutzt.
**Phase**: 2-Architektur
**Plan**: [iOS](../plans/shared-110-ios.md) · [Android](../plans/shared-110-android.md)

---

## Was

Der Editor zum Bearbeiten gefuehrter Meditationen (und der inhaltsgleiche Import-Editor) wird von einem modalen Sheet/BottomSheet zu einem Vollbild-Navigations-Screen. Beim Verlassen mit ungespeicherten Aenderungen erscheint eine Rueckfrage ("Aenderungen verwerfen?" / "Weiter bearbeiten").

## Warum

`dev-docs/reference/ux-conventions.md` §1 ordnet Editoren mit mehreren Sektionen (Metadaten, Wiedergabe-Bereich, Gong-Einstellungen) dem Vollbild-Screen zu — konsistent zum Praxis-Editor. Das loest zugleich die heutige Modal-im-Modal-Konstruktion auf (der Trim-Editor oeffnet als fullScreenCover aus einem Sheet). §3 verlangt Schutz vor stillem Datenverlust: aktuell verwerfen beide Plattformen ungespeicherte Edits kommentarlos beim Swipe-down / X / Back.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Der Meditation-Editor wird als Vollbild-Screen praesentiert (nicht als Sheet/BottomSheet).
- [x] Der Import oeffnet denselben Editor als Vollbild-Screen.
- [x] Save (rechts) und Cancel (links) bleiben in der Top-Bar; Save validiert wie bisher.
- [x] Verlassen ohne Aenderungen schliesst sofort und kommentarlos.
- [x] Verlassen mit ungespeicherten Aenderungen (X, Back, Swipe/Geste) zeigt eine Rueckfrage mit "Verwerfen" / "Weiter bearbeiten".
- [x] Der Trim-Editor bleibt erreichbar und verliert keine Funktion durch den Umbau. (iOS: fullScreenCover aus dem Screen; Android: Trim nicht vorhanden — n/a)
- [x] Lokalisiert (DE + EN).
- [x] Visuell konsistent zwischen iOS und Android.

### Tests
- [x] Unit Tests iOS
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Meditation bearbeiten oeffnen, ein Feld aendern, ohne Speichern zurueck/X/Swipe.
2. Erwartung: Rueckfrage erscheint; "Weiter bearbeiten" kehrt zurueck, "Verwerfen" schliesst ohne Speichern.
3. Import einer Datei starten → Editor oeffnet als Vollbild-Screen, nicht als Sheet.
4. Editor oeffnen, nichts aendern, verlassen → schliesst sofort ohne Rueckfrage.
5. Erwartung: identisches Verhalten auf iOS und Android.

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Praesentation | Navigation-Destination | Navigation-Screen |
| Rueckfrage bei Discard | `confirmationDialog` | `AlertDialog` |
| Verlassen-Geste abfangen | Swipe-/Back-Navigation | System-Back (`BackHandler`) |

---

## Referenz

- Soll: `dev-docs/reference/ux-conventions.md` §1, §3
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/` (Editor + Trim-Editor)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/`

---

## Hinweise

- Import und Edit teilen sich dieselbe Komponente (Mode-Flag) — der Umbau betrifft beide Modi gleichzeitig (siehe ux-conventions.md §4).
- Der Trim-Editor nutzt heute bewusst `fullScreenCover`, um versehentliches Wischen zu verhindern. Wird der Editor selbst ein Screen, kann diese Sonderkonstruktion entfallen.
- Trim selbst ist nicht Teil dieses Tickets (Android-Trim siehe shared-105 ff.).
