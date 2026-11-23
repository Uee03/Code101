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
    // TODO 1: show a Text whose text is stringResource(R.string.summary, openCount, doneCount)
    // TODO 2: give the Text the modifier passed in, so that the caller can place it
}

@Preview(showBackground = true)
@Composable
fun SummaryLinePreview() {
    TasksTheme {
        SummaryLine(openCount = 2, doneCount = 3)
    }
}
