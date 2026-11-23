package com.code101.taskstart.ui

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun SummaryLine(openCount: Int, doneCount: Int, modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.summary, openCount, doneCount),
        modifier = modifier,
    )
}

@Preview(showBackground = true)
@Composable
fun SummaryLinePreview() {
    TasksTheme {
        SummaryLine(openCount = 2, doneCount = 3)
    }
}
