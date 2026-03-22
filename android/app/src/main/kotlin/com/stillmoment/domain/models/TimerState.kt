package com.stillmoment.domain.models

/**
 * Represents the current state of the meditation timer.
 *
 * ## State Machine
 *
 * ```
 *  ┌──────┐ StartPressed  ┌─────────────┐ PrepFinished ┌───────────┐ GongFinished ┌────────────┐ AttunementDone ┌─────────┐ Completed ┌─────────┐ EndGongFinished ┌───────────┐
 *  │ Idle │──────────────►│ Preparation │─────────────►│ StartGong │─────────────►│ Attunement │───────────────►│ Running │──────────►│ EndGong │────────────────►│ Completed │
 *  └──────┘               └─────────────┘              └───────────┘              └────────────┘                └─────────┘           └─────────┘                 └───────────┘
 *     ▲                        │                             │                                                                              │                          │
 *     │   ResetPressed         │                             │ (no attunement)                                                              │                          │
 *     │   (from any state      │                             └──────────────────────────────────►│                                           │                          │
 *     │    except Idle)        │                                                                                                            │                          │
 *     │                        │                                                                                                            │                          │
 *     └────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────────────────┘
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
 * - **Attunement**: Focus Screen. Optional attunement audio playing, timer counting down.
 * - **Running**: Focus Screen. Main meditation timer counting down.
 * - **EndGong**: Focus Screen. Completion gong is playing after timer reached zero. Timer shows 00:00, ring is full.
 * - **Completed**: Focus Screen. Meditation finished, screen stays until user closes.
 *
 * ## Transitions
 *
 * | From         | To           | Action               | Effects                                    |
 * |--------------|--------------|----------------------|--------------------------------------------|
 * | Idle         | Preparation  | StartPressed         | StartForegroundService, StartTimer          |
 * | Preparation  | StartGong    | PreparationFinished  | PlayStartGong                              |
 * | StartGong    | Attunement   | StartGongFinished    | PlayAttunement (if attunement configured)   |
 * | StartGong    | Running      | StartGongFinished    | StartBackgroundAudio (if no attunement)     |
 * | Attunement   | Running      | AttunementFinished   | StopAttunement, StartBackgroundAudio        |
 * | Running      | EndGong      | TimerCompleted       | PlayCompletionSound                         |
 * | EndGong      | Completed    | EndGongFinished      | StopForegroundService                       |
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

    /** Attunement audio is playing, timer counting down. Shows TimerFocusScreen. */
    data object Attunement : TimerState()

    /** Timer is actively counting down the meditation. Shows TimerFocusScreen. */
    data object Running : TimerState()

    /** Completion gong is playing after timer reached zero. Timer shows 00:00, ring is full. */
    data object EndGong : TimerState()

    /** Timer has completed. Shows TimerFocusScreen briefly, then navigates back. */
    data object Completed : TimerState()
}
