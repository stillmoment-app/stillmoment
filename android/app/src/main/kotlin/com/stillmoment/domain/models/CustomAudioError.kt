package com.stillmoment.domain.models

/**
 * Errors thrown by CustomAudioRepository operations.
 */
sealed class CustomAudioError : Exception() {
    /** File format is not supported (e.g. .ogg, .flac) */
    data class UnsupportedFormat(val extension: String) : CustomAudioError() {
        override val message: String = "Unsupported file format: .$extension"
    }

    /** File could not be copied to local storage */
    data class FileCopyFailed(override val message: String) : CustomAudioError()

    /** Metadata persistence failed */
    data class PersistenceFailed(override val message: String) : CustomAudioError()

    /** No file found for the given ID */
    data class FileNotFound(val id: String) : CustomAudioError() {
        override val message: String = "No custom audio file found for id: $id"
    }
}
