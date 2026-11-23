package httpapi

import "encoding/json"

// optional tells three cases apart that a plain pointer cannot: the JSON field is absent, it is null,
// or it has a value. JSON Merge Patch (RFC 7396) needs this: absent means "leave it", null means "clear it".
type optional[T any] struct {
	Set   bool // the field was present in the body
	Value *T   // nil when the field was null
}

// UnmarshalJSON runs only for fields that are present, so Set is true whenever it runs.
func (o *optional[T]) UnmarshalJSON(data []byte) error {
	o.Set = true
	if string(data) == "null" {
		o.Value = nil
		return nil
	}
	var value T
	if err := json.Unmarshal(data, &value); err != nil {
		return err
	}
	o.Value = &value
	return nil
}
