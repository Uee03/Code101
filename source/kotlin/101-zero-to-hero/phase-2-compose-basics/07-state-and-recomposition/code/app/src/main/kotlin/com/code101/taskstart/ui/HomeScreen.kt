package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(modifier: Modifier = Modifier) {
    val tasks = remember {
        mutableStateListOf(
            Task(1, "Buy milk"),
            Task(2, "Call dentist"),
            Task(3, "Pay rent", done = true),
        )
    }
    var draft by rememberSaveable { mutableStateOf("") }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text(stringResource(R.string.app_name)) })
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            AddTaskBar(
                draft = draft,
                onDraftChange = { draft = it },
                onAdd = {
                    val title = draft.trim()
                    if (title.isNotEmpty()) {
                        val nextId = (tasks.maxOfOrNull { it.id } ?: 0) + 1
                        tasks.add(Task(nextId, title))
                        draft = ""
                    }
                },
            )
            Text(
                text = stringResource(R.string.open_count, tasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            tasks.forEachIndexed { index, task ->
                TaskCard(
                    task = task,
                    onToggle = { tasks[index] = task.copy(done = !task.done) },
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen()
    }
}
