package com.stillmoment.presentation.navigation

import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.automirrored.outlined.QueueMusic
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
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
import com.stillmoment.data.FileOpenException
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.AppTab
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.ImportAudioType
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import com.stillmoment.presentation.ui.common.ImportTypeSelectionSheet
import com.stillmoment.presentation.ui.common.MeditationCompletionContent
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreen
import com.stillmoment.presentation.ui.meditations.GuidedMeditationsListScreen
import com.stillmoment.presentation.ui.settings.AppSettingsScreen
import com.stillmoment.presentation.ui.settings.SoundAttributionsScreen
import com.stillmoment.presentation.ui.timer.IntervalGongsEditorScreen
import com.stillmoment.presentation.ui.timer.PraxisEditorScreen
import com.stillmoment.presentation.ui.timer.SelectAttunementScreen
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

    data object PraxisEditorGraph : Screen("praxisEditorGraph")

    data object PraxisEditor : Screen("praxisEditor")

    data object SelectAttunement : Screen("selectAttunement")

    data object SelectBackground : Screen("selectBackground")

    data object SelectGong : Screen("selectGong")

    data object IntervalGongs : Screen("intervalGongs")

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
 * Bundles theme and appearance settings passed through the navigation graph.
 */
data class SettingsSheetState(
    val selectedTheme: ColorTheme,
    val onThemeChange: (ColorTheme) -> Unit,
    val selectedAppearanceMode: AppearanceMode,
    val onAppearanceModeChange: (AppearanceMode) -> Unit
)

private val tabs = persistentListOf(
    TabItem(
        tab = AppTab.TIMER,
        screen = Screen.TimerGraph,
        labelResId = R.string.tab_timer,
        selectedIcon = Icons.Filled.Timer,
        unselectedIcon = Icons.Outlined.Timer,
        accessibilityResId = R.string.accessibility_tab_timer
    ),
    TabItem(
        tab = AppTab.LIBRARY,
        screen = Screen.Library,
        labelResId = R.string.tab_library,
        selectedIcon = Icons.Filled.GraphicEq,
        unselectedIcon = Icons.Outlined.GraphicEq,
        accessibilityResId = R.string.accessibility_tab_library
    ),
    TabItem(
        tab = AppTab.SETTINGS,
        screen = Screen.SettingsGraph,
        labelResId = R.string.tab_settings,
        selectedIcon = Icons.AutoMirrored.Filled.QueueMusic,
        unselectedIcon = Icons.AutoMirrored.Outlined.QueueMusic,
        accessibilityResId = R.string.accessibility_tab_settings
    )
)

