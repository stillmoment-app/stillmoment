# Ticket shared-081: Filter nach Dauer in der Meditationsliste

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Gering. Reine Presentation-Layer-Logik — kein neues Datenmodell, nur Filterung der bestehenden Liste im ViewModel.
**Phase**: 3-Feature

---

## Was

Die Meditationsliste soll nach Dauer filterbar sein. Über der Liste erscheinen Filter-Pills mit festen Dauerkategorien. Der Filter ist eine Einzelauswahl und setzt sich beim Verlassen des Tabs zurück.

## Warum

User wählen Meditationen oft nach verfügbarer Zeit. Wer gerade 8 Minuten hat, soll nicht durch 30-minütige Meditationen scrollen müssen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Filter-Pills erscheinen über der Meditationsliste, sobald mindestens 2 verschiedene Dauerkategorien in der Library belegt sind
- [ ] Bei leerer Library oder wenn alle Meditationen in dieselbe Kategorie fallen: kein Filter sichtbar
- [ ] Feste Buckets (nur befüllte werden angezeigt): `Alle` · `bis 10 Min` · `10–20 Min` · `über 20 Min`
- [ ] Einzelauswahl: nur ein Bucket gleichzeitig aktiv
- [ ] Aktiver Bucket ist visuell hervorgehoben
- [ ] Erneutes Tippen auf den aktiven Bucket kehrt zu „Alle" zurück
- [ ] Nach Auswahl eines Buckets zeigt die Liste ausschließlich Meditationen der gewählten Kategorie
- [ ] Filter setzt sich zurück, sobald der User den Tab verlässt
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests

- [ ] Unit Tests: Filterlogik (korrekter Bucket je Dauer, Grenzwerte 10 Min / 20 Min)
- [ ] Unit Tests: Filter-Sichtbarkeit (erscheint nur bei 2+ Buckets)
- [ ] Unit Tests: Reset-Verhalten beim Tab-Wechsel

### Dokumentation

- [ ] CHANGELOG.md

---

## Manueller Test

1. Library mit Meditationen unterschiedlicher Dauer öffnen (z.B. 5 Min, 15 Min, 35 Min)
2. Filter-Pills erscheinen: `Alle · bis 10 Min · 10–20 Min · über 20 Min`
3. „bis 10 Min" tippen → Liste zeigt nur die 5-Min-Meditation, Pill ist hervorgehoben
4. „bis 10 Min" erneut tippen → zurück zu „Alle", alle Meditationen sichtbar
5. Tab wechseln und zurückkehren → Filter ist auf „Alle" zurückgesetzt
6. Library mit nur 8-Min-Meditationen: kein Filter sichtbar

---

## Mockup

```
┌─────────────────────────────────┐
│  Meditationen                   │
│                                 │
│  ┌──────┐ ┌─────────┐ ┌──────┐ │
│  │ Alle │ │bis 10Min│ │10-20 │ │
│  └──────┘ └─────────┘ └──────┘ │
│                                 │
│  Morgenmeditation        8 Min  │
│  Körper-Scan             18 Min │
│  Atemübung               5 Min  │
│  Tiefe Stille            25 Min │
└─────────────────────────────────┘

         — nach Tap auf "bis 10 Min" —

┌─────────────────────────────────┐
│  Meditationen                   │
│                                 │
│  ┌──────┐ ┌═════════╗ ┌──────┐ │
│  │ Alle │ ║bis 10Min║ │10-20 │ │
│  └──────┘ ╚═════════╝ └──────┘ │
│                                 │
│  Morgenmeditation        8 Min  │
│  Atemübung               5 Min  │
│                                 │
└─────────────────────────────────┘
```

---

## Hinweise

- Bucket-Grenzen: `< 10 Min` / `10 Min ≤ x ≤ 20 Min` / `> 20 Min` — exakt 10 Min fällt in „bis 10 Min", exakt 20 Min in „10–20 Min"
