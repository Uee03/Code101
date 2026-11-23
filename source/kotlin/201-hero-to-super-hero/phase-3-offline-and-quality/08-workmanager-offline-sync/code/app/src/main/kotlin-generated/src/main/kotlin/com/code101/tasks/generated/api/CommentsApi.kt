package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.Comment
import com.code101.tasks.generated.model.CommentCreate
import com.code101.tasks.generated.model.CommentPage
import com.code101.tasks.generated.model.Problem
import com.code101.tasks.generated.model.ValidationProblem

interface CommentsApi {
    /**
     * POST v1/tasks/{taskId}/comments
     * Add a comment
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
     * @param taskId 
     * @param commentCreate 
     * @param idempotencyKey A unique value (a UUID is fine) per create. Same key and same body replays the first response; same key and a different body gives 422; the same key still running gives 409. Keys are scoped to the caller and kept for 24 hours.  (optional)
     * @return [Comment]
     */
    @POST("v1/tasks/{taskId}/comments")
    suspend fun createComment(@Path("taskId") taskId: java.util.UUID, @Body commentCreate: CommentCreate, @Header("Idempotency-Key") idempotencyKey: kotlin.String? = null): Response<Comment>

    /**
     * DELETE v1/comments/{commentId}
     * Delete a comment (its author, a team lead or an admin)
     * 
     * Responses:
     *  - 204: Deleted.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param commentId 
     * @return [Unit]
     */
    @DELETE("v1/comments/{commentId}")
    suspend fun deleteComment(@Path("commentId") commentId: java.util.UUID): Response<Unit>

    /**
     * GET v1/tasks/{taskId}/comments
     * Comments of a task, oldest first
     * 
     * Responses:
     *  - 200: One page of comments.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param taskId 
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @return [CommentPage]
     */
    @GET("v1/tasks/{taskId}/comments")
    suspend fun listComments(@Path("taskId") taskId: java.util.UUID, @Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null): Response<CommentPage>

}
