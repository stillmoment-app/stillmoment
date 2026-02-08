package com.stillmoment.presentation.navigation

import android.net.Uri
import android.util.Log
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.outlined.LibraryMusic
import androidx.compose.material.icons.outlined.Timer
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
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreen
import com.stillmoment.presentation.ui.meditations.GuidedMeditationsListScreen
import com.stillmoment.presentation.ui.timer.TimerFocusScreen
import com.stillmoment.presentation.ui.timer.TimerScreen
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListViewModel
import com.stillmoment.presentation.viewmodel.TimerViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
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
        selectedIcon = Icons.Filled.LibraryMusic,
        unselectedIcon = Icons.Outlined.LibraryMusic,
        accessibilityResId = R.string.accessibility_tab_library
    )
)

/**
 * Main navigation host for Still Moment.
 * Features TabView navigation with Timer and Library tabs.
 * Remembers the last selected tab across app restarts.
 */
@Composable
fun StillMomentNavHost(
    settingsDataStore: SettingsDataStore,
    modifier: Modifier = Modifier,
    fileOpenHandler: FileOpenHandler? = null,
    pendingFileUri: StateFlow<Uri?>? = null,
    onClearFileUri: () -> Unit = {},
    navController: NavHostController = rememberNavController()
) {
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
    val pendingImportedMeditation = remember {
        kotlinx.coroutines.flow.MutableStateFlow<GuidedMeditation?>(null)
    }

    FileOpenEffect(
        fileOpenHandler = fileOpenHandler,
        pendingFileUri = pendingFileUri,
        onClearFileUri = onClearFileUri,
        navController = navController,
        snackbarHostState = snackbarHostState,
        pendingImportedMeditation = pendingImportedMeditation
    )

    NavHostScaffold(
        modifier = modifier,
        navController = navController,
        snackbarHostState = snackbarHostState,
        startDestination = startDestination,
        settingsState = settingsState,
        pendingImportedMeditation = pendingImportedMeditation,
        onTabSelect = { tabItem ->
            scope.launch { settingsDataStore.setSelectedTab(tabItem.tab) }
            navController.navigate(tabItem.screen.route) {
                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                launchSingleTop = true
                restoreState = true
            }
        }
    )
}

@Composable
private fun NavHostScaffold(
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    startDestination: String,
    settingsState: SettingsSheetState,
    pendingImportedMeditation: kotlinx.coroutines.flow.MutableStateFlow<GuidedMeditation?>,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val showBottomBar = currentDestination?.route?.let { route ->
        !route.startsWith("player") && route != Screen.TimerFocus.route
    } != false

    Scaffold(
        modifier = modifier,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            if (showBottomBar) {
                StillMomentBottomBar(tabs = tabs, currentDestination = currentDestination, onTabSelect = onTabSelect)
            }
        },
        containerColor = Color.Transparent
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            StillMomentNavContent(navController, startDestination, settingsState, pendingImportedMeditation)
        }
    }
}

@Composable
private fun StillMomentNavContent(
    navController: NavHostController,
    startDestination: String,
    settingsState: SettingsSheetState,
    pendingImportedMeditation: kotlinx.coroutines.flow.MutableStateFlow<GuidedMeditation?>
) {
    NavHost(navController = navController, startDestination = startDestination) {
        timerNavGraph(navController, settingsState)

        composable(Screen.Library.route) {
            val importedMeditation by pendingImportedMeditation.collectAsState()
            val listViewModel: GuidedMeditationsListViewModel = hiltViewModel()

            LaunchedEffect(importedMeditation) {
                val meditation = importedMeditation ?: return@LaunchedEffect
                pendingImportedMeditation.value = null
                listViewModel.showEditSheet(meditation)
            }

            GuidedMeditationsListScreen(
                onMeditationClick = { navController.navigate(Screen.Player.createRoute(it)) },
                viewModel = listViewModel,
                selectedTheme = settingsState.selectedTheme,
                onThemeChange = settingsState.onThemeChange,
                selectedAppearanceMode = settingsState.selectedAppearanceMode,
                onAppearanceModeChange = settingsState.onAppearanceModeChange
            )
        }

        playerComposable(navController)
    }
}

