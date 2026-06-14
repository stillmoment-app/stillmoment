# UX-Konventionen

## Zweck

Dieses Dokument beschreibt den **Soll-Zustand**, wie sich Dialoge, Editoren und
Einstellungen in Still Moment verhalten — auf beiden Plattformen identisch im
*Verhalten*, je nativ in der *Umsetzung*. Es ersetzt kein HIG/Material, sondern
legt fest, welches Muster wir wann wählen, damit die App sich überall gleich anfühlt.

Es beschreibt das **Ziel**, nicht den heutigen Code. Stellen, an denen die
Implementierung abweicht, werden als Tickets geführt, nicht hier.

**Oberste Regel** (aus `CLAUDE.md`): Beide Plattformen verhalten sich identisch —
gleiche Features, gleiche UX, gleiche Edge Cases. Plattform-Unterschiede sind nur
dort erlaubt, wo das native Framework es erzwingt (siehe [Cross-Platform](#cross-platform)).

---

## Grundprinzipien

1. **Editoren sind abgeschlossene Aufgaben.** Es ist immer nur eine View vorne.
   Wer einen Editor oder ein Sheet verlässt, hat dort alle Aktionen beendet —
   gespeichert oder verworfen. Zwei bearbeitende Views überschneiden sich nie.
   (App-weiter Constraint dahinter: Während ein Timer läuft oder eine Meditation
   spielt, lässt die UI keine Navigation weg zu — ein Tab-Wechsel würde die Session
   beenden. Siehe `CLAUDE.md`.)
2. **Explizite Zustandsübergänge** (ADR-002): kein versteckter State-Change.
   Was der User ändert, ist sichtbar; was gespeichert wird, ist eine bewusste Aktion
   *oder* eine bewusst gewählte Auto-Save-Konvention — nie ein Zufall.
3. **Kein stiller Datenverlust.** Eine angefangene, ungespeicherte Eingabe darf nie
   kommentarlos verschwinden.

---

## 1. Navigation: Sheet vs. Screen vs. Inline

**Entscheidungsregel:**

| Aufgabe | Muster | iOS | Android |
|---------|--------|-----|---------|
| **Kern-Feature** (Timer-Fokus, Meditations-Player) | Vollbild-**Screen** mit Navigation, X-Icon zum Beenden | Navigation-Destination | Navigation-Screen |
| **Editor mit mehreren Feldern/Sektionen** (Meditation bearbeiten + Import, Praxis/Timer-Konfiguration) | Vollbild-**Screen** | Navigation-Destination | Navigation-Screen |
| **Kurze, einzelne Eingabe** (z.B. Umbenennen) | **Sheet / Dialog** | `.sheet` | `ModalBottomSheet` / Dialog |
| **Einzelne Einstellung / Auswahl** (Theme, Sound-Auswahl, Vorbereitungszeit) | **Inline** in Liste/Form oder eigener Auswahl-Screen | Form-Row / Push | Settings-Row / Screen |
| **Bestätigung / Zerstörerische Aktion** (Löschen, Verwerfen) | **Alert / ConfirmationDialog** | `confirmationDialog` | `AlertDialog` |

**Begründung** (shared-036): Sheets signalisieren „temporär, kommt zurück" und eignen
sich für kurze Einzelaufgaben. Kern-Features und Editoren mit mehreren Feldern sind
Vollbild-Screens, damit sie sich ernst und fokussiert anfühlen und Platz für ihre
Sektionen haben.

**Meditation bearbeiten & Import** sind ein Editor mit mehreren Sektionen (Metadaten,
Wiedergabe-Bereich, Gong-Einstellungen) → **Screen**, identisch zum Praxis-Editor. Das
vermeidet auch Modal-im-Modal-Konstruktionen (ein Vollbild-Sub-Editor, der aus einem
Sheet aufgeht).

---

## 2. Speicher-Semantik: Explizit Save vs. Auto-Save

Die zentrale Konvention. Sie entscheidet sich an der Art des Inhalts:

| Inhalt | Semantik | Cancel? | Beispiele |
|--------|----------|---------|-----------|
| **Benanntes Objekt aus mehreren Feldern** | **Explizit Save/Cancel** | Ja, verwirft | Meditation-Edit, Import, Praxis-Editor |
| **Einzelne Einstellung umschalten** | **Auto-Save on-change** | Nein | App-Settings, Vorbereitungszeit |
| **Auswahl aus einer Liste** | **Auto-Save bei Auswahl** | Nein (Back = fertig) | Hintergrund-Sound, Theme |

**Kernunterscheidung:** *Bearbeite ich ein zusammenhängendes Objekt?* → explizit
Save/Cancel, weil der User mehrere Felder als Einheit bestätigt. *Stelle ich einen
einzelnen Schalter / eine Auswahl ein?* → Auto-Save, weil jede Änderung für sich steht.

**Soll für Editoren** (explizit Save):
- Save-Button rechts in der Toolbar, validiert (deaktiviert/Fehler bei ungültig).
- Cancel-Button links (X-Icon).
- Speichern ist die *einzige* Persistierung — Verlassen ohne Save verwirft
  (mit Schutz, siehe §3).

---

## 3. Abbrechen & Schutz vor Datenverlust

**Soll:** Ein Editor mit **ungespeicherten Änderungen** fragt beim Schließen nach.

| Situation | Verhalten |
|-----------|-----------|
| Editor **ohne** Änderungen schließen | Schließt sofort, kommentarlos |
| Editor **mit** ungespeicherten Änderungen schließen (X, Swipe, Back) | **Confirmation**: „Änderungen verwerfen?" / „Weiter bearbeiten" |
| Speichern bei ungültiger Eingabe | Save deaktiviert / Inline-Fehler, kein Schließen |

**Umsetzung nativ identisch im Verhalten:**
- iOS: Swipe-/Back-Geste bei „dirty"-State abfangen + `confirmationDialog` mit
  „Verwerfen"/„Weiter bearbeiten".
- Android: `BackHandler` bei „dirty"-State + `AlertDialog` mit gleichen Optionen.

---

## 4. Import vs. Edit (Guided Meditations)

**Soll:** Import und Edit teilen sich **dieselbe Komponente** (Mode-Flag). Sie
unterscheiden sich nur in:

| Aspekt | Import | Edit |
|--------|--------|------|
| Button-Label | „Importieren" | „Speichern" |
| Autofokus | Namensfeld (wenn Prefill leer) | kein Autofokus |
| Persistierung | Datei wird **erst bei Save** kopiert (deferred); Cancel lässt die Library unverändert | ändert vorhandenes Objekt |
| Prefill | aus ID3-Tags + Dateiname berechnet | bestehende Werte |

**Begründung** (shared-031, ios-043): Nach Import öffnet sich automatisch der Editor
mit Prefill; bis Save ist nichts persistiert (Pending-State, Security-Scope bleibt
offen). Das ist konsistent gelöst und soll so bleiben.

> ℹ️ **Trim** ist heute (iOS) im Import-Modus ausgeblendet, nur im nachträglichen
> Edit verfügbar. Trim-spezifische Konventionen werden separat behandelt
> (Feature kommt später) und sind **nicht** Teil dieses Dokuments.

---

## 5. Cross-Platform {#cross-platform}

**Identisch im Verhalten** (muss gleich sein):
- Wann gespeichert / abgebrochen wird (Save-Semantik aus §2).
- Ob es eine Discard-Confirmation gibt (§3).
- Welche Felder editierbar sind, Validierungsregeln, Prefill-Logik.
- Verfügbarkeit von Features (ein Feature existiert auf beiden oder keiner Plattform).

**Nativ unterschiedlich erlaubt** (Framework-Zwang, nicht angleichen):
- Navigations-Mechanik: iOS Navigation-Destination vs. Android Navigation-Screen.
- Confirmation-Mechanik: iOS `confirmationDialog`/Action Sheet vs. Android `AlertDialog`.
- Button-Platzierung nach jeweiliger Plattform-Konvention (beide: Cancel links, Save rechts in der Top-Bar).
- Back-Geste (Android System-Back) vs. Swipe-/Back-Navigation (iOS).

<!-- Trim/Waveform-Konsistenz (iOS vs. Android) wird separat behandelt, kommt später. -->
