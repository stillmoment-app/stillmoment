# Ticket 009: TabView Navigation

**Status**: [ ] TODO
**Priorität**: HOCH
**Aufwand**: Klein (~1-2h)
**Abhängigkeiten**: 007, 008

---

## Beschreibung

Bottom Navigation mit zwei Tabs implementieren (wie iOS TabView):
- Tab 1: Timer
- Tab 2: Library (Guided Meditations)

Jeder Tab hat seinen eigenen Navigation Stack.

---

## Akzeptanzkriterien

- [ ] `BottomNavigation` mit zwei Tabs
- [ ] Tab 1: Timer (Icon: Timer)
- [ ] Tab 2: Library (Icon: Library/Folder)
- [ ] Separate Navigation pro Tab
- [ ] Tab-State bleibt bei Wechsel erhalten
- [ ] Accessibility Labels für Tabs
- [ ] Lokalisierte Tab-Labels

### Dokumentation
- [ ] CLAUDE.md: Android-Sektion um "Navigation Pattern" erweitern
- [ ] CHANGELOG.md: Eintrag für TabView Navigation

---

## Betroffene Dateien

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt`
- `android/app/src/main/kotlin/com/stillmoment/MainActivity.kt`

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/BottomNavItem.kt`

---

## Technische Details

### Bottom Nav Items:
```kotlin
// presentation/navigation/BottomNavItem.kt
sealed class BottomNavItem(
    val route: String,
    @StringRes val labelRes: Int,
    val icon: ImageVector
) {
    data object Timer : BottomNavItem(
        route = "timer",
        labelRes = R.string.tab_timer,
        icon = Icons.Default.Timer
    )

    data object Library : BottomNavItem(
        route = "library",
        labelRes = R.string.tab_library,
        icon = Icons.Default.LibraryMusic
    )

    companion object {
        val items = listOf(Timer, Library)
    }
}
```

### Updated NavGraph:
```kotlin
// presentation/navigation/NavGraph.kt
sealed class Screen(val route: String) {
    data object Timer : Screen("timer")
    data object Library : Screen("library")
    data object Player : Screen("player/{meditationId}") {
        fun createRoute(meditationId: String) = "player/$meditationId"
    }
}

@Composable
fun StillMomentNavHost(
    navController: NavHostController = rememberNavController(),
    startDestination: String = Screen.Timer.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Timer.route) {
            TimerScreen()
        }

        composable(Screen.Library.route) {
            GuidedMeditationsListScreen(
                onMeditationClick = { meditation ->
                    navController.navigate(Screen.Player.createRoute(meditation.id))
                }
            )
        }

        composable(
            route = Screen.Player.route,
            arguments = listOf(navArgument("meditationId") { type = NavType.StringType })
        ) { backStackEntry ->
            val meditationId = backStackEntry.arguments?.getString("meditationId")
            // Load meditation and show player
            GuidedMeditationPlayerScreen(
                meditationId = meditationId ?: "",
                onBack = { navController.popBackStack() }
            )
        }
    }
}
```

### Main Activity with Bottom Navigation:
```kotlin
// MainActivity.kt
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            StillMomentTheme {
                MainScreen()
            }
        }
    }
}

@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Determine if bottom bar should be shown
    val showBottomBar = currentRoute in listOf(Screen.Timer.route, Screen.Library.route)

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar(
                    containerColor = WarmCream
                ) {
                    BottomNavItem.items.forEach { item ->
                        NavigationBarItem(
                            icon = {
                                Icon(
                                    imageVector = item.icon,
                                    contentDescription = stringResource(item.labelRes)
                                )
                            },
                            label = { Text(stringResource(item.labelRes)) },
                            selected = currentRoute == item.route,
                            onClick = {
                                navController.navigate(item.route) {
                                    // Pop up to start destination to avoid stack buildup
                                    popUpTo(navController.graph.startDestinationId) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = Terracotta,
                                selectedTextColor = Terracotta,
                                unselectedIconColor = WarmGray,
                                unselectedTextColor = WarmGray,
                                indicatorColor = WarmSand
                            )
                        )
                    }
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            StillMomentNavHost(navController = navController)
        }
    }
}
```

---

## Design Details

- Bottom Navigation Bar Farbe: `WarmCream`
- Selected Icon/Text: `Terracotta`
- Unselected Icon/Text: `WarmGray`
- Indicator: `WarmSand`
- Bottom Bar wird im Player ausgeblendet

---

## Testanweisungen

```bash
# Build prüfen
cd android && ./gradlew assembleDebug

# Manueller Test:
# 1. App starten → Timer-Tab aktiv
# 2. Auf Library-Tab tippen → Library anzeigen
# 3. Zurück zu Timer → State ist erhalten
# 4. In Library: Meditation öffnen → Player ohne Bottom Bar
# 5. Zurück → Bottom Bar wieder sichtbar
# 6. Sprache wechseln → Tab-Labels sind lokalisiert
```

---

## iOS-Referenz

- `ios/StillMoment/Presentation/Views/Shared/MainTabView.swift`
