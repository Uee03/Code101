package com.code101.tasks.di

import com.code101.tasks.BuildConfig
import com.code101.tasks.data.remote.QueryEnums
import com.code101.tasks.data.remote.UrlPolicyInterceptor
import com.code101.tasks.data.remote.wireJson
import com.code101.tasks.generated.api.PlatformApi
import com.code101.tasks.generated.api.ProjectsApi
import com.code101.tasks.generated.api.TasksApi
import com.code101.tasks.generated.api.TeamsApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun okHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .followRedirects(false)
        .followSslRedirects(false)
        .addInterceptor(UrlPolicyInterceptor())
        .apply {
            if (BuildConfig.DEBUG) {
                addInterceptor(
                    HttpLoggingInterceptor().apply {
                        redactHeader("Authorization")
                        level = HttpLoggingInterceptor.Level.BASIC
                    },
                )
            }
        }
        .build()

    @Provides
    @Singleton
    fun retrofit(client: OkHttpClient): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.API_BASE_URL + "/")
        .client(client)
        .addConverterFactory(QueryEnums())
        .addConverterFactory(wireJson.asConverterFactory("application/json".toMediaType()))
        .build()

    @Provides
    @Singleton
    fun platformApi(retrofit: Retrofit): PlatformApi = retrofit.create(PlatformApi::class.java)

    @Provides
    @Singleton
    fun teamsApi(retrofit: Retrofit): TeamsApi = retrofit.create(TeamsApi::class.java)

    @Provides
    @Singleton
    fun projectsApi(retrofit: Retrofit): ProjectsApi = retrofit.create(ProjectsApi::class.java)

    @Provides
    @Singleton
    fun tasksApi(retrofit: Retrofit): TasksApi = retrofit.create(TasksApi::class.java)
}
