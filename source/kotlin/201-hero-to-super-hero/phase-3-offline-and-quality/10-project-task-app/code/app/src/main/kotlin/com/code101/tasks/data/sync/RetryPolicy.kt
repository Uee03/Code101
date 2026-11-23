package com.code101.tasks.data.sync

import kotlin.random.Random

object RetryPolicy {
    fun isRetryable(status: Int): Boolean = status == 408 || status == 425 || status == 429 || status in 500..599

    fun delayMillis(attempts: Int, retryAfterMillis: Long = 0, random: Random = Random.Default): Long {
        val base = minOf(30_000L * (1L shl minOf(attempts, 6)), 3_600_000L)
        return maxOf(base + random.nextLong(0, 1_000), retryAfterMillis)
    }
}
