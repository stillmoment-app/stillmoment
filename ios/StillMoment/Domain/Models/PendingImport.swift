//
//  PendingImport.swift
//  Still Moment
//
//  Domain-Value: Ausstehender Import zwischen Datei-Auswahl und Save im Edit-Sheet (ios-043).
//
//  Solange dieser Wert im ViewModel gehalten wird, ist eine Audiodatei extrahiert,
//  aber noch nicht persistiert — die Datei-Kopie und der `addMeditation`-Aufruf
//  erfolgen erst beim Save im Edit-Sheet. Cancel verwirft den Pending-State.
//

import Foundation

struct PendingImport: Equatable {
    /// Quelldatei mit Security-Scope (DocumentPicker oder Share Extension).
    let url: URL

    /// Extrahierte Audio-Metadaten (Dauer wird beim Save persistiert).
    let metadata: AudioMetadata

    /// Wurde `startAccessingSecurityScopedResource()` mit `true` quittiert?
    /// Wenn ja, muss bei Cancel/Save `stopAccessingSecurityScopedResource()` gerufen werden.
    let didStartAccessing: Bool

    /// ID des Draft-Eintrags, der im Edit-Sheet angezeigt wird.
    /// Dient zur Unterscheidung "Save im Import-Modus" vs. "Save im Edit-Modus" beim Save-Callback.
    let draftId: UUID
}
