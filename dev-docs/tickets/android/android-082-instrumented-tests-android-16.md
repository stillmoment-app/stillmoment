# Ticket android-082: Instrumented Tests auf Android 16 wieder gruen

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Komplexitaet**: Die Arbeit steckt in der Diagnose, nicht im Fix. 17 rote Tests koennen eine Ursache oder acht sein — das ist vorab nicht bekannt. Mindestens ein Fall (Endlos-Rekomposition im Player) ist bekannt schwierig und braucht manuelle Kontrolle der Compose-Frame-Clock. Jeder Durchlauf braucht einen laufenden Android-16-Emulator; kein Unit-Test fangt davon etwas.
**Abhaengigkeiten**: android-081 (abgeschlossen — hat die Failures sichtbar gemacht und den vorgelagerten Blocker behoben)
**Phase**: 5-QA

---

## Was

Die bestehenden Instrumented Tests der Android-App sollen auf einem Android-16-Emulator wieder vollstaendig durchlaufen. Derzeit scheitern dort 17 von 36 Tests, 19 laufen.

Der Weg dahin ist zweistufig: zuerst eine Bestandsaufnahme, die die Failures nach gemeinsamer Ursache gruppiert, dann die Behebung. Ob am Ende Test-Code oder Produktionscode angepasst wird, ist offen und Teil der Untersuchung.

## Warum

Android 16 ist ab jetzt die Zielplattform der App — dort laeuft, was ausgeliefert wird. Eine Testsuite, die auf der Zielplattform zu knapp der Haelfte rot ist, sagt nichts mehr aus: Wer sie ausfuehrt, gewoehnt sich an das Rot und sieht eine echte neue Regression nicht mehr. Damit verliert die Suite genau die Eigenschaft, wegen der sie existiert.

Das Kriterium „Bestehende Instrumented Tests laufen auf einem Android-16-Emulator gruen" stand in android-081 und ist dort offen geblieben. Es wird hierhin verschoben.

---

## Akzeptanzkriterien

### Bestandsaufnahme
- [ ] Ein dokumentierter Lauf auf einem Android-16-Emulator listet jeden Test mit Ergebnis — die Gesamtzahl der tatsaechlich ausgefuehrten Tests ist damit belegt statt geschaetzt
- [ ] Zu jedem fehlschlagenden Test ist die Fehlerursache benannt, nicht nur die Fehlermeldung
- [ ] Die Failures sind zu Gruppen mit gemeinsamer Ursache zusammengefasst; Einzelfaelle sind als solche ausgewiesen
- [ ] Der Zustand der Screenshot-Tests ist mit erfasst: ob sie im Lauf enthalten sind und ob sie durchlaufen

### Behebung
- [ ] Alle Instrumented Tests laufen auf einem Android-16-Emulator gruen
- [ ] Kein Test wurde deaktiviert, uebersprungen oder in seiner Aussage abgeschwaecht, um das zu erreichen
- [ ] Fuer jede Failure-Gruppe ist begruendet dokumentiert, ob der Test oder das Produktionsverhalten falsch war — und warum
- [ ] Wo Produktionscode geaendert wurde: die betroffene Funktion verhaelt sich auf dem Geraet unveraendert (kurz durchgetippt, nicht nur gruen)

### Tests
- [ ] Die bestehende Unit-Test-Suite bleibt gruen
- [ ] `make check` ist gruen

### Dokumentation
- [ ] Die Bestandsaufnahme und die Begruendungen stehen im Verifikationsabschnitt dieses Tickets — es ist die Quelle fuer den naechsten Android-Versionssprung
- [ ] Falls beim Ausfuehren der Suite Schritte noetig sind, die nicht selbsterklaerend sind: in `android/CLAUDE.md` festhalten
- [ ] CHANGELOG.md nur, wenn Produktionsverhalten geaendert wurde

---

## Manueller Test

