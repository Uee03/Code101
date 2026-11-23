package com.code101.taskstart.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.settingsDataStore by preferencesDataStore(name = "settings")

class SettingsStore(private val context: Context) {
    private val hideDoneKey = booleanPreferencesKey("hide_done")

    val hideDone: Flow<Boolean> = context.settingsDataStore.data
        .map { preferences -> preferences[hideDoneKey] ?: false }

    suspend fun setHideDone(value: Boolean) {
        context.settingsDataStore.edit { preferences ->
            preferences[hideDoneKey] = value
        }
    }
}
