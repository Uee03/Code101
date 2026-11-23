TYPES = {
    "object": lambda v: isinstance(v, dict),
    "array": lambda v: isinstance(v, list),
    "string": lambda v: isinstance(v, str),
    "boolean": lambda v: isinstance(v, bool),
    "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
    "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
    "null": lambda v: v is None,
}


def validate(value, schema, path="$"):
    expected = schema.get("type")
    if expected:
        checker = TYPES.get(expected)
        if checker is None:
            raise ValueError(f"unsupported schema type {expected!r}")
        if not checker(value):
            return [f"{path}: expected {expected}, got {type(value).__name__}"]
    errors = []
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: {value!r} is not one of {schema['enum']}")
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            errors.append(f"{path}: shorter than {schema['minLength']} characters")
        if len(value) > schema.get("maxLength", len(value)):
            errors.append(f"{path}: longer than {schema['maxLength']} characters")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            errors.append(f"{path}: {value} is below the minimum {schema['minimum']}")
        if "maximum" in schema and value > schema["maximum"]:
            errors.append(f"{path}: {value} is above the maximum {schema['maximum']}")
    if isinstance(value, dict):
        errors += validate_object(value, schema, path)
    if isinstance(value, list):
        errors += validate_array(value, schema, path)
    return errors


def validate_object(value, schema, path):
    errors = []
    properties = schema.get("properties", {})
    for name in schema.get("required", []):
        if name not in value:
            errors.append(f"{path}: missing required property {name!r}")
    if schema.get("additionalProperties") is False:
        for name in value:
            if name not in properties:
                errors.append(f"{path}: unexpected property {name!r}")
    for name, sub_schema in properties.items():
        if name in value:
            errors += validate(value[name], sub_schema, f"{path}.{name}")
    return errors


def validate_array(value, schema, path):
    errors = []
    if len(value) < schema.get("minItems", 0):
        errors.append(f"{path}: fewer than {schema['minItems']} items")
    if len(value) > schema.get("maxItems", len(value)):
        errors.append(f"{path}: more than {schema['maxItems']} items")
    if "items" in schema:
        for index, item in enumerate(value):
            errors += validate(item, schema["items"], f"{path}[{index}]")
    return errors
