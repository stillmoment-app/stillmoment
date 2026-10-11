# iOS Gerätetest

**Typ**: Kurzer manueller Test auf echtem iPhone, ca. 5 Minuten
**Wann**: Vor `make release`, **nur wenn** seit dem letzten Release Code für Audio, Sperrbildschirm,
Timer-Ablauf oder Hintergrund-Verhalten geändert wurde (siehe `RELEASE_GUIDE.md` → „Gerätetest“)
**Gegenstück**: `TEST_PLAN_ANDROID.md`

Alles andere decken die automatischen Tests ab (Unit- und UI-Tests in `make test`). Geprüft wird hier nur,
was im Simulator nicht geht: hörbares Audio und Vibration bei gesperrtem Bildschirm.
Begriffe nach `dev-docs/reference/glossary.md`.

## Voraussetzungen

- Echtes iPhone, Stummschalter aus, Lautstärke mittel
- Neue Version installiert (aus Xcode aufs Gerät oder als TestFlight-Build)
- Eine Meditation in der Bibliothek

## 1. Timer bei gesperrtem Bildschirm

Dauer 2 Min, Vorbereitung 10 s, Intervall-Gongs jede Minute, ein Hintergrundklang.
Start drücken, **sofort** sperren, Telefon weglegen.

- [ ] Nach 10 s Start-Gong, danach Hintergrundklang
- [ ] Nach 1 Min Intervall-Gong
- [ ] Nach 2 Min End-Gong, klingt vollständig aus; Hintergrundklang verstummt
- [ ] „Start & Ende“ auf „Vibration“, 1 Min, starten und sperren: Vibration am Anfang und am Ende spürbar

## 2. Geführte Meditation bei gesperrtem Bildschirm

Meditation mit Wiedergabe-Bereich und eingeschalteten Gongs abspielen, **sofort** sperren.

- [ ] Start-Gong, danach Audio ab Beginn des Wiedergabe-Bereichs
- [ ] Sperrbildschirm zeigt Titel und Lehrer; Pause und Wiedergabe funktionieren
- [ ] Am Ende des Wiedergabe-Bereichs End-Gong, klingt vollständig aus
