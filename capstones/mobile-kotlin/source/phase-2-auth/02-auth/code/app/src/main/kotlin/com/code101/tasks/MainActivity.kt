package com.code101.tasks

import android.os.Bundle
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
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycleScope.launch { auth.restore() }
        setContent {
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
                lifecycleScope.launch { if (result.resultCode == RESULT_OK) auth.clear() else error = true; busy = false }
            }
            MaterialTheme {
                SessionScreen(status, busy, error, login = {
                    lifecycleScope.launch {
                        busy = true; error = false
                        try { login.launch(auth.loginIntent()) } catch (_: Exception) { error = true; busy = false }
                    }
                }, logout = {
                    lifecycleScope.launch {
                        busy = true
                        try {
                            val intent = auth.logoutIntent()
                            if (intent != null) logout.launch(intent) else { error = true; busy = false }
                        } catch (_: Exception) { error = true; busy = false }
                    }
                })
            }
        }
    }
}
