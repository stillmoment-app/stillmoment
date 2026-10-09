---
name: real-world-fixtures-hooks
description: Echte Server-Antworten als Testdaten muessen von trailing-whitespace/end-of-file-fixer ausgenommen werden, sonst schreiben die Hooks sie um
metadata:
  type: feedback
---

Wenn byte-treue echte Server-Antworten als Testdaten ins Repo kommen (Podcast-Feeds,
HTTP-Dumps, fremde XML/JSON), gehoert der Fixture-Ordner in die `exclude`-Liste von
`trailing-whitespace` und `end-of-file-fixer` in `.pre-commit-config.yaml`.

**Why:** Beide Hooks strippen Whitespace am Zeilenende und ergaenzen einen Schluss-Zeilenumbruch —
auch **innerhalb** von CDATA- und Textknoten. Damit ist die Datei keine echte Server-Antwort mehr,
sondern eine aufgeraeumte Nachbildung. Bei shared-124 hat das drei der vier Feed-Fixtures beim
ersten Commit-Versuch veraendert; die Aenderung faellt nicht auf, weil kein Test darauf schaut,
und genau das ist die Gefahr: Ein spaeteres Fixture, bei dem ein Folgentitel auf ein Leerzeichen
endet, wuerde stillschweigend gefixt und der Parser-Test damit wertlos.

**How to apply:** Vor dem ersten Commit neuer Fixtures pruefen, ob die Hooks sie anfassen
(der Commit schlaegt fehl und nennt die Dateien). Dann den Ordner ausnehmen statt die Dateien
neu zu kopieren — der Eintrag existiert bereits fuer `^ios/StillMomentTests/Fixtures/`.
Das ist **kein** Umgehen von Hooks (`--no-verify` bleibt verboten), sondern eine begruendete
Bereichsausnahme, und sie gehoert in die Commit-Message.

Nebenbefund aus demselben Commit: `detect-secrets` haelt 32-stellige Hex-Kennungen (Podcast-GUIDs)
fuer Secrets. Loesung ist der dokumentierte Inline-Kommentar `// pragma: allowlist secret`
**in derselben Zeile** — die `nextline`-Variante ist nicht verlaesslich.

Siehe auch [[test-fixtures-bundle-flat]].
