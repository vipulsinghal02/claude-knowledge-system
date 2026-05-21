#!/usr/bin/env bash
# Install the claude-knowledge-system into ~/.claude/.
#
# Symlinks the canonical architecture doc and skill files so Claude Code can find them.
# Idempotent — safe to re-run after pulling updates from this repo.
#
# Run from a fresh clone:
#     git clone <this-repo-url> ~/repos/claude-knowledge-system
#     cd ~/repos/claude-knowledge-system && ./install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

mkdir -p "$SKILLS_DIR"

# Architecture doc → ~/.claude/knowledge-system-architecture.md
ARCH_LINK="$CLAUDE_DIR/knowledge-system-architecture.md"
ln -sfn "$REPO_DIR/knowledge-system-architecture.md" "$ARCH_LINK"
echo "  symlinked $ARCH_LINK -> $REPO_DIR/knowledge-system-architecture.md"

# Skills → ~/.claude/skills/<name>.md
for skill_path in "$REPO_DIR"/skills/*.md; do
    skill_name="$(basename "$skill_path")"
    target="$SKILLS_DIR/$skill_name"

    # If target exists and is a regular file (not a symlink), warn but don't overwrite.
    if [[ -f "$target" && ! -L "$target" ]]; then
        echo "  WARN: $target is a regular file, not a symlink. Move it aside before re-running, or it'll be left as-is."
        continue
    fi
    ln -sfn "$skill_path" "$target"
    echo "  symlinked $target -> $skill_path"
done

echo
echo "Install complete. Verify with:"
echo "    ls -la $CLAUDE_DIR/knowledge-system-architecture.md $SKILLS_DIR/"
