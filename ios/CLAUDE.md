# iOS-Specific Patterns

Extends the root `CLAUDE.md`. Read that first.

---

## Swift Conventions

### @MainActor ViewModels

All ViewModels are `@MainActor final class`:

```swift
@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var displayState: TimerDisplayState = .initial
    @Published var settings: MeditationSettings = .default

    init(
        timerService: TimerServiceProtocol = TimerService(),
        audioService: AudioServiceProtocol = AudioService()
    ) { ... }
}
```

### Protocol-Based Architecture

Every service is a protocol in Domain, implemented in Infrastructure:

```swift
// Domain/
protocol AudioServiceProtocol {
    func configureAudioSession() throws
    func playStartGong(soundId: String, volume: Float) throws
}

// Infrastructure/
final class AudioService: AudioServiceProtocol { ... }
```

Constructor injection everywhere — no service locators, no singletons (except `AudioSessionCoordinator.shared`).

### Combine Bindings

Always `receive(on:)` before UI updates, always `[weak self]`:

```swift
private func setupBindings() {
    timerService.timerPublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] timer in
            self?.handleTimerUpdate(timer)
        }
        .store(in: &cancellables)
}
```

### Forbidden Type Patterns

Never use implicitly unwrapped optionals — use proper optionals instead:

```swift
var property: String!    // FORBIDDEN: implicitly unwrapped
var property: String?    // OK: proper optional
```

### Error Handling

Domain errors conform to `LocalizedError`:

```swift
enum MeditationTimerError: Error, LocalizedError {
    case invalidDuration(Int)

    var errorDescription: String? {
        switch self {
        case let .invalidDuration(minutes):
            "Invalid duration: \(minutes) minutes. Duration must be between 1 and 60 minutes."
        }
    }
}
```

Handle errors explicitly — never `try!`:

```swift
do {
    try audioService.configureAudioSession()
} catch {
    Logger.viewModel.error("Failed to configure audio session", error: error)
}
```

Prefer `guard let` for optionals:

```swift
guard let value = optional else { return }
```

---

## DDD in Swift

### Immutable Value Objects

Domain models never mutate — return new instances:

```swift
struct PreparationCountdown: Equatable {
    let totalSeconds: Int
    let remainingSeconds: Int

    func tick() -> PreparationCountdown {
        PreparationCountdown(
            totalSeconds: totalSeconds,
            remainingSeconds: max(0, remainingSeconds - 1)
        )
    }
}
```

Builder pattern for state transitions:

```swift
func withLocalFilePath(_ path: String) -> GuidedMeditation {
    GuidedMeditation(id: id, localFilePath: path, fileName: fileName, ...)
}
```

### Reducer Pattern

Pure function: `(State, Action, Settings) -> (State, [Effect])`:

```swift
enum TimerReducer {
    static func reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) { ... }
}
```

### Explicit Effects

Side effects are data, not hidden calls:

```swift
enum TimerEffect: Equatable {
    case configureAudioSession
    case playStartGong
    case startTimer(durationMinutes: Int)
    case saveSettings(MeditationSettings)
}
```

ViewModel executes effects after reducing:

```swift
func dispatch(_ action: TimerAction) {
    let (newState, effects) = TimerReducer.reduce(
        state: displayState, action: action, settings: settings
    )
    displayState = newState
    effects.forEach { executeEffect($0) }
}
```

---

## Logging

Use structured loggers with metadata — never `print()`:

```swift
Logger.timer.info("Started", metadata: ["duration": 10])
Logger.audio.info("Audio session activated for \(source.rawValue)")
Logger.viewModel.error("Failed to configure", error: error)
Logger.performance.measure(operation: "Loading audio") { try loadAudioFile() }
```

Available loggers: `.timer`, `.audio`, `.audioPlayer`, `.viewModel`, `.infrastructure`, `.performance`

---

## AudioSessionCoordinator

Thread-safe singleton managing exclusive audio access between Timer and Guided Meditations:

```swift
AudioSessionCoordinator.shared.requestAudioSession(for: .timer)
```

Uses a private serial `DispatchQueue` — always go through the coordinator, never configure `AVAudioSession` directly.

---

## Testing

### Mock Services via Protocols

```swift
@MainActor
final class TimerViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        sut = TimerViewModel(
            timerService: MockTimerService(),
            audioService: MockAudioService()
        )
    }
}
```

### Fachlich, Not Technical

```swift
// Wrong: tests implementation detail
XCTAssertTrue(SupportedAudioFormats.types.contains(.mpeg4Audio))

// Right: tests user requirement
XCTAssertTrue(canImportFile(withExtension: "mp4"))
```

### Given-When-Then

```swift
func testSecondSourceReplacesFirstSource() {
    // Given
    _ = try? sut.requestAudioSession(for: .timer)

    // When
    _ = try? sut.requestAudioSession(for: .guidedMeditation)

    // Then
    XCTAssertEqual(sut.activeSource.value, .guidedMeditation)
}
```
