package com.code101.tasks.data.remote

import com.code101.tasks.BuildConfig
import okhttp3.HttpUrl
import okhttp3.Interceptor
import okhttp3.Response

object HttpUrlPolicy {
    fun requireAllowed(url: HttpUrl) {
        require(url.isHttps || (BuildConfig.DEBUG && url.scheme == "http" &&
            url.host in setOf("10.0.2.2", "localhost", "127.0.0.1")))
        require(url.username.isEmpty() && url.password.isEmpty())
    }
}
class UrlPolicyInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        HttpUrlPolicy.requireAllowed(chain.request().url)
        return chain.proceed(chain.request())
    }
}
