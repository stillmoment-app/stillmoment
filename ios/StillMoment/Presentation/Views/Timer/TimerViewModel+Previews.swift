//
//  TimerViewModel+Previews.swift
//  Still Moment
//
//  Presentation - SwiftUI preview support for the timer screens (built on AppDependencies).
//

// MARK: - SwiftUI Preview Support

#if DEBUG
extension TimerViewModel {
    /// Creates a view model on the app's real services for SwiftUI previews,
    /// showing the given timer state.
    static func preview(state: TimerState = .idle) -> TimerViewModel {
        let viewModel = AppDependencies.live().makeTimerViewModel()

        switch state {
        case .idle:
            break // timer stays nil
        case .preparation:
            viewModel.timer = .stub(
                remainingSeconds: 600,
                state: .preparation,
                remainingPreparationSeconds: 10
            )
        case .startGong:
            viewModel.timer = .stub(remainingSeconds: 597, state: .startGong)
        case .running:
            viewModel.timer = .stub(remainingSeconds: 300, state: .running)
        case .endGong:
            viewModel.timer = .stub(remainingSeconds: 0, state: .endGong)
        case .completed:
            viewModel.timer = .stub(remainingSeconds: 0, state: .completed)
        }

        return viewModel
    }
}
#endif
