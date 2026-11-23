package com.code101.tasks.data.local

import com.code101.tasks.domain.model.Snapshot
import kotlinx.coroutines.flow.StateFlow

interface CacheStore {
    val snapshot: StateFlow<Snapshot>
    suspend fun current(): Snapshot = snapshot.value
    suspend fun change(block: (Snapshot) -> Snapshot)
}