1. Emulator `Medium_Phone_API_36.1` (Android 16) starten
2. Die vollstaendige Instrumented-Test-Suite ausfuehren
3. Erwartung: Kein Fehlschlag; die Zahl der ausgefuehrten Tests stimmt mit der Bestandsaufnahme ueberein
4. Suite ein zweites Mal ausfuehren, ohne den Emulator neu zu starten
5. Erwartung: Gleiches Ergebnis — kein Test, der nur beim ersten oder nur beim zweiten Lauf gruen ist
6. Falls Produktionscode geaendert wurde: App auf demselben Emulator starten und die betroffenen Stellen von Hand bedienen
7. Erwartung: Verhalten wie vorher, keine sichtbare Aenderung

---

## Referenz

- android-081 — Target API Level 36; der Verifikationsabschnitt dort enthaelt die Messung, aus der dieses Ticket entstanden ist
- android-012 / android-017 — Ursprung der Instrumented Tests und der Test-Interaktionen
- android-042 — automatisierte Screenshots, die ueber dieselbe Suite laufen
- Android: `android/app/src/androidTest/kotlin/com/stillmoment/`
- Doku: [Compose testing — synchronization](https://developer.android.com/develop/ui/compose/testing/synchronization)

---

## Hinweise

**Der Target-SDK-Bump ist nicht die Ursache.** In android-081 wurden Laeufe mit targetSdk 35 und 36 auf demselben Emulator verglichen, beide mit derselben Espresso-Version: identische Fehler-Mengen. Die 17 Failures sind vorbestehend auf Android 16. Ein Rollback des Target-SDK wuerde nichts loesen — diese Richtung ist bereits ausgeschlossen.

**Ein vorgelagerter Blocker ist schon erledigt.** Vorher scheiterte auf Android 16 *jeder* Test in der Espresso-Idle-Pruefung an einer fehlenden Framework-Methode. Der Sprung auf Espresso 3.7.0 in android-081 hat das behoben und die 19 gruenen Tests ueberhaupt erst ermoeglicht. Das ist nicht Teil dieses Tickets; die Espresso-Version nicht zuruecknehmen (der Hinweis dazu steht in der Versions-Katalogdatei).

**Fehlerbild:** ueberwiegend fehlgeschlagene Sichtbarkeitspruefungen, plus eine Compose-„nicht zur Ruhe gekommen"-Ausnahme. Letztere betrifft den Player-Screen und ist bekannt: Der Screen rekomponiert unter Instrumentierung endlos, und die Navigation dorthin gelingt nur, wenn die Compose-Frame-Clock von Hand weitergedreht wird — automatisches Vorruecken abschalten, Zeit in Schritten vorschieben und dabei mit echten Wartezeiten verschraenken. Ein reiner Tap pumpt die Clock nicht. Das ist im Projekt-Gedaechtnis dokumentiert (`project_android_screenshot_nav_testclock`).

**Sichtbarkeitspruefungen zuerst gruppieren, nicht einzeln reparieren.** Bei 17 Failures ist die Wahrscheinlichkeit hoch, dass mehrere auf dieselbe Ursache zurueckgehen — etwa eine Android-16-Verhaltensaenderung bei Insets, Fenstergroesse oder Fokus. Einzeln geflickte Tests verstecken so eine gemeinsame Ursache, statt sie zu beheben. Deshalb steht die Gruppierung als eigenes Kriterium vor der Behebung.

**Die Zahl 36 ist eine Beobachtung, keine Definition.** Sie stammt aus dem Lauf in android-081. Im Testverzeichnis liegen mehr Testmethoden als das; unklar ist, welche im gemessenen Lauf ueberhaupt eingesammelt wurden — die Screenshot-Tests sind der naechstliegende Verdacht, weil sie andere Voraussetzungen haben als die uebrigen. Das aufzuloesen ist Teil der Bestandsaufnahme, denn ein „gruen" ueber einer stillschweigend verkleinerten Menge ist wertlos.

**Screenshot-Tests haengen an dieser Suite.** Wer sie erzeugt, faehrt denselben Weg. Ein Fix, der die Screenshot-Tests bricht, faellt erst beim naechsten Store-Release auf — deshalb gehoert ihr Zustand in die Bestandsaufnahme, vorher und nachher.

**Umfang bewusst begrenzt:** kein Ausbau der Suite, keine neuen Testfaelle, keine Umstellung der Test-Infrastruktur. Nur: das Bestehende auf der Zielplattform wieder aussagefaehig machen.
