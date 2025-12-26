package com.stillmoment.presentation.navigation

import android.net.Uri
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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.stillmoment.R
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreen
import com.stillmoment.presentation.ui.meditations.GuidedMeditationsListScreen
import com.stillmoment.presentation.ui.theme.Terracotta
import com.stillmoment.presentation.ui.theme.WarmGray
import com.stillmoment.presentation.ui.theme.WarmSand
import com.stillmoment.presentation.ui.timer.TimerScreen
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Navigation routes for Still Moment
 */
sealed class Screen(val route: String) {
    data object Timer : Screen("timer")

    data object Library : Screen("library")

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
    val screen: Screen,
    val labelResId: Int,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val accessibilityResId: Int
)

/**
 * Main navigation host for Still Moment.
 * Features TabView navigation with Timer and Library tabs.
 * Remembers the last selected tab across app restarts.
 */
@Composable
fun StillMomentNavHost(
    settingsDataStore: SettingsDataStore,
    navController: NavHostController = rememberNavController()
) {
    val scope = rememberCoroutineScope()

    // Load saved tab from DataStore
    val savedTab by produceState(initialValue = Screen.Timer.route) {
        value = settingsDataStore.getSelectedTab()
    }

    // Navigate to saved tab on first load (if not timer)
    LaunchedEffect(savedTab) {
        if (savedTab == Screen.Library.route) {
            navController.navigate(Screen.Library.route) {
                popUpTo(Screen.Timer.route) { inclusive = true }
            }
        }
    }

    val tabs =
        remember {
            listOf(
                TabItem(
                    screen = Screen.Timer,
                    labelResId = R.string.tab_timer,
                    selectedIcon = Icons.Filled.Timer,
                    unselectedIcon = Icons.Outlined.Timer,
                    accessibilityResId = R.string.accessibility_tab_timer
                ),
                TabItem(
                    screen = Screen.Library,
                    labelResId = R.string.tab_library,
                    selectedIcon = Icons.Filled.LibraryMusic,
                    unselectedIcon = Icons.Outlined.LibraryMusic,
                    accessibilityResId = R.string.accessibility_tab_library
                )
            )
        }

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // Hide bottom bar on player screen
    val showBottomBar = currentDestination?.route?.startsWith("player") != true

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                StillMomentBottomBar(
                    tabs = tabs,
                    currentDestination = currentDestination,
                    onTabSelected = { screen ->
                        // Save selected tab for next app launch
                        scope.launch {
                            settingsDataStore.setSelectedTab(screen.route)
                        }
                        navController.navigate(screen.route) {
                            // Pop up to start destination to avoid building up a large stack
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            // Avoid multiple copies of the same destination
                            launchSingleTop = true
                            // Restore state when re-selecting a previously selected item
                            restoreState = true
                        }
                    }
                )
            }
        },
        containerColor = Color.Transparent
    ) { padding ->
        Box(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            NavHost(
                navController = navController,
                startDestination = Screen.Timer.route
            ) {
                composable(Screen.Timer.route) {
                    TimerScreen()
                }

                composable(Screen.Library.route) {
                    GuidedMeditationsListScreen(
                        onMeditationClick = { meditation ->
                            navController.navigate(Screen.Player.createRoute(meditation))
                        }
                    )
                }

                composable(
                    route = Screen.Player.route,
                    arguments =
                    listOf(
                        navArgument("meditationJson") { type = NavType.StringType }
                    )
                ) { backStackEntry ->
                    val meditationJson = backStackEntry.arguments?.getString("meditationJson")
                    val meditation =
                        meditationJson?.let {
                            Json.decodeFromString<GuidedMeditation>(Uri.decode(it))
                        }

                    meditation?.let {
                        GuidedMeditationPlayerScreen(
                            meditation = it,
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StillMomentBottomBar(
    tabs: List<TabItem>,
    currentDestination: androidx.navigation.NavDestination?,
    onTabSelected: (Screen) -> Unit,
    modifier: Modifier = Modifier
) {
    NavigationBar(
        containerColor = WarmSand,
        contentColor = Terracotta,
        modifier = modifier
    ) {
        tabs.forEach { tab ->
            val selected = currentDestination?.hierarchy?.any { it.route == tab.screen.route } == true
            val accessibilityLabel = stringResource(tab.accessibilityResId)

            NavigationBarItem(
                selected = selected,
                onClick = { onTabSelected(tab.screen) },
                icon = {
                    Icon(
                        imageVector = if (selected) tab.selectedIcon else tab.unselectedIcon,
                        contentDescription = null
                    )
                },
                label = {
                    Text(
                        text = stringResource(tab.labelResId),
                        style = MaterialTheme.typography.labelSmall
                    )
                },
                colors =
                NavigationBarItemDefaults.colors(
                    selectedIconColor = Terracotta,
                    selectedTextColor = Terracotta,
                    unselectedIconColor = WarmGray,
                    unselectedTextColor = WarmGray,
                    indicatorColor = Terracotta.copy(alpha = 0.1f)
                ),
                modifier =
                Modifier.semantics {
                    contentDescription = accessibilityLabel
                }
            )
        }
    }
}
