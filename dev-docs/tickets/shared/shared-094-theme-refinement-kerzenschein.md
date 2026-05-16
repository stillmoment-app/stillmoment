# Ticket shared-094: Theme-Refinement Kerzenschein 2.0

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mechanisch — zentralisiertes Theme-System ist nach shared-093 vorhanden, Refinement laeuft hauptsaechlich ueber Token-Werte plus zwei neue Tokens und einen wiederverwendbaren Shadow/Fade-Mechanismus. Risiko liegt in stillen visuellen Regressionen auf Screens, die nicht Teil der Validierung sind (Player, Settings-Sheets, Onboarding, Completion).
**Phase**: 4-Polish
**Plan (iOS)**: [Implementierungsplan](../plans/shared-094-ios.md)

---

## Was

Die einzige verbleibende Farbpalette (nach shared-093) wird auf Basis eines Design-Handovers verfeinert: Light wird gesaettigter (Sunrise statt Pastell), Dark bekommt waerme Karten und einen waermeren Border. Karten heben sich plastisch gegen den Gradient-Hintergrund ab, der Hauptknopf wirkt plastisch (Gradient + Highlight), und ein weicher Bottom-Fade trennt die Scroll-Region von der Tabbar. Die Tabbar bekommt Blur und einen warmen Akzent fuer den aktiven Tab.

## Warum

Die aktuelle Palette ist nach dem Reduzieren auf ein Theme (shared-093) bewusst noch unveraendert geblieben. Im aktuellen Zustand verschwinden Karten in einigen Hintergrundzonen (cardBackground = bg-top im Light), Borders wirken kuehl im warmen Kontext, der Hauptknopf bleibt flach, und der Uebergang Scroll/Tabbar ist hart. Ein gezieltes Refinement der zentralen Tokens und zweier wiederverwendbarer Komponenten (Karten-Hintergrund, Hauptknopf) propagiert die Verbesserung in alle Screens, ohne dass jeder Screen einzeln angefasst werden muss.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-093    |
| Android   | [ ]    | shared-093    |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, validiert wird an Library + Timer-Idle -->

### Karten-Lift gegen Gradient
- [ ] Eine Karte am oberen Rand der Scroll-Region (gegen den helleren Gradient-Stop) und eine Karte am unteren Rand (gegen den Akzent-Stop) lesen sich gleich gut als gehobene Elemente
- [ ] Im Dark Mode traegt die Karten-Helligkeit den Lift; im Light Mode traegt der warme Doppelschatten den Lift (weil weniger Luminance-Spielraum vorhanden ist)
- [ ] Border wirkt warm-getoent, nicht neutral/grau

### Hauptknopf "Beginnen"
- [ ] Der Knopf wirkt plastisch — kein flacher Volltonkupfer mehr, sondern mit subtilem vertikalem Verlauf und weichem Schlagschatten
- [ ] Das Play-Glyph und der Text sitzen in einer warmen Kontrast-Farbe (auf dem Verlauf gut lesbar in Light und Dark)

### Soft Fade unten
- [ ] Am unteren Rand der Scroll-Region laeuft der Inhalt sanft in den Akzent-Stop des Hintergrunds aus, statt hart an der Tabbar zu enden
- [ ] Der Fade liegt visuell zwischen Scroll-Content und Tabbar und blockiert keine Interaktionen
- [ ] Im Dark Mode wirkt der Fade als Mahagoni-Smoke, im Light Mode als Apricot-Smoke (jeweils transparent ueber dem Gradient)

### Tabbar
- [ ] Tabbar wirkt durch Blur ueber dem Hintergrund, nicht als opake Flaeche
- [ ] Tabbar hat einen warmen, dezenten Border zur Scroll-Region
- [ ] Der aktive Tab traegt eine warme, gut sichtbare Akzent-Pille (Label + Glyph im Akzent)
- [ ] In Light und Dark gleichermassen lesbar und vom Hintergrund klar abgesetzt

