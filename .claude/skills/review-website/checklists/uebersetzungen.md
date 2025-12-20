# Uebersetzungen

DE/EN Sprachversionen muessen vollstaendig und konsistent sein.

## Pruefmethode

Die Website verwendet CSS-Klassen fuer Sprachumschaltung:
- `lang-en` fuer englische Inhalte
- `lang-de` fuer deutsche Inhalte

### Automatischer Check

```bash
# Zaehle Elemente pro Sprache (sollten gleich sein)
grep -c "lang-en" docs/index.html
grep -c "lang-de" docs/index.html

grep -c "lang-en" docs/support.html
grep -c "lang-de" docs/support.html
```

**Melden wenn:** Anzahl unterschiedlich = fehlende Uebersetzung

### Manueller Check

Fuer jedes `lang-en` Element muss es ein `lang-de` Aequivalent geben:

```html
<!-- Korrekt -->
<h1 class="lang-en">A warmhearted meditation app</h1>
<h1 class="lang-de hidden">Eine warmherzige Meditations-App</h1>

<!-- Fehler: DE fehlt -->
<p class="lang-en">Some text without German translation</p>
```

## Zu pruefen

### Alle Seiten
- index.html
- support.html
- (privacy.html und impressum.html sind nur in einer Sprache - OK)

### Elemente
- Alle Ueberschriften (h1, h2, h3)
- Alle Absaetze in Content-Bereichen
- Alle Buttons und Links
- Alle Feature-Cards
- Alle FAQ-Eintraege
- Footer und Header

## Screenshots

```bash
# Screenshot-Dateien pruefen
ls docs/images/screenshots/

# Erwartetes Muster:
# timer-main.png (EN)
# timer-main-de.png (DE)
```

## NICHT pruefen

- Qualitaet der Uebersetzung (inhaltlich korrekt annehmen)
- Rechtschreibung
- Grammatik