/**
 * Main navigation host for Still Moment.
 * Features TabView navigation with Timer, Library, and Settings tabs.
 * Remembers the last selected tab across app restarts.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Suppress("LongMethod") // Top-level navigation host coordinates import flow, sheet, and nav state
@Composable
fun StillMomentNavHost(
    settingsDataStore: SettingsDataStore,
    modifier: Modifier = Modifier,
    fileOpenHandler: FileOpenHandler? = null,
    customAudioRepository: CustomAudioRepository? = null,
    urlAudioDownloader: UrlAudioDownloaderProtocol? = null,
    pendingFileUri: StateFlow<Uri?> = MutableStateFlow(null),
    onClearFileUri: () -> Unit = {},
    pendingDownloadUrl: StateFlow<String?> = MutableStateFlow(null),
    onClearDownloadUrl: () -> Unit = {},
    navController: NavHostController = rememberNavController(),
    // Activity-scoped ViewModel — `LocalViewModelStoreOwner` at this composable's call
    // site is the host Activity, so the ViewModel lives until the activity is destroyed.
    // Its SavedStateHandle persists across system-initiated process death (shared-080).
    overlayViewModel: CompletionOverlayViewModel = hiltViewModel()
) {
    // Snapshot the marker at app start: later setMarker() calls (while the player
    // is still active) must not flip this overlay on. The overlay is only meant
    // for the case where a meditation finished while the app was suspended.
    var showCompletionOverlay by remember { mutableStateOf(overlayViewModel.isMarkerSetInitially) }

    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val savedTab by produceState<AppTab?>(initialValue = null) { value = settingsDataStore.getSelectedTab() }
    val startDestination = savedTab?.route ?: return
    val selectedTheme by settingsDataStore.selectedThemeFlow.collectAsState(initial = ColorTheme.DEFAULT)
    val selectedAppearanceMode by settingsDataStore.appearanceModeFlow
        .collectAsState(initial = AppearanceMode.DEFAULT)
    val settingsState = SettingsSheetState(
        selectedTheme = selectedTheme,
        onThemeChange = { scope.launch { settingsDataStore.setSelectedTheme(it) } },
        selectedAppearanceMode = selectedAppearanceMode,
        onAppearanceModeChange = { scope.launch { settingsDataStore.setAppearanceMode(it) } }
    )
    val pendingImportedMeditation = remember { MutableStateFlow<GuidedMeditation?>(null) }
    val pendingImportedCustomAudio = remember { MutableStateFlow<CustomAudioFile?>(null) }
    val stopMeditationSignal = remember { MutableStateFlow(false) }

    // Import type selection sheet state
    var showImportTypeSheet by remember { mutableStateOf(false) }
    var pendingImportUri by remember { mutableStateOf<Uri?>(null) }

    FileOpenEffect(
        fileOpenHandler = fileOpenHandler,
        pendingFileUri = pendingFileUri,
        onClearFileUri = onClearFileUri,
        snackbarHostState = snackbarHostState,
        onValidFile = { uri ->
            pendingImportUri = uri
            // Intentional: stop any running meditation before showing the type selection sheet.
            // If the user dismisses the sheet, the meditation stays stopped — the file open action
            // itself is the decision, no confirmation dialog for meditation abort.
            stopMeditationSignal.value = true
            showImportTypeSheet = true
        }
    )

    DownloadUrlEffect(
        urlAudioDownloader = urlAudioDownloader,
        pendingDownloadUrl = pendingDownloadUrl,
        onClearDownloadUrl = onClearDownloadUrl,
        onDownloadSuccess = { uri ->
            pendingImportUri = uri
            stopMeditationSignal.value = true
            showImportTypeSheet = true
        }
    )

    ImportTypeSheetEffect(
        showSheet = showImportTypeSheet,
        pendingUri = pendingImportUri,
        fileOpenHandler = fileOpenHandler,
        customAudioRepository = customAudioRepository,
        navController = navController,
        snackbarHostState = snackbarHostState,
        settingsDataStore = settingsDataStore,
        scope = scope,
        onMeditationImport = { pendingImportedMeditation.value = it },
        onCustomAudioImport = { pendingImportedCustomAudio.value = it },
        onDismiss = {
            showImportTypeSheet = false
            pendingImportUri = null
        }
    )

    Box(modifier = modifier.fillMaxSize()) {
        NavHostScaffold(
            navController = navController,
            snackbarHostState = snackbarHostState,
            startDestination = startDestination,
            settingsState = settingsState,
            pendingImportedMeditation = pendingImportedMeditation,
            onClearImportedMeditation = { pendingImportedMeditation.value = null },
            pendingImportedCustomAudio = pendingImportedCustomAudio,
            onClearImportedCustomAudio = { pendingImportedCustomAudio.value = null },
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

        // Top-level completion overlay — covers the entire NavHost when the previous
        // meditation finished while the app was suspended/terminated. See shared-080.
        if (showCompletionOverlay) {
            MeditationCompletionContent(
                onBack = {
                    overlayViewModel.clearMarker()
                    showCompletionOverlay = false
                },
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
    pendingImportedMeditation: StateFlow<GuidedMeditation?>,
    onClearImportedMeditation: () -> Unit,
    pendingImportedCustomAudio: StateFlow<CustomAudioFile?>,
    onClearImportedCustomAudio: () -> Unit,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    onMeditationFinish: () -> Unit,
    onMeditationLoad: () -> Unit,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // Screens with their own inner Scaffold manage system-bar insets themselves.
    // NavHostScaffold must NOT pass its padding to these screens, otherwise
    // full-screen overlays (completion screens) cannot cover the navigation bar area,
    // causing background colour bleed-through (green bar at the bottom).
    // Rule: screens that have an inner Scaffold AND hide the bottom bar.
    val screenManagesOwnInsets = currentDestination?.route?.let { route ->
        route == Screen.TimerFocus.route ||
            route == Screen.PraxisEditor.route ||
            route.startsWith("player")
    } == true

    val showBottomBar = currentDestination?.route?.let { route ->
        !screenManagesOwnInsets &&
            route != Screen.SoundAttributions.route &&
            route != Screen.SelectAttunement.route &&
            route != Screen.SelectBackground.route &&
            route != Screen.SelectGong.route &&
            route != Screen.IntervalGongs.route
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
                pendingImportedMeditation,
                onClearImportedMeditation,
                pendingImportedCustomAudio,
                onClearImportedCustomAudio,
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
    pendingImportedMeditation: StateFlow<GuidedMeditation?>,
    onClearImportedMeditation: () -> Unit,
    pendingImportedCustomAudio: StateFlow<CustomAudioFile?>,
    onClearImportedCustomAudio: () -> Unit,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    onMeditationFinish: () -> Unit,
    onMeditationLoad: () -> Unit
) {
    NavHost(navController = navController, startDestination = startDestination) {
        timerNavGraph(
            navController = navController,
            stopMeditationSignal = stopMeditationSignal,
            onConsumeStopSignal = onConsumeStopSignal,
            pendingImportedCustomAudio = pendingImportedCustomAudio,
            onClearImportedCustomAudio = onClearImportedCustomAudio
        )

        composable(Screen.Library.route) {
            val importedMeditation by pendingImportedMeditation.collectAsState()
            val listViewModel: GuidedMeditationsListViewModel = hiltViewModel()
            val currentOnClear by rememberUpdatedState(onClearImportedMeditation)

            LaunchedEffect(importedMeditation) {
                val meditation = importedMeditation ?: return@LaunchedEffect
                currentOnClear()
                listViewModel.showEditSheet(meditation)
            }

            GuidedMeditationsListScreen(
                onMeditationClick = { navController.navigate(Screen.Player.createRoute(it)) },
                viewModel = listViewModel
            )
        }

        navigation(startDestination = Screen.Settings.route, route = Screen.SettingsGraph.route) {
            composable(Screen.Settings.route) {
                val appSettingsViewModel: AppSettingsViewModel = hiltViewModel()
                val appSettingsUiState by appSettingsViewModel.uiState.collectAsState()
                AppSettingsScreen(
                    selectedTheme = settingsState.selectedTheme,
                    onThemeChange = settingsState.onThemeChange,
                    selectedAppearanceMode = settingsState.selectedAppearanceMode,
                    onAppearanceModeChange = settingsState.onAppearanceModeChange,
                    guidedSettings = appSettingsUiState.guidedSettings,
                    onGuidedSettingsChange = appSettingsViewModel::updateGuidedSettings,
                    onSoundAttributionsClick = { navController.navigate(Screen.SoundAttributions.route) }
                )
            }
            composable(Screen.SoundAttributions.route) {
                SoundAttributionsScreen(onBack = { navController.popBackStack() })
            }
        }

        playerComposable(navController, onMeditationFinish, onMeditationLoad)
    }
}

private fun NavGraphBuilder.timerNavGraph(
    navController: NavHostController,
    stopMeditationSignal: StateFlow<Boolean>,
    onConsumeStopSignal: () -> Unit,
    pendingImportedCustomAudio: StateFlow<CustomAudioFile?>,
    onClearImportedCustomAudio: () -> Unit
) {
    navigation(startDestination = Screen.Timer.route, route = Screen.TimerGraph.route) {
        composable(Screen.Timer.route) { backStackEntry ->
            val parentEntry = remember(backStackEntry) {
                navController.getBackStackEntry(Screen.TimerGraph.route)
            }
            val sharedViewModel: TimerViewModel = hiltViewModel(parentEntry)

            // Observe stop meditation signal from file import flow
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
                onNavigateToEditor = { navController.navigate(Screen.PraxisEditor.route) },
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

        praxisEditorNavGraph(navController, pendingImportedCustomAudio, onClearImportedCustomAudio)
    }
}

private fun NavGraphBuilder.praxisEditorNavGraph(
    navController: NavHostController,
    pendingImportedCustomAudio: StateFlow<CustomAudioFile?>,
    onClearImportedCustomAudio: () -> Unit
) {
    navigation(
        startDestination = Screen.PraxisEditor.route,
        route = Screen.PraxisEditorGraph.route
    ) {
        praxisEditorComposable(navController)
        praxisEditorSubScreens(navController, pendingImportedCustomAudio, onClearImportedCustomAudio)
    }
}

private fun NavGraphBuilder.praxisEditorComposable(navController: NavHostController) {
    composable(Screen.PraxisEditor.route) { backStackEntry ->
        val parentEntry = remember(backStackEntry) {
            navController.getBackStackEntry(Screen.PraxisEditorGraph.route)
        }
        val editorViewModel: PraxisEditorViewModel = hiltViewModel(parentEntry)
        val timerEntry = remember(backStackEntry) {
            navController.getBackStackEntry(Screen.TimerGraph.route)
        }
        val timerViewModel: TimerViewModel = hiltViewModel(timerEntry)

        PraxisEditorScreen(
            onNavigateBack = { praxis ->
                timerViewModel.applyPraxisUpdate(praxis)
                navController.popBackStack(Screen.Timer.route, false)
            },
            onNavigateToAttunement = { navController.navigate(Screen.SelectAttunement.route) },
            onNavigateToBackground = { navController.navigate(Screen.SelectBackground.route) },
            onNavigateToGong = { navController.navigate(Screen.SelectGong.route) },
            onNavigateToIntervalGongs = { navController.navigate(Screen.IntervalGongs.route) },
            viewModel = editorViewModel
        )
    }
}

private fun NavGraphBuilder.praxisEditorSubScreens(
    navController: NavHostController,
    pendingImportedCustomAudio: StateFlow<CustomAudioFile?>,
    onClearImportedCustomAudio: () -> Unit
) {
    composable(Screen.SelectAttunement.route) { backStackEntry ->
        val editorViewModel: PraxisEditorViewModel = hiltViewModel(
            remember(backStackEntry) { navController.getBackStackEntry(Screen.PraxisEditorGraph.route) }
        )
        val pendingFile by pendingImportedCustomAudio.collectAsState()
        val currentOnClear by rememberUpdatedState(onClearImportedCustomAudio)
        SelectAttunementScreen(
            onBack = { navController.popBackStack() },
            viewModel = editorViewModel,
            initialFileToRename = pendingFile?.takeIf { it.type == CustomAudioType.ATTUNEMENT },
            onConsumeInitialRename = currentOnClear
        )
    }

    composable(Screen.SelectBackground.route) { backStackEntry ->
        val editorViewModel: PraxisEditorViewModel = hiltViewModel(
            remember(backStackEntry) { navController.getBackStackEntry(Screen.PraxisEditorGraph.route) }
        )
        val pendingFile by pendingImportedCustomAudio.collectAsState()
        val currentOnClear by rememberUpdatedState(onClearImportedCustomAudio)
        SelectBackgroundSoundScreen(
            onBack = { navController.popBackStack() },
            viewModel = editorViewModel,
            initialFileToRename = pendingFile?.takeIf { it.type == CustomAudioType.SOUNDSCAPE },
            onConsumeInitialRename = currentOnClear
        )
    }

    composable(Screen.SelectGong.route) { backStackEntry ->
        val editorViewModel: PraxisEditorViewModel = hiltViewModel(
            remember(backStackEntry) { navController.getBackStackEntry(Screen.PraxisEditorGraph.route) }
        )
        SelectGongScreen(onBack = { navController.popBackStack() }, viewModel = editorViewModel)
    }

    composable(Screen.IntervalGongs.route) { backStackEntry ->
        val editorViewModel: PraxisEditorViewModel = hiltViewModel(
            remember(backStackEntry) { navController.getBackStackEntry(Screen.PraxisEditorGraph.route) }
        )
        IntervalGongsEditorScreen(onBack = { navController.popBackStack() }, viewModel = editorViewModel)
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

/**
 * Handles URL download when an audio URL is shared via text (e.g. Chrome).
 *
 * Shows an indeterminate progress dialog while downloading.
 * On success, passes the local file URI to [onDownloadSuccess] so the
 * existing import flow can proceed (type selection, import).
 * On failure, shows an error dialog with retry and cancel options.
 */
