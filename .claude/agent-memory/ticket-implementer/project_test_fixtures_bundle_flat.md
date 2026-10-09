---
name: test-fixtures-bundle-flat
description: Ressourcen im Testtarget landen flach im Bundle-Root; der Clean-Build-Fallstrick fuer neue Dateitypen ist dort 2026-09 nicht aufgetreten
metadata:
  type: project
---

Nicht-Swift-Dateien unter `ios/StillMomentTests/` landen im gebauten `.xctest`-Bundle
**flach im Root**, nicht im Projekt-Unterordner. `Bundle(for:).url(forResource:withExtension:)`
ohne `subdirectory:` ist also richtig; `subdirectory: "PodcastFeeds"` liefert `nil`.

**Why:** Das Testtarget nutzt `fileSystemSynchronizedGroups`. Xcode uebernimmt neue Dateien
automatisch in die Resources-Phase, flacht die Ordnerstruktur dabei aber ein (keine
Folder-Reference).

**How to apply:** Beim Anlegen neuer Fixtures nicht praeventiv clean bauen. Der aus dem
App-Target bekannte Fallstrick ("erster Auftritt eines neuen Dateityps in einer synchronized
Group fehlt im inkrementellen Bundle") ist im **Testtarget** bei shared-124 mit vier XML-Dateien
**nicht** aufgetreten — der inkrementelle Build hat sie sofort mitgenommen. Erst wenn ein Test
mit "Fixture nicht gefunden" scheitert, ist ein Clean-Build der naechste Schritt. Der erste
Fixture-Test sollte trotzdem ein `XCTUnwrap` mit sprechender Meldung tragen, damit niemand
einen Bundle-Fehler fuer einen Parser-Bug haelt.

Gilt nur fuer das Testtarget. Fuer das App-Target bleibt die aeltere Beobachtung zu
`.stringsdict` unberuehrt.

Siehe auch [[real-world-fixtures-hooks]].
