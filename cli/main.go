// Command acr is the nitays-agent-toolkit CLI: a single static binary that replaces
// the install / sync / link / update shell scripts. Run `acr --help` for usage.
package main

import "github.com/nitayk/nitays-agent-toolkit/cli/cmd"

func main() {
	cmd.Execute()
}
