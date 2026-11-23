package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.Problem
import com.code101.tasks.generated.model.Team
import com.code101.tasks.generated.model.TeamCreate
import com.code101.tasks.generated.model.TeamPage
import com.code101.tasks.generated.model.TeamUpdate
import com.code101.tasks.generated.model.ValidationProblem

interface TeamsApi {
    /**
     * POST v1/teams
     * Create a team (admin); the lead becomes its first member
     * 
     * Responses:
     *  - 201: Created.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 409: Duplicate name or key, a business rule, or an Idempotency-Key still in progress.
     *  - 422: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
     *
     * @param teamCreate 
     * @param idempotencyKey A unique value (a UUID is fine) per create. Same key and same body replays the first response; same key and a different body gives 422; the same key still running gives 409. Keys are scoped to the caller and kept for 24 hours.  (optional)
     * @return [Team]
     */
    @POST("v1/teams")
    suspend fun createTeam(@Body teamCreate: TeamCreate, @Header("Idempotency-Key") idempotencyKey: kotlin.String? = null): Response<Team>

    /**
     * DELETE v1/teams/{teamId}
     * Delete a team with its projects, tasks and comments (admin)
     * 
     * Responses:
     *  - 204: Deleted.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param teamId 
     * @return [Unit]
     */
    @DELETE("v1/teams/{teamId}")
    suspend fun deleteTeam(@Path("teamId") teamId: java.util.UUID): Response<Unit>

    /**
     * GET v1/teams/{teamId}
     * One team
     * 
     * Responses:
     *  - 200: The team.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param teamId 
     * @return [Team]
     */
    @GET("v1/teams/{teamId}")
    suspend fun getTeam(@Path("teamId") teamId: java.util.UUID): Response<Team>


    /**
    * enum for parameter sort
    */
    @Serializable
    enum class SortListTeams(val value: kotlin.String) {
        @SerialName(value = "-createdAt") MinusCreatedAt("-createdAt"),
        @SerialName(value = "createdAt") createdAt("createdAt")
    }

    /**
     * GET v1/teams
     * Teams the caller belongs to (admins see every team)
     * 
     * Responses:
     *  - 200: One page of teams.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @param sort  (optional, default to Sort.MinusCreatedAt)
     * @param q Case-insensitive prefix of the team name. (optional)
     * @return [TeamPage]
     */
    @GET("v1/teams")
    suspend fun listTeams(@Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null, @Query("sort") sort: SortListTeams? = SortListTeams.MinusCreatedAt, @Query("q") q: kotlin.String? = null): Response<TeamPage>

    /**
     * PATCH v1/teams/{teamId}
     * Change name or description (JSON Merge Patch)
     * 
     * Responses:
     *  - 200: The updated team with its new ETag.
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
     * @param teamId 
     * @param teamUpdate 
     * @return [Team]
     */
    @PATCH("v1/teams/{teamId}")
    suspend fun updateTeam(@Header("If-Match") ifMatch: kotlin.String, @Path("teamId") teamId: java.util.UUID, @Body teamUpdate: TeamUpdate): Response<Team>

}
