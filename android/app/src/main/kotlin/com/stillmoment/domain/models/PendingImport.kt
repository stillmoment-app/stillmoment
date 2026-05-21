package com.stillmoment.domain.models

/**
 * In-flight import waiting for user confirmation in the edit sheet (shared-103).
 *
 * Holds everything needed to either persist the meditation (on Save) or to
 * discard it (on Cancel) without leaving a stray file in the app container.
 *
 * The URI is a plain string because Android `Uri` is a framework type — we
 * keep the domain layer Android-free. The infrastructure layer converts back
 * to `android.net.Uri` when reading the file.
 */
data class PendingImport(
    val uri: String,
    val fileName: String,
    val metadata: AudioMetadata,
    val prefill: ImportPrefill
)
