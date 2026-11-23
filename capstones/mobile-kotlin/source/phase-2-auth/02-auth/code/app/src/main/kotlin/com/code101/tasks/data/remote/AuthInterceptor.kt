package com.code101.tasks.data.remote

import com.code101.tasks.domain.repository.Session
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Route

class AuthInterceptor(private val session: Session) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        if (chain.request().url.encodedPath == "/health") return chain.proceed(chain.request())
        val token = runBlocking { session.accessToken() }
        return chain.proceed(chain.request().newBuilder().header("Authorization", "Bearer $token").build())
    }
}
class TokenAuthenticator(private val session: Session) : Authenticator {
    override fun authenticate(route: Route?, response: Response): Request? {
        if (response.priorResponse != null) return null
        val rejected = response.request.header("Authorization")?.removePrefix("Bearer ")
        val token = try { runBlocking { session.accessToken(true, rejected) } } catch (_: Exception) { return null }
        return response.request.newBuilder().header("Authorization", "Bearer $token").build()
    }
}