private fun NavGraphBuilder.timerNavGraph(navController: NavHostController, settingsState: SettingsSheetState) {
    navigation(startDestination = Screen.Timer.route, route = Screen.TimerGraph.route) {
        composable(Screen.Timer.route) { backStackEntry ->
            val parentEntry = remember(backStackEntry) {
                navController.getBackStackEntry(Screen.TimerGraph.route)
            }
            val sharedViewModel: TimerViewModel = hiltViewModel(parentEntry)

            TimerScreen(
                onNavigateToFocus = { navController.navigate(Screen.TimerFocus.route) },
                viewModel = sharedViewModel,
                selectedTheme = settingsState.selectedTheme,
                onThemeChange = settingsState.onThemeChange,
                selectedAppearanceMode = settingsState.selectedAppearanceMode,
                onAppearanceModeChange = settingsState.onAppearanceModeChange
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
}

private fun NavGraphBuilder.playerComposable(navController: NavHostController) {
    composable(
        route = Screen.Player.route,
        arguments = listOf(navArgument("meditationJson") { type = NavType.StringType })
    ) { backStackEntry ->
        val meditationJson = backStackEntry.arguments?.getString("meditationJson")
        val meditation = meditationJson?.let {
            Json.decodeFromString<GuidedMeditation>(Uri.decode(it))
        }
        meditation?.let {
            GuidedMeditationPlayerScreen(meditation = it, onBack = { navController.popBackStack() })
        }
    }
}

/**
 * Handles "Open with" file import as a side effect.
 * Extracted from StillMomentNavHost to reduce complexity.
 */
@Composable
private fun FileOpenEffect(
    fileOpenHandler: FileOpenHandler?,
    pendingFileUri: StateFlow<Uri?>?,
    onClearFileUri: () -> Unit,
    navController: NavHostController,
    snackbarHostState: SnackbarHostState,
    pendingImportedMeditation: kotlinx.coroutines.flow.MutableStateFlow<GuidedMeditation?>
) {
    val errorUnsupportedFormat = stringResource(R.string.error_unsupported_format)
    val errorAlreadyImported = stringResource(R.string.error_already_imported)
    val errorImportFailed = stringResource(R.string.error_import_failed)

    val fileUri by pendingFileUri?.collectAsState() ?: remember {
        kotlinx.coroutines.flow.MutableStateFlow<Uri?>(null)
    }.collectAsState()

    val currentOnClearFileUri by rememberUpdatedState(onClearFileUri)

    LaunchedEffect(fileUri) {
        Log.d("FileOpen", "LaunchedEffect fired: fileUri=$fileUri, handler=${fileOpenHandler != null}")
        val uri = fileUri ?: return@LaunchedEffect
        val handler = fileOpenHandler ?: return@LaunchedEffect
        Log.d("FileOpen", "Processing file URI: $uri")

        navController.navigate(Screen.Library.route) {
            popUpTo(navController.graph.findStartDestination().id) {
                saveState = true
            }
            launchSingleTop = true
            restoreState = true
        }

        val result = handler.handleFileOpen(uri)
        currentOnClearFileUri()
        Log.d("FileOpen", "handleFileOpen result: ${result.isSuccess}, ${result.exceptionOrNull()?.message}")
        result.fold(
            onSuccess = { meditation ->
                Log.d("FileOpen", "Import success: ${meditation.fileName}")
                pendingImportedMeditation.value = meditation
            },
            onFailure = { error ->
                Log.e("FileOpen", "Import failed", error)
                val message = when ((error as? FileOpenException)?.error) {
                    FileOpenError.UNSUPPORTED_FORMAT -> errorUnsupportedFormat
                    FileOpenError.ALREADY_IMPORTED -> errorAlreadyImported
                    FileOpenError.IMPORT_FAILED -> errorImportFailed
                    null -> errorImportFailed
                }
                snackbarHostState.showSnackbar(
                    message = message,
                    duration = SnackbarDuration.Short
                )
            }
        )
    }
}

@Composable
private fun StillMomentBottomBar(
    tabs: ImmutableList<TabItem>,
    currentDestination: androidx.navigation.NavDestination?,
    onTabSelect: (TabItem) -> Unit,
    modifier: Modifier = Modifier
) {
    NavigationBar(
        containerColor = MaterialTheme.colorScheme.background,
        contentColor = MaterialTheme.colorScheme.primary,
        modifier = modifier
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
