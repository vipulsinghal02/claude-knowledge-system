---
name: minechat
description: Retroactively mine a prior chat (this session's context, a .jsonl transcript, or a pasted log) for knowledge worth persisting — propose updates to CLAUDE.md, the project's knowledge/ directory, auto-memory, and slash skills. Conservative, iterative, never guesses. Works in any repo — resolves all paths from CLAUDE.md and pwd at runtime.
---

# /minechat

Scan a chat transcript and propose additions / refinements to the four persistence layers. Built for iterative back-fill: assume many chats will be mined over time, so each pass should be small, surgical, and explicitly mark gaps rather than guess.

## Resolve paths for the current repo

This skill is shared across all of your repos — resolve the per-repo paths first, then refer to them as variables.

1. **`KNOWLEDGE_DIR`** — read CLAUDE.md at the project root; find the path ending in `knowledge/` under the "Knowledge system" section. Fallback: `find . -path '*/knowledge/index.md' -not -path '*/.git/*' -not -path '*/.venv/*' 2>/dev/null | head -5`. If still ambiguous, ask.
2. **`KNOWLEDGE_INDEX`** = `$KNOWLEDGE_DIR/index.md`
3. **`MEMORY_DIR`** = `~/.claude/projects/$(pwd | tr '/_.' '-')/memory/` — this is how Claude Code encodes the per-project memory path: every `/`, `_`, and `.` in the absolute pwd becomes `-`.
4. **`CHANGELOG`** = `$(dirname $KNOWLEDGE_DIR)/changelog.md` — sibling of knowledge/. If this file doesn't exist yet, create it (see step 1) — every repo using this system has a changelog.

Never paste a hardcoded `terray_notebooks/…` or `claude_tutorials/…` or specific encoded memory path. Always use the resolved variables.

## Source of truth (read these FIRST, before scanning anything)

1. `$CHANGELOG` — the most-recent-first activity log. Read at least the **top 50 rows**. This is your fastest signal for "what's already been mined / added / edited recently." If the file doesn't exist, create it now with the standard header (see step 1 below for the format), then continue.
2. `CLAUDE.md` at the project root — current every-session conventions.
3. `$KNOWLEDGE_INDEX` — what's already in the situational knowledge base.
4. `$MEMORY_DIR/MEMORY.md` and the memory files it links to — user-specific preferences, references, project state.
5. `~/.claude/skills/` — existing slash skills (don't propose a skill that duplicates one of these).

Without this orientation step, you will propose duplicates or contradict existing entries. The changelog read in particular is the cheapest way to catch "this was mined two days ago, no need to re-mine."

**Standard changelog header** (use this verbatim when creating one):
```markdown
# Activity log

Most-recent-first. Each row is one file written or edited via a skill (`/learnthis`, `/logsession`, `/minechat`). Read this when you forget what you were working on, or when a skill needs to know what's already been added.

| Date | Action | Path | Description |
|---|---|---|---|
```

## Identify the transcript source

Ask the user (in one batch) if not already clear:
- Are we mining **this session's context**? (User resumed an old chat.)
- Are we mining a **transcript file**? (Path to a `.jsonl` in `~/.claude/projects/...` or a pasted markdown log.) — if so, get the path.

## Mining rules

1. **Conservative bias.** It is better to capture three high-quality items per chat than to dump twenty mediocre ones. Future chats will fill in what you skip.
2. **Never guess.** If a fact isn't explicitly stated or unambiguous from code the user wrote/edited, either ask once (batched at the end) or write the entry with `**TBD:** <what's uncertain>` and leave it for a future chat to resolve.
3. **Nothing is permanent.** Treat all existing entries as drafts. If this chat contradicts or refines an existing entry, propose an **update** to that entry, not a new one. Cite the existing entry by path so the user can compare.
4. **Skip the obvious.** Don't capture: routine code edits, file paths derivable from the repo, things already in CLAUDE.md, debugging recipes (the fix is in the code), in-progress task state.
5. **Capture the why, not the what.** Especially for feedback/project memories — without the "why," future-you can't judge when the rule still applies.

## Routing — which layer does each insight belong to?

Apply this in order; first match wins:

| Layer | Trigger | Format |
|---|---|---|
| `CLAUDE.md` | Convention or constraint that should shape **every** session in this repo | One short paragraph or bullet; add to existing section if related |
| `~/.claude/skills/` | A reusable multi-step workflow the user wants to invoke by name | New skill file, modeled on existing skills |
| `$KNOWLEDGE_DIR/<subproject>/` | Situational pattern, gotcha, or worked example useful only when working on a specific area | Per `/learnthis` template; add line to `$KNOWLEDGE_INDEX` |
| `$MEMORY_DIR` | User-specific preference, role, ongoing project state, or external reference | Per auto-memory frontmatter convention; update `$MEMORY_DIR/MEMORY.md` index |

Borderline cases: prefer the **narrower** layer. Knowledge > CLAUDE.md when in doubt (CLAUDE.md loads every session, so every line there has a cost).

## Steps

1. **Orient.** Read the four source-of-truth files above. Acknowledge to the user what's already there: "I see the existing memory covers X, Y. Knowledge index has Z. CLAUDE.md current sections are …". One short paragraph.

2. **Get the transcript.** Confirm source (this session vs file vs paste). If a path, read it.

3. **Extract candidates.** Walk the transcript and list candidate insights. For each, note:
   - One-line summary
   - Proposed target layer + file
   - Whether it's a **new entry** or a **refinement** of an existing entry (cite the existing entry by path)
   - Any blanks / TBDs

4. **Present the batch to the user.** Show all candidates at once as a numbered list. Ask: "Which of these should I save, skip, or revise? Anything I missed?" Do NOT write anything yet.

5. **Ask follow-ups in one batch.** For any TBDs that would meaningfully change the entry, ask in a single `AskUserQuestion` call. If the answer isn't critical, leave the TBD in the entry and move on — future chats will fill it.

6. **Apply approved entries.** For each approved item:
   - **New file:** write it; update the index (`$MEMORY_DIR/MEMORY.md` for memory, `$KNOWLEDGE_INDEX` for knowledge).
   - **Refinement:** edit the existing file in place. Preserve unchanged sections. Add a brief inline note where you altered an existing claim, e.g. `(updated YYYY-MM-DD: was X, refined to Y because Z)` — but only when the prior claim was misleading, not for routine additions.
   - **Skill:** write to `~/.claude/skills/<name>.md` modeled on existing skills. Skills are global, not per-repo — if the skill's logic is repo-specific, generalize it with the same path-resolution pattern this skill uses.
   - **CLAUDE.md:** edit the relevant section; don't append a dated dump.
   - **Changelog:** for every file written or edited in this pass, append a row to `$CHANGELOG` immediately after the header divider (so most-recent-first stays correct): `| YYYY-MM-DD | CREATED or EDITED | path/relative/to/$(dirname $KNOWLEDGE_DIR) | ~5-word description |`. Description can be 10–15 words if needed; keep it scannable. The changelog is mandatory in every repo — if it didn't exist at the start, you already created it in step 1.

7. **Report.** Short summary: "Added: …. Refined: …. Still TBD: …." Name the TBDs explicitly so the user (or a future chat) can knock them down.

## What this skill does NOT do

- Does not summarize the chat for the user (that's `/logsession`).
- Does not capture one-off insights mid-conversation (that's `/learnthis`).
- Does not write CLAUDE.md / memory / knowledge entries autonomously without per-item approval.
- Does not delete or rewrite existing entries beyond targeted refinements — if an entry seems fully obsolete, flag it for the user and let them decide.

## Anti-patterns to avoid

- **Guessing to fill a gap.** If user said "we use the X table" and never specified the fully-qualified name, write `<schema>.<X>` with a TBD note — do NOT invent `poc.public.X`.
- **Re-capturing things already in the source-of-truth files.** Step 1 exists to prevent this.
- **Mass-add.** If you have >8 candidates from one chat, you're probably mining noise. Prioritize the top 3-5 and tell the user the rest were judged too thin.
- **Inventing structure.** Use existing skill/memory/knowledge templates verbatim. Don't introduce new schemas.
- **Hardcoding paths from one repo into a skill.** This skill is global. Always resolve paths from CLAUDE.md + pwd; never paste `terray_notebooks/…` or any other repo-specific prefix.
