# claude-knowledge-system

The premise: Claude has no memory across sessions by default. Without scaffolding, every session starts cold. This repo holds the design doc and skills that let context accumulate over time. 

> [!NOTE]
> It was brought to my attention that Karpathy [already articulated this](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). This is basically that, and other implementations exist (see that thread). 

In his words: 
> Instead of just retrieving from raw documents at query time, the LLM incrementally builds and maintains a persistent wiki — a structured, interlinked collection of markdown files that sits between you and the raw sources. When you add a new source, the LLM doesn't just index it for later retrieval. It reads it, extracts the key information, and integrates it into the existing wiki — updating entity pages, revising topic summaries, noting where new data contradicts old claims, strengthening or challenging the evolving synthesis. The knowledge is compiled once and then kept current, not re-derived on every query.
> -Karpathy

## The four layers

This is a four-layer persistence system for working with Claude Code.
| Layer | Lives in | Purpose |
|---|---|---|
| 1. **CLAUDE.md** | per-repo, project root | Loaded every session. Subproject map, must-know rules, commands. |
| 2. **`knowledge/`** | per-repo, under a personal-parent dir | Accumulated insights, decisions, indexed pointers to existing docs. |
| 3. **Auto-memory** | `~/.claude/projects/<encoded-pwd>/memory/` | User preferences, behavioral corrections, validated approaches. Loaded automatically. |
| 4. **`changelog.md`** | per-repo, sibling of `knowledge/` | Most-recent-first file-level activity log. Cross-layer visibility + skill dedup signal. |

Full design rationale is in `knowledge-system-architecture.md` (this repo).

## What's in this repo

```
claude-knowledge-system/
├── knowledge-system-architecture.md   ← the canonical design doc (claude reads this; humans read OVERVIEW.md)
├── OVERVIEW.md                         ← An overview file for you to read (a bit more detailed than the readme)
├── install.sh                          ← symlinks files into ~/.claude/
├── README.md                           ← this file
└── skills/
    ├── learnthis.md                    ← /learnthis: save an insight to knowledge/
    ├── logsession.md                   ← /logsession: write a session summary
    ├── minechat.md                     ← /minechat: retroactively mine a chat
    └── setup-knowledge-system.md       ← /setup-knowledge-system: bootstrap a new repo
```

## Install

```bash
git clone <this-repo-url> ~/repos/claude-knowledge-system
cd ~/repos/claude-knowledge-system
./install.sh
```

`install.sh` creates symlinks in `~/.claude/` so Claude Code can discover the skills and architecture doc. 

Verify:
```bash
ls -la ~/.claude/skills/ ~/.claude/knowledge-system-architecture.md
```

You should see four symlinks under `skills/` and one for the architecture doc, all pointing into this repo. (Note: the skills slash commands don't seem to be working for me just yet. Will look into it later, but for now I've just been telling claude "read that skill markdown file and do the thing (!)"). 

## Bootstrap a new repo

After install, in any fresh repo:

```
/setup-knowledge-system
```

The skill runs a pre-bootstrap diagnostic, asks ~4 questions about the repo (externally-managed? subprojects? existing CLAUDE.md?), and writes the full four-layer scaffolding. Takes ~5 minutes per repo.

## Why this exists

- **Multi-repo work** drifts: every repo you touch accumulates its own conventions, gotchas, and decisions. Without persistence, you re-explain them every session. (todo: need to figure out a single knowledge base across all the repos. not sure why I didn't just set it up one level up from all the repos from the start..)
- **CLAUDE.md is per-repo**, so it can't be canonicalized. But the *design* of the system, the *skills* that operate on it, and the *procedure* for bootstrapping it absolutely can be — and that's this repo.
- **Adding a new repo** to the system should be one slash command, not a 30-minute manual procedure. Hence `/setup-knowledge-system`.

## Updating

When you tweak a skill or the architecture doc, edit the file *in this repo*, commit, and `git push`. On other machines: `git pull && ./install.sh` (the install is idempotent).

The per-repo CLAUDE.md files in each project don't need to change unless the design itself changes — they reference `~/.claude/knowledge-system-architecture.md` (which is a symlink to this repo).

## Sharing

Open to others on your team: share the repo URL, they clone + install. Everyone's skills + architecture doc stay in sync via git. Per-repo CLAUDE.md and knowledge content remain individual.
