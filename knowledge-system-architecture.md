## Knowledge & Tracking System Architecture

**Date:** 2026-05-19
**Subproject:** cross-cutting
**Tags:** knowledge-system, setup, architecture, persistence

This document describes the full knowledge and session-tracking system used in this workspace. It is written so that it can be handed to Claude at the start of a new project to reproduce the same setup from scratch.

---

## The problem this solves

Claude has no memory across sessions by default. Without a system, every session starts cold — prior decisions, package setup, gotchas, and rationale are all lost. This system creates four layers of persistence so that context accumulates over time rather than evaporating.

---

## Four layers of persistence

### Layer 1 — CLAUDE.md (per-project, in-repo)

**What it is:** A markdown file at the project root, auto-loaded by Claude Code at the start of every session in that directory.

**What it contains:**
- Project overview and subproject table (directory → description)
- Pointer to the `knowledge/` system and how to use it
- List of available slash commands (`/learnthis`, `/logsession`)
- Proactive learning instruction (tells Claude to prompt the user after non-trivial tasks)
- Style and conventions (grows over time)

**Key instruction to include verbatim:**
```
Always check `knowledge/index.md` at the start of any non-trivial task.

After completing any non-trivial task, say:
"We just figured out [one-line summary]. Want to save this to the knowledge base?
I'd add it to `knowledge/[path]` as: [draft entry]. Say yes to save, or tell me what to change."

Do NOT do this for: simple lookups, minor edits, or tasks where nothing generalizable was learned.
```

**When to update it:** When a new subproject is added (add row to table, add `knowledge/[subproject]/` path). When a new convention is established.

**Reminder instruction to include:**
```
When starting a new subproject, remind the user:
"Don't forget to add this subproject to the table in CLAUDE.md
and create a knowledge/[subproject]/ directory for it."
```

---

### Layer 2 — knowledge/ directory (per-project, in-repo)

**What it is:** A directory of markdown files in the project root, committed to git, holding accumulated insights, decisions, and patterns.

**Directory structure:**
```
knowledge/
  index.md                    ← master index, checked at session start
  sessions.md                 ← chronological session journal, most recent first
  cross_cutting/              ← knowledge that applies across subprojects
    python-packaging-pytorch.md
    knowledge-system-architecture.md   ← this file
  [subproject-name]/          ← one directory per subproject
    [slug].md
```

**`knowledge/index.md` format:**
```markdown
# Project Knowledge Index

## How to use
- Run `/learnthis` after figuring something out to add an entry
- Reference this index when starting work in a subproject
- Entries tagged [cross] apply across subprojects

---

## Entries

- [YYYY-MM-DD] [cross] **Title** — one-line hook → knowledge/path/to/file.md
- [YYYY-MM-DD] **Title** — one-line hook (no [cross] tag = subproject-specific)
```

**`knowledge/sessions.md` format:**
```markdown
# Session Log

Most recent first. Use `/logsession` to append a new entry.

---

## YYYY-MM-DD
**Topics:** topic1, topic2, topic3
**Files:** path/to/file1, path/to/file2
**Summary:** One sentence describing what the session accomplished.
```

**Individual knowledge entry format:**
```markdown
## [Short title]

**Date:** YYYY-MM-DD
**Subproject:** [name or "cross-cutting"]
**Tags:** [2-4 keywords]

[2-4 sentence description of what was learned and why it matters.]

**Key detail:** [the single most important specific fact — a command, a constraint, a gotcha]

**When to apply:** [concrete trigger — "when doing X", "if you see Y"]
```

---

### Layer 3 — Auto-memory (per-user, global, not in-repo)

**What it is:** A set of markdown files stored at `~/.claude/projects/[encoded-project-path]/memory/`, loaded automatically by Claude Code across all sessions for this project path. Not committed to git — personal to the user.

**What it contains:**
- `MEMORY.md` — index file, 1 line per memory, under 200 lines total (truncated beyond that)
- Individual `.md` files for each memory, with frontmatter

**Memory types:**
| Type | Contains |
|---|---|
| `user` | User's role, expertise level, preferences |
| `feedback` | Corrections and validated approaches ("don't do X", "yes exactly") |
| `project` | Ongoing decisions, deadlines, active initiatives |
| `reference` | Pointers to external systems (Linear boards, dashboards) |