### Trennlinien zwischen Titel-Karten
- [ ] In der Library sind die Trennlinien zwischen mehreren Titeln derselben Lehrerin klar sichtbar — nicht hart, aber unverwechselbar
- [ ] Die Linie liegt farblich in der warmen Akzent-Familie, nicht in einem neutralen Grau

### Light-Mode-Palette gesaettigt
- [ ] Der Hintergrund wirkt als Sunrise-Verlauf — sichtbar gesaettigt, nicht pastellig/cremig
- [ ] Text und Akzent sind etwas tiefer/erdiger als zuvor, ohne den warmen Charakter zu verlieren

### Dark-Mode-Palette konsistent
- [ ] Gradient, Text und Akzent bleiben visuell konsistent mit dem aktuellen Dark-Mode-Eindruck
- [ ] Karten heben sich gegen alle drei Gradient-Stops ab (oben, mitte, Akzent unten)

### Allgemein
- [ ] Die Validierung erfolgt an Library und Timer-Idle, beide in Light und Dark, sowohl am oberen Scroll-Rand als auch ueber den Akzent-Stop gescrollt
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Kontrast-Tests (WCAG) decken die neuen Token-Werte in Light und Dark ab
- [ ] Bestehende Snapshot-/Screenshot-Tests werden gegen die neuen Werte aktualisiert (nicht ausgeblendet)
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md — user-sichtbare visuelle Verfeinerung
- [ ] CLAUDE.md auf beiden Plattformen pruefen: Verweise auf alte Card-/Shadow-Werte aktualisieren falls vorhanden

---

## Manueller Test

1. App im Light Mode oeffnen, Library-Tab
2. Bis zum unteren Rand scrollen, sodass eine Karte ueber dem Akzent-Stop des Gradienten liegt
3. Erwartung: Karte hebt sich sichtbar ab, Border und Schatten wirken warm; der Inhalt laeuft am unteren Rand sanft in den Akzent aus, ohne harten Schnitt zur Tabbar
4. In Dark Mode wechseln, gleiche Stelle
5. Erwartung: Karte hebt sich durch Helligkeit ab, Border ist warm-braun, kein neutraler Grau-Schimmer
6. Timer-Tab oeffnen (Idle), "Beginnen"-Knopf betrachten
7. Erwartung: Plastischer Verlauf, weicher Schlagschatten, Glyph + Text gut lesbar
8. Tabbar in beiden Modi betrachten
9. Erwartung: Blur sichtbar, aktiver Tab durch warme Akzent-Pille gekennzeichnet

---

## Referenz

- Design-Handover: `handoffs/claude_code_handoff_kerzenschein_2/` (README + HTML-Vorschau)
- Vorgaenger-Ticket: shared-093 (Theme-System auf ein Theme reduziert)
- Verwandte Tickets: shared-032 (Themes eingefuehrt), shared-033 (Paletten finalisiert), shared-035 (Kontrast-Audit), ios-035 (Card visuelle Separation), ios-038 (Tab-Bar aktiver Tab)

---

## Hinweise

- Die Token-Werte (Hex, Opacities, Shadow-Stops, Stroke-Widths) im Handover sind final und pixelgenau zu uebernehmen — das ist die Lieferung.
- Validierung bewusst nur an zwei Screens (Library + Timer-Idle). Andere Screens (Player, Settings-Sheets, Onboarding, Completion) erben die Tokens automatisch; etwaige Ausreisser werden in einem zweiten Sweep nach diesem Refinement adressiert.
- Running Timer (Sanduhr-Vessel, ios-046) hat eigene, vom Theme entkoppelte Farben und ist von diesem Refinement nicht betroffen.
- UIKit-bridged Controls (z. B. Tabbar-Hintergrund) brauchen ggf. eine `.id(theme)`-Strategie, falls sie nach Theme/Mode-Wechsel nicht aktualisieren — vgl. MEMORY-Notiz zu UIAppearance.
- Persistierter `ColorTheme`-State ist nach shared-093 obsolet und sollte hier nicht erneut auftauchen.

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Konkrete Hex-Werte (stehen im Handover)
- Token-Namen (cardShadow, fadeMid etc. sind Implementierungsdetail)
- Dateilisten / Pfade
-->
