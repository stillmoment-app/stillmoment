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
| **Editor mit mehreren Feldern/Sektionen** (Meditation bearbeiten + Import) | Vollbild-**Screen** | Navigation-Destination | Navigation-Screen |
| **Kurze, einzelne Eingabe** (z.B. Umbenennen) | **Sheet / Dialog** | `.sheet` | `ModalBottomSheet` / Dialog |
| **Einzelne Einstellung / Auswahl** (Theme, Sound-Auswahl, Timer-Einstellungen wie Vorbereitungszeit/Gong/Intervall/Hintergrundton) | **Inline** in Liste/Form oder eigener Auswahl-Screen | Form-Row / Push | Settings-Row / Screen |
| **Bestätigung / Zerstörerische Aktion** (Löschen, Verwerfen) | **Alert / ConfirmationDialog** | `confirmationDialog` | `AlertDialog` |

**Begründung** (shared-036): Sheets signalisieren „temporär, kommt zurück" und eignen
sich für kurze Einzelaufgaben. Kern-Features und Editoren mit mehreren Feldern sind
Vollbild-Screens, damit sie sich ernst und fokussiert anfühlen und Platz für ihre
Sektionen haben.

**Meditation bearbeiten & Import** sind ein Editor mit mehreren Sektionen (Metadaten,
Wiedergabe-Bereich, Gong-Einstellungen) → **Screen**. Das vermeidet auch
Modal-im-Modal-Konstruktionen (ein Vollbild-Sub-Editor, der aus einem Sheet aufgeht).

> Der **Timer** ist bewusst *kein* solcher Editor: Seine Einstellungen werden inline auf
> dem Timer-Screen gestellt und sofort gespeichert — siehe §2 und
> das Gegenbeispiel in [§6](#verschachtelt).

---

## 2. Speicher-Semantik: Explizit Save vs. Auto-Save

Die zentrale Konvention. Sie entscheidet sich an der Art des Inhalts:

| Inhalt | Semantik | Cancel? | Beispiele |
|--------|----------|---------|-----------|
| **Dedizierter Editor für ein benanntes Objekt** | **Explizit Save/Cancel** | Ja, verwirft | Meditation-Edit, Import |
| **Einzelne Einstellung umschalten** | **Auto-Save on-change** | Nein | App-Settings, Timer-Einstellungen |
| **Auswahl aus einer Liste** | **Auto-Save bei Auswahl** | Nein (Back = fertig) | Hintergrund-Sound, Theme |

**Kernunterscheidung — maßgeblich ist die Fläche/Absicht, nicht der Inhaltstyp:**
*Öffne ich einen dedizierten Editor, um ein benanntes Objekt als Ganzes zu bearbeiten
(Meditation)?* → explizit Save/Cancel, weil der User mehrere Felder als Einheit bestätigt.
*Stelle ich auf einem Nutzungs-Screen einzelne Schalter / Auswahlen ein
(Timer-Einstellungen)?* → Auto-Save, weil jede Änderung für sich steht — auch wenn die
Einstellungen zusammen die eine gespeicherte Timer-Konfiguration bilden. Entscheidend ist
also nicht, ob technisch ein Objekt dahintersteht, sondern ob es ein Editor oder ein
Nutzungs-Screen ist.

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

> Für Flächen, die *aus* einem Editor geöffnet werden (z. B. Trim), greift der Schutz
> **einmal** beim äußeren Editor — siehe [§6](#verschachtelt).

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

---

## 6. Verschachtelte Flächen: Sub-Editoren & Sub-Einstellungen {#verschachtelt}

§2 regelt die Speicher-Semantik *einer* Fläche. Sobald eine Fläche *aus* einer anderen
geöffnet wird (z. B. der Trim-Editor aus dem Meditation-Editor), stellt sich die Frage
neu: Wer entscheidet über Speichern und Verwerfen?

**Regel: Eine Sub-Fläche erbt die Speicher-Semantik ihres Eltern — sie führt keine eigene ein.**

| Geöffnet aus … | Verhalten der Sub-Fläche | Affordance |
|----------------|--------------------------|------------|
| **Explizitem Save/Cancel-Editor** (§2, „benanntes Objekt") | Bearbeitet direkt den *Puffer* des Editors; ihre Änderungen zählen zum Dirty-State des Editors | Nur **„Zurück"** (eine Ebene hoch) |
| **Auto-Save-Screen** (§2, „Einstellung/Auswahl") | Übernimmt sofort wie jede Einstellung | „Zurück" = fertig |

**Folge — genau eine Ebene besitzt die Persistenz:**

- **Kein** verschachteltes Save/Cancel: Die Sub-Fläche eines Editors hat **kein** eigenes
  „Speichern" und **kein** eigenes „Verwerfen".
- **Keine** zweite Discard-Rückfrage: Der Schutz aus §3 greift **einmal**, beim äußersten
  expliziten Editor.
- Der Persistenz-Punkt ist immer der nächste „explizite Editor"-Vorfahre. Gibt es keinen,
  ist es Auto-Save.

**Container ≠ Semantik:** Die Regel betrifft nur die *Speicher-Logik*, nicht die
Darstellung. Eine Sub-Fläche darf Vollbild-Cover, Sheet oder Push sein — je nachdem, wie
viel Platz ihr Inhalt braucht (Trim z. B. volle Höhe für die Waveform).

**Beispiel Trim (Library):** Der Trim-Editor wird aus dem Meditation-Editor (explizit
Save/Cancel) geöffnet → nur „Zurück"; die gesetzte Wiedergabe-Auswahl fließt in den
Editor-Puffer und markiert ihn als verändert. „Ganze Datei verwenden" setzt den Schnitt
*innerhalb* von Trim zurück. Gespeichert oder verworfen wird ausschließlich über den
Editor (Save bzw. X mit Rückfrage, §3).

**Gegenbeispiel Timer:** Vorbereitungszeit, Gong, Intervall und Hintergrundton werden aus
dem Timer-Screen geöffnet, der *kein* expliziter Editor ist → jede Änderung wird sofort
übernommen, „Zurück" = fertig, kein Discard-Thema.
