package com.code101.tasks

import android.app.Application
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.code101.tasks.data.auth.AuthStateManager
import com.code101.tasks.data.sync.SyncScheduler
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.*
import javax.inject.Inject

@HiltAndroidApp
class TasksApplication : Application(), Configuration.Provider {
    @Inject lateinit var workerFactory: HiltWorkerFactory
    @Inject lateinit var auth: AuthStateManager
    @Inject lateinit var scheduler: SyncScheduler
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder().setWorkerFactory(workerFactory).build()
    override fun onCreate() {
        super.onCreate()
        scope.launch { auth.restore(); scheduler.start(scope) }
    }
}
