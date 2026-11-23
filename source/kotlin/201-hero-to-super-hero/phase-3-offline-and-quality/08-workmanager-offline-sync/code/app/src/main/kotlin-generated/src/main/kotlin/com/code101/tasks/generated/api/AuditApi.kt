package com.code101.tasks.generated.api

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.code101.tasks.generated.model.AuditEntityType
import com.code101.tasks.generated.model.AuditPage
import com.code101.tasks.generated.model.Problem

interface AuditApi {
    /**
     * GET v1/audit-log
     * The audit trail, newest first (admin)
     * 
     * Responses:
     *  - 200: One page of audit entries.
     *  - 400: Malformed JSON, a bad query parameter or a bad cursor.
     *  - 401: Missing, expired or invalid bearer token.
     *  - 403: The token is valid but the role, scope or team membership does not allow this.
     *
     * @param limit Page size. (optional, default to 25)
     * @param cursor Opaque value copied from &#x60;page.nextCursor&#x60;. Do not build or parse it. (optional)
     * @param entityType  (optional)
     * @param entityId  (optional)
     * @param actorId  (optional)
     * @param from Entries at or after this instant. (optional)
     * @param to Entries before this instant. (optional)
     * @return [AuditPage]
     */
    @GET("v1/audit-log")
    suspend fun listAuditLog(@Query("limit") limit: kotlin.Int? = 25, @Query("cursor") cursor: kotlin.String? = null, @Query("entityType") entityType: AuditEntityType? = null, @Query("entityId") entityId: java.util.UUID? = null, @Query("actorId") actorId: java.util.UUID? = null, @Query("from") from: java.time.OffsetDateTime? = null, @Query("to") to: java.time.OffsetDateTime? = null): Response<AuditPage>

}
