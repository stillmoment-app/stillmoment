package com.stillmoment.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.stillmoment.presentation.ui.timer.TimerScreen

/**
 * Navigation routes for Still Moment
 */
sealed class Screen(val route: String) {
    data object Timer : Screen("timer")
    data object Library : Screen("library")
}

/**
 * Main navigation host for Still Moment.
 * Currently single-screen (Timer), will add TabNavigation for Library later.
 */
@Composable
fun StillMomentNavHost(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Timer.route
    ) {
        composable(Screen.Timer.route) {
            TimerScreen()
        }
        // Library screen will be added in next phase
    }
}
