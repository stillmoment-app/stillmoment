package com.stillmoment.presentation.navigation

import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.navigation
import com.stillmoment.R
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.data.LinkImportHandler
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.AppTab
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.presentation.ui.common.DownloadProgressModal
import com.stillmoment.presentation.ui.common.LinkImportErrorDialog
import com.stillmoment.presentation.ui.common.MeditationCompletionContent
import com.stillmoment.presentation.ui.common.NoLinkErrorDialog
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreen
import com.stillmoment.presentation.ui.meditations.GuidedMeditationsListScreen
import com.stillmoment.presentation.ui.settings.AppSettingsScreen
import com.stillmoment.presentation.ui.settings.SoundAttributionsScreen
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.timer.IntervalGongsEditorScreen
import com.stillmoment.presentation.ui.timer.PreparationTimeSelectionScreen
import com.stillmoment.presentation.ui.timer.SelectBackgroundSoundScreen
import com.stillmoment.presentation.ui.timer.SelectGongScreen
import com.stillmoment.presentation.ui.timer.TimerFocusScreen
import com.stillmoment.presentation.ui.timer.TimerScreen
import com.stillmoment.presentation.viewmodel.AppSettingsViewModel
import com.stillmoment.presentation.viewmodel.CompletionOverlayViewModel
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListViewModel
import com.stillmoment.presentation.viewmodel.PraxisSettingsViewModel
import com.stillmoment.presentation.viewmodel.TimerViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Navigation routes for Still Moment.
 * Top-level tab routes are derived from AppTab (single source of truth).
 */
sealed class Screen(val route: String) {
    /** Parent route for timer-related screens (for shared ViewModel scoping) */
    data object TimerGraph : Screen(AppTab.TIMER.route)

    data object Timer : Screen("timer")

    data object TimerFocus : Screen("timerFocus")

    data object Library : Screen(AppTab.LIBRARY.route)

    /** Parent route for settings-related screens (for tab hierarchy matching) */
    data object SettingsGraph : Screen(AppTab.SETTINGS.route)

    data object Settings : Screen("settingsHome")

    data object SoundAttributions : Screen("soundAttributions")

    /** Debug-only Typography Reference Screen (shared-099). */
    data object DebugTypography : Screen("debugTypography")

    data object SelectBackground : Screen("selectBackground")

    data object SelectGong : Screen("selectGong")

    data object IntervalGongs : Screen("intervalGongs")

    data object PreparationTime : Screen("preparationTime")

    data object Player : Screen("player/{meditationJson}") {
        fun createRoute(meditation: GuidedMeditation): String {
            val json = Uri.encode(Json.encodeToString(meditation))
            return "player/$json"
        }
    }
}

/**
 * Tab item for bottom navigation
 */
data class TabItem(
    val tab: AppTab,
    val screen: Screen,
    val labelResId: Int,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val accessibilityResId: Int
)

/**
 * Bundles the appearance settings passed through the navigation graph.
 */
data class SettingsSheetState(
    val selectedAppearanceMode: AppearanceMode,
    val onAppearanceModeChange: (AppearanceMode) -> Unit
)

private val tabs = persistentListOf(
    TabItem(
        tab = AppTab.LIBRARY,
        screen = Screen.Library,
        labelResId = R.string.tab_library,
        selectedIcon = Icons.Filled.GraphicEq,
        unselectedIcon = Icons.Outlined.GraphicEq,
        accessibilityResId = R.string.accessibility_tab_library
    ),
    TabItem(
        tab = AppTab.TIMER,
        screen = Screen.TimerGraph,
        labelResId = R.string.tab_timer,
        selectedIcon = Icons.Filled.Timer,
        unselectedIcon = Icons.Outlined.Timer,
        accessibilityResId = R.string.accessibility_tab_timer
    ),
    TabItem(
        tab = AppTab.SETTINGS,
        screen = Screen.SettingsGraph,
        labelResId = R.string.tab_settings,
        selectedIcon = Icons.Filled.Tune,
        unselectedIcon = Icons.Outlined.Tune,
        accessibilityResId = R.string.accessibility_tab_settings
    )
)

