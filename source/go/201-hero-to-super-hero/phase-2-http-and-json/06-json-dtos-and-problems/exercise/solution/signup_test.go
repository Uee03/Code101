package signup

import (
	"reflect"
	"strings"
	"testing"
)

func TestValidate(t *testing.T) {
	tests := []struct {
		name string
		req  Request
		want []FieldError
	}{
		{"valid", Request{Email: "ada@example.com", Age: 36}, nil},
		{"missing email", Request{Age: 36}, []FieldError{{"email", "is required"}}},
		{"blank email", Request{Email: "   ", Age: 36}, []FieldError{{"email", "is required"}}},
		{"email without at", Request{Email: "ada.example.com", Age: 36}, []FieldError{{"email", "must contain @"}}},
		{"too young", Request{Email: "ada@example.com", Age: 12}, []FieldError{{"age", "must be between 13 and 120"}}},
		{"too old", Request{Email: "ada@example.com", Age: 121}, []FieldError{{"age", "must be between 13 and 120"}}},
		{"two problems keep their order", Request{}, []FieldError{{"email", "is required"}, {"age", "must be between 13 and 120"}}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := tc.req.Validate(); !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got %v, want %v", got, tc.want)
			}
		})
	}
}

func TestDecode(t *testing.T) {
	tests := []struct {
		name    string
		body    string
		want    Request
		wantErr bool
	}{
		{"valid", `{"email":"ada@example.com","age":36}`, Request{Email: "ada@example.com", Age: 36}, false},
		{"empty", ``, Request{}, true},
		{"unknown field", `{"email":"a@b.c","age":20,"admin":true}`, Request{}, true},
		{"wrong type", `{"email":"a@b.c","age":"twenty"}`, Request{}, true},
		{"trailing data", `{"email":"a@b.c","age":20} {}`, Request{}, true},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := Decode(strings.NewReader(tc.body))
			if (err != nil) != tc.wantErr {
				t.Fatalf("error = %v, want error: %v", err, tc.wantErr)
			}
			if got != tc.want {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
		})
	}
}