@Composable
private fun DownloadUrlEffect(
    urlAudioDownloader: UrlAudioDownloaderProtocol?,
    pendingDownloadUrl: StateFlow<String?>,
    onClearDownloadUrl: () -> Unit,
    onDownloadSuccess: (Uri) -> Unit
) {
    val downloadUrl by pendingDownloadUrl.collectAsState()
    var isDownloading by remember { mutableStateOf(false) }
    var failedUrl by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val currentOnClearDownloadUrl by rememberUpdatedState(onClearDownloadUrl)
    val currentOnDownloadSuccess by rememberUpdatedState(onDownloadSuccess)

    LaunchedEffect(downloadUrl) {
        val url = downloadUrl ?: return@LaunchedEffect
        val downloader = urlAudioDownloader ?: return@LaunchedEffect
        // Clear AFTER the download finishes; clearing first would mutate `downloadUrl`
        // mid-flight and cause LaunchedEffect to cancel its own coroutine, leaving
        // `isDownloading = true` forever and the loading dialog stuck on screen.
        isDownloading = true
        failedUrl = null
        val result = downloader.download(url)
        isDownloading = false
        result.fold(
            onSuccess = { uri -> currentOnDownloadSuccess(uri) },
            onFailure = { failedUrl = url }
        )
        currentOnClearDownloadUrl()
    }

    DownloadProgressDialog(isDownloading = isDownloading)

    DownloadErrorDialog(
        failedUrl = failedUrl,
        urlAudioDownloader = urlAudioDownloader,
        scope = scope,
        onRetryStart = { isDownloading = true },
        onRetryEnd = { isDownloading = false },
        onSuccess = currentOnDownloadSuccess,
        onFailure = { url -> failedUrl = url },
        onDismiss = { failedUrl = null }
    )
}

