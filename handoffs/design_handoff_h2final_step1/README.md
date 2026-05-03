# Handoff: Timer-Konfiguration — Schritt 1

**Sitzungs-Settings wandern aus dem dedizierten Settings-Screen heraus auf den Timer-Konfigurations-Screen.**

> **Hinweis zum Scope:** Dieser Handoff betrifft **nur** Schritt 1 von drei geplanten Schritten in Richtung "H2-Final".
> Die Umstellung der zentralen Zeitauswahl vom Number-Picker auf den Atemkreis ist **bewusst nicht Teil** dieses Tickets — sie kommt in Schritt 2.
> Der Number-Picker bleibt also unverändert; geändert wird ausschließlich, *wo* und *wie* die fünf Sitzungs-Settings angezeigt und geöffnet werden.

---

## Worum geht es

### Vorher
- Auf dem Idle/Konfig-Screen liegen unter dem Minuten-Picker drei kleine Pillen (`Tempelglocke · Stille · 5 Min.`). Diese Pillen sind tippbar und öffnen Settings, sehen aber wie dekorative Tags aus. Tester verstehen das nicht.
- **Vorbereitung** und **Einstimmung** sind aktuell nur über einen separaten Settings-Screen erreichbar — also versteckt.
- Insgesamt fünf Sitzungs-Settings, drei davon halb-sichtbar, zwei ganz versteckt.

### Nachher
- Direkt unter dem Minuten-Picker erscheinen **fünf eindeutig tippbare Karten** — eine pro Setting:
  1. Vorbereitung
  2. Einstimmung
  3. Hintergrund (Ambient)
  4. Gong
  5. Intervall
- Jede Karte zeigt: Label · Icon · aktueller Wert. On/Off-State sichtbar über Opazität.
- Tap auf eine Karte öffnet das **bereits existierende Detail-Sheet/Subscreen** für dieses Setting. Keine neuen Sheets, keine neue Logik.
- Der dedizierte Settings-Screen für Sitzungs-Settings entfällt. (Falls dort noch App-Settings wie Theme, Konto etc. liegen, bleiben die in einem reduzierten Settings-Tab — diese App-Ebene ist nicht Teil dieses Tickets.)

---

## Was ändert sich technisch

### Im Scope dieses Tickets

1. **Idle-Screen UI** — fünf neue Setting-Karten unter dem Picker. Layout: 3 Karten oben (Vorbereitung, Einstimmung, Hintergrund), 2 Karten unten (Gong, Intervall). Siehe Prototyp.
2. **Routing** — die fünf existierenden Detail-Sheets/Subscreens müssen vom Idle-Screen aus geöffnet werden können (zusätzlich zum bisherigen Eintrittsweg über den Settings-Screen).
3. **Alter Settings-Screen** — die Liste der Sitzungs-Settings entfällt. Falls der Settings-Tab dadurch leer wird: Tab entfernen oder auf App-Settings reduzieren (Theme, Konto, Über die App, …).

### Explizit **nicht** im Scope

- ❌ **Zentrale Zeitauswahl umbauen** (Number-Picker → Atemkreis) — kommt in Schritt 2.
- ❌ Atmosphärische Politur (Sternenhimmel, Halos, 2-zeilige Werte) — kommt in Schritt 3.
- ❌ Neue Settings einführen.
- ❌ Sitzungs-Engine anfassen — alle Phasen (inkl. Vorbereitungs-Pre-Roll und Einstimmung) sind bereits implementiert.
- ❌ Detail-Sheets/Subscreens neu bauen — alle fünf existieren bereits in der App.
- ❌ State-Schema ändern — die `on/off`- und Wert-Felder existieren bereits in der App-State.

---

## Die fünf Setting-Karten — Inhalt

| Karte | Label | Wert (Beispiel) | Wenn aus |
|---|---|---|---|
| Vorbereitung | `Vorbereitung` | `15 Sek.` | `Aus` |
| Einstimmung | `Einstimmung` | `Atem-Anker` | `Ohne` |
| Hintergrund | `Hintergrund` | `Regen` | `Stille` |
| Gong | `Gong` | `Tempelglocke` | (immer an) |
| Intervall | `Intervall` | `5 Min.` | `Aus` |

Wert-Texte folgen dem Pattern *„kurzer, lesbarer Wert in einer Zeile"*. Bei Bedarf Ellipsis (`…`).

