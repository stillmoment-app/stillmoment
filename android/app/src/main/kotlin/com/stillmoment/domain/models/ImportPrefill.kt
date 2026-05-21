package com.stillmoment.domain.models

/**
 * Domain value: suggested values for the import edit sheet (shared-103).
 *
 * Two optionals — `null` means "no suggestion; leave the field empty in the
 * edit sheet". The provenance (ID3 vs. filename) is deliberately not stored:
 * the handoff drops source-badges/banners ("Prefill ist still"), so the
 * information is not needed in the domain.
 *
 * 1:1 port of the iOS implementation (`ImportPrefill.swift`).
 */
data class ImportPrefill(
    val teacher: String?,
    val name: String?
) {
    companion object {
        /**
         * Computes prefill suggestions for `teacher` and `name` from ID3
         * metadata and the original filename.
         *
         * `knownTeachers` is the deduplicated list of teachers already in the
         * library (see ViewModel aggregation). Legacy `"Unknown Artist"`
         * entries are filtered out by [sanitize] before being matched against
         * the filename.
         */
        fun compute(metadata: AudioMetadata, fileName: String, knownTeachers: List<String>): ImportPrefill {
            val basename = stripExtension(fileName)
            val preprocessed = preprocessFilename(fileName)
            val teacher = computeTeacher(
                artist = metadata.artist,
                preprocessedFilename = preprocessed,
                knownTeachers = knownTeachers
            )
            val name = computeName(
                title = metadata.title,
                basename = basename,
                preprocessedFilename = preprocessed,
                teacher = teacher
            )
            return ImportPrefill(teacher = teacher, name = name)
        }

        /**
         * Central filter for ID3 values, entries from `knownTeachers`, and the
         * preprocessed filename.
         *
         * Steps:
         * 1. Trim whitespace → if empty: `null`.
         * 2. Build comparison copy (lowercase, all separators removed).
         * 3. Comparison copy hits the blacklist → `null`.
         * 4. Comparison copy is pure track numbering → `null`.
         * 5. Otherwise: trimmed original (content unchanged).
         */
        fun sanitize(raw: String?): String? {
            if (raw == null) {
                return null
            }
            val trimmed = raw.trim()
            if (trimmed.isEmpty()) {
                return null
            }
            val comparison = trimmed
                .lowercase()
                .filter { it !in SEPARATORS }
            if (comparison in EXCLUDED_TOKENS) {
                return null
            }
            if (isPureTrackNumbering(comparison)) {
                return null
            }
            return trimmed
        }

        /**
         * Cleans up a filename for use in both prefill cascades.
         *
         * Steps:
         * 1. Strip extension (`.mp3`, `.m4a`, …).
         * 2. Strip track-number prefix (`^\d{1,3}[-_.\s]+`).
         * 3. Normalize separators `_`, `-`, `.` to spaces; collapse runs.
         * 4. Insert word boundaries at CamelCase and digit/letter transitions —
         *    `04Fuesse` → `04 Fuesse`, `MomentMal` → `Moment Mal`.
         * 5. Casing inside words is **not** changed — content stays verbatim so
         *    German prepositions like "im" stay readable.
         *
         * Diacritic re-mapping (`ue` → `ü`, `oe` → `ö`, `ae` → `ä`, `ss` → `ß`)
         * is deliberately **not** performed — the heuristic produces too many
         * false positives (e.g. `Quelle` → `Quölle`). The user fixes remaining
         * special characters manually.
         */
        fun preprocessFilename(raw: String): String {
            var working = stripExtension(raw)
            working = TRACK_PREFIX_REGEX.replaceFirst(working, "")
            val spaced = working
                .replace('_', ' ')
                .replace('-', ' ')
                .replace('.', ' ')
            val segmented = insertWordBoundaries(spaced)
            return WHITESPACE_REGEX.replace(segmented, " ").trim()
        }

        /**
         * Detects unusable filenames (UUID pattern, long single token without
         * separators, empty).
         *
         * Placeholder strings like `audio` or `voicememo` are already filtered
         * by [sanitize]; this guard only covers what sanitize cannot see.
         */
        fun isGarbageFilename(candidate: String): Boolean {
            if (candidate.isEmpty()) {
                return true
            }
            if (UUID_REGEX.matches(candidate)) {
                return true
            }
            if (candidate.length >= LONG_TOKEN_THRESHOLD && candidate.none(::isFilenameSeparator)) {
                return true
            }
            return false
        }

        // MARK: - Internal helpers

        private fun computeTeacher(
            artist: String?,
            preprocessedFilename: String,
            knownTeachers: List<String>
        ): String? {
            sanitize(artist)?.let { return it }
            val sanitizedKnown = knownTeachers
                .mapNotNull { sanitize(it) }
                .filter { isEligibleTeacherForFilenameMatch(it) }
                .sortedByDescending { it.length }
            val needle = preprocessedFilename.lowercase()
            for (candidate in sanitizedKnown) {
                if (candidate.lowercase() in needle) {
                    return candidate
                }
            }
            return null
        }

        private fun computeName(
            title: String?,
            basename: String,
            preprocessedFilename: String,
            teacher: String?
        ): String? {
            val sanitizedTitle = sanitize(title)
            if (sanitizedTitle != null) {
                return sanitizedTitle
            }
            if (isGarbageFilename(basename) || isGarbageFilename(preprocessedFilename)) {
                return null
            }
            val strippedCandidate = nameWithTeacherStripped(preprocessedFilename, teacher)
            if (strippedCandidate != null) {
                return strippedCandidate
            }
            val direct = sanitize(preprocessedFilename)
            return direct?.takeIf { it.length >= MIN_NAME_LENGTH }
        }

        private fun nameWithTeacherStripped(preprocessedFilename: String, teacher: String?): String? {
            if (teacher == null) {
                return null
            }
            val stripped = removeTeacherSubstring(
                filename = preprocessedFilename,
                teacher = teacher
            ) ?: return null
            val candidate = sanitize(stripped) ?: return null
            return candidate.takeIf { it.length >= MIN_NAME_LENGTH }
        }

        private fun removeTeacherSubstring(filename: String, teacher: String): String? {
            val needle = teacher.lowercase()
            val haystack = filename.lowercase()
            val start = haystack.indexOf(needle)
            if (start < 0) {
                return null
            }
            val end = start + needle.length
            val working = filename.removeRange(start, end)
            return WHITESPACE_REGEX.replace(working, " ").trim()
        }

        private fun isEligibleTeacherForFilenameMatch(name: String): Boolean {
            val words = name.split(WHITESPACE_REGEX).count { it.isNotBlank() }
            return words >= MIN_TEACHER_WORDS || name.length >= ELIGIBLE_TEACHER_MIN_LENGTH
        }

        private fun insertWordBoundaries(input: String): String {
            if (input.isEmpty()) {
                return input
            }
            val builder = StringBuilder(input.length + (input.length / BUILDER_GROWTH_DIVISOR))
            for (index in input.indices) {
                val current = input[index]
                if (index > 0) {
                    val previous = input[index - 1]
                    val next = input.getOrNull(index + 1)
                    if (isWordBoundary(previous = previous, current = current, next = next)) {
                        builder.append(' ')
                    }
                }
                builder.append(current)
            }
            return builder.toString()
        }

        private fun isWordBoundary(previous: Char, current: Char, next: Char?): Boolean {
            return isCamelCaseBoundary(previous, current) ||
                isAcronymEndBoundary(previous, current, next) ||
                isDigitLetterBoundary(previous, current)
        }

        /** lowercase letter → uppercase letter: "MomentMal" → "Moment Mal" */
        private fun isCamelCaseBoundary(previous: Char, current: Char): Boolean {
            return previous.isLetter() && previous.isLowerCase() && current.isUpperCase()
        }

        /** acronym → capitalized word: "MBSRBodyscan" → "MBSR Bodyscan" */
        private fun isAcronymEndBoundary(previous: Char, current: Char, next: Char?): Boolean {
            if (next == null) return false
            return previous.isLetter() && previous.isUpperCase() &&
                current.isLetter() && current.isUpperCase() &&
                next.isLetter() && next.isLowerCase()
        }

        /** digit ↔ letter transition in either direction: "04Fuesse" → "04 Fuesse" */
        private fun isDigitLetterBoundary(previous: Char, current: Char): Boolean {
            return (previous.isDigit() && current.isLetter()) ||
                (previous.isLetter() && current.isDigit())
        }

        private fun isPureTrackNumbering(comparison: String): Boolean {
            val stripped = if (comparison.startsWith("track")) {
                comparison.removePrefix("track")
            } else {
                comparison
            }
            if (stripped.isEmpty() || stripped.length > MAX_TRACK_DIGITS) {
                return false
            }
            return stripped.all { it.isDigit() }
        }

        private fun stripExtension(filename: String): String {
            val dotIndex = filename.lastIndexOf('.')
            if (dotIndex <= 0) {
                return filename
            }
            return filename.substring(0, dotIndex)
        }

        private fun isFilenameSeparator(character: Char): Boolean =
            character == '_' || character == '-' || character == '.' ||
                character == ' ' || character == '/'

        private const val MIN_NAME_LENGTH = 3
        private const val MIN_TEACHER_WORDS = 2
        private const val ELIGIBLE_TEACHER_MIN_LENGTH = 6
        private const val LONG_TOKEN_THRESHOLD = 24
        private const val MAX_TRACK_DIGITS = 3
        private const val BUILDER_GROWTH_DIVISOR = 4

        private val SEPARATORS = setOf('_', '-', '.', ' ', '/')

        private val EXCLUDED_TOKENS = setOf(
            "unknown",
            "unknownartist",
            "untitled",
            "audio",
            "recording",
            "voicememo",
            "voicerecording"
        )

        private val TRACK_PREFIX_REGEX = Regex("^\\d{1,3}[-_.\\s]+")
        private val WHITESPACE_REGEX = Regex("\\s+")
        private val UUID_REGEX = Regex(
            "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
            RegexOption.IGNORE_CASE
        )
    }
}
