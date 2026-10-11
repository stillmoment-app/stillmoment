# Android Gerätetest

**Typ**: Kurzer manueller Test auf echtem Android-Gerät, ca. 5 Minuten
**Wann**: Vor `make release`, **nur wenn** seit dem letzten Release Code für Audio, Sperrbildschirm,
Timer-Ablauf oder Hintergrund-Verhalten geändert wurde (siehe `RELEASE_GUIDE.md` → „Gerätetest“)
**Gegenstück**: `TEST_PLAN_IOS.md`

Alles andere decken die automatischen Tests ab (Unit-Tests und Compose-UI-Tests). Geprüft wird hier nur,
was im Emulator nicht geht: hörbares Audio und Vibration bei gesperrtem Bildschirm.
Begriffe nach `dev-docs/reference/glossary.md`.

## Voraussetzungen

- Echtes Android-Gerät, Ton an, Medienlautstärke mittel
- Neue Version installiert, z. B. Debug-Build aus Android Studio. Ein lokales Build lässt sich nicht über
  die Store-Version installieren (andere Signatur) — dann die Store-Version vorher deinstallieren.
- Eine Meditation in der Bibliothek

## 1. Timer bei gesperrtem Bildschirm

Dauer 2 Min, Vorbereitung 10 s, Intervall-Gongs jede Minute, ein Hintergrundklang.
Start drücken, **sofort** sperren, Telefon weglegen.

- [ ] Nach 10 s Start-Gong, danach Hintergrundklang
- [ ] Nach 1 Min Intervall-Gong
- [ ] Nach 2 Min End-Gong, klingt vollständig aus; Hintergrundklang verstummt
- [ ] Während der Timer läuft, steht „Meditation läuft“ in der Benachrichtigungsleiste; danach verschwindet sie
- [ ] „Start & Ende“ auf „Vibration“, 1 Min, starten und sperren: Vibration am Anfang und am Ende spürbar

## 2. Geführte Meditation bei gesperrtem Bildschirm

Meditation mit Wiedergabe-Bereich und eingeschalteten Gongs abspielen, **sofort** sperren.

- [ ] Start-Gong, danach Audio ab Beginn des Wiedergabe-Bereichs
- [ ] Sperrbildschirm zeigt Titel und Lehrer; Pause und Wiedergabe funktionieren
- [ ] Am Ende des Wiedergabe-Bereichs End-Gong, klingt vollständig aus
