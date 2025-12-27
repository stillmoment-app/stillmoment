package com.stillmoment.infrastructure.logging

import android.util.Log
import com.stillmoment.domain.services.LoggerProtocol
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Android Log-based implementation of LoggerProtocol.
 */
@Singleton
class AndroidLogger
@Inject
constructor() : LoggerProtocol {

    override fun d(tag: String, message: String) {
        Log.d(tag, message)
    }

    override fun w(tag: String, message: String) {
        Log.w(tag, message)
    }

    override fun e(tag: String, message: String) {
        Log.e(tag, message)
    }

    override fun e(tag: String, message: String, throwable: Throwable) {
        Log.e(tag, message, throwable)
    }
}
