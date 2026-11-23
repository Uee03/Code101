package com.code101.tasks.data.local

import androidx.room.withTransaction
import com.code101.tasks.domain.model.Snapshot
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RoomStore @Inject constructor(private val db: TasksDatabase) : CacheStore {
    private val dao = db.cache()
    override val snapshot = dao.invalidations().map { dao.read() }
        .stateIn(CoroutineScope(SupervisorJob() + Dispatchers.IO), SharingStarted.Eagerly, Snapshot())
    override suspend fun current(): Snapshot = db.withTransaction { dao.read() }
    override suspend fun change(block: (Snapshot) -> Snapshot) {
        db.withTransaction { dao.replace(block(dao.read())) }
    }
}
