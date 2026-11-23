package com.code101.tasks

import android.os.Bundle
import android.content.Intent
import androidx.compose.runtime.saveable.rememberSaveable
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.domain.repository.SessionStatus
import com.code101.tasks.ui.navigation.AppGraph
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import com.code101.tasks.data.auth.AuthStateManager
import com.code101.tasks.ui.login.SessionScreen
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var auth: AuthStateManager
    @Inject lateinit var repository: TasksRepository
    private var incoming by mutableStateOf<String?>(null)
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent); setIntent(intent); incoming = intent.data?.path ?: intent.getStringExtra("route")
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycleScope.launch { auth.restore() }
        incoming = intent.data?.path ?: intent.getStringExtra("route")
        setContent {
            var intended by rememberSaveable { mutableStateOf(incoming) }
            var deleteOffline by rememberSaveable { mutableStateOf(false) }
            LaunchedEffect(incoming) { if (incoming != null) intended = incoming }
            val status by auth.status.collectAsStateWithLifecycle()
            var busy by remember { mutableStateOf(false) }
            var error by remember { mutableStateOf(false) }
            val login = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
                lifecycleScope.launch {
                    busy = true
                    try { result.data?.let { auth.acceptLogin(it) } } catch (_: Exception) { error = true }
                    finally { busy = false }
                }
            }
            val logout = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
                lifecycleScope.launch {
                    if (result.resultCode == RESULT_OK) { if (deleteOffline) repository.clear(); auth.clear() }
                    else error = true
                    busy = false
                }
            }
            fun launchLogout(delete: Boolean) {
                deleteOffline = delete
                lifecycleScope.launch {
                    busy = true
                    try {
                        val intent = auth.logoutIntent()
                        if (intent != null) logout.launch(intent) else { error = true; busy = false }
                    } catch (_: Exception) { error = true; busy = false }
                }
            }
            MaterialTheme {
                if (status == SessionStatus.SignedIn) {
                    AppGraph(intended, consumed = { intended = null; incoming = null }, logout = ::launchLogout)
                } else SessionScreen(status, busy, error, login = {
                    lifecycleScope.launch {
                        busy = true; error = false
                        try { login.launch(auth.loginIntent()) } catch (_: Exception) { error = true; busy = false }
                    }
                }, logout = { launchLogout(false) })
            }
        }
    }
}
