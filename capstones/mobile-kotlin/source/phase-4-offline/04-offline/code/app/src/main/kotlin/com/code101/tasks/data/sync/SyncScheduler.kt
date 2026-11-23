package com.code101.tasks.data.sync

import android.content.Context
import androidx.work.*
import com.code101.tasks.domain.repository.Session
import com.code101.tasks.domain.repository.SessionStatus
import com.code101.tasks.domain.repository.TasksRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SyncScheduler @Inject constructor(@ApplicationContext private val context: Context,
    private val repository: TasksRepository, private val session: Session) {
    fun start(scope: CoroutineScope) {
        val manager = WorkManager.getInstance(context)
        val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()
        manager.enqueueUniquePeriodicWork("tasks-periodic", ExistingPeriodicWorkPolicy.KEEP,
            PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES).setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS).build())
        scope.launch {
            combine(repository.online, session.status,
                repository.snapshot.map { it.outbox.size }.distinctUntilChanged()) { online, status, count ->
                online && status == SessionStatus.SignedIn && count > 0
            }.distinctUntilChanged().collect { ready ->
                if (ready) {
                    manager.enqueueUniqueWork("tasks-sync", ExistingWorkPolicy.KEEP,
                        OneTimeWorkRequestBuilder<SyncWorker>().setConstraints(constraints)
                            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS).build())
                    runCatching { repository.sync() }
                }
            }
        }
    }
}
