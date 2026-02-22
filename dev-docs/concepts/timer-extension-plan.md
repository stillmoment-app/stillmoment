# Epics & Tickets: UI/UX Redesign & Timer-Erweiterungen

Dieses Dokument enthält die strukturierten Entwicklungs-Tickets für das Redesign der Timer-Konfiguration und die Einführung der "Praxis"-Presets sowie des Audio-Imports.

## EPIC 1: Neue App-Struktur & Globale Einstellungen

Ziel: Entrümpelung des Timer-Screens und Schaffung eines zentralen Ortes für app-weite Einstellungen.

### Ticket 1.1: Neue Hauptnavigation (Tab-Bar) implementieren

Typ: Story

Beschreibung: Als Nutzer möchte ich eine klare Navigation am unteren Bildschirmrand, um zwischen Timer, Bibliothek und Einstellungen zu wechseln.

Akzeptanzkriterien:

Tab-Bar mit 3 Icons: "Timer", "Bibliothek", "Einstellungen" ist permanent sichtbar (außer während einer laufenden Meditation).


Beim Wechsel der Tabs wird der korrekte View geladen.

### Ticket 1.2: Globalen "Einstellungen"-Screen aufbauen

Typ: Story

Beschreibung: Als Nutzer möchte ich meine App-übergreifenden Einstellungen an einem zentralen Ort verwalten.

Akzeptanzkriterien:

Neuer Screen im Tab "Einstellungen" (Design laut Mockup).

Bereich "Erscheinungsbild": Bisherige Color-Theme-Auswahl wird hierher migriert. Funktionalität bleibt erhalten.

Bereich "Info & Rechtliches": Statische Links zu Sound Attributions, Datenschutz und Anzeige der aktuellen App-Version.

## EPIC 2: "Praxis" (Timer-Presets)

Ziel: Nutzer können individuelle Timer-Setups speichern, abrufen und chronologisch bearbeiten, ohne den Hauptscreen zu überladen.

### Ticket 2.1: Datenmodell für "Praxis" (Presets) anlegen

Typ: Tech Task

Beschreibung: Das Datenmodell muss so erweitert werden, dass beliebig viele Timer-Konfigurationen ("Praxis") gespeichert werden können.

Akzeptanzkriterien:

Neues Datenmodell (z. B. CoreData, Realm, JSON) für ein Praxis-Objekt.

Eigenschaften: id, name, preparationTime, introAudioId, backgroundAudioId, startGongId, endGongId, intervalGongId.

Dauer (duration) ist kein Teil des Presets, sondern bleibt variabel auf dem Main-Screen.

Ein Default-Preset ("Standard") wird bei Neuinstallation automatisch angelegt.

### Ticket 2.2: Praxis-Auswahl (Pill-Button & Bottom Sheet) auf Main-Screen

Typ: Story

Beschreibung: Als Nutzer möchte ich auf dem Timer-Startbildschirm schnell meine gewünschte "Praxis" auswählen können.

Akzeptanzkriterien:

Pill-Button ("Praxis: [Name]") ist oben auf dem Timer-Screen platziert.

Klick auf Pill-Button öffnet ein Bottom Sheet mit einer Liste aller gespeicherten Praxis-Vorlagen.

Liste zeigt Name und kurze Zusammenfassung (z. B. "Stille • Tempelglocke").

Klick auf ein Listenelement wählt die Praxis aus (Häkchen) und schließt das Sheet.

Button "Neue Praxis erstellen" am Ende der Liste (öffnet leeren Bearbeiten-Screen).

### Ticket 2.3: "Praxis bearbeiten"-Screen (Chronologische UI)

Typ: Story

Beschreibung: Als Nutzer möchte ich die Bestandteile meiner Meditation in einer logischen, zeitlichen Reihenfolge (Vorbereitung -> Audio -> Gongs) konfigurieren.

Akzeptanzkriterien:

Klick auf das Bearbeiten-Icon im Bottom Sheet öffnet den Full-Screen-Editor.

Textfeld für den Namen der Praxis (bearbeitbar).

Sektion "Vorbereitung": UI für Vorbereitungszeit.

Sektion "Audio & Klänge": Einstiegspunkte für Einstimmung und Hintergrundklang.

Sektion "Gongs": Einstiegspunkte für Start/Ende und Intervalle.

Button "Praxis löschen" ganz unten (mit Bestätigungsdialog).

## EPIC 3: Eigene Audiodateien (CRUD)

