package com.stillmoment.domain.models

/**
 * Errors that can occur during "Open with" file handling.
 * Mirrors iOS FileOpenError for cross-platform consistency.
 */
enum class FileOpenError {
    /** The file format is not supported (only MP3 and M4A) */
    UNSUPPORTED_FORMAT,

    /** The file could not be imported (corrupt, unreadable, or service error) */
    IMPORT_FAILED,

    /** A meditation with the same filename is already in the library */
    ALREADY_IMPORTED
}
