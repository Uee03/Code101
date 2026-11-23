package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.Health
import com.code101.tasks.generated.model.Me
import com.code101.tasks.generated.model.Problem
import com.code101.tasks.generated.model.UserPage

interface PlatformApi {
    /**
     * GET health
     * Liveness and database check
     * 
     * Responses:
     *  - 200: The service and its database are reachable.
     *  - 503: The database is not reachable.
     *
     * @return [Health]
     */
    @GET("health")
    suspend fun getHealth(): Response<Health>

    /**
     * GET v1/me
     * The calling user, roles, scopes and team memberships
     * 
     * Responses:
     *  - 200: The caller. The user row is created on the first authenticated request.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 429: Rate limit exceeded.
     *
     * @return [Me]
     */
    @GET("v1/me")
    suspend fun getMe(): Response<Me>

    /**
     * GET v1/users
     * Find users, for example to add a team member
     * 
     * Responses:
     *  - 200: One page of users.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @param q Case-insensitive prefix of username or display name. (optional)
     * @return [UserPage]
     */
    @GET("v1/users")
    suspend fun listUsers(@Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null, @Query("q") q: kotlin.String? = null): Response<UserPage>

}
