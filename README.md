# Praxis CLI v2

Full terminal client for the Praxis webapp with a **git-like notebook** model.

## Notebook Model (Git-Like)

Each topic is a "repo" — stored in `~/.praxis/notebook/<topic>/`:

| Git Concept | Praxis Equivalent |
|-------------|-------------------|
| Repository | Topic (goal/domain) |
| Commit | Entry (SHA, parent, message, content) |
| `git log` | `praxis nb log` — parent-linked history |
| `git show` | `praxis nb show` — entry details |
| `git tag` | `praxis nb tag` — milestone tags |
| `git diff` | `praxis nb diff` — compare entries |
| `git branch` | `praxis nb list` — all topics |
| `git init` | `praxis nb init` — create topic |
| `git push` | Auto-synced on entry creation |
| `git pull` | `praxis sync pull` — fetch from webapp |

## Install

```bash
cd /home/gio/Praxis/praxis_cli
npm install
npm run build
npm link  # makes `praxis` available globally
```

## Quick Start

```bash
# Login to webapp
praxis auth login
praxis auth status

# View dashboard
praxis dashboard

# Notebook (git-like)
praxis nb init fitness
praxis nb entry fitness -m "Leg day" --content "3x10 squats" --mood strong
praxis nb entry fitness -m "Cardio" --content "5K run" --mood tired
praxis nb log fitness           # parent-linked history
praxis nb log fitness --oneline # compact
praxis nb show fitness          # latest entry (HEAD)
praxis nb show fitness 375c6    # specific entry (prefix match)
praxis nb tag fitness 375c6 milestone
praxis nb diff fitness 375c6 c4f21

# Goals
praxis goals list
praxis goals add -n "Run 5K"

# Daily check-in
praxis checkin -n "Feeling good"

# Streaks & bets
praxis streak
praxis bets

# Sync
praxis sync pull   # fetch goals/entries from webapp
praxis sync push   # entries auto-push on creation

# Config
praxis config get
praxis config set apiUrl https://your-api-url
```

## Local Storage

```
~/.praxis/
├── index.json              — topic index (name, HEAD, count, lastEntry)
└── notebook/
    └── fitness/
        ├── HEAD            — SHA of latest entry
        └── entries/
            ├── 375c620d.json  — entry data
            └── c4f21eb4.json  — child entry (parent: 375c620d)
```

## Entry Format

```json
{
  "sha": "c4f21eb4a8b3",
  "parent": "375c620d...",
  "message": "Cardio day",
  "content": "30 min running",
  "mood": "tired",
  "tags": ["milestone"],
  "author": "gio",
  "createdAt": "2026-04-04T10:50:28.000Z"
}
```

## Architecture

- **Node.js + TypeScript** — type-safe, compiled
- **Commander.js** — CLI command parsing
- **Ora** — spinner animations
- **CLI-Table3** — formatted tables
- **Chalk** — colored terminal output
- **Webapp API** — all data synced to/from Praxis webapp

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `praxis auth login` | — | Login to webapp |
| `praxis auth logout` | — | Clear session |
| `praxis auth status` | — | Show auth status |
| `praxis dashboard` | `dash` | Dashboard summary |
| `praxis nb init` | — | Create topic |
| `praxis nb list` | `ls` | List topics |
| `praxis nb log` | — | Entry history |
| `praxis nb entry` | `add` | Add entry |
| `praxis nb show` | — | Show entry |
| `praxis nb tag` | — | Tag entry |
| `praxis nb diff` | — | Compare entries |
| `praxis goals list` | `ls` | List goals |
| `praxis goals add` | — | Add goal |
| `praxis checkin` | `ci` | Daily check-in |
| `praxis streak` | — | View streak |
| `praxis bets` | — | View bets |
| `praxis sync pull` | — | Pull from webapp |
| `praxis sync push` | — | Push to webapp |
| `praxis config get` | — | Get config |
| `praxis config set` | — | Set config |
