package com.code101.tasks.ui.projects

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.R
import com.code101.tasks.ui.ProjectsViewModel
import com.code101.tasks.ui.components.*

@Composable
fun ProjectsScreen(id: String, vm: ProjectsViewModel, open: (String) -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    var archived by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(id, archived) { vm.load(id, archived) }
    PageFrame(R.string.projects, state) {
        item {
            Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).toggleable(archived, role = Role.Checkbox, onValueChange = { archived = it })) {
                Checkbox(archived, null); Text(stringResource(R.string.archived))
            }
            Action(R.string.refresh, R.drawable.ic_refresh_cw, !state.busy) { vm.load(id, archived) }
        }
        val projects = state.data.projects.filter { it.teamId == id && it.archived == archived }
        if (projects.isEmpty()) item { Text(stringResource(R.string.empty)) }
        items(projects, key = { it.id }) { project ->
            Text(project.name, style = MaterialTheme.typography.titleLarge)
            Text(project.description)
            Action(R.string.task_list, R.drawable.ic_list, detail = project.name) { open(project.id) }
        }
    }
}
