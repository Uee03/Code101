package com.code101.tasks.di

import com.code101.tasks.data.auth.AuthStateManager
import com.code101.tasks.domain.repository.Session
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {
    @Binds abstract fun session(manager: AuthStateManager): Session
}