**Memory file frontmatter format:**
```markdown
---
name: short-kebab-slug
description: one-line summary used to decide relevance in future sessions
metadata:
  type: user | feedback | project | reference
---

Body of memory.

**Why:** reason this matters
**How to apply:** when/where this kicks in
```

**`MEMORY.md` format:**
```markdown
# Memory Index

- [Title](filename.md) — one-line hook (under 150 chars)
```

**Rules for what to save in memory:**
- Save: user preferences, behavioral corrections, validated non-obvious approaches
- Do not save: code patterns, file paths, git history — those are derivable from the repo

---

### Layer 4 — Changelog (per-project, in-repo activity log)

**What it is:** A single markdown file with a most-recent-first table, recording every CREATE or EDIT of a four-layer file. Lives as a sibling of `knowledge/` (so for the externally-managed variant: `[personal-parent]/changelog.md`).

#### Philosophy — what question does it answer?

The changelog answers a different question than every other file in the system:

| File | Question it answers |
|---|---|
| `knowledge/index.md` | What do you know, organized by topic? |
| `MEMORY.md` | What's the current state of the user and project? |
| `sessions.md` | What happened in each session, narratively? |
| `changelog.md` | **What files were touched and when, in order?** |

That last question comes up in three specific situations where the others fail:

1. **Dedup across sessions.** When `/minechat` runs in a new chat, it needs to know "was this already mined?" The knowledge index is organized by topic — you'd have to read every entry to check. The changelog is chronological and file-level, so you can scan it in seconds: "yes, `bindimage-to-foldover-factors.md` was created on 2026-05-20, skip it."

2. **Cold-start orientation.** "What did we actually do recently?" is not well-answered by reading the knowledge index (topical, not temporal) or MEMORY.md (state, not history). The changelog gives you a reverse-chronological activity feed — see at a glance that three files were created today, two were refined last week, and nothing touched compound_maps in a month.

3. **Cross-layer visibility.** No single file tracks all four layers together. The knowledge index misses memory files and skill edits. MEMORY.md misses knowledge entries. The changelog is the only place that shows everything — knowledge, memory, skills, CLAUDE.md — on one timeline.

The underlying principle: **content indexes and activity logs serve different queries and shouldn't be conflated.** The knowledge index is a library card catalog. The changelog is a git log. Both are necessary; neither substitutes for the other.

#### The rule: one row per file touch, regardless of trigger

The changelog is per-**file**, not per-**event**. Every CREATE or EDIT of a four-layer file (`knowledge/*`, `memory/*`, `CLAUDE.md`, `~/.claude/skills/*`) adds exactly one row. The trigger doesn't matter.

| Trigger | What gets logged |
|---|---|
| Manual instruction (e.g. "update CLAUDE.md with X") | 1 row for the file you edited |
| `/learnthis` | Typically 2–3 rows (knowledge entry + index update; +1 if CLAUDE.md is also bumped) |
| `/logsession` | Exactly 1 row, for `sessions.md`. The skill's scope is narrow by design — mining the session for knowledge entries is `/minechat`'s job, not logsession's |
| `/minechat` | Many rows, one per file touched in the pass |
| Any future automation that edits a four-layer file | Same rule: one row per file |

The changelog's own row update is not itself logged — that would be infinite. Apart from that one bootstrap edit, the rule is absolute.

**Behavioral implication for Claude:** when the user asks for a direct edit to any four-layer file (CLAUDE.md, knowledge/, memory/, skills/), Claude must remember to also append a changelog row. This convention is reiterated in CLAUDE.md so it loads every session.

**Format:**

```markdown
# Activity log

Most-recent-first. Each row is one file written or edited via a skill (`/learnthis`, `/logsession`, `/minechat`). Read this when you forget what you were working on, or when a skill needs to know what's already been added.

| Date | Action | Path | Description |
|---|---|---|---|
| 2026-05-19 | CREATED | knowledge/cross_cutting/python-env.md | UV/CodeArtifact gotchas |
| 2026-05-19 | EDITED | CLAUDE.md | added subproject table + framework sections |
```

