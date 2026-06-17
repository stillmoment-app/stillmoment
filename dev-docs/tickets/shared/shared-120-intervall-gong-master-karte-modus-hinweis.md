# Ticket shared-120: Intervall-Gong-Screen — Master-Karte, Modus-Hinweis & Off-Zustand

**Status**: [x] DONE
**Plan**: inline (siehe Abschnitt „Spezifikation")
**Prioritaet**: NIEDRIG
**Komplexitaet**: Reines Presentation-Polish auf einem bestehenden Screen. Risiko gering; einzige Substanz ist der dynamische, plural-korrekte Modus-Hinweistext (erstmals `Localizable.stringsdict` auf iOS bzw. `<plurals>` auf Android).
**Phase**: 4-Polish

---

## Was

Der Intervall-Gong-Screen (Timer → Intervall-Gongs) wird gemäß Design-Handoff `handoffs/intervall-gongs/` um die letzten Elemente vervollständigt, die shared-118 (nur Klang-Auswahl) noch offen ließ:

1. Der schlichte An-/Aus-Toggle wird zu einer **Master-Karte** mit führendem Icon (wiederkehrend) und einem **zustandsabhängigen Untertitel**.
2. Im **Aus-Zustand** erscheint unter der Master-Karte ein erklärender Hinweistext (statt einer leeren Fläche).
3. **Intervall** und **Modus** werden in **zwei getrennte Eyebrow-Sektionen** aufgeteilt (bisher in einer kombinierten Karte).
4. Unter der Modus-Auswahl erscheint ein **dynamischer Hinweistext**, der die Bedeutung des gewählten Modus inkl. Intervall-Dauer in ganzen Sätzen erklärt.

## Warum

shared-118 hat den Screen optisch auf das Karten-Layout gehoben, aber nur die Klang-Auswahl. Der Handoff `intervall-gongs` zeigt den vollständigen Screen: Die Master-Karte macht den An-/Aus-Zustand ruhig erfahrbar, und vor allem der Modus-Hinweis erklärt in nicht-technischer Sprache, was „Regelmäßig / Nach Start / Vor Ende" konkret bedeutet — heute muss der Nutzer das raten. Das senkt die Schwelle, die Intervall-Gongs überhaupt sinnvoll einzustellen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-118    |
| Android   | [x]    | shared-118    |

---

## Spezifikation (verbindlich für beide Plattformen)

Reihenfolge der Sektionen im Screen (von oben), wenn **eingeschaltet**:

1. **Master-Karte** (immer sichtbar): führendes Icon (wiederkehrend/„repeat"), Titel „Intervall-Gongs", Untertitel, rechts der Schalter.
2. Eyebrow **„Intervall"** + Karte mit nur dem Minuten-Stepper.
3. Eyebrow **„Modus"** + Segmented-Control (Regelmäßig / Nach Start / Vor Ende) + darunter der **Modus-Hinweistext**.
4. Eyebrow **„Klang"** + Klang-Karten-Liste (unverändert aus shared-118).
5. Bei Nicht-Vibration: Eyebrow **„Lautstärke"** + Lautstärke-Karte (unverändert). Bei Vibration: Vibrations-Hinweistext (unverändert).

Wenn **ausgeschaltet**: nur die Master-Karte + darunter der **Aus-Hinweistext**. Keine weiteren Sektionen.

### Master-Karte
- Führendes Icon: plattform-idiomatisches „wiederkehrend"-Symbol (iOS z. B. `arrow.triangle.2.circlepath`, Android z. B. `Icons.*.Repeat`). In Akzent-/Sekundärfarbe gemäß bestehendem Karten-Stil.
- Untertitel zustandsabhängig:
  - **An** → `…master.subtitle.on`
  - **Aus** → `…master.subtitle.off`
- Titel bleibt der bestehende Key (`settings.intervalGongs.title` / `settings_interval_gongs`).
- Der bestehende Toggle-Accessibility-Identifier/-Label bleibt erhalten.

### Modus-Hinweistext (dynamisch, plural-korrekt)
- Hängt vom gewählten Modus **und** der Intervall-Minutenzahl ab.
- **Plural-korrekt** über `Localizable.stringsdict` (iOS) bzw. `<plurals>` (Android) — KEINE manuelle if/else-Pluralbildung, KEIN „alle 1 Minute".
- Eine pluralisierte Zeichenkette **pro Modus** (Singular bei Intervall = 1, Plural sonst). Der Count (`intervalMinutes`) steuert die Plural-Auswahl und wird im Plural-Fall als `%d` eingesetzt.

### Pure-Logik (testbar, fachlich)
- Eine reine Funktion `IntervalMode → L10n-Key` für den Modus-Hinweis (welcher der drei Keys gilt). Diese Abbildung ist der fachliche Test (kein Assert auf lokalisierten Text).
- iOS: passend zu DDD als reine Funktion/Extension (kein Plattform-Import).

### Localization-Keys + Copy

**iOS** (`Localizable.strings`, DE + EN):

| Key | DE | EN |
|-----|----|----|
| `praxis.intervalGongs.master.subtitle.on` | Wiederkehrende Gongs während der Sitzung | Recurring gongs throughout the session |
| `praxis.intervalGongs.master.subtitle.off` | Aus — keine Gongs während der Sitzung | Off — no gongs during the session |
| `praxis.intervalGongs.disabled.helper` | Schalte Intervall-Gongs ein, um in regelmäßigen Abständen einen sanften Klang zu hören — eine ruhige Markierung der Zeit. | Turn on interval gongs to hear a gentle sound at regular intervals — a quiet marker of time. |
| `praxis.intervalGongs.section.mode` | Modus | Mode |

**iOS** (`Localizable.stringsdict`, neu — DE + EN, je `one`/`other`):

| Key | DE one | DE other | EN one | EN other |
|-----|--------|----------|--------|----------|
| `praxis.intervalGongs.mode.help.repeating` | Ein Gong ertönt jede Minute während der gesamten Sitzung. | Ein Gong ertönt alle %d Minuten während der gesamten Sitzung. | A gong sounds every minute throughout the session. | A gong sounds every %d minutes throughout the session. |
| `praxis.intervalGongs.mode.help.afterStart` | Ein einzelner Gong, eine Minute nach Beginn der Sitzung. | Ein einzelner Gong, %d Minuten nach Beginn der Sitzung. | A single gong, one minute after the session begins. | A single gong, %d minutes after the session begins. |
| `praxis.intervalGongs.mode.help.beforeEnd` | Ein einzelner Gong, eine Minute vor dem Ende der Sitzung. | Ein einzelner Gong, %d Minuten vor dem Ende der Sitzung. | A single gong, one minute before the session ends. | A single gong, %d minutes before the session ends. |

**Android** (`strings.xml` values + values-de):

| Key | EN | DE |
|-----|----|----|
| `praxis_interval_gongs_master_subtitle_on` | Recurring gongs throughout the session | Wiederkehrende Gongs während der Sitzung |
| `praxis_interval_gongs_master_subtitle_off` | Off — no gongs during the session | Aus — keine Gongs während der Sitzung |
| `praxis_interval_gongs_disabled_helper` | Turn on interval gongs to hear a gentle sound at regular intervals — a quiet marker of time. | Schalte Intervall-Gongs ein, um in regelmäßigen Abständen einen sanften Klang zu hören — eine ruhige Markierung der Zeit. |
| `praxis_gong_section_mode` | Mode | Modus |

**Android** (`<plurals>` values + values-de, je `one`/`other`):

Gleiche Sätze wie iOS oben. Platzhalter `%d`. Keys:
`praxis_interval_gongs_mode_help_repeating`, `praxis_interval_gongs_mode_help_after_start`, `praxis_interval_gongs_mode_help_before_end`.

> Hinweis EN-Copy: Übersetzung des deutschen Handoffs (Handoff ist DE-only). Stil = ruhig, nicht-technisch, Em-Dash wie im Bestand.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Master-Karte mit führendem „wiederkehrend"-Icon, Titel und zustandsabhängigem Untertitel (An/Aus).
- [ ] Im Aus-Zustand erscheint der Aus-Hinweistext; es werden keine weiteren Sektionen gezeigt.
- [ ] Intervall (Stepper) und Modus (Segmented) stehen in zwei getrennten Eyebrow-Sektionen.
- [ ] Unter der Modus-Auswahl steht der dynamische Modus-Hinweistext; er ändert sich korrekt bei Wechsel von Modus und Intervall-Minuten.
- [ ] Modus-Hinweis ist plural-korrekt: bei Intervall = 1 die Singular-Form (z. B. „jede Minute" / „eine Minute"), sonst die Plural-Form mit Zahl.
- [ ] Klang-Auswahl, Vibrations-Hinweis und Lautstärke-Karte bleiben funktional und optisch wie in shared-118.
- [ ] Auto-Save unverändert (Änderungen sofort persistiert).
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell & textlich konsistent zwischen iOS und Android.
- [ ] Accessibility: Master-Karte als ein Element mit Titel+Untertitel+Schalter sinnvoll lesbar; Hinweistexte werden vorgelesen.

### Tests
- [ ] Unit-Test (iOS): reine `IntervalMode → Hinweis-Key`-Abbildung deckt alle drei Modi ab.
- [ ] Unit-Test (Android): analoge Abbildung deckt alle drei Modi ab.
- [ ] Bestehende Tests bleiben grün.

### Dokumentation
- [ ] CHANGELOG.md (Changed, iOS + Android) — wird vom Orchestrator gepflegt, NICHT vom Implementier-Agenten.

---

## Manueller Test
1. Timer-Tab → Intervall-Gongs öffnen.
2. Ausgeschaltet: Master-Karte zeigt Untertitel „Aus — …"; darunter der Aus-Hinweistext; keine weiteren Sektionen.
3. Einschalten: Untertitel wechselt auf „Wiederkehrende Gongs …"; Sektionen Intervall / Modus / Klang / Lautstärke erscheinen.
4. Intervall auf 1 Min. → Modus-Hinweis nutzt Singular-Form. Intervall auf 5 Min. → Plural-Form mit Zahl.
5. Modus durchschalten (Regelmäßig / Nach Start / Vor Ende) → Hinweistext passt sich jeweils sinngemäß an.
6. Verlassen & erneut öffnen → alle Werte erhalten (Auto-Save).
7. Identisches Erscheinungsbild & Verhalten iOS ↔ Android.

---

## Referenz
- Handoff (Design-Quelle): `handoffs/intervall-gongs/intervall-app.jsx` (+ `intervall.css`)
- iOS umzubauen: `ios/StillMoment/Presentation/Views/Timer/IntervalGongsEditorView.swift`
- iOS Muster (Karten/Eyebrow/Helper): `ios/StillMoment/Presentation/Views/Timer/GongSelectionView.swift` + `Components/`
- Android umzubauen: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/IntervalGongsEditorScreen.kt`
- ViewModel: iOS `PraxisSettingsViewModel`, Android `presentation/viewmodel/PraxisSettingsViewModel.kt` (`intervalGongsEnabled`, `intervalMinutes`, `intervalMode`, `intervalSoundId`, `intervalGongVolume`)

---

## Hinweise
- Nur Presentation-Polish — keine Änderung an Timer-Logik, Persistenz oder Audio.
- `stringsdict`/`plurals` sind neu im Projekt: beide Sprachen vollständig pflegen, sonst schlägt der Localization-Check bzw. die Anzeige fehl.
- Wellenform-Charakter, Klang-Liste und Vibrations-Verhalten NICHT anfassen (Stand shared-118).
- iOS `make check` enthält einen Localization-Check — neue Keys in DE **und** EN.
