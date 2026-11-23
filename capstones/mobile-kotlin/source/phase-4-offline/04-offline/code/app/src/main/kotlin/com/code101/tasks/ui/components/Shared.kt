package com.code101.tasks.ui.components

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.ApiProblem
import com.code101.tasks.ui.ScreenState
import java.text.NumberFormat
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@Composable
fun Action(@StringRes label: Int, @DrawableRes icon: Int, enabled: Boolean = true, detail: String? = null, click: () -> Unit) {
    Button(onClick = click, enabled = enabled, modifier = Modifier.heightIn(min = 48.dp)) {
        Icon(painterResource(icon), contentDescription = null)
        Spacer(Modifier.width(8.dp))
        Text(if (detail == null) stringResource(label)
            else stringResource(R.string.label_value, stringResource(label), detail))
    }
}
@Composable
fun PageFrame(@StringRes title: Int, state: ScreenState, listState: LazyListState = rememberLazyListState(), content: LazyListScope.() -> Unit) {
    LazyColumn(Modifier.fillMaxSize().padding(16.dp), state = listState, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text(stringResource(title), style = MaterialTheme.typography.headlineMedium) }
        if (state.busy) item { CircularProgressIndicator() }
        state.problem?.let { problem -> item { Text(problemText(problem), Modifier.semantics { liveRegion = LiveRegionMode.Polite }) } }
        content()
    }
}
@Composable
fun OfflineBanner(online: Boolean, pending: Int, sync: () -> Unit, queue: () -> Unit) {
    if (!online || pending > 0) Surface(color = MaterialTheme.colorScheme.secondaryContainer) {
        Column(Modifier.fillMaxWidth().padding(12.dp).semantics { liveRegion = LiveRegionMode.Polite }) {
            Text(stringResource(R.string.offline_pending, NumberFormat.getIntegerInstance().format(pending)))
            Action(R.string.sync_now, R.drawable.ic_refresh_cw, click = sync)
            TextButton(onClick = queue) { Text(stringResource(R.string.sync_queue)) }
        }
    }
}
@Composable
fun Value(@StringRes label: Int, value: String?) {
    Text(stringResource(R.string.label_value, stringResource(label), value ?: stringResource(R.string.not_set)))
}
fun localeDate(raw: String?): String? = raw?.let {
    runCatching { LocalDate.parse(it).format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)) }
        .getOrElse { _ -> runCatching { OffsetDateTime.parse(it).format(DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM)) }.getOrDefault(it) }
}
@Composable
fun fieldLabel(key: String): String = stringResource(when (key) {
    "title" -> R.string.title_field
    "description" -> R.string.description
    "status" -> R.string.status
    "priority" -> R.string.priority
    "assigneeId" -> R.string.assignee
    "dueDate" -> R.string.due_date
    else -> R.string.comment
})
@Composable
fun wireLabel(key: String): String = stringResource(when (key) {
    "todo" -> R.string.todo
    "in_progress" -> R.string.in_progress
    "blocked" -> R.string.blocked
    "done" -> R.string.done
    "cancelled" -> R.string.cancelled
    "low" -> R.string.low
    "medium" -> R.string.medium
    "high" -> R.string.high
    "urgent" -> R.string.urgent
    "pending", "in_flight" -> R.string.waiting
    "conflict" -> R.string.conflict
    "failed" -> R.string.failed
    else -> R.string.synced
})
@Composable
fun fieldError(problem: ApiProblem?, pointer: String): String? {
    val detail = problem?.errors?.firstOrNull { it.pointer == pointer }?.detail ?: return null
    return when (detail) {
        "title_limit" -> stringResource(R.string.title_limit)
        "description_limit" -> stringResource(R.string.description_limit)
        "date_format" -> stringResource(R.string.date_format)
        "uuid_format" -> stringResource(R.string.uuid_format)
        "comment_limit" -> stringResource(R.string.comment_limit)
        else -> detail
    }
}
@Composable
fun problemText(problem: ApiProblem): String {
    val resource = when (problem.type.substringAfterLast('/')) {
        "bad-request" -> R.string.problem_bad_request
        "unauthorized" -> R.string.problem_unauthorized
        "forbidden" -> R.string.problem_forbidden
        "not-found" -> R.string.problem_not_found
        "conflict" -> R.string.problem_conflict
        "precondition-failed" -> R.string.problem_stale
        "validation-error" -> R.string.problem_validation
        "precondition-required" -> R.string.problem_precondition
        "rate-limited" -> R.string.problem_rate
        "internal-error" -> R.string.problem_server
        "payload-too-large" -> R.string.problem_large
        "method-not-allowed" -> R.string.problem_method
        "unsupported-media-type" -> R.string.problem_media
        "service-unavailable" -> R.string.problem_unavailable
        "offline" -> R.string.problem_offline
        "queue-not-empty" -> R.string.problem_queue
        "account-changed" -> R.string.problem_account
        else -> null
    }
    return resource?.let { stringResource(it) } ?: problem.title
}
