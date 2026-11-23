package com.code101.tasks.domain.repository

import kotlinx.coroutines.flow.StateFlow

enum class SessionStatus { Checking, SignedOut, SignedIn }

interface Session {
    val accountId: StateFlow<String?>
    val status: StateFlow<SessionStatus>

    suspend fun accessToken(force: Boolean = false, rejected: String? = null): String
}
