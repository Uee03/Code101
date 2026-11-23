package com.code101.tasks.data.auth

fun needsRefresh(expiresAtMillis: Long?, nowMillis: Long, skewMillis: Long = 60_000L): Boolean =
    expiresAtMillis == null || expiresAtMillis - nowMillis <= skewMillis
