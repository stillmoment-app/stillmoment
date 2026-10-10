---
id: android-089
title: "Automatische Dependency-Updates für Android und GitHub Actions (Dependabot)"
status: done
phase: 5-QA
priority: niedrig
depends_on: []
---

# Ticket android-089: Automatische Dependency-Updates für Android und GitHub Actions (Dependabot)

## Was

Updates für die Android-Abhängigkeiten und die GitHub-Actions-Workflows kommen regelmäßig als Pull Requests ins Repo, statt dass sie jemand von Hand suchen muss. Eng gekoppelte Build-Werkzeuge kommen gemeinsam in einem Pull Request.

## Warum

Die Android-Abhängigkeiten veralten unbemerkt. Wenn dann gesammelt aktualisiert wird, brechen gekoppelte Werkzeuge zusammen. Präzedenzfall ist das AGP-9-Upgrade: AGP, Kotlin und KSP wurden angehoben, Hilt blieb auf einer alten Version. Die war mit der neuen KSP-Version inkompatibel, und der Build war kaputt, bis Hilt nachgezogen wurde. Kleine, regelmäßige Updates in sinnvollen Gruppen machen solche Brüche seltener und leichter zu finden.

---

## Akzeptanzkriterien

- [ ] Für die Android-Abhängigkeiten erscheinen höchstens einmal im Monat Update-Pull-Requests
- [ ] Für die GitHub-Actions-Workflows erscheinen höchstens einmal im Monat Update-Pull-Requests
- [ ] Updates für AGP, Kotlin (samt Kotlin-Compiler-Plugins), KSP und Hilt kommen gemeinsam in einem Pull Request
- [ ] AndroidX- und Compose-Bibliotheken, Test-Abhängigkeiten und GitHub Actions kommen jeweils in einem eigenen gebündelten Pull Request, nicht als einzelne Pull Requests pro Abhängigkeit
- [ ] Update-Pull-Requests durchlaufen die CI wie jeder andere Pull Request
- [ ] Für iOS, die Fastlane-Gemfiles und die Website kommen keine Update-Pull-Requests

---

## Manueller Test

1. Konfiguration auf `main` mergen
2. Auf GitHub unter Insights → Dependency graph → Dependabot die Updates manuell anstoßen
3. Erwartung: Gebündelte Pull Requests erscheinen gemäß den Gruppen oben, die CI läuft darauf, und für iOS, Fastlane und die Website erscheinen keine Pull Requests

---

## Nicht Teil dieses Tickets

- iOS: Die App hat keine Swift-Package-Abhängigkeiten, es gibt also nichts zu überwachen
- Fastlane-Gemfiles (`ios/`, `android/`) und `docs/Gemfile`
- Automatisches Mergen von Update-Pull-Requests
- Die Restarbeiten der AGP-9-Migration (Opt-out-Flags in `gradle.properties`, alte Variant-API)

---

## Hinweise

- **Dependabot statt Renovate:** Dependabot ist in GitHub eingebaut und braucht weder eine App-Installation noch einen externen Dienst. Die feineren Regeln von Renovate braucht dieses Projekt nicht.
- **Monatlich statt wöchentlich:** So kommen weniger Pull Requests, und das Repo bleibt ruhig.
- **Toolchain-Gruppe:** Die Bündelung von AGP, Kotlin, KSP und Hilt ist der Kern des Tickets. Diese Werkzeuge müssen zueinander passen, einzeln angehoben brechen sie den Build (siehe Warum).
- Gemergt wird erst bei grüner CI, so wie bei jedem anderen Pull Request auch (`.github/BRANCH_PROTECTION.md`).

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
