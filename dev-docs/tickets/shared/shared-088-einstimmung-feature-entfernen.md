# Ticket shared-088: Einstimmung-Feature entfernen

**Status**: [~] IN PROGRESS
**Plan (iOS)**: [Implementierungsplan](../plans/shared-088-ios.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Querschnitt durch alle Layer — Domain (Timer-State-Machine, Phasen), Application (ViewModels, Timer-Berechnung), Presentation (Timer-Konfig, Import-UI), Infrastructure (Audio-Resolver, Persistenz). Risiko: Migration bestehender Settings/Imports und vollstaendiges Aufraeumen ohne tote Code-Pfade.
**Phase**: 2-Architektur

---

## Was

Das Einstimmung-Feature (Attunement) wird vollstaendig aus dem Meditations-Timer entfernt: Audio-Import-Typ, Timer-Konfiguration, Timer-Phase und alle damit verbundenen Code-Pfade. Bestehende Einstimmungs-Audio-Dateien werden bei der Migration stillschweigend geloescht.

## Warum

Die Hypothese: Das Feature wird kaum genutzt, kostet aber unverhaeltnismaessig viel Komplexitaet:

- 3 Optionen beim Audio-Import (Einstimmung als eine davon)
- Mehrere zusaetzliche Settings in der Timer-Konfiguration
- Komplexere Timer-Zeitberechnung (Einstimmung verlaengert die Sitzung implizit)
- Zusaetzliche Phase und Uebergaenge in der Timer-State-Machine

Das widerspricht der App-Philosophie "Einfachheit ueber Features". Die Entfernung reduziert UX- und Code-Komplexitaet nachhaltig.

---

## Plattform-Status

| Plattform | Status         | Abhaengigkeit |
|-----------|----------------|---------------|
| iOS       | [~] IN PROGRESS| -             |
| Android   | [ ]            | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Timer-Konfiguration zeigt keinen Einstimmung-Toggle/Picker mehr
- [ ] Datei-Import bietet keine Einstimmung-Option mehr (nur noch verbleibende Typen)
- [ ] Timer-State-Machine hat keine Einstimmung-Phase mehr; Uebergaenge entsprechend reduziert
- [ ] Timer-Zeitberechnung enthaelt keine Einstimmungs-Komponente mehr
- [ ] User mit bestehender Einstimmung-Konfiguration erleben keinen Crash; Setting wird stillschweigend ignoriert/migriert
- [ ] Bestehende importierte Einstimmungs-Audio-Dateien werden bei der Migration stillschweigend geloescht
- [ ] Alle Lokalisierungs-Keys zum Einstimmung-Feature sind entfernt (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android (gleiche reduzierte Konfig-Optik)

### Tests
- [ ] Unit Tests iOS — Timer-State-Machine ohne Einstimmung-Phase, Migration stillschweigend
- [ ] Unit Tests Android — analog
- [ ] Bestehende Tests, die Einstimmung referenzieren, sind entweder geloescht oder umgeschrieben

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung)
- [ ] Architektur-Diagramme aktualisiert (sofern Einstimmung dort sichtbar ist)
- [ ] Timer-State-Chart in `dev-docs/architecture/timer-state-machine.md` aktualisiert
- [ ] Audio-System-Doku in `dev-docs/architecture/audio-system.md` ggf. anpassen
- [ ] Glossar `dev-docs/reference/glossary.md` — Eintrag "Attunement/Einstimmung" entfernen
- [ ] Plattform-CLAUDE.md (`ios/CLAUDE.md`, `android/CLAUDE.md`) auf Referenzen pruefen
- [ ] Website-Texte (falls Einstimmung dort beworben wird) anpassen

---

## Manueller Test

1. Frische App-Installation: Timer-Konfiguration oeffnen — keine Einstimmung-Option sichtbar
2. Datei-Import oeffnen — Auswahl bietet keine Einstimmung-Option mehr
3. Update-Pfad: Vorherige Version mit konfigurierter Einstimmung + importierter Datei → Update auf neue Version → App startet ohne Crash, Timer laeuft regulaer ohne Einstimmungs-Phase, importierte Datei ist verschwunden
4. Timer starten und durchlaufen lassen: Es gibt nur noch die regulaeren Phasen (Vorbereitung → Meditation → Endgong)
5. Erwartung: Identisches Verhalten auf iOS und Android

---

## Referenz

- Vorgeschichte: shared-050 (Einleitung eingefuehrt), shared-067 (Code-Rename Introduction → Attunement), shared-072 (Toggle-Konsistenz), shared-073 (Import mit Typ-Auswahl), shared-074 (Audio-Resolver fuer Einstimmung)
- iOS: `ios/StillMoment/Domain/`, `ios/StillMoment/Application/`, `ios/StillMoment/Presentation/`
- Android: `android/app/src/main/kotlin/com/stillmoment/`

---

## Hinweise

- **Reihenfolge**: Erst Domain (State-Machine, Modelle) bereinigen, dann Application (ViewModels, Timer-Berechnung), dann Presentation (UI). Infrastructure (Audio-Resolver, Persistenz, Migration) zuletzt — die Migration muss stillschweigend funktionieren.
- **Migration ist einmalig**: Beim ersten Start nach Update werden Einstimmungs-Eintraege aus persistierten Settings entfernt und die Audio-Dateien geloescht. Kein Dialog, kein Hinweis.
- **Tote Code-Pfade vermeiden**: Nach Entfernung sollten keine Funktionen, Properties, Lokalisierungs-Keys oder Test-Helfer mehr existieren, die nur fuer Einstimmung da waren.
- **shared-072, shared-073, shared-074** sind teilweise oder ganz obsolet, sobald shared-088 abgeschlossen ist — bei Abschluss vermerken.
