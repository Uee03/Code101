package com.code101.tasks.domain.model

data class Team(
    val id: String,
    val name: String,
    val description: String,
    val memberCount: Int,
)

data class Project(
    val id: String,
    val teamId: String,
    val key: String,
    val name: String,
)

data class Profile(
    val displayName: String,
    val email: String,
)

data class TaskItem(
    val id: String,
    val projectId: String,
    val title: String,
    val status: String,
    val version: Int,
    val syncState: String = "synced",
)
