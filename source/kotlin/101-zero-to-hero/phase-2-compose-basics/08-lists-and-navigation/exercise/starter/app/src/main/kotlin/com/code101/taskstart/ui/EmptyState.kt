package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun EmptyState(message: String, modifier: Modifier = Modifier) {
    // TODO 1: show a Row (padding 16.dp, centred vertically, 8.dp between items)
    // TODO 2: first child: Icon with R.drawable.ic_list and contentDescription = null
    // TODO 3: second child: Text with the message
}

@Preview(showBackground = true)
@Composable
fun EmptyStatePreview() {
    TasksTheme {
        EmptyState(message = stringResource(R.string.empty_list))
    }
}
