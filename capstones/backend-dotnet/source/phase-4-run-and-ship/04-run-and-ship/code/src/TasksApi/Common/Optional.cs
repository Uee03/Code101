using System.Text.Json;
using System.Text.Json.Serialization;

namespace TasksApi.Common;

// JSON Merge Patch (RFC 7396) must tell "field absent" (leave it) from "field is null" (clear it).
// A plain nullable property cannot, so PATCH requests use Optional<T>: IsSet is true when the field was in the JSON.
[JsonConverter(typeof(OptionalConverterFactory))]
public readonly record struct Optional<T>(T? Value, bool IsSet);

public sealed class OptionalConverterFactory : JsonConverterFactory
{
    public override bool CanConvert(Type type) => type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Optional<>);

    public override JsonConverter CreateConverter(Type type, JsonSerializerOptions options) =>
        (JsonConverter)Activator.CreateInstance(typeof(OptionalConverter<>).MakeGenericType(type.GetGenericArguments()[0]))!;

    private sealed class OptionalConverter<T> : JsonConverter<Optional<T>>
    {
        public override Optional<T> Read(ref Utf8JsonReader reader, Type type, JsonSerializerOptions options) =>
            new(JsonSerializer.Deserialize<T>(ref reader, options), true);

        public override void Write(Utf8JsonWriter writer, Optional<T> value, JsonSerializerOptions options) =>
            JsonSerializer.Serialize(writer, value.Value, options);
    }
}
