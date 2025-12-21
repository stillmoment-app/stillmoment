# Ticket android-041: Notification Permission Anfrage entfernen

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die automatische Anfrage der POST_NOTIFICATIONS Permission beim App-Start entfernen.

## Warum

Eine Meditations-App sollte beim ersten Start nicht gleich nach Berechtigungen fragen. Das wirkt aufdringlich und stoert den Onboarding-Flow. Der Timer funktioniert auch ohne die Berechtigung - nur die Notification in der Statusleiste ist dann nicht sichtbar.

---

## Akzeptanzkriterien

- [x] Kein Permission-Dialog beim ersten App-Start
- [x] Timer funktioniert weiterhin im Hintergrund
- [x] Audio spielt weiterhin im Hintergrund
- [x] Permission bleibt im Manifest (User kann sie manuell aktivieren)

---

## Manueller Test

1. App deinstallieren (falls installiert)
2. App neu installieren
3. App starten
4. Erwartung: Kein Permission-Dialog erscheint
5. Timer starten und App in den Hintergrund schicken
6. Erwartung: Timer laeuft, Audio spielt

---

## Hinweise

Die Permission `POST_NOTIFICATIONS` bleibt im AndroidManifest deklariert. So koennen User, die die Notification wuenschen, sie manuell in den System-Einstellungen aktivieren.

Ohne Permission:
- Foreground Service laeuft trotzdem (Android 13+)
- Notification ist nicht sichtbar
- Alle anderen Funktionen identisch
