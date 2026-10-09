---
name: simulator-store-and-mail-links
description: iOS-Simulator — apps.apple.com-Links enden in Safari mit "Adresse ungueltig", mailto liefert openURL accepted=false; Zwischenablage per simctl pbpaste pruefen
metadata:
  type: feedback
---

Beim Verifizieren externer Links im iOS-Simulator (shared-134, iOS 18.4):

- **`https://apps.apple.com/app/id…` zeigt in Safari "Safari kann die Seite nicht oeffnen, da die Adresse ungueltig ist".** Gilt auch fuer Apples eigene Apps (Pages, id361309726) — der Simulator hat keinen App Store. Kein Fehler im eigenen Code; zum Gegenbeweis `xcrun simctl openurl <udid> https://apps.apple.com/app/id361309726` aufrufen (vorher alten Safari-Dialog schliessen, sonst sieht man den alten).
- **`mailto:` → `openURL(url) { accepted in }` liefert `false`** (keine Mail-App) — eigener Fallback-Dialog laesst sich so direkt im Simulator pruefen.
- **Zwischenablage:** `xcrun simctl pbpaste <udid>` zeigt, was die App kopiert hat.

**Why:** Sonst wird der Store-Fehler faelschlich als kaputte Adresse gedeutet.
**How to apply:** Store-Links nur am Geraet fachlich abnehmen; im Simulator Vergleich mit fremder App-ID dokumentieren. Siehe [[simulator-verification-setup]].
