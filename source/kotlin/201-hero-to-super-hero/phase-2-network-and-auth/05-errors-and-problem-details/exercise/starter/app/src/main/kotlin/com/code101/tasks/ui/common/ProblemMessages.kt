package com.code101.tasks.ui.common

import com.code101.tasks.R
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.model.ApiProblem

fun problemMessage(problem: ApiProblem): Int = when (problem.status) {
    400 -> R.string.problem_bad_request
    401 -> R.string.problem_unauthorized
    403 -> R.string.problem_forbidden
    404 -> R.string.problem_not_found
    409 -> R.string.problem_conflict
    412 -> R.string.problem_stale
    // TODO: 413 -> the string R.string.problem_large (the request is too large)
    422 -> R.string.problem_validation
    428 -> R.string.problem_precondition
    429 -> R.string.problem_rate
    in 500..599 -> R.string.problem_server
    else -> R.string.problem_unknown
}

fun failureMessage(error: Exception): Int = when (error) {
    is ApiFailure -> problemMessage(error.problem)
    else -> R.string.problem_offline
}
