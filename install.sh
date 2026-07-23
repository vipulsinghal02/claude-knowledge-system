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
BACKUP_DIR="$CLAUDE_DIR/skills-backup-$(date +%Y%m%d%H%M%S)"

mkdir -p "$SKILLS_DIR"

STALE_FOUND=0

# Architecture doc → ~/.claude/knowledge-system-architecture.md
ARCH_LINK="$CLAUDE_DIR/knowledge-system-architecture.md"
ln -sfn "$REPO_DIR/knowledge-system-architecture.md" "$ARCH_LINK"
echo "  symlinked $ARCH_LINK -> $REPO_DIR/knowledge-system-architecture.md"

# Skills → ~/.claude/skills/<name>/SKILL.md
# Claude Code discovers a personal skill only when it lives in its own directory
# as SKILL.md. A flat ~/.claude/skills/<name>.md file is silently ignored.
for skill_path in "$REPO_DIR"/skills/*.md; do
    skill_file="$(basename "$skill_path")"       # e.g. learnthis.md
    skill_name="${skill_file%.md}"               # e.g. learnthis

    # Migrate any old flat install: ~/.claude/skills/<name>.md
    legacy="$SKILLS_DIR/$skill_file"
    if [[ -L "$legacy" ]]; then
        rm "$legacy"
        echo "  removed legacy flat symlink $legacy"
    elif [[ -f "$legacy" ]]; then
        echo "  WARN: $legacy is a regular file, not a symlink. Move it aside; leaving as-is."
    fi

    skill_dir="$SKILLS_DIR/$skill_name"
    target="$skill_dir/SKILL.md"

    # If target exists and is a regular file (not a symlink), it's a stale copy
    # blocking discovery of the real skill. Back it up and replace it — don't
    # leave it in place silently, that's how skills silently vanish.
    if [[ -f "$target" && ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$skill_name"
        echo "  !! $target was a plain file (not a symlink) — moved to $BACKUP_DIR/$skill_name and replaced with a symlink"
        STALE_FOUND=1
    fi
    mkdir -p "$skill_dir"
    ln -sfn "$skill_path" "$target"
    echo "  symlinked $target -> $skill_path"
done

# Verify every skill has valid frontmatter — a skill file without a leading
# `---` YAML block is invisible to Claude Code's skill discovery, even when
# correctly symlinked.
echo
echo "Verifying skill frontmatter..."
FRONTMATTER_MISSING=0
for skill_path in "$REPO_DIR"/skills/*.md; do
    skill_name="$(basename "$skill_path")"
    if [[ "$(head -1 "$skill_path")" != "---" ]]; then
        echo "  !! $skill_name has no YAML frontmatter — it will NOT show up as a slash command"
        FRONTMATTER_MISSING=1
    fi
done
if [[ "$FRONTMATTER_MISSING" -eq 0 ]]; then
    echo "  ok: all skills have frontmatter"
fi

echo
echo "Install complete."
if [[ "$STALE_FOUND" -eq 1 ]]; then
    echo
    echo "NOTE: one or more stale plain files were found in $SKILLS_DIR and replaced."
    echo "      Backups saved to $BACKUP_DIR (safe to delete once you confirm nothing was lost)."
fi
echo
echo "Verify with:"
echo "    ls -la $CLAUDE_DIR/knowledge-system-architecture.md $SKILLS_DIR/"
echo
echo "IMPORTANT: Claude Code reads the skills list once at session start."
echo "If you had a Claude Code session already open, restart it (or open a new"
echo "one) before expecting /learnthis, /logsession, /minechat, or"
echo "/setup-knowledge-system to appear."
