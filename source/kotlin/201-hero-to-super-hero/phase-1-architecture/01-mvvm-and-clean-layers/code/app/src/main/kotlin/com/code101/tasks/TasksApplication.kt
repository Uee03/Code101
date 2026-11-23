package com.code101.tasks

import android.app.Application
import com.code101.tasks.data.repository.FakeTasksRepository
import com.code101.tasks.domain.repository.TasksRepository

class TasksApplication : Application() {
    val repository: TasksRepository by lazy { FakeTasksRepository() }
}
