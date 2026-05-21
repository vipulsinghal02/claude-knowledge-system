---
name: learnthis
description: Save a non-obvious insight from the current conversation as a knowledge entry in the current project's knowledge/ directory, and index it. Works in any repo — resolves paths from CLAUDE.md at runtime. Reads the project changelog first to avoid duplicating recent work.
---

# /learnthis

Save an insight from the current conversation to the project knowledge base.

## Resolve paths for the current repo

This skill works in any repo. Before doing anything else, locate the project's knowledge directory:

1. **Read CLAUDE.md at the project root.** Find a path ending in `knowledge/` (or similar marker) under the "Knowledge system" section. That's `KNOWLEDGE_DIR`. Examples seen in practice: `claude_tutorials/knowledge/`, `terray_notebooks/docs_vs/knowledge/`.
2. **Fallback discovery if step 1 yields nothing:** run
   ```
   find . -path '*/knowledge/index.md' -not -path '*/.git/*' -not -path '*/.venv/*' 2>/dev/null | head -5
   ```
   Pick the unique match. If zero or multiple matches, ask the user.
3. **Derive sibling paths from `KNOWLEDGE_DIR`:**
   - `KNOWLEDGE_INDEX = $KNOWLEDGE_DIR/index.md`
   - `CHANGELOG = $(dirname $KNOWLEDGE_DIR)/changelog.md` — sibling of knowledge/, inside the personal parent dir.

Treat the resolved paths as variables in the steps below. Never paste a hardcoded `terray_notebooks/…` or `claude_tutorials/…` path — always use what you resolved.

## Steps

1. **Read the changelog first.** Open `$CHANGELOG` and read at least the top 50 rows (most-recent-first). This tells you what's been recently added or edited so you don't propose a duplicate or miss the chance to refine an existing entry. If `$CHANGELOG` does not exist, create it with this header (do not skip — every repo using this system has a changelog):
   ```markdown
   # Activity log

   Most-recent-first. Each row is one file written or edited via a skill (`/learnthis`, `/logsession`, `/minechat`). Read this when you forget what you were working on, or when a skill needs to know what's already been added.

   | Date | Action | Path | Description |
   |---|---|---|---|
   ```
   Then continue.

2. **Extract the insight.** Identify the single most useful, non-obvious thing learned in this conversation. Skip if all that happened was a routine edit, a lookup, or something already obvious from reading the code. If the insight is clearly a refinement of something you saw in the changelog or knowledge index, propose an **update** to that file rather than a new entry.

3. **Classify it.** Decide:
   - Is this cross-cutting (applies across subprojects) or specific to one subproject?
   - Which subproject directory under `$KNOWLEDGE_DIR` does it belong in? (`cross_cutting/` or `[subproject]/`)
   - Should it be appended to an existing entry (preferred when topic is related) or written to a new file?

4. **Draft the entry** using this template:
   ```markdown
   ## [Short title]

   **Date:** YYYY-MM-DD
   **Subproject:** [name or "cross-cutting"]
   **Tags:** [2-4 keywords]

   [2-4 sentence description of what was learned and why it matters.]

   **Key detail:** [the single most important specific fact — a command, a constraint, a gotcha]

   **When to apply:** [concrete trigger — "when doing X", "if you see Y"]
   ```

5. **Show the draft to the user** along with the proposed filename and ask: "Save this to `$KNOWLEDGE_DIR/[path].md`? Say yes, or tell me what to change." (Substitute the resolved path.)

6. **On confirmation:**
   - Write or append to the chosen file under `$KNOWLEDGE_DIR/`.
   - Add a one-line entry to `$KNOWLEDGE_INDEX` in the form: `- [YYYY-MM-DD] [cross] **Title** — one-line hook → cross_cutting/file.md` (omit `[cross]` for subproject-specific).
   - Append a row to `$CHANGELOG` immediately after the header divider (so most-recent-first stays correct): `| YYYY-MM-DD | CREATED or EDITED | knowledge/[path] | ~5-word description |`. Description can be a bit longer (10–15 words) if needed; keep it short enough to scan at a glance.
   - If the insight is a project-level constraint that should shape **every** session (not just specific tasks), also add a concise rule + pointer to the **Conventions** section of `CLAUDE.md`, and add a second changelog row for the CLAUDE.md edit.

7. **Report:** `Saved to $KNOWLEDGE_DIR/[path], indexed, and logged in $CHANGELOG.`

## Notes
- Prefer appending to an existing file over creating a new one when the topic is related.
- Never save trivial implementation details, file paths, or things obvious from reading the code — those go stale and add noise.
- If the user prompts you to run this skill but no real insight exists, say so and skip rather than fabricating one.
- The changelog read in step 1 is also useful for "is this a refinement?" judgment — if the top rows show recent work in the same area, prefer refining over re-adding.
