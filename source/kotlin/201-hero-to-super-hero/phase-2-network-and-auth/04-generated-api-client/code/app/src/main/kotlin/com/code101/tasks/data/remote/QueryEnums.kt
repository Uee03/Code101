package com.code101.tasks.data.remote

import com.code101.tasks.generated.api.ProjectsApi
import com.code101.tasks.generated.api.TasksApi
import com.code101.tasks.generated.api.TeamsApi
import com.code101.tasks.generated.model.TaskPriority
import com.code101.tasks.generated.model.TaskStatus
import java.lang.reflect.Type
import retrofit2.Converter
import retrofit2.Retrofit

// The generated query enums print their Kotlin name by default; the server needs their wire value.
class QueryEnums : Converter.Factory() {
    override fun stringConverter(
        type: Type,
        annotations: Array<Annotation>,
        retrofit: Retrofit,
    ): Converter<*, String>? {
        val known = setOf<Type>(
            TasksApi.SortListTasks::class.java,
            TeamsApi.SortListTeams::class.java,
            ProjectsApi.SortListProjects::class.java,
            TaskStatus::class.java,
            TaskPriority::class.java,
        )
        if (type !in known) return null
        return Converter<Any, String> { value ->
            when (value) {
                is TasksApi.SortListTasks -> value.value
                is TeamsApi.SortListTeams -> value.value
                is ProjectsApi.SortListProjects -> value.value
                is TaskStatus -> value.value
                is TaskPriority -> value.value
                else -> error("Unsupported query enum")
            }
        }
    }
}
