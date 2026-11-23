package com.code101.tasks.data.local

import com.code101.tasks.domain.model.Snapshot
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MemoryStore @Inject constructor() : CacheStore {
    private val mutex = Mutex()
    private val state = MutableStateFlow(Snapshot())
    override val snapshot = state.asStateFlow()
    override suspend fun change(block: (Snapshot) -> Snapshot) = mutex.withLock { state.value = block(state.value) }
}
