# Audio Sources

Herkunft und Lizenzinformationen aller Audio-Dateien in der App.

---

## Gong Sounds

Alle Gong-Sounds stammen von [Pixabay](https://pixabay.com/) und stehen unter der [Pixabay Content License](https://pixabay.com/service/license-summary/) (keine Attribution erforderlich, frei fuer kommerzielle Nutzung).

Die Originaldateien liegen in `singing_bowls/`, verarbeitet mit `singing_bowls/process_audio.py` (Stille entfernt, auf 10s gekuerzt, Fade-out, Loudness-Normalisierung auf -16 LUFS).

| In-App Name | ID | Original-Dateiname | Pixabay-URL | Pixabay-ID |
|---|---|---|---|---|
| Temple Bell | `temple-bell` | `tibetan-singing-bowl-55786.mp3` | https://pixabay.com/sound-effects/tibetan-singing-bowl-55786/ | 55786 |
| Classic Bowl | `classic-bowl` | `singing-bowl-hit-3-33366.mp3` | https://pixabay.com/sound-effects/film-special-effects-singing-bowl-hit-3-33366/ | 33366 |
| Deep Resonance | `deep-resonance` | `singing-bowl-male-frequency-29714.mp3` | https://pixabay.com/sound-effects/singing-bowl-male-frequency-29714/ | 29714 |
| Clear Strike | `clear-strike` | `singing-bowl-strike-sound-84682.mp3` | https://pixabay.com/sound-effects/singing-bowl-strike-sound-84682/ | 84682 |

### Plattform-Dateien

| Sound | iOS | Android |
|---|---|---|
| Temple Bell | `Resources/GongSounds/tibetan-singing-bowl-55786-10s.mp3` | `res/raw/gong_temple_bell.mp3` |
| Classic Bowl | `Resources/GongSounds/singing-bowl-hit-3-33366-10s.mp3` | `res/raw/gong_classic_bowl.mp3` |
| Deep Resonance | `Resources/GongSounds/singing-bowl-male-frequency-29714-10s.mp3` | `res/raw/gong_deep_resonance.mp3` |
| Clear Strike | `Resources/GongSounds/singing-bowl-strike-sound-84682-10s.mp3` | `res/raw/gong_clear_strike.mp3` |

---

## Interval Sound

| In-App Name | ID | Original-Dateiname | Pixabay-URL | Pixabay-ID |
|---|---|---|---|---|
| Soft Interval Tone | `soft-interval` | `triangle-40209.mp3` | https://pixabay.com/sound-effects/triangle-40209/ | 40209 |

Uploader: freesound_community. Eingefuehrt mit Ticket `shared-014`. Nachtraeglich LUFS-normalisiert mit ffmpeg.

- iOS: `Resources/interval.mp3`
- Android: `res/raw/interval.mp3`

---

## Background Sounds

Konfiguriert in `Resources/BackgroundAudio/sounds.json`.

| In-App Name | ID | Datei | Quelle |
|---|---|---|---|
| Silence | `silent` | `silence.mp3` / `silence.m4a` | Generiert (stille Audio-Datei fuer Background-Playback) |
| Forest Ambience | `forest` | `forest-ambience.mp3` | [Pixabay 296528](https://pixabay.com/sound-effects/nature-forest-ambience-296528/) |
| Cozy Midnight Rain | `cozy-rain` | `cozy-midnight-rain.mp3` | [Pixabay 448573](https://pixabay.com/sound-effects/dragon-studio-cozy-midnight-rain-02-448573/) |

- iOS: `Resources/BackgroundAudio/`
- Android: `res/raw/`

---

## Lizenz-Zusammenfassung

| Quelle | Lizenz | Attribution erforderlich |
|---|---|---|
| Pixabay | [Pixabay Content License](https://pixabay.com/service/license-summary/) | Nein |
| Freesound (CC0) | [Creative Commons Zero](https://creativecommons.org/publicdomain/zero/1.0/) | Nein |

---

## Neue Sounds hinzufuegen

1. Sound herunterladen und Quelle + Lizenz in dieser Datei dokumentieren
2. Bei Pixabay: Pixabay-URL und ID notieren
3. Bei Freesound: URL, Uploader und Lizenz notieren
4. Gong-Sounds: Mit `singing_bowls/process_audio.py` verarbeiten
5. In beide Plattformen integrieren (iOS + Android)