---

## Setting-Karte — Spezifikation

- **Container**: `border-radius: 16`, Hintergrund `linear-gradient(180deg, rgba(235,226,214,0.045), rgba(235,226,214,0.015))`, Border `1px solid rgba(235,226,214,0.08)`.
- **Padding**: `12px 12px 11px`.
- **Layout**: vertikal gestapelt, zentriert, Gap `7px` — Label oben, Icon Mitte, Wert unten.
- **Label**: Geist 9.5, weight 500, uppercase, letter-spacing `0.14em`, Farbe `--sm-text-3`. Eine Zeile mit Ellipsis.
- **Icon**: 24×24, Farbe `--sm-accent-text`. Ikonografie aus dem bestehenden System (Sanduhr, Sparkle, Wave, Bell, Refresh).
- **Wert**: Newsreader 12, Farbe `--sm-text-2`, Eine Zeile mit Ellipsis.
- **Off-State**: gesamte Karte auf `opacity: 0.45`. Kein Toggle direkt auf der Karte — das Umschalten passiert im jeweiligen Detail-Sheet.
- **Tap-Verhalten**: öffnet das vorhandene Detail-Sheet/Subscreen für dieses Setting.
- **Press-State**: 0.98 scale, 150ms ease (bestehendes `.press`-Pattern).

---

## Layout auf dem Konfig-Screen (oben → unten)

```
┌─────────────────────────────┐
│ Status Bar                  │
├─────────────────────────────┤
│   Schön, dass du da bist    │   ← bestehender Greeter, unverändert
│                             │
│   ┌───────────────────┐     │
│   │   Number-Picker   │     │   ← BLEIBT (Schritt 2 ändert das)
│   │       10          │     │
│   └───────────────────┘     │
│         Minuten             │
│                             │
│   ┌────┬────┬────┐          │
│   │Vorb│Eins│Hint│          │   ← NEU: 5 Setting-Karten
│   │tg. │tim.│grnd│          │
│   └────┴────┴────┘          │
│   ┌────────┬────────┐       │
│   │  Gong  │Intervll│       │
│   └────────┴────────┘       │
│   Tippen, um anzupassen     │
│                             │
│       ▶  Beginnen           │
├─────────────────────────────┤
│ Tab Bar                     │
└─────────────────────────────┘
```

Spalten: `gap: 8`, äußeres Padding `0 18px`. Erste Reihe `1fr 1fr 1fr`, zweite Reihe `1fr 1fr`.

---

## Akzeptanzkriterien

- [ ] Auf dem Timer-Konfigurations-Screen erscheinen unter dem Minuten-Picker fünf Setting-Karten in der Reihenfolge Vorbereitung · Einstimmung · Hintergrund · Gong · Intervall.
- [ ] Jede Karte zeigt Label, Icon und aktuellen Wert; der On/Off-Zustand ist sichtbar.
- [ ] Tap auf eine Karte öffnet das jeweilige existierende Detail-Sheet/Subscreen.
- [ ] Der bisherige dedizierte Settings-Screen für **Sitzungs**-Settings ist entfernt (oder, falls App-Settings dort weiterleben, auf diese reduziert).
- [ ] Die kryptischen Pillen unter dem Picker sind entfernt.
- [ ] Keine Änderung an der Sitzungs-Engine.
- [ ] Keine Änderung am Number-Picker (das ist Schritt 2).
- [ ] Funktioniert in allen drei Themes (warm/sage/dusk) und in beiden Locales (DE/EN).

---

## Dateien in diesem Bundle

- `Timer Config Step 1.html` — der Vorher/Nachher-Prototyp, der die UI-Änderung im Browser zeigt.
- `timer-config-step1.jsx` — React/HTML-Referenz-Implementierung der Setting-Karte und des neuen Layouts. **Reine Referenz, keine Produktiv-Code-Vorlage.**
- `shell.jsx` — geteilte Phone-Shell-Komponenten (Status Bar, Tab Bar, Icon Set). Reine Referenz.
- `styles.css` — vollständige Design-Tokens für das warme Theme. Source-of-Truth für Farb- und Typo-Werte.

Implementiert wird auf der jeweiligen Plattform mit den dort etablierten Komponenten und Theme-Tokens — siehe das Pattern aus dem `shared-039`-Handoff.
