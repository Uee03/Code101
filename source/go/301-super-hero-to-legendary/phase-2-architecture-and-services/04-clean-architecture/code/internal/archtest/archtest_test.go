package archtest

import (
	"go/parser"
	"go/token"
	"path/filepath"
	"strings"
	"testing"
)

// rules lists, for each package directory, import paths it must never use.
// A rule is a substring match on the import path.
var rules = []struct {
	dir       string
	forbidden []string
}{
	{"../domain", []string{"/internal/", "net/http", "database/sql", "encoding/json"}},
	{"../app", []string{"/adapters/", "net/http", "database/sql", "encoding/json"}},
	{"../adapters/memory", []string{"/adapters/httpapi", "/internal/app", "net/http"}},
	{"../adapters/httpapi", []string{"/adapters/memory", "/adapters/idgen"}},
}

func TestDependencyRules(t *testing.T) {
	fset := token.NewFileSet()
	for _, rule := range rules {
		files, err := filepath.Glob(filepath.Join(rule.dir, "*.go"))
		if err != nil || len(files) == 0 {
			t.Fatalf("%s: no Go files found (err = %v)", rule.dir, err)
		}
		for _, name := range files {
			if strings.HasSuffix(name, "_test.go") {
				continue
			}
			f, err := parser.ParseFile(fset, name, nil, parser.ImportsOnly)
			if err != nil {
				t.Fatal(err)
			}
			for _, imp := range f.Imports {
				path := strings.Trim(imp.Path.Value, `"`)
				for _, bad := range rule.forbidden {
					if strings.Contains(path, bad) {
						t.Errorf("%s imports %q, which breaks the rule against %q", name, path, bad)
					}
				}
			}
		}
	}
}
