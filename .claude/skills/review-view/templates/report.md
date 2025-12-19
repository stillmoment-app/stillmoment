# View Quality Report: {ViewName}

**Datum**: {YYYY-MM-DD HH:MM}
**Keyword**: {keyword}
**Plattformen**: iOS + Android

---

## Gefundene Dateien

### iOS
- Views: {Liste der View-Dateien}
- ViewModels: {Liste der ViewModel-Dateien}
- Tests: {Liste der Test-Dateien}

### Android
- Screens: {Liste der Screen-Dateien}
- ViewModels: {Liste der ViewModel-Dateien}
- Tests: {Liste der Test-Dateien}

---

## Gesamt-Score: {X}/100

| Kategorie | iOS | Android | Gesamt | Cross-Platform |
|-----------|-----|---------|--------|----------------|
| Accessibility | {X}/25 | {X}/25 | {X}/25 | {Status} |
| Code-Qualität | {X}/25 | {X}/25 | {X}/25 | {Status} |
| Test-Coverage | {X}/25 | {X}/25 | {X}/25 | {Status} |
| UX/Layout | {X}/25 | {X}/25 | {X}/25 | {Status} |
| **Gesamt** | **{X}/100** | **{X}/100** | **{X}/100** | |

**Cross-Platform Status:**
- Konsistent: Beide Plattformen erfüllen Kriterium gleich gut
- Abweichung: Eine Plattform besser als andere
- Inkonsistent: Signifikante Unterschiede

---

## Bewertung

| Score | Kategorie |
|-------|-----------|
| 90-100 | Exzellent |
| 75-89 | Gut |
| 60-74 | Verbesserungswürdig |
| < 60 | Kritisch |

**Gesamt-Bewertung**: {Exzellent/Gut/Verbesserungswürdig/Kritisch}

---

## Findings

### Kritisch (Tickets erstellt)

{Für jedes kritische Finding:}
- **{Kategorie}**: {Beschreibung}
  - Plattform: {iOS/Android/Beide}
  - Ticket: {platform}-{NNN}
  - Abzug: {X} Punkte

### Verbesserungswürdig

{Für jedes mittlere Finding:}
- **{Kategorie}**: {Beschreibung}
  - Plattform: {iOS/Android/Beide}
  - Empfehlung: {Was tun}
  - Abzug: {X} Punkte

### Gut umgesetzt

{Für jeden positiven Aspekt:}
- **{Kategorie}**: {Was gut gemacht wurde}

---

## Cross-Platform Vergleich

### Feature-Parity
| Feature | iOS | Android | Status |
|---------|-----|---------|--------|
| {Feature 1} | {Ja/Nein} | {Ja/Nein} | {Konsistent/Lücke} |
| {Feature 2} | {Ja/Nein} | {Ja/Nein} | {Konsistent/Lücke} |

### Platform-Guidelines
- **iOS**: {Befolgt HIG? Details}
- **Android**: {Befolgt Material Design? Details}

### Konsistenz-Bewertung
{Zusammenfassung: Sind beide Plattformen konsistent implementiert?}

---

## Erstellte Tickets

| Ticket | Plattform | Phase | Beschreibung |
|--------|-----------|-------|--------------|
| {platform}-{NNN} | {iOS/Android/Shared} | {Phase} | {Kurzbeschreibung} |

**INDEX.md aktualisiert**: {Ja/Nein}

---

## Empfehlungen

### Priorität 1 (Sofort)
{Liste der wichtigsten Verbesserungen}

### Priorität 2 (Bald)
{Liste der mittelfristigen Verbesserungen}

### Priorität 3 (Nice-to-have)
{Liste der optionalen Verbesserungen}

---

## Nächste Schritte

1. {Erster Schritt}
2. {Zweiter Schritt}
3. {Dritter Schritt}

---

*Generiert mit `/review-view {keyword}`*
