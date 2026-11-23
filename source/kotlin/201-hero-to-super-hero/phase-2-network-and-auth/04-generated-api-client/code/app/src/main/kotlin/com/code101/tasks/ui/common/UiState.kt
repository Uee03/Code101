package com.code101.tasks.ui.common

import com.code101.tasks.R

sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Failure(val messageRes: Int) : UiState<Nothing>
}

fun <T> screenState(data: List<T>, refreshed: Boolean, failed: Boolean): UiState<List<T>> = when {
    data.isNotEmpty() -> UiState.Success(data)
    failed -> UiState.Failure(R.string.error_offline)
    refreshed -> UiState.Success(data)
    else -> UiState.Loading
}
