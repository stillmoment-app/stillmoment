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
import androidx.compose.material3.AlertDialog
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
import androidx.compose.material3.TextButton
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
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.AppTab
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.UrlAudioDownloadError
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import com.stillmoment.presentation.ui.common.DownloadProgressModal
import com.stillmoment.presentation.ui.common.MeditationCompletionContent
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreen
import com.stillmoment.presentation.ui.meditations.GuidedMeditationsListScreen
import com.stillmoment.presentation.ui.settings.AppSettingsScreen
import com.stillmoment.presentation.ui.settings.SoundAttributionsScreen
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.timer.IntervalGongsEditorScreen
import com.stillmoment.presentation.ui.timer.PraxisEditorScreen
import com.stillmoment.presentation.ui.timer.PreparationTimeSelectionScreen
import com.stillmoment.presentation.ui.timer.SelectBackgroundSoundScreen
import com.stillmoment.presentation.ui.timer.SelectGongScreen
import com.stillmoment.presentation.ui.timer.TimerFocusScreen
import com.stillmoment.presentation.ui.timer.TimerScreen
import com.stillmoment.presentation.viewmodel.AppSettingsViewModel
import com.stillmoment.presentation.viewmodel.CompletionOverlayViewModel
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListViewModel
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel
import com.stillmoment.presentation.viewmodel.TimerViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.CancellationException
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

    data object PraxisEditor : Screen("praxisEditor")

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
    urlAudioDownloader: UrlAudioDownloaderProtocol? = null,
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
    val pendingMeditationImportUri = remember { MutableStateFlow<Uri?>(null) }
    val stopMeditationSignal = remember { MutableStateFlow(false) }
    var isDownloading by remember { mutableStateOf(false) }

    FileOpenEffect(
        fileOpenHandler = fileOpenHandler,
        pendingFileUri = pendingFileUri,
        onClearFileUri = onClearFileUri,
        snackbarHostState = snackbarHostState,
        onValidFile = { uri ->
            stopMeditationSignal.value = true
            pendingMeditationImportUri.value = uri
        }
    )

    DownloadUrlEffect(
        urlAudioDownloader = urlAudioDownloader,
        pendingDownloadUrl = pendingDownloadUrl,
        onClearDownloadUrl = onClearDownloadUrl,
        onDownloadingChange = { isDownloading = it },
        onDownloadSuccess = { uri ->
            stopMeditationSignal.value = true
            pendingMeditationImportUri.value = uri
        }
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
            onMeditationFinish = { overlayViewModel.setMarker() },
            onMeditationLoad = { overlayViewModel.clearMarker() },
            onTabSelect = { tabItem ->
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
                    urlAudioDownloader?.cancel()
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
    pendingMeditationImportUri: StateFlow<Uri?>,
    onClearPendingImport: () -> Unit,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    onMeditationFinish: () -> Unit,
    onMeditationLoad: () -> Unit,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val screenManagesOwnInsets = currentDestination?.route?.let { route ->
        route == Screen.TimerFocus.route ||
            route == Screen.PraxisEditor.route ||
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
                onMeditationFinish,
                onMeditationLoad
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
    pendingMeditationImportUri: StateFlow<Uri?>,
    onClearPendingImport: () -> Unit,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    onMeditationFinish: () -> Unit,
    onMeditationLoad: () -> Unit
) {
    NavHost(navController = navController, startDestination = startDestination) {
        timerNavGraph(
            navController = navController,
            stopMeditationSignal = stopMeditationSignal,
            onConsumeStopSignal = onConsumeStopSignal
        )

        composable(Screen.Library.route) {
            val importedUri by pendingMeditationImportUri.collectAsState()
            val listViewModel: GuidedMeditationsListViewModel = hiltViewModel()
            val currentOnClear by rememberUpdatedState(onClearPendingImport)

            LaunchedEffect(importedUri) {
                val uri = importedUri ?: return@LaunchedEffect
                currentOnClear()
                listViewModel.importMeditation(uri)
            }

            ResetLibrarySearchOnPause(viewModel = listViewModel)

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

        playerComposable(navController, onMeditationFinish, onMeditationLoad)
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

private fun NavGraphBuilder.timerNavGraph(
    navController: NavHostController,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit
) {
    navigation(startDestination = Screen.Timer.route, route = Screen.TimerGraph.route) {
        timerIdleAndFocusComposables(navController, stopMeditationSignal, onConsumeStopSignal)
        praxisEditorComposable(navController)
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

private fun NavGraphBuilder.praxisEditorComposable(navController: NavHostController) {
    composable(Screen.PraxisEditor.route) { backStackEntry ->
        val timerEntry = remember(backStackEntry) {
            navController.getBackStackEntry(Screen.TimerGraph.route)
        }
        val editorViewModel: PraxisEditorViewModel = hiltViewModel(timerEntry)
        val timerViewModel: TimerViewModel = hiltViewModel(timerEntry)

        PraxisEditorScreen(
            onNavigateBack = { praxis ->
                timerViewModel.applyPraxisUpdate(praxis)
                navController.popBackStack(Screen.Timer.route, false)
            },
            onNavigateToBackground = { navController.navigate(Screen.SelectBackground.route) },
            onNavigateToGong = { navController.navigate(Screen.SelectGong.route) },
            onNavigateToIntervalGongs = { navController.navigate(Screen.IntervalGongs.route) },
            viewModel = editorViewModel
        )
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
): Pair<PraxisEditorViewModel, TimerViewModel> {
    val timerEntry = remember(backStackEntry) {
        navController.getBackStackEntry(Screen.TimerGraph.route)
    }

    @Suppress("ViewModelInjection")
    val editorViewModel: PraxisEditorViewModel = hiltViewModel(timerEntry)

    @Suppress("ViewModelInjection")
    val timerViewModel: TimerViewModel = hiltViewModel(timerEntry)
    return editorViewModel to timerViewModel
}

private fun saveAndPop(
    navController: NavHostController,
    editorViewModel: PraxisEditorViewModel,
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

private fun NavGraphBuilder.playerComposable(
    navController: NavHostController,
    onMeditationFinish: () -> Unit,
    onMeditationLoad: () -> Unit
) {
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
                onBack = { navController.popBackStack() },
                onMeditationFinish = onMeditationFinish,
                onMeditationLoad = onMeditationLoad
            )
        }
    }
}

private data class DownloadFailure(val url: String, val notAudio: Boolean)

@Composable
private fun DownloadUrlEffect(
    urlAudioDownloader: UrlAudioDownloaderProtocol?,
    pendingDownloadUrl: StateFlow<String?>,
    onClearDownloadUrl: () -> Unit,
    onDownloadingChange: (Boolean) -> Unit,
    onDownloadSuccess: (Uri) -> Unit
) {
    val downloadUrl by pendingDownloadUrl.collectAsState()
    var failure by remember { mutableStateOf<DownloadFailure?>(null) }
    val scope = rememberCoroutineScope()
    val currentOnClearDownloadUrl by rememberUpdatedState(onClearDownloadUrl)
    val currentOnDownloadingChange by rememberUpdatedState(onDownloadingChange)
    val currentOnDownloadSuccess by rememberUpdatedState(onDownloadSuccess)

    LaunchedEffect(downloadUrl) {
        val url = downloadUrl ?: return@LaunchedEffect
        val downloader = urlAudioDownloader ?: return@LaunchedEffect
        currentOnDownloadingChange(true)
        failure = null
        val result = downloader.download(url)
        currentOnDownloadingChange(false)
        result.fold(
            onSuccess = { uri -> currentOnDownloadSuccess(uri) },
            onFailure = { error ->
                if (error !is CancellationException) {
                    failure = DownloadFailure(url = url, notAudio = error is UrlAudioDownloadError.NotAudio)
                }
            }
        )
        currentOnClearDownloadUrl()
    }

    val current = failure
    if (current != null) {
        if (current.notAudio) {
            NotAudioErrorDialog(onDismiss = { failure = null })
        } else {
            RetryableErrorDialog(
                failedUrl = current.url,
                urlAudioDownloader = urlAudioDownloader,
                scope = scope,
                onRetryStart = { currentOnDownloadingChange(true) },
                onRetryEnd = { currentOnDownloadingChange(false) },
                onSuccess = currentOnDownloadSuccess,
                onFailure = { url, notAudio -> failure = DownloadFailure(url, notAudio) },
                onDismiss = { failure = null }
            )
        }
    }
}

@Composable
private fun NotAudioErrorDialog(onDismiss: () -> Unit) {
    val title = stringResource(R.string.download_error_not_audio_title)
    val message = stringResource(R.string.download_error_not_audio_message)
    val closeText = stringResource(R.string.download_error_close)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(closeText) }
        }
    )
}

@Composable
private fun InvalidShareEffect(invalidShareSignal: StateFlow<Boolean>, onClearSignal: () -> Unit) {
    val signal by invalidShareSignal.collectAsState()
    val currentOnClear by rememberUpdatedState(onClearSignal)
    if (signal) {
        NoLinkErrorDialog(onDismiss = { currentOnClear() })
    }
}

@Composable
private fun NoLinkErrorDialog(onDismiss: () -> Unit) {
    val title = stringResource(R.string.download_error_no_link_title)
    val message = stringResource(R.string.download_error_no_link_message)
    val closeText = stringResource(R.string.download_error_close)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(closeText) }
        }
    )
}

