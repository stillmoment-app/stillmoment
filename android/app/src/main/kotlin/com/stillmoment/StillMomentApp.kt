package com.stillmoment

import android.app.Application
import com.stillmoment.data.migration.AttunementCleanupMigration
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject
import kotlinx.coroutines.runBlocking

/**
 * Still Moment Android Application class.
 * Initializes Hilt dependency injection and runs one-shot startup migrations.
 */
@HiltAndroidApp
class StillMomentApp : Application() {
    @Inject
    lateinit var attunementCleanupMigration: AttunementCleanupMigration

    override fun onCreate() {
        super.onCreate()
        // runBlocking is intentional: the migration must finish before any DataStore-backed
        // singleton tries to deserialize the custom-audio JSON list (which would crash on the
        // legacy "ATTUNEMENT" enum value). The migration is idempotent and short — only the
        // first start after upgrade does any real work.
        runBlocking { attunementCleanupMigration.runIfNeeded() }
    }
}
