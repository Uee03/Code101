package com.code101.taskstart.ui

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ClickCounter(modifier: Modifier = Modifier) {
    var count by remember { mutableStateOf(0) }
    Button(onClick = { count += 1 }, modifier = modifier) {
        Text(stringResource(R.string.taps, count))
    }
}

@Preview(showBackground = true)
@Composable
fun ClickCounterPreview() {
    TasksTheme {
        ClickCounter()
    }
}
