package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ProfileCard(name: String, role: String, modifier: Modifier = Modifier) {
    // TODO 1: wrap everything in a Card that fills the width (modifier.fillMaxWidth())
    // TODO 2: inside it put a Row with an Icon (R.drawable.ic_check, contentDescription = null) and a Column
    // TODO 3: the Column shows name with MaterialTheme.typography.titleMedium and role with bodyMedium
}

@Preview(showBackground = true)
@Composable
fun ProfileCardPreview() {
    TasksTheme {
        ProfileCard(name = "Ana", role = "Team lead")
    }
}
