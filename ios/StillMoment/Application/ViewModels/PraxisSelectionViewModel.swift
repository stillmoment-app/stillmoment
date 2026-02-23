//
//  PraxisSelectionViewModel.swift
//  Still Moment
//
//  Application Layer - ViewModel for Praxis selection bottom sheet
//

import Foundation
import OSLog

/// ViewModel for the Praxis selection bottom sheet.
///
/// Manages loading, selecting, creating, and deleting Praxis presets.
/// Calls back into TimerViewModel via `onPraxisSelected` when a selection is made.
@MainActor
final class PraxisSelectionViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        repository: PraxisRepository = UserDefaultsPraxisRepository(),
        onPraxisSelected: @escaping (Praxis) -> Void
    ) {
        self.repository = repository
        self.onPraxisSelected = onPraxisSelected
    }

    // MARK: Internal

    /// All stored Praxis presets
    @Published var praxes: [Praxis] = []

    /// ID of the currently active Praxis
    @Published var activePraxisId: UUID?

    /// Praxis pending deletion (drives confirmation dialog)
    @Published var praxisToDelete: Praxis?

    /// Error message for failed operations
    @Published var errorMessage: String?

    /// Whether more than one Praxis exists (deletion guard)
    var canDeletePraxis: Bool {
        self.praxes.count > 1
    }

    /// The currently active Praxis, falling back to the first one
    var activePraxis: Praxis? {
        if let id = self.activePraxisId {
            return self.praxes.first { $0.id == id }
        }
        return self.praxes.first
    }

    // MARK: - Actions

    /// Loads all praxes from the repository
    func load() {
        self.praxes = self.repository.loadAll()
        self.activePraxisId = self.repository.activePraxisId ?? self.praxes.first?.id
        Logger.viewModel.info("Loaded \(self.praxes.count) praxes for selection")
    }

    /// Selects a Praxis: persists the active ID and calls back into TimerViewModel
    func selectPraxis(_ praxis: Praxis) {
        self.activePraxisId = praxis.id
        self.repository.setActivePraxisId(praxis.id)
        self.onPraxisSelected(praxis)
        Logger.viewModel.info("Praxis selected", metadata: ["name": praxis.name])
    }

    /// Creates a new Praxis with default values, saves it, selects it, and returns it
    @discardableResult
    func createNewPraxis() -> Praxis {
        let newPraxis = Praxis(
            name: NSLocalizedString("praxis.default.name", comment: "")
        )
        self.repository.save(newPraxis)
        self.praxes = self.repository.loadAll()
        self.selectPraxis(newPraxis)
        Logger.viewModel.info("Created new praxis", metadata: ["id": newPraxis.id.uuidString])
        return newPraxis
    }

    /// Schedules a Praxis for deletion (shows confirmation dialog)
    func requestDelete(_ praxis: Praxis) {
        self.praxisToDelete = praxis
    }

    /// Confirms and performs the pending deletion
    func confirmDelete() {
        guard let praxis = self.praxisToDelete else {
            return
        }
        do {
            try self.repository.delete(id: praxis.id)
            self.praxes = self.repository.loadAll()
            // If the deleted praxis was active, fall back to first remaining
            if self.activePraxisId == praxis.id, let first = self.praxes.first {
                self.selectPraxis(first)
            }
            Logger.viewModel.info("Deleted praxis", metadata: ["id": praxis.id.uuidString])
        } catch PraxisRepositoryError.cannotDeleteLastPraxis {
            self.errorMessage = NSLocalizedString("praxis.delete.title", comment: "")
            Logger.viewModel.error("Cannot delete last praxis")
        } catch {
            self.errorMessage = error.localizedDescription
            Logger.viewModel.error("Failed to delete praxis", error: error)
        }
        self.praxisToDelete = nil
    }

    // MARK: Private

    private let repository: PraxisRepository
    private let onPraxisSelected: (Praxis) -> Void
}
