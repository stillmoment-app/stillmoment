package com.stillmoment.domain.services

/**
 * Protocol for logging operations.
 *
 * Abstracts Android's Log class for testability.
 * Implementation uses Log.d, Log.e, etc.
 */
interface LoggerProtocol {
    fun d(tag: String, message: String)
    fun w(tag: String, message: String)
    fun e(tag: String, message: String)
    fun e(tag: String, message: String, throwable: Throwable)
}
