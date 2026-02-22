package com.stillmoment.domain.models

/**
 * Represents the current state of the meditation timer.
 *
 * ## State Machine
 *
 * ```
 *  ┌──────┐ StartPressed  ┌─────────────┐ PrepFinished ┌───────────┐ GongFinished ┌──────────────┐ IntroFinished ┌─────────┐ Completed ┌───────────┐
 *  │ Idle │──────────────►│ Preparation │─────────────►│ StartGong │─────────────►│ Introduction │──────────────►│ Running │──────────►│ Completed │
 *  └──────┘               └─────────────┘              └───────────┘              └──────────────┘               └─────────┘           └───────────┘
 *     ▲                        │                             │                                                                              │
 *     │   ResetPressed         │                             │ (no intro)                                                                   │
 *     │   (from any state      │                             └──────────────────────────────────►│                                           │
 *     │    except Idle)        │                                                                                                            │
 *     │                        │                                                                                                            │
 *     └────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 * ```
 *
 * ## Philosophy
 *
 * Meditation has no pause. If interrupted, the session ends (Close/Reset).
 * The timer keeps running — that IS the practice.
 *
 * ## States
 *
 * - **Idle**: Timer Config Screen. User selects duration.
 * - **Preparation**: Focus Screen. Configurable preparation time before meditation starts.
 * - **StartGong**: Transitional. Start gong is playing, timer countdown is active.
 * - **Introduction**: Focus Screen. Optional introduction audio playing, timer counting down.
 * - **Running**: Focus Screen. Main meditation timer counting down.
 * - **Completed**: Focus Screen. Meditation finished, screen stays until user closes.
 *
 * ## Transitions
 *
 * | From         | To           | Action               | Effects                                    |
 * |--------------|--------------|----------------------|--------------------------------------------|
 * | Idle         | Preparation  | StartPressed         | StartForegroundService, StartTimer          |
 * | Preparation  | StartGong    | PreparationFinished  | PlayStartGong                              |
 * | StartGong    | Introduction | StartGongFinished    | PlayIntroduction (if intro configured)      |
 * | StartGong    | Running      | StartGongFinished    | StartBackgroundAudio (if no intro)          |
 * | Introduction | Running      | IntroductionFinished | StopIntroduction, StartBackgroundAudio      |
 * | Running      | Completed    | TimerCompleted       | PlayCompletionSound, StopForegroundService  |
 * | Any*         | Idle         | ResetPressed         | StopForegroundService, ResetTimer           |
 *
 * *ResetPressed has no effect when already Idle.
 *
 * ## UI Screens
 *
 * - **TimerScreen** (Config): Shown when state is Idle
 * - **TimerFocusScreen**: Shown when state is Preparation, Running, or Completed
 */
sealed class TimerState {
    /** Timer is idle and ready to start. Shows TimerScreen (config). */
    data object Idle : TimerState()

    /** Timer is in preparation phase before meditation. Shows TimerFocusScreen. */
    data object Preparation : TimerState()

    /** Transitional state: start gong is playing, timer countdown is active. */
    data object StartGong : TimerState()

    /** Introduction audio is playing, timer counting down. Shows TimerFocusScreen. */
    data object Introduction : TimerState()

    /** Timer is actively counting down the meditation. Shows TimerFocusScreen. */
    data object Running : TimerState()

    /** Timer has completed. Shows TimerFocusScreen briefly, then navigates back. */
    data object Completed : TimerState()
}
