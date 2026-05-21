package com.stillmoment.domain.services

import com.stillmoment.domain.models.AudioMetadata

/**
 * Domain-level interface for reading audio metadata (duration + ID3 tags) from
 * a URI.
 *
 * The interface is Android-framework-free — it takes a URI **string** so it
 * stays in the domain layer. The Android implementation
 * (`AndroidAudioMetadataService`) converts the string to a real `Uri` before
 * calling `MediaMetadataRetriever`.
 *
 * Implementations must return a fallback `AudioMetadata(0L, null, null)` when
 * extraction fails — callers depend on the call always succeeding.
 */
interface AudioMetadataService {
    /**
     * Extracts metadata for the given URI string.
     *
     * @param uri URI string (`content://...` or `file://...`).
     * @return Best-effort metadata. Missing fields are returned as `null`.
     */
    suspend fun extract(uri: String): AudioMetadata
}
