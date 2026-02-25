# Implementation Log: shared-064 iOS

## REVIEW 1
Verdict: FAIL

make check: OK
make test-unit: OK (776 passed, 0 failed)

BLOCKER:
- ios/StillMoment/Presentation/Views/Timer/PraxisEditorView.swift:72-73 - Bug: `dismiss()` wird nach `confirmDelete()` immer aufgerufen, auch wenn das Loeschen fehlschlaegt (z.B. letzte Praxis). Der Editor schliesst sich dann, bevor die Error-Alert angezeigt werden kann. Das onDeleted-Callback wird zwar nicht aufgerufen, aber die View verlasst trotzdem den Editor. Fix: `dismiss()` nur aufrufen wenn `confirmDelete()` erfolgreich war — z.B. durch einen Rueckgabewert oder indem man auf `errorMessage == nil` prueft.

DISCUSSION:
<!-- DISCUSSION_START -->
- ios/StillMoment/Resources/en.lproj/Localizable.strings:319,336,337,346 - EN-Inkonsistenz: Die gesamte restliche EN-Lokalisierung verwendet "Practice" (praxis.pill.label, praxis.sheet.title, praxis.delete.title etc.), aber die Editor-Keys nutzen "Praxis" ("Edit Praxis", "Delete Praxis?", "Praxis name"). Das sieht fuer EN-Nutzer inkonsistent aus. Entweder durchgehend "Praxis" oder durchgehend "Practice" verwenden.
- ios/StillMoment/Application/ViewModels/PraxisEditorViewModel.swift:147-154 - `playGongPreview` und `playIntervalGongPreview` sind faktisch identisch (beide rufen `audioService.playGongPreview` auf). Eine gemeinsame Methode wuerde ausreichen — der Unterschied liegt nur im Log-Prefix.
<!-- DISCUSSION_END -->

Summary:
Der Code ist solide implementiert und erfuellt fast alle Akzeptanzkriterien. Architektur, Testabdeckung und Lokalisierungsabdeckung sind gut. Es gibt einen echten Bug: Wenn der User versucht die letzte Praxis zu loeschen, wird der Editor geschlossen (dismiss() wird aufgerufen), bevor die Fehlermeldung angezeigt werden kann. Der Nutzer sieht die Fehlermeldung nie. Ausserdem gibt es eine Inkonsistenz in der EN-Lokalisierung: der Rest der App sagt "Practice", der Editor sagt "Praxis".
