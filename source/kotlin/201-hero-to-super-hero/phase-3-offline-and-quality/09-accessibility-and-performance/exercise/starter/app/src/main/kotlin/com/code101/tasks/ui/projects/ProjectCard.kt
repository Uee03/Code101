package com.code101.tasks.ui.projects

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.code101.tasks.domain.model.Project

@Composable
fun ProjectCard(project: Project, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    // TODO 1: make the whole card one TalkBack item: merge the descendants' semantics
    // TODO 2: make the whole card clickable with onClickLabel = stringResource(R.string.open_project)
    Card(modifier = modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(project.name, style = MaterialTheme.typography.titleMedium)
            Text(project.key)
        }
    }
}
