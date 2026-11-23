package com.code101.tasks.di

import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import java.time.Clock

@Module
@InstallIn(SingletonComponent::class)
object TimeModule {
    // TODO: add a function that provides one shared Clock.systemUTC() for the whole app
    // (annotate it so that Hilt knows it is a provider and keeps a single instance)
}
