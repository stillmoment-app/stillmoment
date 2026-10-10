package com.stillmoment

import android.app.Application
import com.stillmoment.data.migration.AttunementCleanupMigration
import com.stillmoment.domain.services.ImportDownloadsProtocol
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

/**
 * Still Moment Android Application class.
 * Initializes Hilt dependency injection and runs one-shot startup migrations.
 */
@HiltAndroidApp
class StillMomentApp : Application() {
    @Inject
    lateinit var attunementCleanupMigration: AttunementCleanupMigration

    @Inject
    lateinit var importDownloads: ImportDownloadsProtocol

    private val startupScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        // runBlocking is intentional: the migration must finish before any DataStore-backed
        // singleton tries to deserialize the custom-audio JSON list (which would crash on the
        // legacy "ATTUNEMENT" enum value). The migration is idempotent and short — only the
        // first start after upgrade does any real work.
        runBlocking { attunementCleanupMigration.runIfNeeded() }

        // android-087: remove link/podcast downloads earlier runs left behind. Once per
        // process start, not per Activity start: the Activity is re-created on dark mode or
        // font size changes while a download or an open edit sheet lives on in its
        // ViewModel. A new process has no import yet; a share that cold-starts the app and
        // begins downloading meanwhile is protected by ImportDownloadFolder itself.
        startupScope.launch { importDownloads.removeLeftovers() }
    }
}
