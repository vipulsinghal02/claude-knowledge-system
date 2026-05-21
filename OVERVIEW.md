# claude-knowledge-system — overview

A way to make Claude actually **remember things** across sessions when you work in many repos. Also, for you to review what you worked on in the past (via `changelog.md` and `sessions.md`). 

## The problem

Every conversation with Claude Code starts cold. Yesterday you spent 20 minutes explaining your env setup, the team's testing conventions, a weird gotcha in your AWS pipeline, the reason your tests are structured oddly. Tomorrow you'll do it all again — because Claude has no memory of the previous chat.

Across N repos this gets worse. Each repo has its own conventions, gotchas, and ongoing work. Every session, in every repo, you re-explain the same things.

This system fixes that with **four layers of persistence** that sit next to your code. Claude reads them automatically at the start of each session, so context accumulates over time instead of evaporating.

## The four layers

```
┌─────────────────────────────────────────────────────────────────┐
│  Per-repo (lives in each project, locally)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CLAUDE.md                ← rules + project map (auto-loaded)   │
│  [personal-parent]/                                              │
│    ├─ knowledge/          ← decisions, gotchas, patterns         │
│    └─ changelog.md        ← timeline of what's been written      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Per-user (across all your repos, in ~/.claude/)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ~/.claude/projects/<repo>/memory/   ← your preferences         │
│  ~/.claude/skills/                   ← slash commands (shared)   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

| Layer | What it stores | When it's loaded |
|---|---|---|
| **CLAUDE.md** | "What rules apply every session in this repo?" | Auto, every session |
| **knowledge/** | "What have we figured out, organized by topic?" | On demand (skills + you reference it) |
| **auto-memory** | "What does the user prefer or how should Claude behave?" | Auto, every session |
| **changelog.md** | "What four-layer files have been written/edited, and when?" | On demand (skills read it to dedup; you skim it to remember what you were up to) |

The four layers are **complementary**, not overlapping:
- `knowledge/index.md` is a library card catalog — *what do we know, organized by topic?*
- `MEMORY.md` is current state — *what does the user prefer right now?*
- `sessions.md` is the narrative journal — *what happened, in each session?*
- `changelog.md` is the git-log of the personal layer — *what files were touched, in order?*

## What this looks like day-to-day

**Session 1 (cold start in a new repo)**

You add the system: `/setup-knowledge-system`. Skill asks you 4 questions (where to put `knowledge/`, what to do with existing docs, etc.). Five minutes later, scaffolding is in place. Nothing committed to the team's repo — all your personal files are local-only via `.git/info/exclude`.

**Session 2 (working)**

You ask Claude to help debug a memory issue. Twenty minutes in, you figure out that the OOM was caused by accumulating raw frames in a `ThreadPoolExecutor`. Claude proactively offers:

> *"We just figured out that ThreadPoolExecutor memory grows because frames accumulate in the futures list. Want me to save this to the knowledge base? I'd add it to `knowledge/cross_cutting/parallel-fetch-oom.md` as: [draft entry]."*

You say yes. Claude writes the entry, indexes it, and appends a row to the changelog. Total time: 30 seconds.

**Session 3 (end of day)**

You type `/logsession`. Claude appends a one-paragraph summary of what you worked on to `sessions.md` and logs that to the changelog.

**Session 7 (two weeks later, same repo)**

You come back to the parallel-fetch code. Claude already knows about the ThreadPoolExecutor gotcha because the entry you saved in session 2 is still in this repo's `knowledge/` — and it surfaces when you start working in the relevant area. No re-explaining.

(If you'd switched to a *different* repo, the entry would not be available there — see "What if I learn something useful for a different repo too?" in the questions below.)

## The slash commands

You install once per machine. After install, all four are available in any Claude Code session:

| Command | What it does |
|---|---|
| `/learnthis` | Save a non-obvious insight from the current chat as a knowledge entry. |
| `/logsession` | End-of-session summary. Appends to `sessions.md`. |
| `/minechat` | Retroactively mine a longer conversation (or a `.jsonl` transcript) for stuff worth saving. Conservative — proposes a batch, you approve. |
| `/setup-knowledge-system` | Bootstrap the whole system into a fresh repo. Run this once per repo. |

All four resolve paths from the repo you're currently in. Same skills work everywhere; no per-repo configuration.

## Getting started (5 minutes)

```bash
# 1. Clone this repo
git clone <repo-url> ~/repos/claude-knowledge-system

