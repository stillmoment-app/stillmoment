# Ticket shared-119: Vorbereitungszeit-Screen an neue Timer-Vorlage angleichen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: UI-Redesign mit Domain-Auswirkung — der Wertebereich der Vorbereitungszeit wandert von einer diskreten Preset-Liste auf einen gerasterten Slider-Bereich (Validierung + Default in beiden Domain-Modellen betroffen). Risiko liegt in der Cross-Platform-Konsistenz und der Migration des Default-Werts.
**Phase**: 4-Polish
**Plan**: [iOS](../plans/shared-119-ios.md) · [Android](../plans/shared-119-android.md)

---

## Was

Der Timer-Detail-Screen „Vorbereitungszeit" (Timer → Vorbereitungszeit) wird auf dasselbe gehobene Muster wie die bereits ueberarbeiteten Screens „Start & Ende" (shared-115) und „Intervall-Gongs" (shared-118) gebracht: Master-Schalter-Karte oben, darunter — nur wenn an — die Dauer-Auswahl ueber einen grossen Serif-Wert-Hero und einen gerasterten Slider. Die bisherige diskrete Options-Liste mit Haekchen entfaellt.

## Warum

Der Screen ist der letzte Timer-Detail-Screen im alten Listen-Stil und wirkt neben den ueberarbeiteten Geschwistern inkonsistent. Das Master-Switch-Muster macht den Aus-Zustand klarer und ruhiger; ein einzelnes Stellelement (Slider) statt einer Auswahlliste passt besser zum meditativen Charakter.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Oben eine Master-Karte mit Sanduhr-Icon, Titel „Vorbereitungszeit" und einem Schalter (an/aus).
- [ ] Der Karten-Untertitel traegt die einzige Zweck-Erklaerung: AN → „Eine kurze Stille vor dem Start", AUS → „Aus — der Timer startet sofort".
- [ ] Bei Schalter AN: Eyebrow-Label „DAUER", darunter ein grosser Serif-Wert-Hero (gewaehlte Sekundenzahl + Einheit „Sekunden"), darunter eine Slider-Karte.
- [ ] Der Slider ist gerastert auf 5-Sekunden-Schritte, Bereich 5–60 Sekunden, mit End-Labels „5 Sek." (links) und „1 Min." (rechts). Der Wert-Hero aktualisiert sich live beim Ziehen.
- [ ] Bei Schalter AUS: statt der Dauer-Auswahl ein kurzer Hilfetext, der zum Einschalten einlaedt.
- [ ] Aus- und Wieder-Einschalten stellt die zuletzt gewaehlte Dauer wieder her (kein Reset auf Default).
- [ ] Default-Dauer ist 10 Sekunden; gueltige Werte sind 5,10,15,…,60 (5er-Raster).
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell und im Verhalten konsistent zwischen iOS und Android.

### Tests
- [ ] Unit Tests iOS (Validierung/Default des neuen Wertebereichs, gemerkte Dauer)
- [ ] Unit Tests Android (dito)

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Timer-Tab → „Vorbereitungszeit" oeffnen.
2. Schalter ist an, Wert-Hero zeigt die gespeicherte Dauer, Slider darunter.
3. Slider ziehen: Wert-Hero aktualisiert live, rastet auf 5-Sekunden-Schritte.
4. Schalter aus: Wert-Hero + Slider verschwinden, Hilfetext erscheint.
5. Schalter wieder an: zuvor gewaehlte Dauer ist erhalten.
6. Zurueck, Screen erneut oeffnen: Auswahl persistiert.
7. Erwartung: identisches Verhalten auf iOS und Android.

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_vorbereitungszeit/` (README.md, vorbereitung-app.jsx, vorbereitung.css)
- Schwester-Redesigns (gleiches Muster): shared-115 (Start & Ende), shared-118 (Intervall-Gongs)
- iOS: `ios/StillMoment/Presentation/Views/Timer/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/`

---

## Hinweise

- **Wertebereich-Migration:** Bisher diskrete Liste `[5,10,15,20,30,45]`, Default 15. Neu: 5er-Raster 5–60, Default 10. Validierung und Default in beiden Domain-Modellen (iOS `MeditationSettings`, Android `Praxis`) anpassen. Bereits gespeicherte Werte (z.B. 45) liegen weiter im neuen Raster bzw. werden auf den naechsten 5er-Wert validiert.
- Nur Nacht-Theme ist im Handoff aktiv; die App nutzt ihre semantischen Tokens, nicht die hartkodierten CSS-Werte des Prototyps.
- Wiederverwendbare Komponenten der Schwester-Screens nutzen (Master-Switch-Karte, Karten-Hintergrund, Eyebrow, Slider-Karte) statt neu zu erfinden.
