package com.code101.tasks.ui.teams

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.R
import com.code101.tasks.ui.TeamsViewModel
import com.code101.tasks.ui.components.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeamsScreen(vm: TeamsViewModel, open: (String) -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    var q by rememberSaveable { mutableStateOf("") }
    LaunchedEffect(Unit) { vm.load(q) }
    PullToRefreshBox(isRefreshing = state.busy, onRefresh = { vm.load(q) }) {
        PageFrame(R.string.teams, state) {
            item {
                OutlinedTextField(q, { q = it }, label = { Text(stringResource(R.string.search)) })
                Action(R.string.search, R.drawable.ic_refresh_cw, !state.busy) { vm.load(q) }
            }
            val teams = state.data.teams.filter { it.name.contains(q, ignoreCase = true) }
            if (teams.isEmpty()) item { Text(stringResource(R.string.empty)) }
            items(teams, key = { it.id }) { team ->
                Action(R.string.projects, R.drawable.ic_folder, detail = team.name) { open(team.id) }
                Text(team.name, style = MaterialTheme.typography.titleLarge)
                Text(team.description)
            }
        }
    }
}
