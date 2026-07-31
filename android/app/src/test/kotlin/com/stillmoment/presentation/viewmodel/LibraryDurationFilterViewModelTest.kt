package com.stillmoment.presentation.viewmodel

import com.stillmoment.data.FileOpenHandler
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.LibrarySearchState
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformProviderProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever
import org.mockito.kotlin.wheneverBlocking

/**
 * Tests fuer das Zusammenspiel von Dauer-Filter und Suche (shared-081).
 *
 * Die Bibliothek stammt aus dem Ticket-Mockup: drei Lehrer:innen, sechs Dauern
 * ueber alle Stufen verteilt.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class LibraryDurationFilterViewModelTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeGuidedMeditationRepository
    private lateinit var fakeSearchHistoryRepository: FakeSearchHistoryRepository
    private lateinit var viewModel: GuidedMeditationsListViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeGuidedMeditationRepository()
        fakeSearchHistoryRepository = FakeSearchHistoryRepository()
        val audioService = mock<AudioServiceProtocol>()
        whenever(audioService.meditationPreviewPositionFlow).thenReturn(MutableStateFlow(0L).asStateFlow())
        whenever(audioService.meditationPreviewDurationFlow).thenReturn(MutableStateFlow(0L).asStateFlow())
        whenever(audioService.meditationPreviewCompletionFlow)
            .thenReturn(MutableSharedFlow<Unit>(extraBufferCapacity = 1).asSharedFlow())
        val praxisRepository = mock<PraxisRepository>()
        wheneverBlocking { praxisRepository.load() }.thenReturn(Praxis.Default)

        viewModel = GuidedMeditationsListViewModel(
            repository = fakeRepository,
            audioService = audioService,
            meditationSourceRepository = FakeMeditationSourceRepository(),
            searchHistoryRepository = fakeSearchHistoryRepository,
            fileOpenHandler = mock<FileOpenHandler>(),
            praxisRepository = praxisRepository,
            waveformProvider = mock<WaveformProviderProtocol>(),
            logger = mock<LoggerProtocol>()
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - Einzelauswahl und Ruecksprung auf `Alle`

    @Nested
    inner class SingleSelection {
        @Test
        fun `initially no filter is active and the list stays grouped`() = runTest {
            seedLibrary()

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.ALL, state.durationFilter)
            assertFalse(state.isFilterActive)
            assertEquals(LibrarySearchState.Idle, state.searchState)
        }

        @Test
        fun `selecting a step activates it and flattens the list`() = runTest {
            seedLibrary()

            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.FROM_5_TO_15, state.durationFilter)
            assertTrue(state.isFilterActive)
            assertEquals(LibrarySearchState.Filtered, state.searchState)
        }

        @Test
        fun `tapping the active step returns to All and regroups the list`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.ALL, state.durationFilter)
            assertEquals(LibrarySearchState.Idle, state.searchState)
        }

        @Test
        fun `selecting another step replaces the active one`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            viewModel.selectDurationFilter(DurationFilter.OVER_30)

            assertEquals(DurationFilter.OVER_30, viewModel.uiState.value.durationFilter)
        }

        @Test
        fun `tapping an unavailable step leaves the filter unchanged`() = runTest {
            // Bibliothek ohne Meditation unter 5 Minuten.
            fakeRepository.emitMeditations(listOf(meditation("Body Scan", "Sarah Kornfield", 942)))
            advanceUntilIdle()

            viewModel.selectDurationFilter(DurationFilter.UP_TO_5)

            assertEquals(DurationFilter.ALL, viewModel.uiState.value.durationFilter)
        }
    }

    // MARK: - Wirkung auf die Liste

    @Nested
    inner class VisibleMeditations {
        @Test
        fun `flat list without search follows the grouped order`() = runTest {
            seedLibrary()

            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            // Reihenfolge wie in der gruppierten Ansicht, nur ohne Ueberschriften:
            // Anna Berg (nichts in dieser Stufe), Sarah Kornfield, Tara Goldstein.
            assertEquals(
                listOf("Mindful Breathing", "Loving Kindness"),
                viewModel.uiState.value.visibleMeditations.map { it.name }
            )
        }

        @Test
        fun `count line compares the visible meditations against the whole library`() = runTest {
            seedLibrary()

            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            val state = viewModel.uiState.value
            assertEquals(2, state.visibleMeditations.size)
            assertEquals(6, state.totalCount)
        }

        @Test
        fun `without a filter every meditation stays visible`() = runTest {
            seedLibrary()

            assertEquals(6, viewModel.uiState.value.visibleMeditations.size)
        }
    }

    // MARK: - Zusammenspiel mit der Suche

    @Nested
    inner class SearchAndFilterTogether {
        @Test
        fun `search and filter narrow the list together`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            viewModel.updateSearchQuery("b")

            // „b" trifft Body Scan (15:42), Mindful Breathing (7:33) und beide von Anna Berg.
            // Nur Mindful Breathing erfuellt zusaetzlich die Dauer-Stufe.
            val state = viewModel.uiState.value
            assertEquals(listOf("Mindful Breathing"), state.visibleMeditations.map { it.name })
            assertEquals(LibrarySearchState.Results, state.searchState)
        }

        @Test
        fun `removing the filter brings the meditation back without touching the search`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)
            viewModel.updateSearchQuery("b")

            viewModel.resetDurationFilter()

            val state = viewModel.uiState.value
            assertTrue(state.visibleMeditations.any { it.name == "Body Scan" })
            assertEquals("b", state.searchQuery)
        }

        @Test
        fun `search and filter without a common match show the empty state`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.OVER_30)

            viewModel.updateSearchQuery("loving")

            val state = viewModel.uiState.value
            assertTrue(state.visibleMeditations.isEmpty())
            assertEquals(LibrarySearchState.Empty, state.searchState)
        }

        @Test
        fun `available steps follow the whole library not the current search`() = runTest {
            seedLibrary()

            // „mindful" trifft nur die 7:33-Meditation — aber sobald Text im Suchfeld
            // steht, ist die Stufenzeile ohnehin dem Chip gewichen.
            viewModel.updateSearchQuery("mindful")

            assertEquals(DurationFilter.entries.toSet(), viewModel.uiState.value.availableDurationSteps)
        }

        @Test
        fun `available steps ignore the active filter so it stays reversible`() = runTest {
            seedLibrary()

            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            assertEquals(DurationFilter.entries.toSet(), viewModel.uiState.value.availableDurationSteps)
        }

        @Test
        fun `search mode is active while a query is present even without focus`() = runTest {
            seedLibrary()

            viewModel.updateSearchQuery("b")
            viewModel.setSearchFocused(false)

            assertTrue(viewModel.uiState.value.isSearchModeActive)
        }

        @Test
        fun `search mode is inactive without focus and without a query`() = runTest {
            seedLibrary()

            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            assertFalse(viewModel.uiState.value.isSearchModeActive)
        }

        @Test
        fun `the filter chip stays visible while the history is shown`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            viewModel.setSearchFocused(true)

            val state = viewModel.uiState.value
            assertEquals(LibrarySearchState.History, state.searchState)
            assertTrue(state.isFilterActive)
        }
    }

    // MARK: - Lebensdauer des Filters

    @Nested
    inner class FilterLifetime {
        @Test
        fun `cancelling the search keeps the filter and restores the filter row`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)
            viewModel.updateSearchQuery("b")
            viewModel.setSearchFocused(true)

            viewModel.resetSearch()

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.FROM_5_TO_15, state.durationFilter)
            assertEquals("", state.searchQuery)
            assertEquals(LibrarySearchState.Filtered, state.searchState)
        }

        @Test
        fun `opening a meditation keeps the filter while the search is reset`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)
            viewModel.updateSearchQuery("mindful")

            // Der Player-Ausflug committet die Suche und setzt sie zurueck — der Filter bleibt.
            viewModel.recordSearchCommittedByOpening()
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.FROM_5_TO_15, state.durationFilter)
            assertEquals("", state.searchQuery)
        }

        @Test
        fun `leaving the library tab drops the filter`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)

            viewModel.resetDurationFilter()

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.ALL, state.durationFilter)
            assertEquals(LibrarySearchState.Idle, state.searchState)
        }

        @Test
        fun `resetting search and filter together clears both`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.OVER_30)
            viewModel.updateSearchQuery("loving")

            viewModel.resetSearchAndFilter()

            val state = viewModel.uiState.value
            assertEquals(DurationFilter.ALL, state.durationFilter)
            assertEquals("", state.searchQuery)
            assertEquals(LibrarySearchState.Idle, state.searchState)
        }
    }

    // MARK: - Suchhistorie unter aktivem Filter

    @Nested
    inner class SearchHistoryUnderActiveFilter {
        @Test
        fun `a term whose matches the filter removes does not enter the history`() = runTest {
            // „mindful" trifft die 7:33-Meditation, der Filter raeumt sie weg —
            // der User sieht „Nichts gefunden" und darf den Begriff nicht wiederfinden.
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.OVER_30)
            viewModel.updateSearchQuery("mindful")

            viewModel.submitSearch()
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(LibrarySearchState.Empty, state.searchState)
            assertTrue(state.searchHistory.isEmpty())
        }

        @Test
        fun `a term with a visible match still enters the history`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.FROM_5_TO_15)
            viewModel.updateSearchQuery("mindful")

            viewModel.submitSearch()
            advanceUntilIdle()

            assertEquals(listOf("mindful"), viewModel.uiState.value.searchHistory.toList())
        }
    }

    // MARK: - Kein Treffer durch den Filter allein

    @Nested
    inner class FilterWithoutAnyMatch {
        @Test
        fun `a filter without any matching meditation shows the empty state`() = runTest {
            seedLibrary()
            viewModel.selectDurationFilter(DurationFilter.OVER_30)

            // Die einzige lange Meditation verschwindet aus der Bibliothek.
            fakeRepository.emitMeditations(library().filter { it.name != "Long Sit" })
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertTrue(state.visibleMeditations.isEmpty())
            assertEquals(LibrarySearchState.Empty, state.searchState)
        }

        @Test
        fun `whitespace-only input is no search term for the empty state text`() = runTest {
            seedLibrary()

            viewModel.updateSearchQuery("   ")

            assertEquals("", viewModel.uiState.value.trimmedSearchQuery)
        }
    }

    // MARK: - Test helpers

    private fun TestScope.seedLibrary() {
        fakeRepository.emitMeditations(library())
        advanceUntilIdle()
    }

    /** Bibliothek aus dem Ticket-Mockup: drei Lehrer:innen, sechs Dauern ueber alle Stufen. */
    private fun library(): List<GuidedMeditation> = listOf(
        meditation("Body Scan", "Sarah Kornfield", 942),
        meditation("Mindful Breathing", "Sarah Kornfield", 453),
        meditation("Loving Kindness", "Tara Goldstein", 737),
        meditation("Evening Wind", "Tara Goldstein", 1145),
        meditation("Quick Pause", "Anna Berg", 180),
        meditation("Long Sit", "Anna Berg", 2520)
    )

    private fun meditation(name: String, teacher: String, seconds: Int): GuidedMeditation = GuidedMeditation(
        id = name,
        fileUri = "content://test/$name",
        fileName = "$name.mp3",
        duration = seconds * 1000L,
        teacher = teacher,
        name = name,
        // Fester Zeitstempel — der Ranking-Tiebreaker der Suche darf nicht von der Uhr abhaengen.
        dateAdded = 0L
    )
}
