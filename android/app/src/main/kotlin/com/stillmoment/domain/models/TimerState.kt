package com.stillmoment.domain.models

/**
 * Represents the current state of the meditation timer.
 *
 * ## State Machine
 *
 * ```
 *  ┌──────┐ StartPressed  ┌───────────┐ CountdownFinished ┌─────────┐ TimerCompleted ┌───────────┐
 *  │ Idle │──────────────►│ Countdown │──────────────────►│ Running │───────────────►│ Completed │
 *  └──────┘               └───────────┘   + StartGong     └─────────┘   + Gong       └───────────┘
 *     ▲                        │                            │    ▲            │
 *     │                        │                 PausePressed│    │            │
 *     │   ResetPressed         │                            ▼    │            │
 *     │   (from any state      │                        ┌────────┐            │
 *     │    except Idle)        │                        │ Paused │            │
 *     │                        │                        └────────┘            │
 *     │                        │                            │ ResumePressed   │
 *     │                        │                            └─────────────────┤
 *     │                        │                                              │
 *     └────────────────────────┴──────────────────────────────────────────────┘
 * ```
 *
 * ## States
 *
 * - **Idle**: Timer Config Screen. User selects duration.
 * - **Countdown**: Focus Screen. 15s preparation countdown before meditation starts.
 * - **Running**: Focus Screen. Main meditation timer counting down.
 * - **Paused**: Focus Screen. Timer paused, can resume or reset.
 * - **Completed**: Focus Screen (briefly). Meditation finished, auto-navigates back.
 *
 * ## Transitions
 *
 * | From      | To        | Action            | Effects                          |
 * |-----------|-----------|-------------------|----------------------------------|
 * | Idle      | Countdown | StartPressed      | StartForegroundService, StartTimer |
 * | Countdown | Running   | CountdownFinished | PlayStartGong                    |
 * | Running   | Paused    | PausePressed      | PauseBackgroundAudio, PauseTimer |
 * | Paused    | Running   | ResumePressed     | ResumeBackgroundAudio, ResumeTimer |
 * | Running   | Completed | TimerCompleted    | PlayCompletionSound, StopForegroundService |
 * | Any*      | Idle      | ResetPressed      | StopForegroundService, ResetTimer |
 *
 * *ResetPressed has no effect when already Idle.
 *
 * ## UI Screens
 *
 * - **TimerScreen** (Config): Shown when state is Idle
 * - **TimerFocusScreen**: Shown when state is Countdown, Running, Paused, or Completed
 */
sealed class TimerState {
    /** Timer is idle and ready to start. Shows TimerScreen (config). */
    data object Idle : TimerState()

    /** Timer is in countdown phase (15 seconds before meditation). Shows TimerFocusScreen. */
    data object Countdown : TimerState()

    /** Timer is actively counting down the meditation. Shows TimerFocusScreen. */
    data object Running : TimerState()

    /** Timer is paused and can be resumed. Shows TimerFocusScreen. */
    data object Paused : TimerState()

    /** Timer has completed. Shows TimerFocusScreen briefly, then navigates back. */
    data object Completed : TimerState()
}
