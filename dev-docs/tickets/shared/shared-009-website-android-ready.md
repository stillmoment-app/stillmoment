# Ticket shared-009: Website fuer iOS + Android anpassen

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Website ~1h
**Phase**: 4-Polish

---

## Was

Die GitHub Pages Website so anpassen, dass sie nicht mehr den Eindruck einer reinen iOS-App erweckt, sondern beide Plattformen (iOS + Android) kommuniziert.

## Warum

- Android-Release steht bevor
- Aktuelle Website erwaehnt nur iOS in Meta-Tags, Footer und Privacy Policy
- Android-Nutzer sollen sich angesprochen fuehlen
- SEO: "iOS & Android" Keywords fuer bessere Auffindbarkeit

---

## Plattform-Status

| Bereich | Status |
|---------|--------|
| Footer  | [x]    |
| Meta-Tags | [x]  |
| Privacy Policy | [x] |

---

## Akzeptanzkriterien

- [ ] Footer zeigt "for iOS & Android" (EN) / "fuer iOS & Android" (DE)
- [ ] Meta description erwaehnt beide Plattformen
- [ ] Meta keywords enthalten "iOS" und "Android"
- [ ] Open Graph + Twitter Cards erwaehnen beide Plattformen
- [ ] Privacy Policy Datum aktualisiert (December 21, 2025)
- [ ] Privacy Policy erwaehnt beide Plattformen im Overview
- [ ] iOS-spezifische Begriffe in Privacy Policy generalisiert
- [ ] Google Play Store Guidelines in Compliance Section ergaenzt
- [ ] Lokalisiert (DE + EN)

---

## Aenderungen im Detail

### Footer (`docs/_includes/footer.html`)

```
Alt: "A warmhearted meditation app for iOS"
Neu: "A warmhearted meditation app for iOS & Android"
```

### Index Meta-Tags (`docs/index.html`)

| Zeile | Alt | Neu |
|-------|-----|-----|
| 8 | "meditation app for iOS" | "meditation app for iOS & Android" |
| 9 | "iOS meditation app" | "iOS, Android meditation app" |
| 16 | "app for iOS" | "app for iOS & Android" |
| 23 | "app for iOS" | "app for iOS & Android" |

### Privacy Policy (`docs/privacy.html`)

| Bereich | Aenderung |
|---------|-----------|
| Last Updated | November 8, 2024 → December 21, 2025 |
| Overview | "for iOS" → "for iOS & Android" |
| File Access | "iOS file picker" → "system file picker" |
| Data Storage | iOS-spezifische Begriffe generalisieren |
| Compliance | Google Play Store Developer Policy ergaenzen |

**Data Storage Details:**
- "iOS UserDefaults" → "local app storage (UserDefaults on iOS, DataStore on Android)"
- "security-scoped bookmarks" → "secure file references"

---

## Manueller Test

1. Website lokal mit Jekyll starten (optional)
2. Sprache auf EN stellen → Footer pruefen
3. Sprache auf DE stellen → Footer pruefen
4. Privacy Policy aufrufen → Datum und Texte pruefen
5. Page Source anzeigen → Meta-Tags pruefen

---

## Bereits erledigt

- [x] Android "Coming Soon" Button hinzugefuegt (index.html + styles.css)

---

## Referenz

- `docs/_includes/footer.html`
- `docs/index.html`
- `docs/privacy.html`
- `docs/styles.css` (bereits angepasst fuer Coming Soon Button)

---

## Hinweise

- Screenshots bleiben vorerst iPhone-only (Industry Standard)
- Wenn Android live ist: "Coming Soon" Button durch echten Play Store Link ersetzen
- Bei Android-Release: /review-website Skill fuer Gesamtpruefung nutzen

---