@Composable
private fun DownloadProgressDialog(isDownloading: Boolean) {
    if (!isDownloading) return
    val loadingText = stringResource(R.string.download_loading)
    AlertDialog(
        onDismissRequest = { /* not dismissable during download */ },
        title = { Text(loadingText) },
        text = { CircularProgressIndicator() },
        confirmButton = {}
    )
}

@Suppress("LongParameterList") // Retry dialog coordinates download state across multiple callbacks
@Composable
private fun DownloadErrorDialog(
    failedUrl: String?,
    urlAudioDownloader: UrlAudioDownloaderProtocol?,
    scope: kotlinx.coroutines.CoroutineScope,
    onRetryStart: () -> Unit,
    onRetryEnd: () -> Unit,
    onSuccess: (Uri) -> Unit,
    onFailure: (String) -> Unit,
    onDismiss: () -> Unit
) {
    if (failedUrl == null) return
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
                        result.fold(onSuccess = onSuccess, onFailure = { onFailure(failedUrl) })
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
 * On valid format, invokes [onValidFile] so the caller can show the type selection sheet.
 * On invalid format, shows an error snackbar.
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
 * Handles the import type selection sheet and subsequent import + navigation.
 * Shows [ImportTypeSelectionSheet] when [showSheet] is true.
 * On type selection, imports the file and navigates to the appropriate screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Suppress("LongParameterList") // Coordinates import flow across multiple subsystems
@Composable
private fun ImportTypeSheetEffect(
    showSheet: Boolean,
    pendingUri: Uri?,
    fileOpenHandler: FileOpenHandler?,
    customAudioRepository: CustomAudioRepository?,
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    settingsDataStore: SettingsDataStore,
    scope: kotlinx.coroutines.CoroutineScope,
    onMeditationImport: (GuidedMeditation) -> Unit,
    onCustomAudioImport: (CustomAudioFile) -> Unit,
    onDismiss: () -> Unit
) {
    val currentOnMeditationImport by rememberUpdatedState(onMeditationImport)
    val currentOnCustomAudioImport by rememberUpdatedState(onCustomAudioImport)
    val currentOnDismiss by rememberUpdatedState(onDismiss)

    // Resolve strings in composable scope so suspend functions don't need navController.context
    val errorAlreadyImported = stringResource(R.string.error_already_imported)
    val errorImportFailed = stringResource(R.string.error_import_failed)

    if (showSheet) {
        ImportTypeSelectionSheet(
            onTypeSelect = { importType ->
                currentOnDismiss()
                val uri = pendingUri ?: return@ImportTypeSelectionSheet
                scope.launch {
                    handleImportTypeSelection(
                        importType = importType,
                        uri = uri,
                        fileOpenHandler = fileOpenHandler,
                        customAudioRepository = customAudioRepository,
                        navController = navController,
                        snackbarHostState = snackbarHostState,
                        settingsDataStore = settingsDataStore,
                        onMeditationImport = currentOnMeditationImport,
                        onCustomAudioImport = currentOnCustomAudioImport,
                        errorAlreadyImported = errorAlreadyImported,
                        errorImportFailed = errorImportFailed
                    )
                }
            },
            onDismiss = currentOnDismiss
        )
    }
}

/**
 * Handles file import based on the selected type.
 * Navigates to the appropriate screen after successful import.
 */
@Suppress("LongParameterList") // Import handler dispatches to different flows based on type
private suspend fun handleImportTypeSelection(
    importType: ImportAudioType,
    uri: Uri,
    fileOpenHandler: FileOpenHandler?,
    customAudioRepository: CustomAudioRepository?,
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    settingsDataStore: SettingsDataStore,
    onMeditationImport: (GuidedMeditation) -> Unit,
    onCustomAudioImport: (CustomAudioFile) -> Unit,
    errorAlreadyImported: String,
    errorImportFailed: String
) {
    when (importType) {
        ImportAudioType.GUIDED_MEDITATION -> handleGuidedMeditationImport(
            uri = uri,
            fileOpenHandler = fileOpenHandler,
            navController = navController,
            snackbarHostState = snackbarHostState,
            onMeditationImport = onMeditationImport,
            errorAlreadyImported = errorAlreadyImported,
            errorImportFailed = errorImportFailed
        )
        ImportAudioType.SOUNDSCAPE -> handleCustomAudioImport(
            uri = uri,
            audioType = CustomAudioType.SOUNDSCAPE,
            customAudioRepository = customAudioRepository,
            navController = navController,
            snackbarHostState = snackbarHostState,
            settingsDataStore = settingsDataStore,
            targetScreen = Screen.SelectBackground,
            onCustomAudioImport = onCustomAudioImport,
            errorImportFailed = errorImportFailed
        )
        ImportAudioType.ATTUNEMENT -> handleCustomAudioImport(
            uri = uri,
            audioType = CustomAudioType.ATTUNEMENT,
            customAudioRepository = customAudioRepository,
            navController = navController,
            snackbarHostState = snackbarHostState,
            settingsDataStore = settingsDataStore,
            targetScreen = Screen.SelectAttunement,
            onCustomAudioImport = onCustomAudioImport,
            errorImportFailed = errorImportFailed
        )
    }
}

private suspend fun handleGuidedMeditationImport(
    uri: Uri,
    fileOpenHandler: FileOpenHandler?,
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    onMeditationImport: (GuidedMeditation) -> Unit,
    errorAlreadyImported: String,
    errorImportFailed: String
) {
    val handler = fileOpenHandler ?: return

    navController.navigate(Screen.Library.route) {
        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }

    val result = handler.handleFileOpen(uri)
    result.fold(
        onSuccess = { meditation -> onMeditationImport(meditation) },
        onFailure = { error ->
            val message = when ((error as? FileOpenException)?.error) {
                FileOpenError.ALREADY_IMPORTED -> errorAlreadyImported
                FileOpenError.UNSUPPORTED_FORMAT, FileOpenError.IMPORT_FAILED, null -> errorImportFailed
            }
            snackbarHostState.showSnackbar(message = message, duration = SnackbarDuration.Short)
        }
    )
}

@Suppress("LongParameterList") // Import + navigate + error display requires these dependencies
private suspend fun handleCustomAudioImport(
    uri: Uri,
    audioType: CustomAudioType,
    customAudioRepository: CustomAudioRepository?,
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    settingsDataStore: SettingsDataStore,
    targetScreen: Screen,
    onCustomAudioImport: (CustomAudioFile) -> Unit,
    errorImportFailed: String
) {
    val repository = customAudioRepository ?: return

    val result = repository.importFile(uri, audioType)
    result.fold(
        onSuccess = { file ->
            onCustomAudioImport(file)
            settingsDataStore.setSelectedTab(AppTab.TIMER)
            navController.navigate(Screen.TimerGraph.route) {
                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                launchSingleTop = true
                restoreState = true
            }
            navController.navigate(Screen.PraxisEditor.route)
            navController.navigate(targetScreen.route)
        },
        onFailure = { error ->
            val errorMessage = error.message ?: errorImportFailed
            snackbarHostState.showSnackbar(
                message = errorMessage,
                duration = SnackbarDuration.Short
            )
        }
    )
}

@Composable
private fun StillMomentBottomBar(
    tabs: ImmutableList<TabItem>,
    currentDestination: androidx.navigation.NavDestination?,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        NavigationBar(
            containerColor = Color.Transparent,
            contentColor = MaterialTheme.colorScheme.primary,
            modifier = Modifier.widthIn(max = 280.dp)
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
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary,
                        unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
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