**Column conventions:**
- **Date:** YYYY-MM-DD.
- **Action:** `CREATED` or `EDITED`. Bookkeeping only — no skill reads this conditionally; the distinction is for the human eye when scanning.
- **Path:** relative to the personal-parent dir (e.g. `knowledge/cross_cutting/foo.md`, `CLAUDE.md`, or `~/.claude/...` for files outside the repo).
- **Description:** roughly 5 words. 10–15 is fine if the row demands it. Goal is scannable, not strict.

**Insertion rule:** new rows go immediately after the divider line (`|---|---|---|---|`). The header always stays at top; the table grows downward with the **newest** row on top. (Most-recent-first.)

**Skill integration:**
- `/learnthis`: reads **top 50 rows** of changelog first (to spot duplicates / candidate refinements), then appends a row for every file written or edited.
- `/logsession`: appends one row for the sessions.md edit. Doesn't need to read first — sessions are append-only and don't dedupe, and the skill's scope is intentionally narrow (one file touched per invocation).
- `/minechat`: reads **top 50 rows** of changelog as the *first* item in its source-of-truth orientation step (before CLAUDE.md, knowledge index, and memory index — because the changelog gives the fastest dedup signal). Appends a row per file touched in the mining pass.

The "top 50" read window is a soft default; read more if the recent rows suggest you should look further back.

If the changelog doesn't exist when a skill runs, the skill **creates it** using the header template above. This is mandatory in every repo — unlike the `knowledge/` directory layout (which the user picks), the changelog format is fixed.

---

## Variant: externally-managed repos

A repo is **externally managed** when the team owns the directory layout, the `.gitignore`, and what gets committed — and your personal Claude scaffolding (CLAUDE.md, knowledge/, scratch files) is *yours*, not theirs. They should never see it land in their tree.

The default layout in this doc (CLAUDE.md and `knowledge/` at the repo root, committed to git) assumes you own the repo. For externally-managed repos, three adjustments:

### 1. Nest `knowledge/` under an already-personal subdirectory

Don't create a top-level `knowledge/` at the repo root — even if it's local-only, it's visually intrusive and tempts an accidental `git add .`. Find a directory that's already personal (e.g. `claude_tutorials/`, `personal_notes/`, `scratch/`) and nest knowledge there:

```
[repo-root]/
  claude_tutorials/              ← already personal, already excluded
    changelog.md                 ← sibling of knowledge/, same parent dir
    knowledge/
      index.md
      sessions.md
      cross_cutting/
      [subproject]/
```

CLAUDE.md still goes at repo root (it has to — Claude Code only auto-loads CLAUDE.md from the project root). Update all knowledge/ pointers in CLAUDE.md and elsewhere to the nested path.

### 2. Use `.git/info/exclude`, not `.gitignore`

`.gitignore` is checked into the repo. Adding `CLAUDE.md` or `claude_tutorials/` to it would broadcast to the whole team "this person ignores these files" — which leaks the existence of your personal scaffolding even if the files themselves stay out.

`.git/info/exclude` is git's per-clone, never-committed equivalent. Same syntax as `.gitignore`. This is exactly the case it was designed for.

```
# in .git/info/exclude
CLAUDE.md
claude_tutorials/
.claude/
notebooks/scratch_*.py
```

### 3. Adjusted file listing

```
[repo-root]/
  CLAUDE.md                       ← excluded via .git/info/exclude
  .git/info/exclude               ← lists CLAUDE.md + personal subdir + scratch patterns
  claude_tutorials/               ← already personal, in exclude
    changelog.md                  ← activity log, sibling of knowledge/
    knowledge/
      index.md
      sessions.md
      cross_cutting/[slug].md
      [subproject]/[slug].md
    [existing personal docs left in place, referenced via [Ref] entries]
```

The user home directory layout (`~/.claude/skills/`, `~/.claude/projects/[encoded]/memory/`) is unchanged — those were never in the repo.

### When this variant applies
- The repo has a CODEOWNERS file and your name isn't on the team that owns the top-level structure
- The repo is shared with a team larger than just you and your immediate collaborators
- A team-owned `.gitignore` exists and is curated for shared concerns
- You have any doubt about whether your scaffolding belongs in their tree