/**
 * Main navigation host for Still Moment.
 *
 * Share-Import flow (shared-103): a shared audio file is imported directly as
 * a meditation — the previous Meditation/Soundscape choice sheet is gone.
 * Soundscape imports happen exclusively via Settings > Hintergrund-Sound.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Suppress("LongMethod") // Top-level navigation host coordinates import flow and nav state
@Composable
fun StillMomentNavHost(
    settingsDataStore: SettingsDataStore,
    modifier: Modifier = Modifier,
    fileOpenHandler: FileOpenHandler? = null,
    linkImportHandler: LinkImportHandler? = null,
    pendingFileUri: StateFlow<Uri?> = MutableStateFlow(null),
    onClearFileUri: () -> Unit = {},
    pendingDownloadUrl: StateFlow<String?> = MutableStateFlow(null),
    onClearDownloadUrl: () -> Unit = {},
    invalidShareSignal: StateFlow<Boolean> = MutableStateFlow(false),
    onClearInvalidShareSignal: () -> Unit = {},
    navController: NavHostController = rememberNavController(),
    overlayViewModel: CompletionOverlayViewModel = hiltViewModel()
) {
    var showCompletionOverlay by remember { mutableStateOf(overlayViewModel.isMarkerSetInitially) }
    val playerWiring = remember(overlayViewModel, navController) {
        PlayerCompletionWiring(
            setMarker = overlayViewModel::setMarker,
            clearMarker = overlayViewModel::clearMarker,
            leavePlayer = { navController.popBackStack() }
        )
    }

    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val savedTab by produceState<AppTab?>(initialValue = null) { value = settingsDataStore.getSelectedTab() }
    val startDestination = savedTab?.route ?: return
    val selectedAppearanceMode by settingsDataStore.appearanceModeFlow
        .collectAsState(initial = AppearanceMode.DEFAULT)
    val settingsState = SettingsSheetState(
        selectedAppearanceMode = selectedAppearanceMode,
        onAppearanceModeChange = { scope.launch { settingsDataStore.setAppearanceMode(it) } }
    )
    val pendingMeditationImportUri = remember { MutableStateFlow<SharedImport?>(null) }
    val stopMeditationSignal = remember { MutableStateFlow(false) }
    // shared-081: Der Dauer-Filter faellt nur beim Tab-Wechsel, nicht beim Player-Ausflug.
    // ON_PAUSE des Library-Eintrags feuert in beiden Faellen und taugt deshalb nicht —
    // dieses Signal unterscheidet die beiden. Gleiches Muster wie stopMeditationSignal.
    val libraryFilterResetSignal = remember { MutableStateFlow(false) }
    val sharedLinkImport = rememberSharedLinkImport(linkImportHandler) { imported ->
        stopMeditationSignal.value = true
        playerWiring.onSessionInterrupted()
        pendingMeditationImportUri.value = imported
    }
    val isDownloading by (sharedLinkImport?.isLoading ?: NotLoading).collectAsState()

    FileOpenEffect(
        fileOpenHandler = fileOpenHandler,
        pendingFileUri = pendingFileUri,
        onClearFileUri = onClearFileUri,
        snackbarHostState = snackbarHostState,
        onValidFile = { uri ->
            stopMeditationSignal.value = true
            playerWiring.onSessionInterrupted()
            pendingMeditationImportUri.value = SharedImport(uri = uri, suggestion = null)
        }
    )

    DownloadUrlEffect(
        sharedLinkImport = sharedLinkImport,
        pendingDownloadUrl = pendingDownloadUrl,
        onClearDownloadUrl = onClearDownloadUrl
    )

    InvalidShareEffect(
        invalidShareSignal = invalidShareSignal,
        onClearSignal = onClearInvalidShareSignal
    )

    MeditationImportNavigationEffect(
        pendingImportUri = pendingMeditationImportUri,
        navController = navController,
        settingsDataStore = settingsDataStore,
        scope = scope
    )

    Box(modifier = modifier.fillMaxSize()) {
        NavHostScaffold(
            navController = navController,
            snackbarHostState = snackbarHostState,
            startDestination = startDestination,
            settingsState = settingsState,
            pendingMeditationImportUri = pendingMeditationImportUri,
            onClearPendingImport = { pendingMeditationImportUri.value = null },
            stopMeditationSignal = stopMeditationSignal,
            onConsumeStopSignal = { stopMeditationSignal.value = false },
            libraryFilterResetSignal = libraryFilterResetSignal,
            onConsumeLibraryFilterReset = { libraryFilterResetSignal.value = false },
            playerWiring = playerWiring,
            onTabSelect = { tabItem ->
                if (tabItem.tab != AppTab.LIBRARY) {
                    libraryFilterResetSignal.value = true
                }
                scope.launch { settingsDataStore.setSelectedTab(tabItem.tab) }
                navController.navigate(tabItem.screen.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )

        AnimatedVisibility(
            visible = isDownloading,
            enter = fadeIn(animationSpec = tween(durationMillis = 200)),
            exit = fadeOut(animationSpec = tween(durationMillis = 200))
        ) {
            DownloadProgressModal(
                onCancel = {
                    sharedLinkImport?.cancel()
                }
            )
        }

        if (showCompletionOverlay) {
            MeditationCompletionContent(
                onBack = {
                    overlayViewModel.clearMarker()
                    showCompletionOverlay = false
                },
                backAccessibilityLabel = stringResource(R.string.accessibility_back_to_library),
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

@Suppress("LongParameterList") // Scaffold coordinates all nav-level state flows
@Composable
private fun NavHostScaffold(
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    startDestination: String,
    settingsState: SettingsSheetState,
    pendingMeditationImportUri: StateFlow<SharedImport?>,
    onClearPendingImport: () -> Unit,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    libraryFilterResetSignal: StateFlow<Boolean>,
    onConsumeLibraryFilterReset: () -> Unit,
    playerWiring: PlayerCompletionWiring,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val screenManagesOwnInsets = currentDestination?.route?.let { route ->
        route == Screen.TimerFocus.route ||
            route.startsWith("player")
    } == true

    val showBottomBar = currentDestination?.route?.let { route ->
        !screenManagesOwnInsets &&
            route != Screen.SoundAttributions.route &&
            route != Screen.SelectBackground.route &&
            route != Screen.SelectGong.route &&
            route != Screen.IntervalGongs.route &&
            route != Screen.PreparationTime.route
    } != false

    Scaffold(
        modifier = modifier,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            AnimatedVisibility(
                visible = showBottomBar,
                enter = slideInVertically(
                    animationSpec = tween(durationMillis = 350, easing = EaseInOut),
                    initialOffsetY = { it }
                ),
                exit = slideOutVertically(
                    animationSpec = tween(durationMillis = 350, easing = EaseInOut),
                    targetOffsetY = { it }
                )
            ) {
                StillMomentBottomBar(tabs = tabs, currentDestination = currentDestination, onTabSelect = onTabSelect)
            }
        },
        containerColor = Color.Transparent
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(if (screenManagesOwnInsets) PaddingValues(0.dp) else padding)) {
            StillMomentNavContent(
                navController,
                startDestination,
                settingsState,
                pendingMeditationImportUri,
                onClearPendingImport,
                stopMeditationSignal,
                onConsumeStopSignal,
                libraryFilterResetSignal,
                onConsumeLibraryFilterReset,
                playerWiring
            )
        }
    }
}

@Suppress("LongParameterList") // NavContent distributes state flows to child graphs
@Composable
private fun StillMomentNavContent(
    navController: NavHostController,
    startDestination: String,
    settingsState: SettingsSheetState,
    pendingMeditationImportUri: StateFlow<SharedImport?>,
    onClearPendingImport: () -> Unit,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    libraryFilterResetSignal: StateFlow<Boolean>,
    onConsumeLibraryFilterReset: () -> Unit,
    playerWiring: PlayerCompletionWiring
) {
    NavHost(navController = navController, startDestination = startDestination) {
        timerNavGraph(
            navController = navController,
            stopMeditationSignal = stopMeditationSignal,
            onConsumeStopSignal = onConsumeStopSignal
        )

        composable(Screen.Library.route) {
            val sharedImport by pendingMeditationImportUri.collectAsState()
            val listViewModel: GuidedMeditationsListViewModel = hiltViewModel()
            val currentOnClear by rememberUpdatedState(onClearPendingImport)

            LaunchedEffect(sharedImport) {
                val pending = sharedImport ?: return@LaunchedEffect
                currentOnClear()
                listViewModel.importMeditation(pending.uri, pending.suggestion)
            }

            ResetLibrarySearchOnPause(viewModel = listViewModel)

            ResetLibraryFilterOnTabSwitch(
                viewModel = listViewModel,
                signal = libraryFilterResetSignal,
                onConsume = onConsumeLibraryFilterReset
            )

            GuidedMeditationsListScreen(
                onMeditationClick = { meditation ->
                    listViewModel.recordSearchCommittedByOpening()
                    navController.navigate(Screen.Player.createRoute(meditation))
                },
                viewModel = listViewModel
            )
        }

        navigation(startDestination = Screen.Settings.route, route = Screen.SettingsGraph.route) {
            composable(Screen.Settings.route) {
                val appSettingsViewModel: AppSettingsViewModel = hiltViewModel()
                val appSettingsUiState by appSettingsViewModel.uiState.collectAsState()
                AppSettingsScreen(
                    selectedAppearanceMode = settingsState.selectedAppearanceMode,
                    onAppearanceModeChange = settingsState.onAppearanceModeChange,
                    guidedSettings = appSettingsUiState.guidedSettings,
                    onGuidedSettingsChange = appSettingsViewModel::updateGuidedSettings,
                    onSoundAttributionsClick = { navController.navigate(Screen.SoundAttributions.route) },
                    onDebugTypographyClick = { navController.navigate(Screen.DebugTypography.route) }
                )
            }
            composable(Screen.SoundAttributions.route) {
                SoundAttributionsScreen(onBack = { navController.popBackStack() })
            }
            if (com.stillmoment.BuildConfig.DEBUG) {
                composable(Screen.DebugTypography.route) {
                    com.stillmoment.presentation.ui.debug.DebugTypographyReferenceScreen()
                }
            }
        }

        playerComposable(playerWiring)
    }
}

/**
 * shared-101: Setzt die Library-Suche zurueck, sobald der Library-Screen den Fokus
 * verliert.
 */
