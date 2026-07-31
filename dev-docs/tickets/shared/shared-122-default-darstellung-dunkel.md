# Ticket shared-122: Dunkle Darstellung als Standard

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Trivial — ein Standardwert je Plattform. Das Risiko liegt nicht im Code, sondern im Verhalten fuer Bestandsuser (siehe Hinweise).
**Phase**: 1-Quick Fix

---

## Was

Neue User sollen die App in dunkler Darstellung erleben, unabhaengig davon ob ihr Geraet auf hell oder dunkel steht. Bisher folgt die App standardmaessig der Systemeinstellung.

## Warum

Die App soll sich wie eine Pause anfuehlen — die dunkle Darstellung traegt diese Ruhe, ist abends augenschonend und ist das Bild, mit dem die App im Store praesentiert wird. Wer beim ersten Start in der hellen Variante landet, sieht eine andere App als die beworbene. Die Wahlmoeglichkeit bleibt vollstaendig erhalten.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Nach einer Neuinstallation startet die App in dunkler Darstellung, auch wenn das Geraet auf helle Darstellung eingestellt ist
- [ ] In den Einstellungen ist "Dunkel" als aktive Auswahl sichtbar
- [ ] "System", "Hell" und "Dunkel" bleiben unveraendert waehlbar und wirken sofort
- [ ] Eine vom User getroffene Auswahl bleibt nach App-Neustart erhalten und gewinnt gegen den Standardwert
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (Standardwert ist dunkel; gespeicherte Auswahl gewinnt gegen Standardwert)
- [ ] Unit Tests Android (dito)

### Dokumentation
- [ ] CHANGELOG.md — user-sichtbare Aenderung, inklusive Hinweis fuer Bestandsuser

---

## Manueller Test

1. App deinstallieren, Geraet auf helle Darstellung stellen
2. App installieren und starten
3. Erwartung: App erscheint dunkel; Einstellungen zeigen "Dunkel" als Auswahl
4. Auf "System" umstellen
5. Erwartung: App wird hell (Geraet steht auf hell)
6. App beenden und neu starten
7. Erwartung: App bleibt bei "System", der Standardwert ueberschreibt die Auswahl nicht

---

## Referenz

- iOS: `ios/StillMoment/Domain/Models/`, `ios/StillMoment/Presentation/Theme/`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/`

---

## Hinweise

**Bestandsuser wechseln mit — bewusst akzeptiert.** Wer die Darstellung nie selbst gewaehlt hat, hat keinen gespeicherten Wert; diese User landen mit dem Update in der dunklen Darstellung, auch wenn ihr Geraet auf hell steht. Eine Unterscheidung zwischen Neuinstallation und Update ist nicht verlaesslich moeglich — es gibt keinen First-Launch-Marker in der App, und ein neu eingefuehrter waere bei Update-Usern genauso leer wie bei Neuinstallationen. Entscheidung: keine Migrationsheuristik bauen, die Umstellung ist einen Tap entfernt. In den Release Notes erwaehnen.

**Screenshot-Automatisierung.** Beide Plattformen setzen die Darstellung fuer Screenshot-Laeufe explizit und sind daher nicht betroffen. Nur ein iOS-Lauf ohne explizite Angabe rendert kuenftig dunkel statt hell — beim Erzeugen heller Varianten die Angabe also setzen.
