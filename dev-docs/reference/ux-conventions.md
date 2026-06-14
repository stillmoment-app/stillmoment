# UX-Konventionen

## Zweck

Dieses Dokument beschreibt den **Soll-Zustand**, wie sich Dialoge, Editoren und
Einstellungen in Still Moment verhalten — auf beiden Plattformen identisch im
*Verhalten*, je nativ in der *Umsetzung*. Es ersetzt kein HIG/Material, sondern
legt fest, welches Muster wir wann wählen, damit die App sich überall gleich anfühlt.

Es beschreibt das **Ziel**, nicht den heutigen Code. Stellen, an denen die
Implementierung abweicht, werden als Tickets geführt, nicht hier.

**Beim Planen eines neuen Features ist die erste Frage:** *Welcher der zwei
Archetypen (§2) ist das?* Daraus folgen Navigation, Speicher-Semantik,
Discard-Schutz und das Verhalten von Sub-Flächen automatisch — sie sind keine
unabhängigen Entscheidungen.

**Oberste Regel** (aus `CLAUDE.md`): Beide Plattformen verhalten sich identisch —
gleiche Features, gleiche UX, gleiche Edge Cases. Plattform-Unterschiede sind nur
dort erlaubt, wo das native Framework es erzwingt (siehe [§5 Cross-Platform](#cross-platform)).

---

## 1. Grundprinzipien

1. **Eine Fläche, eine abgeschlossene Aufgabe.** Es ist immer nur eine View vorne.
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

## 2. Die zwei Archetypen — die eine Entscheidung {#archetypen}

Fast jede UX-Frage in dieser App entscheidet sich an *einer* Weiche: Ist die Fläche
ein **Nutzungs-Screen** oder ein **Editor**? Alles Weitere — Navigation, Speichern,
Abbrechen, Sub-Flächen — folgt aus dieser Einordnung.

**Entscheidungsfrage:**

> *Öffne ich einen dedizierten Editor, um ein benanntes Objekt als Ganzes zu
> bearbeiten?* → **Editor (§4).**
> *Stelle ich auf einem Nutzungs-Screen einzelne Schalter / Auswahlen ein?* →
> **Nutzungs-Screen (§3).**

**Maßgeblich ist die Fläche/Absicht, nicht der Inhaltstyp** (shared-111): Auch wenn
hinter den Timer-Einstellungen technisch *ein* Konfigurationsobjekt steht, ist der
Timer kein Editor — jede Einstellung steht für sich und wird sofort übernommen.
Entscheidend ist, ob der User mehrere Felder als *Einheit* bestätigt (Editor) oder
einzelne Schalter auf einem Nutzungs-Screen umlegt (Nutzungs-Screen).

|                         | **Nutzungs-Screen** (§3)                                        | **Editor** (§4)                          |
| ----------------------- | --------------------------------------------------------------- | ---------------------------------------- |
| **Beispiele**           | Timer + seine Einstellungen, App-Settings, Theme-/Sound-Auswahl | Meditation bearbeiten, Import, Trim      |
| **Was wird bearbeitet** | einzelne Einstellungen, jede für sich                           | ein benanntes Objekt als Ganzes          |
| **Navigation**          | inline in Liste/Form oder eigener Auswahl-Screen                | Vollbild-**Screen**                      |
| **Speichern**           | Auto-Save bei Änderung/Auswahl                                  | explizit Save/Cancel                     |
| **Abbrechen**           | gibt es nicht — „Zurück" = fertig                               | Cancel verwirft                          |
| **Discard-Schutz**      | nein (nichts geht verloren)                                     | ja, einmal beim Verlassen mit Änderungen |
| **Sub-Flächen**         | übernehmen sofort, „Zurück" = fertig                            | erben den Editor-Puffer, nur „Zurück"    |

**Begründung** (shared-036): Sheets signalisieren „temporär, kommt zurück" und eignen
sich für kurze Einzelaufgaben. Kern-Features und Editoren mit mehreren Feldern sind
Vollbild-Screens, damit sie sich ernst und fokussiert anfühlen und Platz für ihre
Sektionen haben.

**Container ≠ Semantik:** Die Einordnung bestimmt das *Verhalten*, nicht die
*Darstellung*. Eine Fläche darf Vollbild-Cover, Sheet, Push oder inline sein — je
nachdem, wie viel Platz ihr Inhalt braucht. Eine kurze Einzeleingabe (z. B.
Umbenennen) ist als Sheet/Dialog ein Nutzungs-Screen; der Trim-Editor ist als
Vollbild-Fläche trotzdem eine Editor-Sub-Fläche (§4).

---

## 3. Archetyp A — Nutzungs-Screen {#nutzungs-screen}

Ein Screen, auf dem der User die App *benutzt* und dabei einzelne Einstellungen
justiert. Der Timer ist der Leitfall.

**Verhalten:**
- **Navigation:** Einstellungen werden inline auf dem Screen gestellt oder über
  einen eigenen Auswahl-Screen (z. B. Hintergrundton, Theme).
- **Speichern:** Auto-Save. Jede Änderung wird sofort übernommen und persistiert.
- **Kein Cancel, kein Discard:** „Zurück" bedeutet „fertig". Es gibt nichts zu
  verwerfen, weil nichts in der Schwebe ist.

**Sub-Einstellungen** (aus dem Screen geöffnet, z. B. Vorbereitungszeit, Gong,
Intervall, Hintergrundton): verhalten sich genauso — sofort übernehmen, „Zurück" =
fertig. Sie erben die Auto-Save-Semantik ihres Eltern-Screens (§4 erklärt das
allgemeine Erben-Prinzip für beide Archetypen).

**Timer im Detail:** Vorbereitungszeit, Gong, Intervall und Hintergrundton bilden
zusammen die eine gespeicherte Timer-Konfiguration — aber sie werden einzeln und
sofort gespeichert. Es gibt bewusst *keinen* Timer-Editor mit Save/Cancel
(shared-111): Der Timer ist ein Nutzungs-Screen, kein Editor.

---

## 4. Archetyp B — Editor {#editor}

Ein dedizierter Editor, um ein benanntes Objekt (eine Meditation) als Ganzes zu
bearbeiten. Mehrere Felder/Sektionen werden gemeinsam bestätigt.

### Navigation & Speicher-Semantik

- **Navigation:** Vollbild-**Screen** (iOS Navigation-Destination, Android
  Navigation-Screen). Das gibt den Sektionen (Metadaten, Wiedergabe-Bereich,
  Gong-Einstellungen) Platz und vermeidet Modal-im-Modal-Konstruktionen.
- **Save:** Save-Button rechts in der Toolbar, validiert (deaktiviert/Fehler bei
  ungültig). Speichern ist die *einzige* Persistierung.
- **Cancel:** Cancel-Button links (X-Icon). Verlassen ohne Save verwirft — mit
  Schutz (siehe unten).

### Abbrechen & Schutz vor Datenverlust

Ein Editor mit **ungespeicherten Änderungen** fragt beim Schließen nach.

| Situation | Verhalten |
|-----------|-----------|
| Editor **ohne** Änderungen schließen | Schließt sofort, kommentarlos |
| Editor **mit** ungespeicherten Änderungen schließen (X, Swipe, Back) | **Confirmation**: „Änderungen verwerfen?" / „Weiter bearbeiten" |
| Speichern bei ungültiger Eingabe | Save deaktiviert / Inline-Fehler, kein Schließen |

Nativ identisch im *Verhalten*:
- iOS: Swipe-/Back-Geste bei „dirty"-State abfangen + `confirmationDialog` mit
  „Verwerfen"/„Weiter bearbeiten".
- Android: `BackHandler` bei „dirty"-State + `AlertDialog` mit gleichen Optionen.

### Import vs. Edit — dieselbe Komponente

Import und Edit teilen sich **dieselbe Komponente** (Mode-Flag). Sie unterscheiden
sich nur in:

| Aspekt | Import | Edit |
|--------|--------|------|
| Button-Label | „Importieren" | „Speichern" |
| Autofokus | Namensfeld (wenn Prefill leer) | kein Autofokus |
| Persistierung | Datei wird **erst bei Save** kopiert (deferred); Cancel lässt die Library unverändert | ändert vorhandenes Objekt |
| Prefill | aus ID3-Tags + Dateiname berechnet | bestehende Werte |

**Begründung** (shared-031, ios-043): Nach Import öffnet sich automatisch der Editor
mit Prefill; bis Save ist nichts persistiert (Pending-State, Security-Scope bleibt
offen). Auch das ist konsequent die Editor-Semantik: Cancel = nichts passiert ist.

### Sub-Flächen eines Editors (Trim)

Sobald eine Fläche *aus* dem Editor geöffnet wird (z. B. Trim), stellt sich die
Frage, wer über Speichern und Verwerfen entscheidet.

**Regel: Eine Sub-Fläche erbt die Speicher-Semantik ihres Eltern — sie führt keine
eigene ein.** Beim Editor heißt das:

- **Kein** verschachteltes Save/Cancel: Die Sub-Fläche hat **kein** eigenes
  „Speichern" und **kein** eigenes „Verwerfen", nur **„Zurück"** (eine Ebene hoch).
- Sie bearbeitet direkt den *Puffer* des Editors; ihre Änderungen zählen zum
  Dirty-State des Editors.
- **Keine** zweite Discard-Rückfrage: Der Schutz greift **einmal**, beim äußersten
  expliziten Editor.

> Allgemein: Der Persistenz-Punkt ist immer der nächste „Editor"-Vorfahre. Gibt es
> keinen, ist es Auto-Save (Nutzungs-Screen, §3). Genau eine Ebene besitzt die
> Persistenz.

**Trim im Detail:** Der Trim-Editor wird aus dem Meditation-Editor geöffnet → nur
„Zurück"; die gesetzte Wiedergabe-Auswahl fließt in den Editor-Puffer und markiert
ihn als verändert. „Ganze Datei verwenden" setzt den Schnitt *innerhalb* von Trim
zurück. Gespeichert oder verworfen wird ausschließlich über den Editor (Save bzw. X
mit Rückfrage).

> ℹ️ Trim ist heute (iOS) im Import-Modus ausgeblendet, nur im nachträglichen Edit
> verfügbar. Trim-spezifische Konventionen (Waveform, Plattform-Konsistenz) werden
> separat behandelt (Feature kommt später) und sind **nicht** Teil dieses Dokuments.

---

## 5. Cross-Platform {#cross-platform}

**Identisch im Verhalten** (muss gleich sein):
- Welcher Archetyp eine Fläche ist (§2) und damit ihre Save-Semantik (§3/§4).
- Ob es eine Discard-Confirmation gibt (§4).
- Welche Felder editierbar sind, Validierungsregeln, Prefill-Logik.
- Verfügbarkeit von Features (ein Feature existiert auf beiden oder keiner Plattform).

**Nativ unterschiedlich erlaubt** (Framework-Zwang, nicht angleichen):
- Navigations-Mechanik: iOS Navigation-Destination vs. Android Navigation-Screen.
- Confirmation-Mechanik: iOS `confirmationDialog`/Action Sheet vs. Android `AlertDialog`.
- Button-Platzierung nach jeweiliger Plattform-Konvention (beide: Cancel links, Save rechts in der Top-Bar).
- Back-Geste (Android System-Back) vs. Swipe-/Back-Navigation (iOS).
