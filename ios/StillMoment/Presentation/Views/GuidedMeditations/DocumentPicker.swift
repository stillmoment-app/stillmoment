//
//  DocumentPicker.swift
//  Still Moment
//
//  Presentation Layer - Document Picker for audio file import
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        // MARK: Lifecycle

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        // MARK: Internal

        let onPick: (URL) -> Void

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                return
            }
            self.onPick(url)
        }
    }

    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio, .mp3],
            asCopy: false
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: self.onPick)
    }
}

// MARK: - UTType Extension

extension UTType {
    static let mp3 = UTType(filenameExtension: "mp3") ?? .audio
}
