package com.code101.tasks.domain.model

fun TaskItem.canComplete(): Boolean {
    // TODO: true only when the status is not "done" or "cancelled" AND syncState is "synced"
    return false
}
