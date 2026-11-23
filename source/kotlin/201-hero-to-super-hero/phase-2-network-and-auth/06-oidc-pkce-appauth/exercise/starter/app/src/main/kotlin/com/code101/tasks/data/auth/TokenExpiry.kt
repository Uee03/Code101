package com.code101.tasks.data.auth

// TODO: return true when the access token must be refreshed before use:
// there is no expiry time, or fewer than skewMillis milliseconds remain until it
fun needsRefresh(expiresAtMillis: Long?, nowMillis: Long, skewMillis: Long = 60_000L): Boolean = false
