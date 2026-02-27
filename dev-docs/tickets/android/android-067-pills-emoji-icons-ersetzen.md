# Ticket android-067: Konfigurations-Pills: Emoji-Icons durch monochromatische Icons ersetzen

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die bunten Emoji-Zeichen in den Konfigurations-Pills (⏳ 🔔 🌬️ 🎧 🔁) durch monochromatische Material-Icons ersetzen. Die Icons sollen dieselbe Farbe wie der Pill-Text annehmen (`onSurfaceVariant`).

## Warum

Bunte Emojis wirken visuell unruhig und passen nicht zum meditativen Still-Moment-Aesthetik. Emojis sind OS-abhaengig (unterschiedliches Rendering auf verschiedenen Android-Versionen). Monochromatische Icons folgen dem Design-System, sind skalierbar und sehen konsistent aus.

---

## Akzeptanzkriterien

### Feature
- [ ] `SettingPill`-Signatur nimmt `ImageVector` statt `String` als Icon-Parameter
- [ ] Alle 5 Pills nutzen Material-Icons (aus `androidx.compose.material.icons`):
  - Vorbereitung (⏳) → z.B. `Icons.Default.Timer`
  - Gong (🔔) → z.B. `Icons.Default.Notifications` oder `Icons.Outlined.MusicNote`
  - Hintergrund-Sound (🌬️) → z.B. `Icons.Default.Air` oder `Icons.Outlined.Spa`
  - Introduction (🎧) → z.B. `Icons.Outlined.Headphones` oder `Icons.AutoMirrored.Outlined.VolumeUp`
  - Interval Gongs (🔁) → z.B. `Icons.Default.Repeat`
- [ ] Icon-Farbe = `MaterialTheme.colorScheme.onSurfaceVariant` (identisch mit Pill-Text)
- [ ] Icon-Groesse: 14dp (passend zur `Caption`-Schriftgroesse)
- [ ] Kein Emoji-String mehr im Code

### Tests
- [ ] `make test` gruen

### Dokumentation
- [ ] Keine

---

## Manueller Test

1. App starten, Timer-Tab oeffnen
2. Konfigurations-Pills unter dem WheelPicker anschauen
3. Erwartung: Alle Icons monochrom, gleiche Farbe wie Pill-Text, keine Emojis
4. Dark Mode pruefen: Icons passen sich an (heller in Dark Mode)

---

## Referenz

- `android/app/src/main/kotlin/.../timer/TimerScreen.kt` — `ConfigurationPills`, `SettingPill`
- Icons-Import: `import androidx.compose.material.icons.Icons`
- iOS: `ConfigurationPillsRow.swift` — verwendet SF Symbols (monochrom)

---

## Hinweise

Die Icon-Auswahl ist dem Implementierer ueberlassen — wichtig ist nur: monochrom, semantisch passend, aus Material Icons (nicht Emoji). Icons die in `Icons.Default` oder `Icons.Outlined` verfuegbar sind bevorzugen (kein extra Dependency).
