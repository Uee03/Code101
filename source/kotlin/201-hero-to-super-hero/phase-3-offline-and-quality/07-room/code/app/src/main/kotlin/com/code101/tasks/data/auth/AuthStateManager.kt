package com.code101.tasks.data.auth

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.code101.tasks.BuildConfig
import com.code101.tasks.domain.repository.Session
import com.code101.tasks.domain.repository.SessionStatus
import com.code101.tasks.data.remote.HttpUrlPolicy
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import net.openid.appauth.*
import net.openid.appauth.connectivity.ConnectionBuilder
import okhttp3.HttpUrl.Companion.toHttpUrl
import java.io.IOException
import java.net.HttpURLConnection
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthStateManager @Inject constructor(
    @ApplicationContext context: Context, private val vault: TokenVault
) : Session {
    private val mutableAccount = MutableStateFlow<String?>(null)
    override val accountId = mutableAccount.asStateFlow()
    private fun subject(current: AuthState?): String? = runCatching {
        val payload = current?.idToken?.split('.')?.get(1) ?: return@runCatching null
        org.json.JSONObject(String(android.util.Base64.decode(payload, android.util.Base64.URL_SAFE), Charsets.UTF_8)).getString("sub")
    }.getOrNull()
    private val mutex = Mutex()
    private var state: AuthState? = null
    private val mutableStatus = MutableStateFlow(SessionStatus.Checking)
    override val status = mutableStatus.asStateFlow()
    private val connections = ConnectionBuilder { uri ->
        val url = uri.toString().toHttpUrl()
        HttpUrlPolicy.requireAllowed(url)
        (url.toUrl().openConnection() as HttpURLConnection).apply {
            connectTimeout = 15000; readTimeout = 15000; instanceFollowRedirects = false
        }
    }
    private val configuration = AppAuthConfiguration.Builder().apply {
        if (BuildConfig.DEBUG) setSkipIssuerHttpsCheck(true)
        setConnectionBuilder(connections)
    }.build()
    private val service = AuthorizationService(context, configuration)

    suspend fun restore() = withContext(Dispatchers.IO) {
        mutex.withLock {
            state = try { vault.read()?.let(AuthState::jsonDeserialize) } catch (_: Exception) { null }
            mutableAccount.value = subject(state)
            mutableStatus.value = if (state?.isAuthorized == true && mutableAccount.value != null) SessionStatus.SignedIn else SessionStatus.SignedOut
        }
    }
    private suspend fun discovery(): AuthorizationServiceConfiguration = suspendCancellableCoroutine { continuation ->
        AuthorizationServiceConfiguration.fetchFromUrl(
            Uri.parse(AuthConfig.issuer + "/.well-known/openid-configuration"),
            { config, error ->
                if (config != null) continuation.resume(config)
                else continuation.resumeWithException(IOException("Discovery unavailable", error))
            }, connections)
    }
    suspend fun loginIntent(): Intent {
        val config = discovery()
        require(config.authorizationEndpoint.toString().startsWith(AuthConfig.issuer + "/"))
        val request = AuthorizationRequest.Builder(config, AuthConfig.clientId,
            ResponseTypeValues.CODE, Uri.parse(AuthConfig.redirect))
            .setScope(AuthConfig.scopes).build()
        return service.getAuthorizationRequestIntent(request)
    }
    suspend fun acceptLogin(data: Intent) = withContext(Dispatchers.IO + NonCancellable) {
        val error = AuthorizationException.fromIntent(data)
        if (error?.code == AuthorizationException.GeneralErrors.USER_CANCELED_AUTH_FLOW.code) return@withContext
        if (error != null) throw IOException("Authorization failed")
        val response = AuthorizationResponse.fromIntent(data) ?: return@withContext
        mutex.withLock {
            val next = AuthState(response, null)
            val token = tokenRequest(response.createTokenExchangeRequest())
            next.update(token, null)
            vault.save(next.jsonSerializeString())
            state = next
            mutableAccount.value = subject(next)
            mutableStatus.value = SessionStatus.SignedIn
        }
    }
    private suspend fun tokenRequest(request: TokenRequest): TokenResponse = suspendCancellableCoroutine { continuation ->
        service.performTokenRequest(request) { token, error ->
            if (token != null) continuation.resume(token)
            else continuation.resumeWithException(IOException("Session needs sign-in", error))
        }
    }
    override suspend fun accessToken(force: Boolean, rejected: String?): String =
        withContext(Dispatchers.IO + NonCancellable) {
            mutex.withLock {
                val current = state ?: throw IOException("Sign in required")
                val existing = current.accessToken
                val expires = current.accessTokenExpirationTime ?: 0L
                if (existing != null && expires - System.currentTimeMillis() > 60000L &&
                    (!force || (rejected != null && rejected != existing))) return@withLock existing
                try {
                    val token = tokenRequest(current.createTokenRefreshRequest())
                    current.update(token, null)
                    vault.save(current.jsonSerializeString())
                    current.accessToken ?: throw IOException("Sign in required")
                } catch (_: Exception) {
                    mutableStatus.value = SessionStatus.SignedOut
                    throw IOException("Sign in required")
                }
            }
        }
    suspend fun logoutIntent(): Intent? {
        val current = state ?: return null
        val config = current.authorizationServiceConfiguration ?: return null
        if (config.endSessionEndpoint == null) return null
        return service.getEndSessionRequestIntent(EndSessionRequest.Builder(config)
            .setIdTokenHint(current.idToken).setPostLogoutRedirectUri(Uri.parse(AuthConfig.logout)).build())
    }
    suspend fun clear() = mutex.withLock {
        vault.clear(); state = null; mutableAccount.value = null; mutableStatus.value = SessionStatus.SignedOut
    }
}
