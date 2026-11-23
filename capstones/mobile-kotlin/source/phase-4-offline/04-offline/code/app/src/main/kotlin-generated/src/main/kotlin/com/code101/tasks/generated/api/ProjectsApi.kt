package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.Problem
import com.code101.tasks.generated.model.Project
import com.code101.tasks.generated.model.ProjectCreate
import com.code101.tasks.generated.model.ProjectPage
import com.code101.tasks.generated.model.ProjectUpdate
import com.code101.tasks.generated.model.ValidationProblem

interface ProjectsApi {
    /**
     * POST v1/teams/{teamId}/projects
     * Create a project in the team
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
     * @param teamId 
     * @param projectCreate 
     * @param idempotencyKey A unique value (a UUID is fine) per create. Same key and same body replays the first response; same key and a different body gives 422; the same key still running gives 409. Keys are scoped to the caller and kept for 24 hours.  (optional)
     * @return [Project]
     */
    @POST("v1/teams/{teamId}/projects")
    suspend fun createProject(@Path("teamId") teamId: java.util.UUID, @Body projectCreate: ProjectCreate, @Header("Idempotency-Key") idempotencyKey: kotlin.String? = null): Response<Project>

    /**
     * DELETE v1/projects/{projectId}
     * Delete a project with its tasks and comments
     * 
     * Responses:
     *  - 204: Deleted.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param projectId 
     * @return [Unit]
     */
    @DELETE("v1/projects/{projectId}")
    suspend fun deleteProject(@Path("projectId") projectId: java.util.UUID): Response<Unit>

    /**
     * GET v1/projects/{projectId}
     * One project
     * 
     * Responses:
     *  - 200: The project.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param projectId 
     * @return [Project]
     */
    @GET("v1/projects/{projectId}")
    suspend fun getProject(@Path("projectId") projectId: java.util.UUID): Response<Project>


    /**
    * enum for parameter sort
    */
    @Serializable
    enum class SortListProjects(val value: kotlin.String) {
        @SerialName(value = "-createdAt") MinusCreatedAt("-createdAt"),
        @SerialName(value = "createdAt") createdAt("createdAt")
    }

    /**
     * GET v1/teams/{teamId}/projects
     * Projects of a team
     * 
     * Responses:
     *  - 200: One page of projects.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param teamId 
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @param sort  (optional, default to Sort.MinusCreatedAt)
     * @param archived Default false (hide archived projects). (optional, default to false)
     * @return [ProjectPage]
     */
    @GET("v1/teams/{teamId}/projects")
    suspend fun listProjects(@Path("teamId") teamId: java.util.UUID, @Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null, @Query("sort") sort: SortListProjects? = SortListProjects.MinusCreatedAt, @Query("archived") archived: kotlin.Boolean? = false): Response<ProjectPage>

    /**
     * PATCH v1/projects/{projectId}
     * Change name, description or archive a project (JSON Merge Patch)
     * 
     * Responses:
     *  - 200: The updated project with its new ETag.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 412: The If-Match value is stale. Fetch the resource again and retry.
     *  - 422: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
     *  - 428: The request must include If-Match.
     *
     * @param ifMatch The &#x60;ETag&#x60; of the version being changed, quotes included, for example &#x60;\&quot;3\&quot;&#x60;.
     * @param projectId 
     * @param projectUpdate 
     * @return [Project]
     */
    @PATCH("v1/projects/{projectId}")
    suspend fun updateProject(@Header("If-Match") ifMatch: kotlin.String, @Path("projectId") projectId: java.util.UUID, @Body projectUpdate: ProjectUpdate): Response<Project>

}
