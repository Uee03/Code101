package com.code101.tasks.data.remote

import okhttp3.Interceptor
import okhttp3.Response
import java.io.IOException
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.concurrent.atomic.AtomicLong

class RetryGate : Interceptor {
    private val notBefore = AtomicLong(0)
    override fun intercept(chain: Interceptor.Chain): Response {
        while (System.currentTimeMillis() < notBefore.get()) {
            if (chain.call().isCanceled()) throw IOException("Canceled")
            try { Thread.sleep(minOf(100L, notBefore.get() - System.currentTimeMillis()).coerceAtLeast(1)) }
            catch (_: InterruptedException) { Thread.currentThread().interrupt(); throw IOException("Canceled") }
        }
        return chain.proceed(chain.request()).also { response ->
            if (response.code == 429 || response.code == 503) {
                val header = response.header("Retry-After")
                val until = header?.toLongOrNull()?.let { System.currentTimeMillis() + it * 1000 }
                    ?: runCatching { ZonedDateTime.parse(header, DateTimeFormatter.RFC_1123_DATE_TIME).toInstant().toEpochMilli() }.getOrDefault(0)
                notBefore.updateAndGet { previous -> maxOf(previous, until) }
            }
        }
    }
}
