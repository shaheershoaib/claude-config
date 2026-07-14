#!/usr/bin/env bash
# pre-compact-teaching-snapshot.sh
#
# Fires before Claude Code auto-compacts conversation context.
# Writes a timestamped compaction marker to each recently-active teaching system's
# `compaction-markers.md` file. The marker signals to a post-compaction agent that
# recent context may have been lost; Phase 0.1 of the system-explainer skill
# re-reads these markers at re-engagement.
#
# Writes go to a SEPARATE compaction-markers.md file (not learning-log.md) to
# eliminate any append-contention with the teaching-knowledge-base MCP's
# lock_domain tool.
#
# This hook intentionally does NOT use `set -e` — a hook failure should never
# block compaction. We always exit 0.
#
# IMPORTANT: the marker text below must match the buildCompactionMarker function
# in ~/.claude/mcp-servers/teaching-knowledge-base/index.js. If you change one,
# change both.
#
# Triggered by: PreCompact hook entry in ~/.claude/settings.json
# Consumed by: system-explainer skill Phase 0.1 re-engagement protocol

TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
HOOK_DIR="$HOME/.claude/hooks"
LOG_FILE="$HOOK_DIR/last-run.log"
FAILURE_LOG="$HOOK_DIR/pre-compact-failures.log"
REFERENCES_DIR="$HOME/.claude/skills/system-explainer/references"

# Consume any JSON input on stdin so we don't break the harness's pipe
cat > /dev/null 2>&1 || true

# Ensure hooks directory exists for log writes
mkdir -p "$HOOK_DIR" 2>/dev/null || true

# Log hook execution for verification
if ! echo "[$TIMESTAMP] pre-compact-teaching-snapshot.sh fired" >> "$LOG_FILE" 2>/dev/null; then
  : # silent — can't even log
fi

# Append marker to compaction-markers.md of each "recently active" teaching system.
# "Recently active" = compaction-markers.md OR learning-log.md modified in the
# last 14 days. (Using either signal lets us catch systems that haven't had a
# compaction marker yet but are actively being taught.)
if [ -d "$REFERENCES_DIR" ]; then
  for system_dir in "$REFERENCES_DIR"/*/; do
    learning_log="${system_dir}learning-log.md"
    markers_file="${system_dir}compaction-markers.md"

    # Only mark systems touched in the last 14 days
    recent=""
    if [ -f "$learning_log" ] && find "$learning_log" -mtime -14 -print 2>/dev/null | grep -q .; then
      recent=yes
    fi
    if [ -z "$recent" ] && [ -f "$markers_file" ] && find "$markers_file" -mtime -14 -print 2>/dev/null | grep -q .; then
      recent=yes
    fi

    if [ -n "$recent" ]; then
      # Initialize the markers file if it doesn't exist yet
      if [ ! -f "$markers_file" ]; then
        {
          echo "# Compaction Markers"
          echo ""
          echo "**Purpose:** Track auto-compaction events that fired during teaching sessions for this system. Each marker indicates a moment when context was compressed and may have lost detail. Phase 0.1 of the system-explainer skill checks this file at re-engagement."
          echo ""
          echo "**Written by:** \`~/.claude/hooks/pre-compact-teaching-snapshot.sh\` (auto) and the \`teaching-knowledge-base\` MCP's \`record_compaction_marker\` tool (manual)."
        } > "$markers_file" 2>/dev/null || {
          echo "[$TIMESTAMP] FAILED to initialize $markers_file" >> "$FAILURE_LOG" 2>/dev/null
          continue
        }
      fi

      # Append the marker. Must match the buildCompactionMarker template in the MCP.
      if ! {
        echo ""
        echo "---"
        echo ""
        echo "## Compaction marker — $TIMESTAMP"
        echo ""
        echo "Auto-compaction fired during an active session. Recent decisions, corrections, or in-flight reasoning may not be preserved in the post-compaction conversation summary."
        echo ""
        echo "**For the agent re-engaging:** treat this as a signal to re-read this learning log, gotchas.md, and context-index.md in full before responding. Do not produce content from compacted memory alone. If unsure about recent context, ask the user to confirm where you left off."
      } >> "$markers_file" 2>/dev/null; then
        echo "[$TIMESTAMP] FAILED to append marker to $markers_file" >> "$FAILURE_LOG" 2>/dev/null
      fi
    fi
  done
fi

# Always exit 0 — hook failure must not block compaction
exit 0
