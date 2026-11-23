package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.TaskFilter
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterBar(
    selected: TaskFilter,
    onSelect: (TaskFilter) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        TaskFilter.entries.forEach { option ->
            FilterChip(
                selected = selected == option,
                onClick = { onSelect(option) },
                label = { Text(stringResource(labelFor(option))) },
            )
        }
    }
}

private fun labelFor(filter: TaskFilter): Int = when (filter) {
    TaskFilter.All -> R.string.filter_all
    TaskFilter.Open -> R.string.filter_open
    TaskFilter.Done -> R.string.filter_done
}

@Preview(showBackground = true)
@Composable
fun FilterBarPreview() {
    TasksTheme {
        FilterBar(selected = TaskFilter.Open, onSelect = { })
    }
}
