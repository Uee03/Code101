package com.code101.taskstart.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.code101.taskstart.model.TaskFilter
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.settingsDataStore by preferencesDataStore(name = "settings")

class SettingsStore(private val context: Context) {
    private val filterKey = stringPreferencesKey("filter")

    val filter: Flow<TaskFilter> = context.settingsDataStore.data.map { preferences ->
        TaskFilter.entries.firstOrNull { it.name == preferences[filterKey] } ?: TaskFilter.All
    }

    suspend fun setFilter(value: TaskFilter) {
        context.settingsDataStore.edit { preferences ->
            preferences[filterKey] = value.name
        }
    }
}