When in doubt, treat the repo as externally-managed. The cost of being wrong in this direction is a slightly nested path; the cost of being wrong in the other direction is leaking personal files into a team's history.

---

## Skills (slash commands)

**What they are:** Markdown files in `~/.claude/skills/` that define repeatable multi-step procedures. Invoked with `/skillname` in the Claude Code UI.

**Two skills for this system:**

### `/learnthis`
Saves an insight to the knowledge base. Steps:
1. Extract the insight from recent conversation
2. Draft a knowledge entry (title, date, subproject, tags, body, key detail, when to apply)
3. Show draft to user and ask for confirmation or changes
4. On confirmation: write/append to appropriate `knowledge/[path].md`, add one line to `knowledge/index.md`, optionally update `CLAUDE.md` if it affects how Claude should approach the project
5. Report: "Saved to `knowledge/[path]` and indexed."

Prefer appending to an existing file over creating a new one if the topic is related. Never save trivial implementation details or things obvious from reading the code.

### `/logsession`
Appends a session summary to `knowledge/sessions.md`. Steps:
1. Draft entry: date, topics (2-5 noun phrases), files touched (3-6 significant paths), one-liner summary
2. Show draft to user and ask for confirmation
3. On confirmation: prepend entry to `knowledge/sessions.md` (most recent first)
4. Report: "Logged to `knowledge/sessions.md`."

Sessions log *what happened*. `/learnthis` logs *what was learned*. Don't overlap.

**Skill file format** (`~/.claude/skills/[name].md`):

Skills are discovered by YAML frontmatter — `name:` (must match the slash command) and `description:` (used to decide when the skill is relevant). The body is the procedure.

```markdown
---
name: skillname
description: One-sentence summary of when and why to invoke this skill. The CLI uses this to decide whether the skill applies to a given user prompt.
---

# /skillname

[One sentence description, repeated for human readers]

## Steps

1. Step one
2. Step two
...

## Notes
- Caveat or edge case
```

Without the frontmatter, the skill won't appear in the skills list and `/skillname` won't resolve.

---

## Setup checklist for a new project

Run through this when creating or cloning a repo where you want this system:

