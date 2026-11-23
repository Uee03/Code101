package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.Member
import com.code101.tasks.generated.model.MemberPage
import com.code101.tasks.generated.model.MemberPut
import com.code101.tasks.generated.model.Problem
import com.code101.tasks.generated.model.ValidationProblem

interface MembersApi {
    /**
     * GET v1/teams/{teamId}/members
     * Members of a team
     * 
     * Responses:
     *  - 200: One page of members.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *
     * @param teamId 
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @return [MemberPage]
     */
    @GET("v1/teams/{teamId}/members")
    suspend fun listMembers(@Path("teamId") teamId: java.util.UUID, @Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null): Response<MemberPage>

    /**
     * PUT v1/teams/{teamId}/members/{userId}
     * Add a member or change their team role (idempotent)
     * 
     * Responses:
     *  - 200: The member already existed; the role was updated.
     *  - 201: The member was added.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 422: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
     *
     * @param teamId 
     * @param userId 
     * @param memberPut 
     * @return [Member]
     */
    @PUT("v1/teams/{teamId}/members/{userId}")
    suspend fun putMember(@Path("teamId") teamId: java.util.UUID, @Path("userId") userId: java.util.UUID, @Body memberPut: MemberPut): Response<Member>

    /**
     * DELETE v1/teams/{teamId}/members/{userId}
     * Remove a member; the last lead cannot be removed
     * 
     * Responses:
     *  - 204: Removed.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *  - 404: The resource does not exist, or the caller may not know that it exists.
     *  - 409: Duplicate name or key, a business rule, or an Idempotency-Key still in progress.
     *
     * @param teamId 
     * @param userId 
     * @return [Unit]
     */
    @DELETE("v1/teams/{teamId}/members/{userId}")
    suspend fun removeMember(@Path("teamId") teamId: java.util.UUID, @Path("userId") userId: java.util.UUID): Response<Unit>

}
