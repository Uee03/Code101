package com.code101.tasks.data.auth

import com.code101.tasks.BuildConfig

object AuthConfig {
    val issuer = BuildConfig.OIDC_ISSUER
    val clientId = BuildConfig.OIDC_CLIENT_ID
    val redirect = BuildConfig.OIDC_REDIRECT_URI
    val logout = BuildConfig.OIDC_LOGOUT_URI
    const val scopes = "openid profile email offline_access tasks:read tasks:write"
}
