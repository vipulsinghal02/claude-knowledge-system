# claude-knowledge-system

The premise: Claude has no memory across sessions by default. Without scaffolding, every session starts cold. This repo holds the design doc and skills that let context accumulate over time. 

> [!NOTE]
> It was brought to my attention that Karpathy [already articulated this](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). This is basically that, and other implementations exist (see that thread). 

In his words: 
> Instead of just retrieving from raw documents at query time, the LLM incrementally builds and maintains a persistent wiki — a structured, interlinked collection of markdown files that sits between you and the raw sources. When you add a new source, the LLM doesn't just index it for later retrieval. It reads it, extracts the key information, and integrates it into the existing wiki — updating entity pages, revising topic summaries, noting where new data contradicts old claims, strengthening or challenging the evolving synthesis. The knowledge is compiled once and then kept current, not re-derived on every query.
> -Karpathy

## Two kinds of repo in this picture — read this first

It's easy to conflate these. There are always exactly two:

1. **This repo (`claude-knowledge-system`)** — the scaffolding/tooling. You clone it **once**, to one location on your machine (e.g. `~/repos/claude-knowledge-system`). You run `./install.sh` **once per machine** (re-run it after `git pull` when it updates). This repo's job is to get the skills (`/learnthis`, `/logsession`, `/minechat`, `/setup-knowledge-system`) registered globally in `~/.claude/skills/`, so they're available in **every** Claude Code session on that machine, regardless of which project you're working in.
2. **Your project repos** (e.g. `NullStrike`, or any other repo you work in) — where the actual knowledge accumulates. You do **not** clone or copy anything from this repo into them. Instead, once installed, open Claude Code in that project and run the now-globally-available `/setup-knowledge-system` skill. It scaffolds `CLAUDE.md`, `knowledge/`, and `changelog.md` **inside that project**, tailored to it.

So: one install, many projects. You'll run `/setup-knowledge-system` once per project you want this in, but you never touch `install.sh` again unless this scaffolding repo itself changes.

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

## Install (once per machine)

```bash
git clone <this-repo-url> ~/repos/claude-knowledge-system
cd ~/repos/claude-knowledge-system
./install.sh
```

`install.sh` creates symlinks in `~/.claude/` so Claude Code can discover the skills and architecture doc. It's idempotent — safe to re-run any time (e.g. after `git pull`).

The script prints its own verification (symlink targets + a frontmatter check on every skill file), so you shouldn't need to inspect anything by hand. If you want to double check anyway:
```bash
ls -la ~/.claude/skills/ ~/.claude/knowledge-system-architecture.md
```
You should see four **symlinks** under `skills/` (`learnthis.md`, `logsession.md`, `minechat.md`, `setup-knowledge-system.md`) and one for the architecture doc, all pointing into this repo. If any of them is a plain file instead of a symlink (`l` missing from the permissions column), something pre-existing blocked the install — `install.sh` will now detect this itself, back the stale file up, and replace it (see "Troubleshooting" below).

> [!IMPORTANT]
> **Restart Claude Code after installing or updating.** The skills list is read once when a Claude Code session starts — if you had a session open while running `install.sh`, that session will not see the new/updated skills. Close it and open a fresh one (or start a new session in your terminal/IDE) before expecting `/learnthis` etc. to show up.

## Use it in a project (once per repo you want it in)

This is a **separate step**, done inside each project repo where you want persistent knowledge — not inside `claude-knowledge-system` itself.

```bash
cd ~/repos/your-project     # any repo, e.g. NullStrike
# open Claude Code here, then type:
/setup-knowledge-system
```

The skill runs a pre-bootstrap diagnostic, asks ~4 questions about the repo (externally-managed? subprojects? existing CLAUDE.md?), and writes the full four-layer scaffolding **into that project**. Takes ~5 minutes per repo. Repeat this in every project you want the system in — you never need to re-clone or re-install anything for additional projects, only run this one skill.

## Troubleshooting

**`/setup-knowledge-system` (or any of the four skills) doesn't show up as a slash command.** In order of likelihood:
1. You haven't restarted Claude Code since running `install.sh` — see the note above. This is the most common cause.
2. `install.sh` hasn't been run on this machine yet, or errored partway. Re-run it and read its output; it now reports success/failure per file.
3. A stale, non-symlink file already existed at `~/.claude/skills/<name>.md` before you ever ran `install.sh` (this can happen if you hand-created a skill file before adopting this repo, or copy-pasted an old version). `install.sh` now detects this automatically, moves the stale file to a timestamped backup under `~/.claude/skills-backup-*/`, and replaces it with the correct symlink. Just re-run `./install.sh` and restart Claude Code.
4. A skill file is missing its YAML frontmatter (`---\nname: ...\ndescription: ...\n---` at the very top). `install.sh`'s frontmatter check will flag this by name — but it shouldn't happen with files from this repo unless something got corrupted; if you see this, please open an issue.

## Why this exists

- **We have to keep repeating things to Claude**: it builds context from scratch every time. Without persistence, you re-explain them every session. (Each repo's `knowledge/` is independent by design — see "Known limitations" in `knowledge-system-architecture.md` for the cross-repo case and the pointer-stub workaround.)
- **CLAUDE.md is per-repo**, so it can't be canonicalized. But the *design* of the system, the *skills* that operate on it, and the *procedure* for bootstrapping it absolutely can be — and that's this repo.
- **Adding a new repo** to the system should be one slash command, not a 30-minute manual procedure. Hence `/setup-knowledge-system`.

## Updating

When you tweak a skill or the architecture doc, edit the file *in this repo*, commit, and `git push`. On other machines: `git pull && ./install.sh` (the install is idempotent).

The per-repo CLAUDE.md files in each project don't need to change unless the design itself changes — they reference `~/.claude/knowledge-system-architecture.md` (which is a symlink to this repo).

## Sharing

Open to others on your team: share the repo URL, they clone + install. Everyone's skills + architecture doc stay in sync via git. Per-repo CLAUDE.md and knowledge content remain individual.
