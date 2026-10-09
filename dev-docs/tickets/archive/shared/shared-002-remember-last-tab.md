---
id: shared-002
title: Letzten Tab merken
status:
  ios: done
  android: done
phase: 4-Polish
priority: niedrig
---

# Ticket shared-002: Letzten Tab merken

**Aufwand**: iOS ~1h | Android ~1h

---

## Was

Die App soll sich den zuletzt verwendeten Tab (Timer oder Library) merken und beim naechsten App-Start automatisch diesen Tab anzeigen.

## Warum

Bessere UX fuer Nutzer, die hauptsaechlich gefuehrte Meditationen verwenden. Aktuell muessen sie bei jedem App-Start manuell zum Library-Tab wechseln.

---

## Akzeptanzkriterien

- [x] Beim Tab-Wechsel wird der aktuelle Tab gespeichert
- [x] Beim App-Start wird der gespeicherte Tab wiederhergestellt
- [x] Erster App-Start (kein Wert gespeichert): Timer-Tab als Default
- [x] Unit Tests fuer Persistierung (via Framework: @AppStorage / DataStore)
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. App starten (Timer-Tab sichtbar)
2. Zum Library-Tab wechseln
3. App komplett beenden (aus App-Switcher entfernen)
4. App erneut starten
5. Erwartung: Library-Tab ist aktiv

---

## Referenz

- iOS: `ios/StillMoment/StillMomentApp.swift` (TabView)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt`
- iOS Persistence: `ios/StillMoment/Application/ViewModels/TimerViewModel.swift` (Muster)
- Android Persistence: `android/app/src/main/kotlin/com/stillmoment/data/local/SettingsDataStore.kt`

---

## Hinweise

- iOS: TabView selection binding mit @AppStorage oder UserDefaults
- Android: DataStore Key + startDestination dynamisch setzen
