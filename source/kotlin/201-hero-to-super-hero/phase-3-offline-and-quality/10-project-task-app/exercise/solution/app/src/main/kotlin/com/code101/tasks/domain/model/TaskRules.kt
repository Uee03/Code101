package com.code101.tasks.domain.model

fun TaskItem.canComplete(): Boolean =
    status != "done" && status != "cancelled" && syncState == "synced"
