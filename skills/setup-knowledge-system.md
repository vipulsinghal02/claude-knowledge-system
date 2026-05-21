---
name: setup-knowledge-system
description: Bootstrap the four-layer knowledge system (CLAUDE.md + knowledge/ + auto-memory + changelog) into the current repo. Use this in a fresh repo to add framework scaffolding end-to-end, or to bring a partially-set-up repo to parity. Resolves all paths from the current working directory.
---

# /setup-knowledge-system

End-to-end bootstrap of the knowledge system into the **current repo**. Use this once per repo. Idempotent for the most part: if some pieces already exist, the skill detects that and only fills the gaps.

## Read first (mandatory)

Before executing any step below, read the canonical architecture doc at `~/.claude/knowledge-system-architecture.md`. Pay attention to:
- "Pre-bootstrap diagnostic"
- "Variant: externally-managed repos"
- "Layer 4 — Changelog" (especially the per-file rule)
- "Persistent TODOs"

If `~/.claude/knowledge-system-architecture.md` is missing or broken, the user has not run `install.sh` from the claude-knowledge-system scaffolding repo on this machine — stop and tell them to do that first.

## Step 1 — Pre-bootstrap diagnostic

Run this inventory in the current repo (substitute paths and report briefly):

```bash
# What's tracked vs personal?
git ls-files --error-unmatch CLAUDE.md 2>&1     # is CLAUDE.md committed?
ls CLAUDE.md 2>&1                                # does an untracked CLAUDE.md exist?
cat .git/info/exclude                            # what's already locally excluded?
ls docs/ docs_vs/ claude_tutorials/ personal_notes/ doc/ wiki/ 2>/dev/null

# Does prior Claude state exist?
ls ~/.claude/projects/$(pwd | tr '/_.' '-')/memory/ 2>&1
ls ~/.claude/skills/ 2>&1

# Existing knowledge dir?
find . -path '*/knowledge/index.md' -not -path '*/.git/*' -not -path '*/.venv/*' 2>/dev/null | head -5
```

Summarize what's there in 3–5 lines. **Stop before doing anything else and present this summary to the user.**

## Step 2 — Classify the repo

Determine whether this repo is **externally-managed** (team owns root + `.gitignore`) or **you-own-the-repo**. Heuristics:
- `CODEOWNERS` exists and lists names other than the user → externally-managed
- A team-style `.gitignore` already exists, curated for shared concerns → externally-managed
- The user is the sole contributor / it's a personal project → you-own
- When in doubt: externally-managed (safer default).

Report the classification to the user as part of the summary in Step 1.

## Step 3 — Ask the 4 setup questions

Use one `AskUserQuestion` call with these 4 questions:

1. **Personal-parent dir name** (only if externally-managed) — options: `claude_tutorials/`, `docs_vs/`, `personal_notes/`, or other. Recommend defaulting to whatever already exists; otherwise `personal_notes/` is descriptive.
2. **Existing notes handling** — if you found personal docs in `docs/`, `claude_tutorials/`, dated logs, etc.: leave in place + index as `[Ref]` entries (default, lowest risk) / migrate selectively / defer.
3. **Existing CLAUDE.md handling** — if a CLAUDE.md exists: add framework sections only (preserve content verbatim — recommended default) / extract conventions into `knowledge/` entries with pointers / leave CLAUDE.md alone.
4. **Subprojects to seed** — based on what you saw under `docs/` or similar (numbered design docs often map to subprojects): pre-create subproject dirs with `.gitkeep`, or just `cross_cutting/` for now.

## Step 4 — If externally-managed, update `.git/info/exclude` FIRST

Before creating any personal files, append the personal scaffolding patterns to `.git/info/exclude` (never `.gitignore` — see arch doc for why):

```
# Personal Claude scaffolding (never commit — externally-managed repo)
CLAUDE.md
[personal-parent-dir]/
.claude/
```

