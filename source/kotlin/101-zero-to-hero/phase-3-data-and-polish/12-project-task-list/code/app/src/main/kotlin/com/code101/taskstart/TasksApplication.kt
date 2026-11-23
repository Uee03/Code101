package com.code101.taskstart

import android.app.Application
import androidx.room.Room
import com.code101.taskstart.data.SettingsStore
import com.code101.taskstart.data.TasksDatabase
import com.code101.taskstart.data.TasksRepository
import com.code101.taskstart.data.TodoClient

class TasksApplication : Application() {
    private val database by lazy {
        Room.databaseBuilder(this, TasksDatabase::class.java, "tasks.db").build()
    }

    val repository by lazy {
        TasksRepository(database.taskDao(), SettingsStore(this), TodoClient.api)
    }
}
