package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ClickCounter(modifier: Modifier = Modifier) {
    // TODO 1: make count a state value that survives a rotation (by delegate, rememberSaveable and mutableStateOf)
    var count = 0
    Column(modifier = modifier) {
        Button(onClick = { /* TODO 2: increase count by one */ }) {
            Text(stringResource(R.string.taps, count))
        }
        // TODO 3: add a Button with the text stringResource(R.string.reset) that sets count back to 0
    }
}

@Preview(showBackground = true)
@Composable
fun ClickCounterPreview() {
    TasksTheme {
        ClickCounter()
    }
}