Ziel: Nutzer können eigene Audio-Dateien für den Einstieg und den Hintergrund importieren und verwalten.

### Ticket 3.1: CRUD-Verwaltung für "Einstimmung"

Typ: Story

Beschreibung: Als Nutzer möchte ich eigene Sprachdateien als Einstimmung importieren, auswählen und löschen können.

Akzeptanzkriterien:

Klick auf "Einstimmung" im Praxis-Editor öffnet neuen Listen-Screen.

Sektion 1: Option "Ohne Einstimmung starten".

Sektion 2: Liste der integrierten/mitgelieferten Einstimmungen (Read-only).

Sektion 3: Liste der vom Nutzer importierten Dateien.

Swipe-to-Delete (oder Mülleimer-Icon), um eigene Dateien zu löschen (inkl. Löschen aus dem Dateisystem).

Button "+ Eigene Datei importieren" öffnet den nativen iOS Document Picker (oder Media Picker).

Gewählte Datei wird in den lokalen App-Speicher kopiert, umbenannt und der Liste hinzugefügt.

### Ticket 3.2: CRUD-Verwaltung für "Hintergrundklang"

Typ: Story

Beschreibung: Als Nutzer möchte ich eigene atmosphärische Sounds als Hintergrundklang importieren, auswählen und löschen können.

Akzeptanzkriterien:

Klick auf "Hintergrundklang" im Praxis-Editor öffnet neuen Listen-Screen.

Selbe Mechanik und UI wie Ticket 3.1.

Datenmodell hält die importierten Hintergrundklänge logisch getrennt von den Einstimmungen.

(Optional) Feature: Hintergrundklang loopt automatisch, wenn er kürzer als die Timer-Dauer ist.

## Epic 4: UI Polish & Immersion

### Ticket 4.1: Einheitliches Kontextmenü (...) für Listen-Elemente
Typ: Story / UI Task

Beschreibung: Als Nutzer möchte ich Aktionen für meine Timer-Setups ("Praxis") über das gleiche Kontextmenü steuern können, das ich bereits aus der "Guided Meditations" Bibliothek kenne, um eine konsistente Bedienung zu haben.

Akzeptanzkriterien:

Das Stift-Icon in der Praxis-Auswahlliste (Bottom Sheet) wird durch ein "Mehr" (... / MoreHorizontal) Icon ersetzt.

Ein Klick auf ... öffnet ein iOS-Standard-Kontextmenü (UIMenu).

Das Menü enthält die Optionen: "Bearbeiten" (öffnet den Editor) und "Löschen" (löscht das Element nach Bestätigung, Text in Rot).

(Optional) Der rote Löschen-Button am Ende des "Praxis bearbeiten"-Screens kann im Zuge dessen entfernt werden, da die Aktion nun im Kontextmenü lebt.

### Ticket 4.2: "Zen-Modus" (Distraction-Free) für den laufenden Timer
Typ: Story

Beschreibung: Als Nutzer möchte ich während der aktiven Meditation absolut keine ablenkenden UI-Elemente sehen, damit ich mich voll auf meine Praxis konzentrieren kann.

Akzeptanzkriterien:

Sobald auf "Start" geklickt wird, gleitet die untere Tab-Bar fließend nach unten aus dem Bildschirm.

Der "Praxis"-Auswahl-Button (Pill-Button oben) wird ausgeblendet.

Der Bildschirm zeigt ausschließlich: den Timer-Ring, die Begrüßung/Affirmation und einen dezenten "X"-Button zum Abbrechen oben links.

Sobald die Meditation beendet wird (oder über "X" abgebrochen wird), kehren Tab-Bar und Praxis-Auswahl fließend zurück.

auch bei guided meditations wird die tab bar ausgeblendet solange die meditation läuft.



### Ticket 4.4: Visuelle Anker (Icons) im "Praxis bearbeiten"-Screen
Typ: UI Task

Beschreibung: Als Nutzer möchte ich die verschiedenen Kategorien im Editor schneller visuell erfassen können, um mein Setup zügig anzupassen.

Akzeptanzkriterien:

Hinzufügen von dezenten Icons zu den Kategorie-Überschriften im Editor.

"Vorbereitung" erhält ein Sanduhr-Icon (Hourglass).

"Audio & Klänge" erhält ein Wind/Wellen-Icon (Wind).

"Gongs" erhält ein Glocken-Icon (Bell).

Die Icons werden in derselben Farbe wie die Kategorie-Labels (z.B. Slate-400) gerendert.
