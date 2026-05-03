//
//  SettingDetailRoot.swift
//  Still Moment
//
//  Presentation Layer - Wrapper that resolves a SettingDestination into the
//  concrete detail view (shared-083). Kept as a stable single-type View so
//  that NavigationStack's `.navigationDestination(for:)` closure stays simple.
//

import SwiftUI

struct SettingDetailRoot: View {
    let destination: SettingDestination
    @ObservedObject var viewModel: PraxisEditorViewModel

    var body: some View {
        switch self.destination {
        case .preparation:
            PreparationTimeSelectionView(viewModel: self.viewModel)
        case .attunement:
            AttunementSelectionView(viewModel: self.viewModel)
        case .background:
            BackgroundSoundSelectionView(viewModel: self.viewModel)
        case .gong:
            GongSelectionView(viewModel: self.viewModel)
        case .interval:
            IntervalGongsEditorView(viewModel: self.viewModel)
        }
    }
}
