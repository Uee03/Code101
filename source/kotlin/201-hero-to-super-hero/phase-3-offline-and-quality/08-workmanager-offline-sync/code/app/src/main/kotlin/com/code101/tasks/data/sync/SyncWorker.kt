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
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.first

@HiltWorker
class SyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted parameters: WorkerParameters,
    private val repository: TasksRepository,
    private val auth: AuthStateManager,
) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        if (auth.status.value == SessionStatus.Checking) auth.restore()
        if (auth.status.value != SessionStatus.SignedIn) return Result.success()
        return try {
            repository.sync()
            if (repository.pendingCount.first() > 0) Result.retry() else Result.success()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
