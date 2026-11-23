package version

import (
	"fmt"
	"runtime"
	"runtime/debug"
)

// Version and Commit are replaced at build time:
//
//	go build -ldflags "-X example.com/code101/go301/l09/internal/version.Version=1.2.3"
//
// The defaults mark a build that did not come from the release pipeline.
var (
	Version = "dev"
	Commit  = "none"
)

// Info is what /version returns.
type Info struct {
	Version     string `json:"version"`
	Commit      string `json:"commit"`
	GoVersion   string `json:"go_version"`
	VCSRevision string `json:"vcs_revision,omitempty"`
	VCSModified string `json:"vcs_modified,omitempty"`
}

// String is the one-line text printed by the -version flag.
func String() string {
	return fmt.Sprintf("app %s (commit %s)", Version, Commit)
}

// Get combines the values set by the release pipeline with what the Go
// toolchain itself recorded in the binary (version control data is present
// when the binary was built with go build inside a git checkout).
func Get() Info {
	info := Info{Version: Version, Commit: Commit, GoVersion: runtime.Version()}
	if bi, ok := debug.ReadBuildInfo(); ok {
		for _, s := range bi.Settings {
			switch s.Key {
			case "vcs.revision":
				info.VCSRevision = s.Value
			case "vcs.modified":
				info.VCSModified = s.Value
			}
		}
	}
	return info
}