Substitute `[personal-parent-dir]` with the name from question 1. Read the existing file first, append (don't overwrite).

## Step 5 — Create directory structure

```
mkdir -p [personal-parent-dir]/knowledge/cross_cutting
mkdir -p [personal-parent-dir]/knowledge/[subproject1]    # for each subproject from question 4
mkdir -p [personal-parent-dir]/knowledge/[subproject2]
touch [personal-parent-dir]/knowledge/cross_cutting/.gitkeep
touch [personal-parent-dir]/knowledge/[subproject1]/.gitkeep
touch [personal-parent-dir]/knowledge/[subproject2]/.gitkeep
```

## Step 6 — Bootstrap the changelog

Create `[personal-parent-dir]/changelog.md` with the standard header:

```markdown
# Activity log

Most-recent-first. Each row is one file written or edited via a skill (`/learnthis`, `/logsession`, `/minechat`) or by direct instruction. Read this when you forget what you were working on, or when a skill needs to know what's already been added.

| Date | Action | Path | Description |
|---|---|---|---|
```

You'll backfill rows for everything created in step 5–8 at the end (step 10).

## Step 7 — Write `knowledge/index.md`

Use this template, filling in `[Ref]` entries for every team doc you found in step 1 (under `docs/`, root-level `README.md`, `OVERVIEW.md`, etc.):

```markdown
# Project Knowledge Index

## How to use
- Run `/learnthis` after figuring something out to add an entry
- Reference this index when starting work in a subproject
- Entries tagged [cross] apply across subprojects
- Entries tagged [Ref] point to existing docs left in place rather than migrated

---

## Entries

### Cross-cutting

### [subproject1]

### [subproject2]

---

## References (existing docs left in place)

### Team docs in `docs/`
- [Ref] **[Title]** — docs/[file].md
...

### Top-level team docs
- [Ref] **README** — README.md
- [Ref] **[Other]** — [path]
...
```

## Step 8 — Write `knowledge/sessions.md`

```markdown
# Session Log

Most recent first. Use `/logsession` to append a new entry.

---

## YYYY-MM-DD
**Topics:** knowledge-system bootstrap
**Files:** CLAUDE.md, [personal-parent]/knowledge/, [personal-parent]/changelog.md, .git/info/exclude
**Summary:** Bootstrapped the four-layer knowledge system via `/setup-knowledge-system`.
```

## Step 9 — Write CLAUDE.md

This is the meat. If an existing CLAUDE.md was present and the user chose "preserve content" (Q3, default), keep all existing prose intact and add the framework sections around it. If nothing existed, use this full template:

```markdown
# Claude Instructions — [REPO_NAME]

## Project overview
[One-paragraph project overview. If a README/OVERVIEW.md exists, summarize from it. Mention: language, build system, what the repo does, any "externally-managed" warning.]

[For externally-managed:] **Personal scaffolding (this file, `[personal-parent]/`, `.claude/`) is local-only and excluded via `.git/info/exclude`** — never `git add` them.

See [README.md or OVERVIEW.md] for the full overview.

## Subprojects
| Directory | Description | Knowledge |
|---|---|---|
| [Subproject 1 location] | [Description] | `[personal-parent]/knowledge/[subproject1]/` |
| [Subproject 2 location] | [Description] | `[personal-parent]/knowledge/[subproject2]/` |
| (cross-cutting conventions) | Patterns, conventions, env setup | `[personal-parent]/knowledge/cross_cutting/` |

When starting work in a new subproject, remind the user: "Don't forget to add this subproject to the table in CLAUDE.md and create a `[personal-parent]/knowledge/[subproject]/` directory for it."

## Knowledge system
Persistent context lives in four layers:
1. **This file (CLAUDE.md)** — loaded every session. Subproject map, must-know rules, commands.
2. **`[personal-parent]/knowledge/`** — accumulated insights, decisions, and pointers to existing docs. Check `[personal-parent]/knowledge/index.md` at the start of any non-trivial task.
3. **Auto-memory** (`~/.claude/projects/[encoded-pwd]/memory/`) — personal preferences, behavioral corrections, validated approaches. Loaded automatically.
4. **`[personal-parent]/changelog.md`** — most-recent-first activity log of every CREATE/EDIT of a four-layer file. Skim it to remember what was recently worked on, or to avoid duplicating a recent addition.

**Changelog rule:** any time you touch a four-layer file (CLAUDE.md, anything under `[personal-parent]/knowledge/`, anything in the auto-memory dir, or any file under `~/.claude/skills/`), append a row to `[personal-parent]/changelog.md`: `| YYYY-MM-DD | CREATED or EDITED | path | ~5-word description |`. New rows go immediately after the table divider (most-recent-first). This applies whether the edit came from a skill or from a direct instruction — the rule is per file, not per event.

Full architecture in `~/.claude/knowledge-system-architecture.md` (canonical; symlinked from the claude-knowledge-system scaffolding repo).

After completing any non-trivial task, say:
"We just figured out [one-line summary]. Want to save this to the knowledge base? I'd add it to `[personal-parent]/knowledge/[path]` as: [draft entry]. Say yes to save, or tell me what to change."
Do NOT do this for: simple lookups, minor edits, or tasks where nothing generalizable was learned.

## Commands
- `/learnthis` — save an insight to `[personal-parent]/knowledge/`
- `/logsession` — append a session summary to `[personal-parent]/knowledge/sessions.md`
- `/minechat` — retroactively mine a chat for knowledge entries / memory updates
- `/setup-knowledge-system` — bootstrap this system into a new repo (this very skill)

## Communication style
- Be brief and to the point. The user prefers terse responses.

## Conventions — must-know rules

[If an existing CLAUDE.md had conventions, preserve them verbatim under this section. Otherwise leave it empty for now — conventions will accumulate as you work.]
```

Fill in placeholders. Substitute the encoded pwd in the memory path using `pwd | tr '/_.' '-'`.

## Step 10 — Backfill the changelog

Append one row per file you created/edited, most-recent-first (newest at top of the data rows):

```
| 2026-MM-DD | EDITED  | .git/info/exclude            | added CLAUDE.md, [personal-parent]/, .claude/ |
| 2026-MM-DD | CREATED | [personal-parent]/changelog.md | activity log bootstrap |
| 2026-MM-DD | CREATED | [personal-parent]/knowledge/index.md | knowledge index with [Ref] entries for team docs |
| 2026-MM-DD | CREATED | [personal-parent]/knowledge/sessions.md | session log seeded with bootstrap session |
| 2026-MM-DD | CREATED | [personal-parent]/knowledge/cross_cutting/.gitkeep | placeholder |
| 2026-MM-DD | CREATED | [personal-parent]/knowledge/[subproject1]/.gitkeep | placeholder |
| 2026-MM-DD | CREATED | [personal-parent]/knowledge/[subproject2]/.gitkeep | placeholder |
| 2026-MM-DD | EDITED  | CLAUDE.md                    | restructured with framework sections + changelog rule |
```

(Or `CREATED` for CLAUDE.md if none existed.)

## Step 11 — Verify and report

Run `git status --short` to confirm nothing personal is tracked. List what's now in place:

```
✓ .git/info/exclude updated
✓ [personal-parent]/knowledge/ created with subprojects: cross_cutting, [...]
✓ [personal-parent]/knowledge/index.md indexed N team docs as [Ref] entries
✓ [personal-parent]/changelog.md bootstrapped with N rows
✓ CLAUDE.md written (preserved existing X lines of env content) / (fresh from template)
✓ /learnthis, /logsession, /minechat, /setup-knowledge-system available

This repo is now at four-layer parity. Run /learnthis after your next non-trivial insight.
```

## Notes and edge cases

- **Idempotency:** if `[personal-parent]/knowledge/index.md` already exists, do not overwrite. Diff and ask the user what to do.
- **You-own-the-repo case:** skip the `.git/info/exclude` step; instead, the user should `git add` and commit the new files at the end. Mention this in the final report.
- **Skills already global:** never copy skill files into the repo. They live at `~/.claude/skills/` (symlinked from the claude-knowledge-system repo on this machine).
- **Memory directory:** do not auto-create memory files. Memory captures behavioral corrections that the user gives over time — there's nothing to seed during bootstrap unless the user explicitly asks.
- **`/setup-knowledge-system` reading the architecture doc:** this is mandatory. If you skip the read, you'll drift from the canonical design.
