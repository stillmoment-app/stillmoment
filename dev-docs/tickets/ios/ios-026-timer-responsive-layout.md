# Ticket ios-026: Timer View Responsive Layout

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das TimerView Layout soll sich besser an kleine Bildschirme (iPhone SE, 4.7") anpassen, sodass alle Elemente sichtbar und bedienbar bleiben.

## Warum

Auf dem iPhone SE wird der Start-Button vom Tab Bar abgeschnitten. Der User kann die Meditation nicht starten, ohne zu scrollen oder das Geraet zu drehen.

---

## Akzeptanzkriterien

- [x] Start-Button auf iPhone SE vollstaendig sichtbar
- [x] Alle UI-Elemente proportional zur Bildschirmhoehe skaliert
- [x] Keine visuellen Regressionen auf groesseren Geraeten (iPhone 15, Pro Max)
- [x] Kein Scrolling noetig im idle-State
- [x] Unit Tests geschrieben/aktualisiert (falls ViewModel betroffen)

---

## Manueller Test

1. App auf iPhone SE Simulator starten (oder 4.7" Geraet)
2. Timer-Tab oeffnen
3. Erwartung: Start-Button vollstaendig sichtbar, alle Elemente gut lesbar

4. Zusaetzlich: Auf iPhone 15 Pro Max testen
5. Erwartung: Layout sieht weiterhin gut aus, keine uebertriebenen Abstaende

---

## Referenz

- `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- Bestehende GeometryReader-Nutzung als Ausgangspunkt

---

## Hinweise

Das aktuelle Layout verwendet bereits `GeometryReader`, aber mit festen Mindesthoehen (`max(20, ...)`) die auf kleinen Bildschirmen zu viel Platz verbrauchen. Flexible `Spacer(minLength:)` und proportionale Groessen sind der bessere Ansatz.
