package com.code101.tasks.ui.common

sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Failure(val messageRes: Int) : UiState<Nothing>
}

fun <T> screenState(data: List<T>, refreshed: Boolean, failure: Int?): UiState<List<T>> = when {
    data.isNotEmpty() -> UiState.Success(data)
    failure != null -> UiState.Failure(failure)
    refreshed -> UiState.Success(data)
    else -> UiState.Loading
}
