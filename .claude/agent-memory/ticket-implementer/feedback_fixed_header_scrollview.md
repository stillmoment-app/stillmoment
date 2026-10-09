---
name: fixed-header-scrollview
description: Fixierter Kopf ueber einer ScrollView — .safeAreaInset laesst den Inhalt sichtbar hinter dem Kopf durchlaufen; nur bei List clippt es. Kopf in einen VStack ueber die ScrollView setzen.
metadata:
  type: feedback
---

Ein Kopf, der beim Scrollen stehen bleiben soll, gehoert ueber einer
`ScrollView` in einen `VStack` — **nicht** in `.safeAreaInset(edge: .top)`.

**Why:** Die Bibliothek (`GuidedMeditationsListView`) setzt ihren Kopf per
`.safeAreaInset` ueber eine `List`, und dort schneidet iOS den Inhalt an der
Kante ab. Mit einer `ScrollView` tut es das nicht: Der Inhalt laeuft sichtbar
hinter dem Kopf durch, Ueberschrift und Zeilentexte liegen uebereinander
(gesehen am Simulator, shared-124 Folgen-Ansicht). Ein deckender Hintergrund am
Kopf hilft nicht sauber — der Seitenverlauf (`backgroundGradient`) ist
bildschirmhoch, eine einzelne Flaeche darunter erzeugt eine sichtbare Kante.

**How to apply:** Beim Uebertragen des Bibliotheks-Musters auf einen neuen
Screen zuerst pruefen, welcher Scroll-Container darunter liegt. `VStack { kopf;
ScrollView { … } }` im `ZStack` ueber dem Verlauf ist die einfache Loesung; der
Verlauf bleibt durchgehend, weil er `ignoresSafeArea()` hinter allem liegt. Der
Unterschied faellt **nur beim Scrollen** auf — ein Screenshot vom Seitenanfang
sieht in beiden Varianten identisch aus. Siehe
[[simulator-verification-setup]].
