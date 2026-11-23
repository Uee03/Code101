package com.code101.tasks.data.remote

import android.content.Context
import androidx.datastore.preferences.preferencesDataStore
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.code101.tasks.BuildConfig
import com.code101.tasks.domain.model.Backend
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import okhttp3.HttpUrl.Companion.toHttpUrl
import javax.inject.Inject
import javax.inject.Singleton

private val Context.settingsStore by preferencesDataStore("settings")
@Singleton
class BackendSettings @Inject constructor(@ApplicationContext private val context: Context) {
    private val urlKey = stringPreferencesKey("base_url")
    private val labelKey = stringPreferencesKey("backend_label")
    val kind = context.settingsStore.data.map {
        runCatching { Backend.valueOf(it[labelKey] ?: Backend.Python.name) }.getOrDefault(Backend.Python)
    }.stateIn(CoroutineScope(SupervisorJob() + Dispatchers.IO), SharingStarted.Eagerly, Backend.Python)
    val url = context.settingsStore.data.map { it[urlKey] ?: BuildConfig.API_BASE_URL }
        .stateIn(CoroutineScope(SupervisorJob() + Dispatchers.IO), SharingStarted.Eagerly, BuildConfig.API_BASE_URL)
    suspend fun set(value: String, kind: Backend) {
        val parsed = value.toHttpUrl()
        HttpUrlPolicy.requireAllowed(parsed)
        require(parsed.encodedPath == "/" && parsed.query == null && parsed.fragment == null)
        context.settingsStore.edit {
            it[urlKey] = parsed.toString().removeSuffix("/")
            it[labelKey] = kind.name
        }
    }
}
