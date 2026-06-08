// Package ui provides colored terminal logging and run statistics,
// mirroring the log_* helpers in the original shell scripts.
package ui

import (
	"fmt"
	"io"
	"os"
)

// ANSI colors (matched to the shell scripts).
const (
	colRed    = "\033[0;31m"
	colGreen  = "\033[0;32m"
	colYellow = "\033[1;33m"
	colBlue   = "\033[0;34m"
	colReset  = "\033[0m"
)

// Stats tracks the counters the scripts maintain across a run.
type Stats struct {
	Updated int // files copied or (re)linked
	Skipped int // warnings / skipped items
	Errors  int // hard errors
}

// Logger writes status lines and accumulates Stats. It is not safe for
// concurrent use; the sync engine runs sequentially like the shell script.
type Logger struct {
	Out     io.Writer
	Err     io.Writer
	Verbose bool
	Color   bool
	Stats   Stats
}

// New returns a Logger writing to stdout/stderr. Color is enabled when stdout
// is a terminal-like writer; callers may override.
func New(verbose bool) *Logger {
	return &Logger{
		Out:     os.Stdout,
		Err:     os.Stderr,
		Verbose: verbose,
		Color:   colorEnabled(),
	}
}

func colorEnabled() bool {
	if os.Getenv("NO_COLOR") != "" {
		return false
	}
	fi, err := os.Stdout.Stat()
	if err != nil {
		return false
	}
	return (fi.Mode() & os.ModeCharDevice) != 0
}

func (l *Logger) paint(color, s string) string {
	if !l.Color {
		return s
	}
	return color + s + colReset
}

// Info prints an informational line (ℹ, blue).
func (l *Logger) Info(format string, a ...any) {
	fmt.Fprintf(l.Out, "%s %s\n", l.paint(colBlue, "ℹ"), fmt.Sprintf(format, a...))
}

// Success prints a success line (✓, green).
func (l *Logger) Success(format string, a ...any) {
	fmt.Fprintf(l.Out, "%s %s\n", l.paint(colGreen, "✓"), fmt.Sprintf(format, a...))
}

// Warn prints a warning line (⚠, yellow) and increments the skipped counter,
// matching log_warn in the shell scripts.
func (l *Logger) Warn(format string, a ...any) {
	fmt.Fprintf(l.Out, "%s %s\n", l.paint(colYellow, "⚠"), fmt.Sprintf(format, a...))
	l.Stats.Skipped++
}

// Error prints an error line (✗, red) to stderr and increments the error
// counter, matching log_error.
func (l *Logger) Error(format string, a ...any) {
	fmt.Fprintf(l.Err, "%s %s\n", l.paint(colRed, "✗"), fmt.Sprintf(format, a...))
	l.Stats.Errors++
}

// Verbosef prints a debug line only when verbose mode is on.
func (l *Logger) Verbosef(format string, a ...any) {
	if l.Verbose {
		fmt.Fprintf(l.Out, "  [DEBUG] %s\n", fmt.Sprintf(format, a...))
	}
}

// Plain prints a raw line with no marker (for summaries / blank lines).
func (l *Logger) Plain(format string, a ...any) {
	fmt.Fprintf(l.Out, "%s\n", fmt.Sprintf(format, a...))
}
