---
name: shared115-gong-wave-spec
description: shared-115 Gong-Auswahl Redesign — die WAVE-Envelopes sind fixe Cross-Platform-Spec, iOS-Implementierung als Referenz
metadata:
  type: project
---

shared-115 (Gong-Auswahl "Start & Ende" Redesign) hat eine **fixierte, plattformidentische WAVE-Envelope-Spezifikation** (11 Balken je Sound, gekeyt nach Sound-ID, nicht Name):

- temple-bell: [0.35, 0.90, 1.00, 0.85, 0.78, 0.68, 0.60, 0.50, 0.42, 0.34, 0.26]
- classic-bowl: [0.30, 0.95, 0.80, 0.65, 0.55, 0.45, 0.40, 0.32, 0.28, 0.22, 0.18]
- deep-resonance: [0.45, 0.70, 0.90, 1.00, 0.92, 0.86, 0.80, 0.72, 0.64, 0.54, 0.44]
- clear-strike: [0.25, 1.00, 0.70, 0.45, 0.30, 0.20, 0.14, 0.10, 0.08, 0.06, 0.05]
- vibration: keine Envelope (nil) → 3 Punkte statt Wellenform

Balkenhöhe = 4 + round(v*16) pt (4–20pt). Balken 2.5pt breit, Spacing 2pt.

**Why:** Ticket-Risiko ist Cross-Platform-Drift der bedeutungstragenden Wellenform. Die Werte stammen 1:1 aus `handoffs/design_handoff_gong_auswahl/design/auswahl-app.jsx` (WAVE-Map). iOS ist die Referenz-Plattform; Android muss exakt dieselben Werte verwenden.

**How to apply:** Beim Android-Teil (`SelectGongScreen.kt`, `GongWaveform.kt`) die `WAVE`-Map mit identischen Float-Werten anlegen. iOS-Implementierung steht in `ios/StillMoment/Presentation/Views/Timer/Components/GongWaveform.swift` (`waveEnvelopes`), Tests in `GongWaveformTests.swift`. Neue Lokalisierungs-Keys: `praxis.gong.section.sound/volume`, `praxis.gong.vibration.helper`, `accessibility.gong.preview` (Format mit %@).
