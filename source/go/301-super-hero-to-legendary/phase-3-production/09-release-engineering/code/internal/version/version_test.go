package version

import "testing"

func TestStringUsesBuildTimeValues(t *testing.T) {
	oldVersion, oldCommit := Version, Commit
	t.Cleanup(func() { Version, Commit = oldVersion, oldCommit })

	Version, Commit = "1.2.3", "abc1234"
	if got, want := String(), "app 1.2.3 (commit abc1234)"; got != want {
		t.Fatalf("String() = %q, want %q", got, want)
	}
}

func TestGetReportsTheGoVersion(t *testing.T) {
	if Get().GoVersion == "" {
		t.Fatal("GoVersion must not be empty")
	}
}
