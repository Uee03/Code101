package com.code101.tasks.ui.teams

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.Team
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.components.AppScaffold
import com.code101.tasks.ui.components.UiStateContent

@Composable
fun TeamsScreen(
    state: UiState<List<Team>>,
    searchText: String,
    onSearchChange: (String) -> Unit,
    onRetry: () -> Unit,
    onOpenTeam: (String) -> Unit,
) {
    AppScaffold(titleRes = R.string.teams) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedTextField(
                value = searchText,
                onValueChange = onSearchChange,
                label = { Text(stringResource(R.string.search_teams)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            UiStateContent(
                state = state,
                onRetry = onRetry,
                modifier = Modifier.weight(1f),
            ) { teams ->
                if (teams.isEmpty()) {
                    Text(text = stringResource(R.string.empty))
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 4.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(teams, key = { it.id }) { team ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { onOpenTeam(team.id) },
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Text(team.name, style = MaterialTheme.typography.titleMedium)
                                    Text(team.description)
                                    Text(stringResource(R.string.members, team.memberCount))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
