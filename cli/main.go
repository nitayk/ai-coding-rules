// Command acr is the ai-coding-rules CLI: a single static binary that replaces
// the install / sync / link / update shell scripts. Run `acr --help` for usage.
package main

import "github.com/nitayk/ai-coding-rules/cli/cmd"

func main() {
	cmd.Execute()
}