@Suppress("LongParameterList") // Retry dialog coordinates download state across multiple callbacks
@Composable
private fun RetryableErrorDialog(
    failedUrl: String,
    urlAudioDownloader: UrlAudioDownloaderProtocol?,
    scope: kotlinx.coroutines.CoroutineScope,
    onRetryStart: () -> Unit,
    onRetryEnd: () -> Unit,
    onSuccess: (Uri) -> Unit,
    onFailure: (String, Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    val errorTitle = stringResource(R.string.download_error_title)
    val errorMessage = stringResource(R.string.download_error_message)
    val retryText = stringResource(R.string.download_error_retry)
    val cancelText = stringResource(R.string.download_error_cancel)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(errorTitle) },
        text = { Text(errorMessage) },
        confirmButton = {
            TextButton(onClick = {
                onDismiss()
                if (urlAudioDownloader != null) {
                    onRetryStart()
                    scope.launch {
                        val result = urlAudioDownloader.download(failedUrl)
                        onRetryEnd()
                        result.fold(
                            onSuccess = onSuccess,
                            onFailure = { error ->
                                if (error !is CancellationException) {
                                    onFailure(failedUrl, error is UrlAudioDownloadError.NotAudio)
                                }
                            }
                        )
                    }
                }
            }) { Text(retryText) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(cancelText) }
        }
    )
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
    pendingImportUri: StateFlow<Uri?>,
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
