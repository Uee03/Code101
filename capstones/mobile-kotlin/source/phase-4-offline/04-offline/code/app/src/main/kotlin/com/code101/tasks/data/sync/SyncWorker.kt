package com.code101.tasks.data.sync

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.code101.tasks.data.auth.AuthStateManager
import com.code101.tasks.domain.repository.SessionStatus
import com.code101.tasks.domain.repository.TasksRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject

@HiltWorker
class SyncWorker @AssistedInject constructor(@Assisted context: Context, @Assisted parameters: WorkerParameters,
    private val repository: TasksRepository, private val auth: AuthStateManager) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        if (auth.status.value == SessionStatus.Checking) auth.restore()
        if (auth.status.value != SessionStatus.SignedIn) return Result.success()
        return try {
            repository.sync()
            if (repository.hasPending()) Result.retry() else Result.success()
        } catch (e: kotlinx.coroutines.CancellationException) { throw e } catch (_: Exception) { Result.retry() }
    }
}
