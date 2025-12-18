# Ticket android-005: GuidedMeditation Repository

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel (~3-4h)
**Abhaengigkeiten**: android-004
**Phase**: 3-Feature

---

## Beschreibung

Repository und Service fuer Guided Meditations implementieren:
- Import von MP3-Dateien via Storage Access Framework (SAF)
- Metadata-Extraktion (ID3 Tags)
- Persistierung in DataStore
- CRUD-Operationen

---

## Akzeptanzkriterien

- [ ] `GuidedMeditationRepository` Interface in Domain Layer
- [ ] `GuidedMeditationRepositoryImpl` in Data Layer
- [ ] MP3-Import via SAF (Document Picker)
- [ ] ID3-Tag Extraktion (Artist → Teacher, Title → Name)
- [ ] Dauer-Extraktion via MediaMetadataRetriever
- [ ] DataStore Persistierung
- [ ] Unit Tests fuer Repository
- [ ] Manuelle Pruefung: MP3 importieren und Metadaten werden angezeigt

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/domain/repositories/GuidedMeditationRepository.kt`
- `android/app/src/main/kotlin/com/stillmoment/data/repositories/GuidedMeditationRepositoryImpl.kt`
- `android/app/src/main/kotlin/com/stillmoment/data/local/GuidedMeditationDataStore.kt`

### Zu aendern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/di/DataModule.kt`

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/data/repositories/GuidedMeditationRepositoryImplTest.kt`

---

## Technische Details

### Repository Interface:
```kotlin
// domain/repositories/GuidedMeditationRepository.kt
interface GuidedMeditationRepository {
    val meditationsFlow: Flow<List<GuidedMeditation>>

    suspend fun importMeditation(uri: Uri): Result<GuidedMeditation>
    suspend fun deleteMeditation(id: String)
    suspend fun updateMeditation(meditation: GuidedMeditation)
    suspend fun getMeditation(id: String): GuidedMeditation?
}
```

### Repository Implementation:
```kotlin
// data/repositories/GuidedMeditationRepositoryImpl.kt
@Singleton
class GuidedMeditationRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val dataStore: GuidedMeditationDataStore
) : GuidedMeditationRepository {

    override val meditationsFlow: Flow<List<GuidedMeditation>> =
        dataStore.meditationsFlow

    override suspend fun importMeditation(uri: Uri): Result<GuidedMeditation> {
        return try {
            // 1. Take persistable permission
            context.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )

            // 2. Extract metadata
            val metadata = extractMetadata(uri)

            // 3. Create meditation
            val meditation = GuidedMeditation(
                fileUri = uri.toString(),
                fileName = getFileName(uri),
                duration = metadata.duration,
                teacher = metadata.artist ?: "Unknown",
                name = metadata.title ?: getFileName(uri)
            )

            // 4. Save to DataStore
            dataStore.addMeditation(meditation)

            Result.success(meditation)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun extractMetadata(uri: Uri): MediaMetadata {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            MediaMetadata(
                duration = retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_DURATION
                )?.toLongOrNull() ?: 0L,
                artist = retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_ARTIST
                ),
                title = retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_TITLE
                )
            )
        } finally {
            retriever.release()
        }
    }

    // ... weitere Methoden
}

private data class MediaMetadata(
    val duration: Long,
    val artist: String?,
    val title: String?
)
```

### DataStore:
```kotlin
// data/local/GuidedMeditationDataStore.kt
@Singleton
class GuidedMeditationDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val dataStore = context.dataStore

    val meditationsFlow: Flow<List<GuidedMeditation>> = dataStore.data
        .map { preferences ->
            val json = preferences[MEDITATIONS_KEY] ?: "[]"
            Json.decodeFromString<List<GuidedMeditation>>(json)
        }

    suspend fun addMeditation(meditation: GuidedMeditation) {
        dataStore.edit { preferences ->
            val current = getMeditations(preferences)
            val updated = current + meditation
            preferences[MEDITATIONS_KEY] = Json.encodeToString(updated)
        }
    }

    // ... weitere Methoden

    companion object {
        private val MEDITATIONS_KEY = stringPreferencesKey("guided_meditations")
    }
}
```

---

## SAF (Storage Access Framework)

Android verwendet SAF statt Security-Scoped Bookmarks (iOS).

```kotlin
// Activity/Fragment code for file picker
val launcher = registerForActivityResult(
    ActivityResultContracts.OpenDocument()
) { uri ->
    uri?.let { viewModel.importMeditation(it) }
}

// Launch picker
launcher.launch(arrayOf("audio/mpeg", "audio/mp3"))
```

**Wichtig**: `takePersistableUriPermission` muss aufgerufen werden, damit die URI nach App-Neustart noch funktioniert.

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test --tests "*GuidedMeditationRepository*"

# Manueller Test:
# 1. App starten
# 2. MP3-Datei importieren (mit Document Picker)
# 3. Pruefen: Metadaten werden korrekt extrahiert
# 4. App neu starten
# 5. Pruefen: Importierte Meditation ist noch vorhanden
```

---

## Referenzen

- `ios/StillMoment/Domain/Services/GuidedMeditationServiceProtocol.swift`
- `ios/StillMoment/Infrastructure/Services/GuidedMeditationService.swift`
