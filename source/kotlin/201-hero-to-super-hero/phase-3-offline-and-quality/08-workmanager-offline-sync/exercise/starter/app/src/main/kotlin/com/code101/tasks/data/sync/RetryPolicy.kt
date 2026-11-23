package com.code101.tasks.data.sync

import kotlin.random.Random

object RetryPolicy {
    // TODO: true for the statuses worth retrying: 408, 425, 429 and every 5xx
    fun isRetryable(status: Int): Boolean = false

    // TODO: exponential backoff: 30 seconds doubled for each attempt, capped at one hour,
    // plus up to 1000 ms of random jitter; never shorter than retryAfterMillis.
    // (Cap the shift at 6 so the number cannot overflow.)
    fun delayMillis(attempts: Int, retryAfterMillis: Long = 0, random: Random = Random.Default): Long = 0L
}
