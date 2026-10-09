---
name: tap-by-id-offscreen
description: scripts/screenshot-ios/tap_by_id.sh tippt auch auf Elemente ausserhalb des sichtbaren Bereichs (y > Bildschirmhoehe) — vorher scrollen, sonst Fehl-Taps
metadata:
  type: feedback
---

`tap_by_id.sh` nimmt den AXFrame aus dem UI-Dump ohne Sichtbarkeitspruefung. Liegt das
Element in einer ScrollView unterhalb des Bildschirms (z.B. y=1083 bei 932 pt Hoehe),
meldet das Script trotzdem "Tap completed" — der Tap trifft ins Leere oder auf ein anderes
Element, und Folgeschritte (Screenshot, weitere Taps) laufen auf einem falschen Zustand.
In shared-137 oeffnete so ein Folge-Tap unbemerkt Safari.

**Why:** Die gemeldete Erfolgsmeldung taeuscht; erst der Screenshot zeigt den falschen Zustand.

**How to apply:** Vor `tap_by_id` auf Elemente weiter unten in Sheets/Listen erst per
`swipe.sh` scrollen, oder die y-Koordinate im Dump gegen die Bildschirmhoehe pruefen.
Nach jeder Tap-Kette einen Screenshot ansehen, bevor weitergemacht wird.
Siehe [[ios-visual-verification]].
