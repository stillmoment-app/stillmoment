# Ticket 007: Library Screen UI

**Status**: [ ] TODO
**Priorität**: HOCH
**Aufwand**: Mittel (~3-4h)
**Abhängigkeiten**: 006

---

## Beschreibung

Compose UI für die Guided Meditations Library erstellen:
- Gruppierte Liste nach Lehrer
- Import-Button (FAB oder Toolbar)
- Swipe-to-Delete
- Edit Sheet für Metadaten
- Empty State

---

## Akzeptanzkriterien

- [ ] `GuidedMeditationsListScreen` Composable
- [ ] Gruppierte LazyColumn mit Lehrer-Headern
- [ ] Import-FAB mit Document Picker Integration
- [ ] Swipe-to-Delete für einzelne Meditationen
- [ ] Edit Sheet (BottomSheet) für Metadaten
- [ ] Empty State mit Import-Hinweis
- [ ] Loading State während Import
- [ ] Error Snackbar bei Fehlern
- [ ] Accessibility Labels

### Dokumentation
- [ ] CHANGELOG.md: Feature-Eintrag für Guided Meditations Library

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationEditSheet.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/EmptyLibraryState.kt`

### Strings hinzufügen:
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-de/strings.xml`

---

## Technische Details

### Main Screen:
```kotlin
// presentation/ui/meditations/GuidedMeditationsListScreen.kt
@Composable
fun GuidedMeditationsListScreen(
    viewModel: GuidedMeditationsListViewModel = hiltViewModel(),
    onMeditationClick: (GuidedMeditation) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    // Document picker launcher
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let { viewModel.importMeditation(it) }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.tab_library)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { launcher.launch(arrayOf("audio/mpeg", "audio/mp3")) },
                containerColor = Terracotta
            ) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = stringResource(R.string.accessibility_import_meditation)
                )
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            WarmGradientBackground()

            when {
                uiState.isLoading -> LoadingIndicator()
                uiState.groups.isEmpty() -> EmptyLibraryState(
                    onImportClick = { launcher.launch(arrayOf("audio/mpeg")) }
                )
                else -> MeditationsList(
                    groups = uiState.groups,
                    onMeditationClick = onMeditationClick,
                    onEditClick = viewModel::showEditSheet,
                    onDeleteClick = viewModel::deleteMeditation
                )
            }
        }
    }

    // Edit Sheet
    if (uiState.showEditSheet && uiState.selectedMeditation != null) {
        MeditationEditSheet(
            meditation = uiState.selectedMeditation!!,
            onDismiss = viewModel::hideEditSheet,
            onSave = viewModel::updateMeditation
        )
    }

    // Error handling
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }
}
```

### Grouped List:
```kotlin
@Composable
private fun MeditationsList(
    groups: List<GuidedMeditationGroup>,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteClick: (GuidedMeditation) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        groups.forEach { group ->
            // Section Header
            stickyHeader {
                Text(
                    text = group.teacher,
                    style = MaterialTheme.typography.titleMedium,
                    color = WarmGray,
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(WarmSand.copy(alpha = 0.95f))
                        .padding(vertical = 8.dp)
                )
            }

            // Meditations in group
            items(
                items = group.meditations,
                key = { it.id }
            ) { meditation ->
                SwipeToDeleteContainer(
                    onDelete = { onDeleteClick(meditation) }
                ) {
                    MeditationListItem(
                        meditation = meditation,
                        onClick = { onMeditationClick(meditation) },
                        onEditClick = { onEditClick(meditation) }
                    )
                }
            }
        }
    }
}
```

### List Item:
```kotlin
@Composable
fun MeditationListItem(
    meditation: GuidedMeditation,
    onClick: () -> Unit,
    onEditClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = WarmCream)
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = meditation.effectiveName,
                    style = MaterialTheme.typography.bodyLarge,
                    color = WarmBlack
                )
                Text(
                    text = meditation.formattedDuration,
                    style = MaterialTheme.typography.bodySmall,
                    color = WarmGray
                )
            }

            IconButton(onClick = onEditClick) {
                Icon(
                    Icons.Default.Edit,
                    contentDescription = stringResource(R.string.accessibility_edit_meditation),
                    tint = WarmGray
                )
            }
        }
    }
}
```

---

## Neue Strings

```xml
<!-- values/strings.xml -->
<string name="library_empty_title">Your library is empty</string>
<string name="library_empty_description">Import meditation audio files to get started</string>
<string name="library_import_button">Import Meditation</string>
<string name="edit_meditation_title">Edit Meditation</string>
<string name="edit_teacher_label">Teacher</string>
<string name="edit_name_label">Name</string>
<string name="accessibility_import_meditation">Import meditation audio file</string>
<string name="accessibility_edit_meditation">Edit meditation details</string>
<string name="accessibility_delete_meditation">Delete meditation</string>
```

---

## Testanweisungen

```bash
# Build prüfen
cd android && ./gradlew assembleDebug

# Manueller Test:
# 1. App starten, zu Library-Tab wechseln
# 2. Empty State sehen
# 3. FAB drücken, MP3 importieren
# 4. Meditation in Liste sehen
# 5. Auf Meditation tippen → Player öffnet (Ticket 008)
# 6. Edit-Button testen
# 7. Swipe-to-Delete testen
```

---

## iOS-Referenz

- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift`
