---
id: shared-012
title: Portrait-Only Modus
status:
  ios: done
  android: done
phase: 4-Polish
priority: hoch
---

# Ticket shared-012: Portrait-Only Modus

**Aufwand**: iOS ~5min | Android ~5min

---

## Was

App auf Portrait-Modus beschraenken (Landscape deaktivieren).

## Warum

Der TimerScreen wird im Landscape-Modus abgeschnitten. Portrait-only ist ausserdem typisch fuer Meditations-Apps (Headspace, Calm) und sorgt fuer eine ruhigere, fokussiertere UX.

---

## Akzeptanzkriterien

- [x] App rotiert nicht mehr bei Geraetedrehung
- [x] App startet immer im Portrait-Modus
- [x] Gilt fuer Phones und Tablets

---

## Manueller Test

1. App starten
2. Geraet ins Landscape drehen
3. Erwartung: App bleibt im Portrait-Modus

---

## Referenz

- iOS: `ios/StillMoment.xcodeproj/project.pbxproj`
- Android: `android/app/src/main/AndroidManifest.xml`

---

## Hinweise

- iOS: `INFOPLIST_KEY_UISupportedInterfaceOrientations` auf nur Portrait setzen
- Android: `android:screenOrientation="portrait"` in MainActivity
