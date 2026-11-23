package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: TasksUiState,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onToggle: (Int) -> Unit,
    onOpen: (Int) -> Unit,
    onLoadSamples: () -> Unit,
    modifier: Modifier = Modifier,
) {
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
                draft = state.draft,
                onDraftChange = onDraftChange,
                onAdd = onAdd,
            )
            Text(
                text = stringResource(R.string.open_count, state.tasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            OutlinedButton(
                onClick = onLoadSamples,
                enabled = state.importState != ImportState.Loading,
            ) {
                Text(stringResource(R.string.load_samples))
            }
            ImportStatus(state.importState)
            if (state.tasks.isEmpty()) {
                Text(text = stringResource(R.string.empty_list))
            }
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.tasks, key = { it.id }) { task ->
                    TaskCard(
                        task = task,
                        onToggle = { onToggle(task.id) },
                        onOpen = { onOpen(task.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun ImportStatus(importState: ImportState) {
    val text = when (importState) {
        ImportState.Idle -> null
        ImportState.Loading -> stringResource(R.string.loading_samples)
        is ImportState.Done -> stringResource(R.string.samples_done, importState.count)
        ImportState.Failed -> stringResource(R.string.samples_failed)
    }
    if (text != null) {
        Text(
            text = text,
            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
        )
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen(
            state = TasksUiState(
                tasks = listOf(Task(1, "Buy milk"), Task(2, "Pay rent", done = true)),
                importState = ImportState.Failed,
            ),
            onDraftChange = { },
            onAdd = { },
            onToggle = { },
            onOpen = { },
            onLoadSamples = { },
        )
    }
}
