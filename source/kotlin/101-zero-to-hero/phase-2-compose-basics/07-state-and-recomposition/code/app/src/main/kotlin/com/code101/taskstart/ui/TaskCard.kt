package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task

@Composable
fun TaskCard(
    task: Task,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val toggleLabel = stringResource(R.string.toggle_task, task.title)
    Card(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(end = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Checkbox(
                checked = task.done,
                onCheckedChange = { onToggle() },
                modifier = Modifier.semantics { contentDescription = toggleLabel },
            )
            Text(
                text = task.title,
                style = MaterialTheme.typography.titleMedium,
                textDecoration = if (task.done) TextDecoration.LineThrough else TextDecoration.None,
                modifier = Modifier.weight(1f),
            )
            Text(
                text = stringResource(if (task.done) R.string.status_done else R.string.status_open),
                style = MaterialTheme.typography.labelLarge,
            )
        }
    }
}