**In-repo setup (one time per project):**
- [ ] Decide layout: you-own-the-repo (commit, root-level `knowledge/`) or externally-managed (don't commit, `knowledge/` nested under a personal subdir). See "Variant: externally-managed repos" above.
- [ ] If externally-managed: add `CLAUDE.md`, the personal subdir, and `.claude/` to `.git/info/exclude` *before* creating the files
- [ ] Create `CLAUDE.md` at project root using the template above (Layer 1)
- [ ] Create `[knowledge-parent]/knowledge/index.md` with the header template
- [ ] Create `[knowledge-parent]/knowledge/sessions.md` with the header
- [ ] Create `[knowledge-parent]/knowledge/cross_cutting/`, `[knowledge-parent]/knowledge/[subproject]/` directories (add a `.gitkeep` or first entry file)
- [ ] Create `[knowledge-parent]/changelog.md` with the standard header (Layer 4). Skills auto-create it if missing, but seeding it during bootstrap lets you backfill rows for everything you just created.
- [ ] If you-own-the-repo: commit all of the above. If externally-managed: skip — files stay local-only.

**Global setup (one time per machine, shared across all projects):**
- [ ] Create `~/.claude/skills/learnthis.md` using the content in this repo's system or the template above
- [ ] Create `~/.claude/skills/logsession.md` using the content in this repo's system or the template above

**Per-session habit:**
- At the start of non-trivial work: check `knowledge/index.md` (Claude does this automatically if CLAUDE.md is set up)
- After learning something: run `/learnthis` or respond yes when Claude prompts you
- At the end of a session: run `/logsession`

---

## Bootstrapping into an existing repo

### Pre-bootstrap diagnostic

Before creating any files, run this inventory. The answers shape every decision that follows.

```bash
# What's already tracked vs personal?
git ls-files --error-unmatch CLAUDE.md 2>&1            # is CLAUDE.md committed?
git ls-files [proposed-knowledge-parent-dir]/ | head   # is your target dir tracked?
cat .git/info/exclude                                  # what's already locally excluded?
cat .gitignore                                         # what does the team already ignore?

# Does prior Claude state exist?
ls ~/.claude/projects/$(pwd | tr '/' '-')/memory/ 2>&1 # is the auto-memory dir there?
ls ~/.claude/skills/ 2>&1                              # are skills already installed?

# What existing docs would become [Ref] entries?
ls docs/ claude_tutorials/ doc/ wiki/ 2>/dev/null
```

The diagnostic answers four things: (1) is this repo externally-managed, (2) where can `knowledge/` safely live, (3) does CLAUDE.md already exist and is it yours or theirs, (4) what docs already exist that should be indexed rather than recreated.

### Questions to ask the user before touching anything

Don't assume — ask. These four questions cover almost every bootstrap decision:

1. **Where should `knowledge/` live?** Nested under a personal subdir (externally-managed repos), at repo root (you own the repo), or outside the repo entirely.
2. **What to do with existing dated logs / personal docs?** Leave in place and index as `[Ref]` entries (default, lowest risk), migrate selectively (more work, more value), or defer to a later session.
3. **Existing CLAUDE.md handling.** Add framework sections only (preserve everything), also extract conventions into `knowledge/` entries with pointers, or leave CLAUDE.md alone for now.
4. **Create skills now?** Yes installs `/learnthis` and `/logsession` immediately.

### What changes from the from-scratch flow

The setup checklist above is identical for an existing repo — you're adding files, not changing existing ones. The difference is that the knowledge base starts empty while significant context already lives in the codebase, git history, and your own head. You need to populate it deliberately rather than letting it grow organically from new work.

### What changes

**CLAUDE.md:** Write it based on what the project actually is, not a generic template. Before writing it, have Claude read the existing README, the top-level directory structure, and a few key source files, then draft CLAUDE.md from that. Review it before committing — this file shapes every future session. If a CLAUDE.md already exists, see the section below on merging it.

**knowledge/index.md and knowledge/sessions.md:** Start these empty (just the header). Don't try to backfill session logs — they're a forward-looking journal.

**The knowledge/ entries themselves:** These are the main thing to populate. See the extraction workflow below. If existing docs already contain relevant content, see the section on migrating existing docs.

**Auto-memory:** You probably already have preferences and working patterns established. Seed it with 2-3 memories covering things you know you'd have to tell Claude anyway (your role/expertise, any strong behavioral preferences). Don't over-populate — memory that's wrong or stale is worse than no memory.

**Don't seed memory without explicit user direction.** Auto-memory captures personal/behavioral preferences and corrections. During a bootstrap, the user hasn't yet given you those corrections — you have nothing to save. Ask before writing memory files. If the user says "no, I'll let it grow organically," respect that. The exception: if the user explicitly asks you to encode something (a TODO, a preference, a reminder), save it immediately — see "Persistent TODOs" below.

### Persistent TODOs that should outlast a session

When a bootstrap leaves something half-done — "we'll do the selective migration in a future session" — the obvious failure mode is that the future session never happens because nothing reminds anyone. Three places this could be encoded; auto-memory is usually the right one:

| Mechanism | Surfaces when | Use when |
|---|---|---|
| Auto-memory `project` entry | Every session, contextually | Default. Most ongoing work fits here. |
| `knowledge/_pending.md` file | Only when reading the knowledge index | The TODO is informational, you don't want surfacing pressure |
| Section in CLAUDE.md | Every session, prominently | You want a strong, unmissable nag |
| Scheduled wakeup (cron) | At a chosen time | Time-pegged ("ask me about this in 7 days") |

For an auto-memory project TODO, write the body so future-you knows **when to surface it** (e.g. "when the user touches one of these files, mention this — otherwise stay quiet"), not just what the TODO is. A reminder that fires on every unrelated task is a nag; one that fires contextually is a help.

Remove the memory once the TODO is done — stale TODOs poison the well.

---

### Handling an existing CLAUDE.md

**Rule: never delete existing content.** Everything in the existing CLAUDE.md was put there intentionally. The goal is to absorb it into the framework, not replace it.

**Procedure:**

1. Read the existing CLAUDE.md in full before touching it.

2. Classify each existing section into one of:
   - **Stays in CLAUDE.md** — project overview, subproject map, conventions that apply to every session, commands list, proactive learning instruction. These belong here permanently.
   - **Moves to knowledge/** — specific decisions, rationale, gotchas, patterns. Things that are useful when relevant but don't need to load every session. Extract these as `/learnthis` entries, then replace the CLAUDE.md section with a one-line pointer: `See knowledge/[path].md`.
   - **Moves to memory** — behavioral preferences, corrections, things about how you want Claude to interact with you. These belong in auto-memory files, not CLAUDE.md.
   - **Moves to a skill** — step-by-step procedures that Claude should execute on command. Create a skill file and replace the CLAUDE.md section with a `/skillname` entry in the Commands list.

3. Add the new framework sections (Knowledge system block, Commands list, Proactive learning instruction) around the existing content, not instead of it.

4. Reorder sections if needed for clarity — the typical order is: Project overview → Subproject table → Knowledge system → Commands → Style/conventions. But don't reorder if it would bury something important.

5. Commit CLAUDE.md separately from any knowledge/ files you create, so the change is reviewable.

**What a merged CLAUDE.md looks like:**

```
# [Project Name]

## Project overview
[existing overview, kept verbatim or lightly edited]

## Subprojects              ← new, or merged with existing structure
| Directory | Description |
...

## Knowledge system         ← new
...

## Commands                 ← new, or appended to existing commands
- /learnthis
- /logsession
- [existing commands kept]

## Style / conventions      ← existing section, kept intact
[existing conventions]

## [Any other existing sections]   ← kept intact, possibly with pointer to knowledge/
```

---

### Handling existing documentation files

Existing docs (README, ADRs, design docs, runbooks, wikis) often contain exactly the kind of non-obvious rationale that belongs in `knowledge/`. The question is whether to **migrate** them (move content into the knowledge system) or **reference** them (leave them in place, add pointers).

**When to migrate (move content into knowledge/):**
- The doc is a decisions log, architecture rationale, or gotcha list — content that maps cleanly onto knowledge entries
- The doc is informal / internal (not user-facing) and would benefit from being indexed
- The doc is long and unfocused; distilling it into a few targeted entries is an improvement

**When to reference (leave in place, add pointers):**
- The doc is authoritative and well-maintained — a README, API reference, official runbook
- Reformatting it would lose structure or create a maintenance burden (you'd have to update two places)
- The doc is user-facing or shared with others who don't use this system

**Procedure for migrating a doc:**

1. Read the doc. Identify paragraphs or sections that contain non-obvious decisions, constraints, or gotchas.
2. For each: run `/learnthis` (or draft manually) to create a knowledge entry. Keep entries focused — one insight per entry, not one file per doc.
3. In the original doc, replace migrated paragraphs with a line: `See knowledge/[path].md for rationale.` — or delete the paragraph if it's now fully redundant with the knowledge entry.
4. Add the knowledge entries to `knowledge/index.md`.
5. If the doc itself is still useful as an overview, add a pointer to it from `knowledge/index.md` as a reference entry: `- [Ref] **[Doc title]** — [what it covers] → [path/to/doc]`

**Procedure for referencing a doc (leaving it in place):**

1. Add a pointer to `knowledge/index.md` using the reference format: `- [Ref] **[Doc title]** — [what it covers] → [path/to/doc]`
2. If the doc is important enough that Claude should be aware of it at session start, add a one-liner to CLAUDE.md: `See [path/to/doc] for [what it covers].`
3. Do not reformat or rewrite the doc's content — just point to it.

**Sorting content across the three layers — decision table:**

| Content type | Where it goes |
|---|---|
| Non-obvious decision rationale | `knowledge/[subproject]/[slug].md` |
| Cross-project convention or constraint | `knowledge/cross_cutting/[slug].md` |
| Reference to an external or existing doc | `knowledge/index.md` as a `[Ref]` entry |
| Something Claude should know every session | `CLAUDE.md` (or pointer from it) |
| User behavioral preference / correction | Auto-memory file |
| Step-by-step repeatable procedure | `~/.claude/skills/[name].md` |
| What the code does | Leave it in the code |

---

### Extraction workflow: populating knowledge/ from existing work

Do this in one dedicated session, not incrementally during normal work.

**Step 1 — Map the repo**

Ask Claude to read the directory structure, README, and any existing docs, then produce a list of:
- What the main components/modules are
- What the significant decisions or constraints appear to be
- What topics are likely to have non-obvious gotchas

This map tells you which areas are worth extracting knowledge from.

**Step 2 — Extract area by area**

For each significant area (module, infrastructure concern, algorithm, etc.):
1. Ask Claude to read the relevant source files and any related docs/comments
2. Ask: "What would a future Claude need to know about this that isn't obvious from reading the code?"
3. Review the answer — push back on anything that's just restating what the code already says clearly
4. Run `/learnthis` for each non-obvious insight that survives that filter

Good targets for extraction:
- Why an architecture decision was made (the code shows what, not why)
- Non-obvious constraints (a library that can't be used, a performance cliff, a deployment limitation)
- Conventions that aren't enforced by linting (naming patterns, file organization rules, test philosophy)
- Recurring gotchas that caused bugs or wasted time
- External system dependencies and where they're documented

Bad targets (skip these):
- How the code works — Claude can read the code
- What files exist — Claude can `find`/`grep`
- Recent changes — `git log` covers this
- Things already written clearly in existing docs

**Step 3 — Update CLAUDE.md with anything structural**

After extraction, if any knowledge entries reveal project-level constraints or conventions that should shape every session (not just specific tasks), move them up into CLAUDE.md rather than leaving them only in knowledge/. CLAUDE.md is always loaded; knowledge/ entries are only read when relevant.

**Step 4 — Seed auto-memory**

Ask Claude: "Based on what we've just done, are there any behavioral preferences or corrections you should remember for future sessions?" If yes, have it write those as memory files now rather than waiting to discover them through mistakes.

---

### Rough time budget

| Repo size | Extraction session length |
|---|---|
| Small (1-2 modules, <5k lines) | 30–60 min |
| Medium (5-20 modules, 5k–50k lines) | 2–4 hours, possibly split across 2 sessions |
| Large (many modules, 50k+ lines) | Don't try to do it all at once; extract one subsystem per session over multiple days |

For large repos, prioritize the areas you're actively working in. Extract the rest incrementally as you touch them — use the proactive learning prompt (Layer 1) to catch insights as they happen.

---

### Signs the extraction worked

- You can open a new session, ask Claude to check `knowledge/index.md`, and it surfaces something relevant without you having to re-explain it
- CLAUDE.md reads like a useful orientation for an engineer new to the project, not a generic template
- You feel slightly annoyed that you have to explain something Claude "should already know" → that's a signal to run `/learnthis`

---

## What is NOT in this system

These are common temptations to avoid:

| Temptation | Why to avoid |
|---|---|
| Saving code patterns to memory | They go stale; read the code instead |
| Saving file paths to memory | Files move; use `find`/`grep` |
| Saving git history summaries | `git log` is authoritative |
| Writing `/learnthis` entries for trivial things | Noise drowns signal |
| Logging sessions mid-way | `/logsession` is an end-of-session action |
| Using memory for in-session state | Use TodoWrite for that |

---

## Full file listing

After setup of a **you-own-the-repo** project:
```
[project-root]/
  CLAUDE.md                ← committed
  changelog.md             ← committed, sibling of knowledge/
  knowledge/               ← committed
    index.md
    sessions.md
    cross_cutting/[slug].md
    [subproject]/[slug].md
```

After setup of an **externally-managed** project:
```
[project-root]/
  CLAUDE.md                ← local-only, in .git/info/exclude
  .git/info/exclude        ← lists CLAUDE.md + personal parent dir + scratch patterns
  [personal-parent-dir]/   ← already excluded (e.g. claude_tutorials/, personal_notes/)
    changelog.md           ← activity log, sibling of knowledge/
    knowledge/
      index.md
      sessions.md
      cross_cutting/[slug].md
      [subproject]/[slug].md
```

The user home directory layout is identical in both cases:
```
~/.claude/
  skills/
    learnthis.md
    logsession.md
  projects/
    [encoded-project-path]/
      memory/
        MEMORY.md
        [slug].md    ← one file per memory
```

That's the complete system. Hand this file to Claude at the start of any new project and ask it to set up the same structure.
