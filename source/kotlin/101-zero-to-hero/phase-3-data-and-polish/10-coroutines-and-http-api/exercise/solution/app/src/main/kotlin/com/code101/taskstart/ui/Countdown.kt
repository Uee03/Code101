package com.code101.taskstart.ui

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.code101.taskstart.R
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class CountdownViewModel : ViewModel() {
    private val _seconds = MutableStateFlow(3)
    val seconds: StateFlow<Int> = _seconds.asStateFlow()

    fun start() {
        viewModelScope.launch {
            while (_seconds.value > 0) {
                delay(1000)
                _seconds.update { it - 1 }
            }
        }
    }
}

@Composable
fun CountdownButton(
    modifier: Modifier = Modifier,
    viewModel: CountdownViewModel = viewModel(),
) {
    val seconds by viewModel.seconds.collectAsStateWithLifecycle()
    Button(onClick = viewModel::start, modifier = modifier) {
        Text(stringResource(R.string.countdown, seconds))
    }
}
