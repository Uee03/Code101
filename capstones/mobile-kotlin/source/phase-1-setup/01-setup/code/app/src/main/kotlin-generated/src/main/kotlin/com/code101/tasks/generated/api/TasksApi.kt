package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.Problem
import com.code101.tasks.generated.model.ReassignRequest
import com.code101.tasks.generated.model.Task
import com.code101.tasks.generated.model.TaskCreate
import com.code101.tasks.generated.model.TaskPage
import com.code101.tasks.generated.model.TaskPriority
import com.code101.tasks.generated.model.TaskStatus
import com.code101.tasks.generated.model.TaskUpdate
import com.code101.tasks.generated.model.ValidationProblem

interface TasksApi {
    /**
     * POST v1/tasks/{taskId}/complete
     * Mark a task done (calls the complete_task stored procedure)
     * Completing a done task returns it unchanged; a cancelled task gives 409.
     * Responses:
     *  - 200: The completed task.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 409: Duplicate name or key, a business rule, or an Idempotency-Key still in progress.
     *  - 412: The If-Match value is stale. Fetch the resource again and retry.
     *  - 428: The request must include If-Match.
     *
     * @param ifMatch The &#x60;ETag&#x60; of the version being changed, quotes included, for example &#x60;\&quot;3\&quot;&#x60;.
     * @param taskId 
     * @return [Task]
     */
    @POST("v1/tasks/{taskId}/complete")
    suspend fun completeTask(@Header("If-Match") ifMatch: kotlin.String, @Path("taskId") taskId: java.util.UUID): Response<Task>

    /**
     * POST v1/projects/{projectId}/tasks
     * Create a task
     * 
     * Responses:
     *  - 201: Created.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 409: Duplicate name or key, a business rule, or an Idempotency-Key still in progress.
     *  - 422: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
     *
     * @param projectId 
     * @param taskCreate 
     * @param idempotencyKey A unique value (a UUID is fine) per create. Same key and same body replays the first response; same key and a different body gives 422; the same key still running gives 409. Keys are scoped to the caller and kept for 24 hours.  (optional)
     * @return [Task]
     */
    @POST("v1/projects/{projectId}/tasks")
    suspend fun createTask(@Path("projectId") projectId: java.util.UUID, @Body taskCreate: TaskCreate, @Header("Idempotency-Key") idempotencyKey: kotlin.String? = null): Response<Task>

    /**
     * DELETE v1/tasks/{taskId}
     * Delete a task and its comments
     * 
     * Responses:
     *  - 204: Deleted.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 412: The If-Match value is stale. Fetch the resource again and retry.
     *
     * @param taskId 
     * @param ifMatch Optional here; when present it must match the current ETag. (optional)
     * @return [Unit]
     */
    @DELETE("v1/tasks/{taskId}")
    suspend fun deleteTask(@Path("taskId") taskId: java.util.UUID, @Header("If-Match") ifMatch: kotlin.String? = null): Response<Unit>

    /**
     * GET v1/tasks/{taskId}
     * One task; send If-None-Match to get 304 when unchanged
     * 
     * Responses:
     *  - 200: The task.
     *  - 304: The ETag still matches; no body.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param taskId 
     * @param ifNoneMatch  (optional)
     * @return [Task]
     */
    @GET("v1/tasks/{taskId}")
    suspend fun getTask(@Path("taskId") taskId: java.util.UUID, @Header("If-None-Match") ifNoneMatch: kotlin.String? = null): Response<Task>


    /**
    * enum for parameter sort
    */
    @Serializable
    enum class SortListTasks(val value: kotlin.String) {
        @SerialName(value = "-createdAt") MinusCreatedAt("-createdAt"),
        @SerialName(value = "createdAt") createdAt("createdAt"),
        @SerialName(value = "dueDate") dueDate("dueDate")
    }

    /**
     * GET v1/projects/{projectId}/tasks
     * Tasks of a project, filtered and paged
     * 
     * Responses:
     *  - 200: One page of tasks.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param projectId 
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @param sort Order. &#x60;dueDate&#x60; lists tasks without a due date last. Ties break on &#x60;id&#x60;. (optional, default to Sort.MinusCreatedAt)
     * @param status Repeat the parameter to match several statuses. (optional)
     * @param priority  (optional)
     * @param assigneeId  (optional)
     * @param dueBefore Tasks due on or before this date. (optional)
     * @param dueAfter Tasks due on or after this date. (optional)
     * @param q Case-insensitive substring of the title. (optional)
     * @return [TaskPage]
     */
    @GET("v1/projects/{projectId}/tasks")
    suspend fun listTasks(@Path("projectId") projectId: java.util.UUID, @Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null, @Query("sort") sort: SortListTasks? = SortListTasks.MinusCreatedAt, @Query("status") status: @JvmSuppressWildcards kotlin.collections.List<TaskStatus>? = null, @Query("priority") priority: @JvmSuppressWildcards kotlin.collections.List<TaskPriority>? = null, @Query("assigneeId") assigneeId: java.util.UUID? = null, @Query("dueBefore") dueBefore: java.time.LocalDate? = null, @Query("dueAfter") dueAfter: java.time.LocalDate? = null, @Query("q") q: kotlin.String? = null): Response<TaskPage>

    /**
     * POST v1/tasks/{taskId}/reassign
     * Change the assignee (calls the reassign_task stored procedure)
     * The new assignee must belong to the project&#39;s team; &#x60;null&#x60; unassigns.
     * Responses:
     *  - 200: The reassigned task.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 409: Duplicate name or key, a business rule, or an Idempotency-Key still in progress.
     *  - 412: The If-Match value is stale. Fetch the resource again and retry.
     *  - 422: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
     *  - 428: The request must include If-Match.
     *
     * @param ifMatch The &#x60;ETag&#x60; of the version being changed, quotes included, for example &#x60;\&quot;3\&quot;&#x60;.
     * @param taskId 
     * @param reassignRequest 
     * @return [Task]
     */
    @POST("v1/tasks/{taskId}/reassign")
    suspend fun reassignTask(@Header("If-Match") ifMatch: kotlin.String, @Path("taskId") taskId: java.util.UUID, @Body reassignRequest: ReassignRequest): Response<Task>

    /**
     * PATCH v1/tasks/{taskId}
     * Change fields, status, assignee or due date (JSON Merge Patch)
     * Send only the fields to change. &#x60;null&#x60; clears &#x60;assigneeId&#x60; and &#x60;dueDate&#x60;. Setting &#x60;status&#x60; to &#x60;done&#x60; stamps &#x60;completedAt&#x60;; any other status clears it. 
     * Responses:
     *  - 200: The updated task with its new ETag.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 412: The If-Match value is stale. Fetch the resource again and retry.
     *  - 422: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
     *  - 428: The request must include If-Match.
     *
     * @param ifMatch The &#x60;ETag&#x60; of the version being changed, quotes included, for example &#x60;\&quot;3\&quot;&#x60;.
     * @param taskId 
     * @param taskUpdate 
     * @return [Task]
     */
    @PATCH("v1/tasks/{taskId}")
    suspend fun updateTask(@Header("If-Match") ifMatch: kotlin.String, @Path("taskId") taskId: java.util.UUID, @Body taskUpdate: TaskUpdate): Response<Task>

}