# 2. Install (symlinks files into ~/.claude/)
cd ~/repos/claude-knowledge-system && ./install.sh

# 3. In any repo where you want the system:
cd ~/repos/your-project
# ...then in your Claude Code session, type:
/setup-knowledge-system
```

That's it. After step 3, that repo is at full parity and you can start using `/learnthis`, `/logsession`, `/minechat` immediately.

## Staying in sync (across machines or with team updates)

This repo is the single source of truth for the architecture doc and the four slash commands. To pull updates:

```bash
cd ~/repos/claude-knowledge-system
git pull
./install.sh   # idempotent, safe to re-run
```

You don't need to touch any of your other repos — their CLAUDE.md files reference `~/.claude/knowledge-system-architecture.md`, which is a symlink to this repo.

## Things you don't need to do

- **You don't need to commit anything personal to the team's repo.** The system uses `.git/info/exclude` (per-clone, never shared) to hide `CLAUDE.md`, your personal-parent dir, and `.claude/` from `git status`. The team never sees them.
- **You don't need to maintain the changelog manually.** Slash commands update it automatically. The convention also says to add a row when you do a *direct* CLAUDE.md edit (Claude follows this rule on its own once CLAUDE.md is set up).
- **You don't need to learn the full architecture before using it.** CLAUDE.md auto-loads a 5-line summary every session. The full doc is at `~/.claude/knowledge-system-architecture.md` if you ever want to dive deeper.

## How private is this?

- **`CLAUDE.md`, `knowledge/`, and `changelog.md` are local to your machine.** They are never committed to your work repo. They're in `.git/info/exclude`, which is a per-clone file that doesn't get shared.
- **Auto-memory lives in `~/.claude/projects/<encoded-repo>/memory/`** — also local. Never leaves your machine.
- **This scaffolding repo is what gets shared with the team.** It contains the design doc and the slash commands. Everyone who installs gets the same skills.

If a piece of knowledge would benefit the team (not just you), copy it from your local `knowledge/` into the actual project's team docs or open a PR. The personal layer is for *your* per-session reuse, not team knowledge transfer.

## Common questions

**"Won't `CLAUDE.md` get huge?"** No — keep it short. Anything that's only situational ("when you're doing X, remember Y") goes in `knowledge/`. CLAUDE.md is just the must-load-every-session essentials: subproject map, env conventions, slash command list.

**"What if I don't want Claude to save something?"** Just say no. The `/learnthis` flow asks for confirmation before writing. Memory entries also require explicit direction — Claude won't seed memory on its own.

**"Does this work if I share a machine with someone else?"** Auto-memory keys on `pwd`, so two people working in different home directories get separate memory dirs. If you literally share a `~/.claude/`, you'd share memory — but that's not the normal case.

**"What's the relationship to the docs the team already maintains?"** Team docs (`docs/`, READMEs) stay where they are. The knowledge system **references** them via `[Ref]` entries in `knowledge/index.md` — never duplicates content. The system is additive, not a replacement.

**"What if I learn something useful for a different repo too?"** Each repo's `knowledge/` is independent — an entry saved in repo A doesn't show up in repo B. If an insight applies to multiple repos, you either copy the file manually between knowledge dirs, or (better) promote it to the team's actual project docs where it belongs. Cross-repo knowledge transfer is a known gap; see the "Known limitations and open design questions" section of `knowledge-system-architecture.md`.

## Where to read more

- **`README.md`** — install instructions and what's in this repo.
- **`knowledge-system-architecture.md`** — full design rationale. Long but thorough. Read it if you want to know *why* the system is shaped this way, or if you're extending it.
- **`skills/*.md`** — the actual slash command implementations. Each is a single readable file.

## Who to ask

Vipul set this up. Ping him if a slash command doesn't behave, if you want to extend the system, or if you have ideas about what the next layer should be.
