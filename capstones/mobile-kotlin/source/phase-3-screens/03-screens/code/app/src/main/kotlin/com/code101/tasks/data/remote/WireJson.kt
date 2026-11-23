package com.code101.tasks.data.remote

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.contextual
import java.time.LocalDate
import java.time.OffsetDateTime
import java.util.UUID

class TextSerializer<T : Any>(name: String, private val parse: (String) -> T) : KSerializer<T> {
    override val descriptor = PrimitiveSerialDescriptor(name, PrimitiveKind.STRING)
    override fun deserialize(decoder: Decoder) = parse(decoder.decodeString())
    override fun serialize(encoder: Encoder, value: T) = encoder.encodeString(value.toString())
}
val wireJson = Json {
    ignoreUnknownKeys = true
    explicitNulls = true
    serializersModule = SerializersModule {
        contextual(UUID::class, TextSerializer("UUID", UUID::fromString))
        contextual(LocalDate::class, TextSerializer("LocalDate", LocalDate::parse))
        contextual(OffsetDateTime::class, TextSerializer("OffsetDateTime", OffsetDateTime::parse))
    }
}