@Composable
private fun ResetLibrarySearchOnPause(viewModel: GuidedMeditationsListViewModel) {
    val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    val currentViewModel by rememberUpdatedState(viewModel)
    androidx.compose.runtime.DisposableEffect(lifecycleOwner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_PAUSE) {
                currentViewModel.resetSearch()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
}

/**
 * shared-081: Setzt den Dauer-Filter zurueck, wenn der User die Bibliothek per Tab-Wechsel
 * verlaesst — ein Ausflug in den Player laesst ihn dagegen bestehen.
 *
 * Das Signal ueberlebt die Disposition des Composables, deshalb ist die Reihenfolge
 * unkritisch: Feuert der Effekt noch vor dem Verlassen, ist der Filter sofort weg; feuert
 * er erst beim Zurueckkommen, ebenfalls. Beide Wege enden im geforderten Zustand.
 */
@Composable
private fun ResetLibraryFilterOnTabSwitch(
    viewModel: GuidedMeditationsListViewModel,
    signal: StateFlow<Boolean>,
    onConsume: () -> Unit
) {
    val shouldReset by signal.collectAsState()
    val currentViewModel by rememberUpdatedState(viewModel)
    val currentOnConsume by rememberUpdatedState(onConsume)
    LaunchedEffect(shouldReset) {
        if (shouldReset) {
            currentViewModel.resetDurationFilter()
            currentOnConsume()
        }
    }
}

private fun NavGraphBuilder.timerNavGraph(
    navController: NavHostController,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit
) {
    navigation(startDestination = Screen.Timer.route, route = Screen.TimerGraph.route) {
        timerIdleAndFocusComposables(navController, stopMeditationSignal, onConsumeStopSignal)
        timerSubScreenComposables(navController)
    }
}

private fun NavGraphBuilder.timerIdleAndFocusComposables(
    navController: NavHostController,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit
) {
    composable(Screen.Timer.route) { backStackEntry ->
        val parentEntry = remember(backStackEntry) {
            navController.getBackStackEntry(Screen.TimerGraph.route)
        }
        val sharedViewModel: TimerViewModel = hiltViewModel(parentEntry)

        val shouldStop by stopMeditationSignal.collectAsState()
        val currentOnConsumeStop by rememberUpdatedState(onConsumeStopSignal)
        LaunchedEffect(shouldStop) {
            if (shouldStop) {
                sharedViewModel.resetTimer()
                currentOnConsumeStop()
            }
        }

        TimerScreen(
            onNavigateToFocus = { navController.navigate(Screen.TimerFocus.route) },
            onNavigateToPreparation = { navController.navigate(Screen.PreparationTime.route) },
            onNavigateToGong = { navController.navigate(Screen.SelectGong.route) },
            onNavigateToInterval = { navController.navigate(Screen.IntervalGongs.route) },
            onNavigateToBackground = { navController.navigate(Screen.SelectBackground.route) },
            viewModel = sharedViewModel
        )
    }

    composable(
        route = Screen.TimerFocus.route,
        enterTransition = { EnterTransition.None },
        exitTransition = { ExitTransition.None },
        popEnterTransition = { EnterTransition.None },
        popExitTransition = { ExitTransition.None }
    ) { backStackEntry ->
        val parentEntry = remember(backStackEntry) {
            navController.getBackStackEntry(Screen.TimerGraph.route)
        }
        val sharedViewModel: TimerViewModel = hiltViewModel(parentEntry)
        TimerFocusScreen(onBack = { navController.popBackStack() }, viewModel = sharedViewModel)
    }
}

private fun NavGraphBuilder.timerSubScreenComposables(navController: NavHostController) {
    selectBackgroundComposable(navController)
    selectGongComposable(navController)
    intervalGongsComposable(navController)
    preparationTimeComposable(navController)
}

@Suppress("ComposableNaming") // Returns ViewModels — naming convention not applicable.
@Composable
private fun rememberTimerScopedEditorViewModels(
    navController: NavHostController,
    backStackEntry: androidx.navigation.NavBackStackEntry
): Pair<PraxisSettingsViewModel, TimerViewModel> {
    val timerEntry = remember(backStackEntry) {
        navController.getBackStackEntry(Screen.TimerGraph.route)
    }

    @Suppress("ViewModelInjection")
    val editorViewModel: PraxisSettingsViewModel = hiltViewModel(timerEntry)

    @Suppress("ViewModelInjection")
    val timerViewModel: TimerViewModel = hiltViewModel(timerEntry)
    return editorViewModel to timerViewModel
}

private fun saveAndPop(
    navController: NavHostController,
    editorViewModel: PraxisSettingsViewModel,
    timerViewModel: TimerViewModel
) {
    timerViewModel.applyPraxisUpdate(editorViewModel.save())
    navController.popBackStack()
}

private fun NavGraphBuilder.selectBackgroundComposable(navController: NavHostController) {
    composable(Screen.SelectBackground.route) { backStackEntry ->
        val (editorViewModel, timerViewModel) = rememberTimerScopedEditorViewModels(navController, backStackEntry)
        SelectBackgroundSoundScreen(
            onBack = { saveAndPop(navController, editorViewModel, timerViewModel) },
            viewModel = editorViewModel
        )
    }
}

private fun NavGraphBuilder.selectGongComposable(navController: NavHostController) {
    composable(Screen.SelectGong.route) { backStackEntry ->
        val (editorViewModel, timerViewModel) = rememberTimerScopedEditorViewModels(navController, backStackEntry)
        SelectGongScreen(
            onBack = { saveAndPop(navController, editorViewModel, timerViewModel) },
            viewModel = editorViewModel
        )
    }
}

private fun NavGraphBuilder.intervalGongsComposable(navController: NavHostController) {
    composable(Screen.IntervalGongs.route) { backStackEntry ->
        val (editorViewModel, timerViewModel) = rememberTimerScopedEditorViewModels(navController, backStackEntry)
        IntervalGongsEditorScreen(
            onBack = { saveAndPop(navController, editorViewModel, timerViewModel) },
            viewModel = editorViewModel
        )
    }
}

private fun NavGraphBuilder.preparationTimeComposable(navController: NavHostController) {
    composable(Screen.PreparationTime.route) { backStackEntry ->
        val (editorViewModel, timerViewModel) = rememberTimerScopedEditorViewModels(navController, backStackEntry)
        PreparationTimeSelectionScreen(
            onBack = { saveAndPop(navController, editorViewModel, timerViewModel) },
            viewModel = editorViewModel
        )
    }
}

private fun NavGraphBuilder.playerComposable(playerWiring: PlayerCompletionWiring) {
    composable(
        route = Screen.Player.route,
        arguments = listOf(navArgument("meditationJson") { type = NavType.StringType })
    ) { backStackEntry ->
        val meditationJson = backStackEntry.arguments?.getString("meditationJson")
        val meditation = meditationJson?.let {
            Json.decodeFromString<GuidedMeditation>(Uri.decode(it))
        }
        meditation?.let {
            GuidedMeditationPlayerScreen(
                meditation = it,
                onBack = playerWiring::onLeavePlayer,
                onMeditationFinish = playerWiring::onMeditationFinish,
                onMeditationLoad = playerWiring::onMeditationLoad
            )
        }
    }
}

/**
 * A local audio file ready for the import edit sheet. [suggestion] comes from the
 * podcast import (episode title / podcast author, shared-128) and beats the
 * file's own ID3 values; `null` for file shares and ordinary links.
 */
private data class SharedImport(val uri: Uri, val suggestion: ImportPrefill?)

/** Stand-ins while no [LinkImportHandler] is wired (previews, tests): nothing loads, nothing fails. */
private val NotLoading: StateFlow<Boolean> = MutableStateFlow(false)
private val NoFailure: StateFlow<FailedLinkImport?> = MutableStateFlow(null)

/**
 * The [SharedLinkImport] of this navigation host, bound to the composition's scope.
 * `null` when no [LinkImportHandler] is wired.
 */
@Composable
private fun rememberSharedLinkImport(
    linkImportHandler: LinkImportHandler?,
    onImport: (SharedImport) -> Unit
): SharedLinkImport? {
    val scope = rememberCoroutineScope()
    val currentOnImport by rememberUpdatedState(onImport)
    return remember(linkImportHandler, scope) {
        linkImportHandler?.let { handler ->
            SharedLinkImport(
                scope = scope,
                import = handler::import,
                cancelRunning = handler::cancel,
                onImported = { imported -> currentOnImport(SharedImport(imported.uri, imported.suggestion)) }
            )
        }
    }
}

/**
 * Hands every shared link (ordinary audio link or Apple Podcasts episode) to
 * [SharedLinkImport] and shows its message. Which link wins and what loads is
 * decided there.
 */
@Composable
private fun DownloadUrlEffect(
    sharedLinkImport: SharedLinkImport?,
    pendingDownloadUrl: StateFlow<String?>,
    onClearDownloadUrl: () -> Unit
) {
    val downloadUrl by pendingDownloadUrl.collectAsState()
    val currentOnClearDownloadUrl by rememberUpdatedState(onClearDownloadUrl)

    LaunchedEffect(downloadUrl, sharedLinkImport) {
        val url = downloadUrl ?: return@LaunchedEffect
        val linkImport = sharedLinkImport ?: return@LaunchedEffect
        linkImport.share(url)
        currentOnClearDownloadUrl()
    }

    val failed by (sharedLinkImport?.failure ?: NoFailure).collectAsState()
    val current = failed
    if (current != null && sharedLinkImport != null) {
        LinkImportErrorDialog(
            failure = current.failure,
            onRetry = sharedLinkImport::retry,
            onDismiss = sharedLinkImport::dismissFailure
        )
    }
}

@Composable
private fun InvalidShareEffect(invalidShareSignal: StateFlow<Boolean>, onClearSignal: () -> Unit) {
    val signal by invalidShareSignal.collectAsState()
    val currentOnClear by rememberUpdatedState(onClearSignal)
    if (signal) {
        NoLinkErrorDialog(onDismiss = { currentOnClear() })
    }
}

/**
 * Validates file format when a file is shared with the app.
 *
 * On valid format, invokes [onValidFile] so the caller can route the URI to
 * the library import. On invalid format, shows an error snackbar.
 */
@Composable
private fun FileOpenEffect(
    fileOpenHandler: FileOpenHandler?,
    pendingFileUri: StateFlow<Uri?>,
    onClearFileUri: () -> Unit,
    snackbarHostState: SnackbarHostState,
    onValidFile: (Uri) -> Unit
) {
    val errorUnsupportedFormat = stringResource(R.string.error_unsupported_format)

    val fileUri by pendingFileUri.collectAsState()

    val currentOnClearFileUri by rememberUpdatedState(onClearFileUri)
    val currentOnValidFile by rememberUpdatedState(onValidFile)

    LaunchedEffect(fileUri) {
        val uri = fileUri ?: return@LaunchedEffect
        val handler = fileOpenHandler ?: return@LaunchedEffect

        currentOnClearFileUri()
        val result = handler.validateFileFormat(uri)
        result.fold(
            onSuccess = { currentOnValidFile(uri) },
            onFailure = {
                snackbarHostState.showSnackbar(
                    message = errorUnsupportedFormat,
                    duration = SnackbarDuration.Short
                )
            }
        )
    }
}

/**
 * Routes a validated shared URI to the Library tab; the Library composable
 * itself calls `viewModel.importMeditation(uri)` and is responsible for
 * clearing the pending URI when it has handed the work off.
 */
@Composable
private fun MeditationImportNavigationEffect(
    pendingImportUri: StateFlow<SharedImport?>,
    navController: NavHostController,
    settingsDataStore: SettingsDataStore,
    scope: kotlinx.coroutines.CoroutineScope
) {
    val pending by pendingImportUri.collectAsState()
    LaunchedEffect(pending) {
        if (pending == null) {
            return@LaunchedEffect
        }
        scope.launch {
            settingsDataStore.setSelectedTab(AppTab.LIBRARY)
        }
        navController.navigate(Screen.Library.route) {
            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
            launchSingleTop = true
            restoreState = true
        }
    }
}

@Composable
private fun StillMomentBottomBar(
    tabs: ImmutableList<TabItem>,
    currentDestination: androidx.navigation.NavDestination?,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    Box(modifier = modifier.fillMaxWidth()) {
        HorizontalDivider(
            color = theme.cardBorder,
            thickness = 0.5.dp,
            modifier = Modifier.fillMaxWidth().align(Alignment.TopCenter)
        )
        NavigationBar(
            containerColor = theme.tabBarBackground,
            contentColor = theme.settingsValueAccent
        ) {
            tabs.forEach { tabItem ->
                val selected = currentDestination?.hierarchy?.any { it.route == tabItem.screen.route } == true
                val accessibilityLabel = stringResource(tabItem.accessibilityResId)

                NavigationBarItem(
                    selected = selected,
                    onClick = { onTabSelect(tabItem) },
                    icon = {
                        Icon(
                            imageVector = if (selected) tabItem.selectedIcon else tabItem.unselectedIcon,
                            contentDescription = null
                        )
                    },
                    label = {
                        Text(
                            text = stringResource(tabItem.labelResId),
                            style = MaterialTheme.typography.labelSmall
                        )
                    },
                    colors =
                    NavigationBarItemDefaults.colors(
                        selectedIconColor = theme.settingsValueAccent,
                        selectedTextColor = theme.settingsValueAccent,
                        unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        indicatorColor = theme.settingsValueAccent.copy(alpha = 0.12f)
                    ),
                    modifier =
                    Modifier.semantics {
                        contentDescription = accessibilityLabel
                    }
                )
            }
        }
    }
}
