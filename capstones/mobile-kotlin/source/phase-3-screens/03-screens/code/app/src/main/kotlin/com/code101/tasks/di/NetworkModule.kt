package com.code101.tasks.di

import com.code101.tasks.BuildConfig
import com.code101.tasks.data.remote.*
import com.code101.tasks.domain.repository.Session
import com.code101.tasks.generated.api.*
import com.code101.tasks.generated.model.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Converter
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import java.lang.reflect.Type
import javax.inject.Singleton

class QueryEnums : Converter.Factory() {
    override fun stringConverter(type: Type, annotations: Array<Annotation>, retrofit: Retrofit): Converter<*, String>? {
        if (type !in setOf(TasksApi.SortListTasks::class.java, TeamsApi.SortListTeams::class.java,
            ProjectsApi.SortListProjects::class.java, TaskStatus::class.java, TaskPriority::class.java)) return null
        return Converter<Any, String> { value -> when (value) {
            is TasksApi.SortListTasks -> value.value
            is TeamsApi.SortListTeams -> value.value
            is ProjectsApi.SortListProjects -> value.value
            is TaskStatus -> value.value
            is TaskPriority -> value.value
            else -> error("Unsupported query enum")
        } }
    }
}
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides @Singleton
    fun retrofit(settings: BackendSettings, session: Session): Retrofit {
        val client = OkHttpClient.Builder().followRedirects(false).followSslRedirects(false)
            .addInterceptor { chain ->
                val target = settings.url.value.toHttpUrl()
                val url = chain.request().url.newBuilder().scheme(target.scheme).host(target.host).port(target.port).build()
                chain.proceed(chain.request().newBuilder().url(url).build())
            }.addInterceptor(UrlPolicyInterceptor()).addInterceptor(AuthInterceptor(session))
            .authenticator(TokenAuthenticator(session)).apply {
                if (BuildConfig.DEBUG) addInterceptor(HttpLoggingInterceptor().apply {
                    redactHeader("Authorization"); level = HttpLoggingInterceptor.Level.BASIC
                })
            }.build()
        return Retrofit.Builder().baseUrl(BuildConfig.API_BASE_URL + "/").client(client)
            .addConverterFactory(QueryEnums())
            .addConverterFactory(wireJson.asConverterFactory("application/json".toMediaType())).build()
    }
}
