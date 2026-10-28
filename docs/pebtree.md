# pebtree

pebtree is a local web dashboard for running many Claude Code sessions in parallel, one per git worktree.
It shows which sessions are waiting on you and lets you answer them, shows what every tree is running and what it costs your Mac, and gives you controls to stop, clean up and close trees.

It is one dependency-free Node file, `bin/pebtree`, served at http://localhost:4777 and bound to 127.0.0.1 only.

This document is the contract for running it anywhere: what it needs, how to set it up on a new Mac or for a new project, what it reads and writes, and which outside formats it depends on.

## What you get

- **Feed:** Pinned, Your turn (sessions waiting on you), Working, Pending (sessions you set aside while you wait on someone, like a teammate) and Archive (waiting sessions nobody has touched for over a week, folded away).
  Reply from the page (Enter sends to the session's iTerm tab), answer questions and permission prompts, drag to reorder Your turn.
  Move a card between sections by dragging it onto one, with its Move menu, or from the `/` bar; a card you place stays there until its session says something new, and a question or permission prompt always comes back to Your turn.
- **Detail view:** the session's conversation (Claude's in-between messages included), a reply box with `/` skill autocomplete, and a side panel.
  The side panel shows git and PRs with their merge status, the session's subagents (click one to read its conversation), the tree's servers and simulators, memory, and actions.
- **Resources:** Mac memory, swap and CPU over time, and memory by tree.
- **Trees, Sessions, Processes, Cleanup:** every dev server with its real memory, idle and orphan cleanup, a cap on how many trees run at once, and Close tree (stop its processes, return the worktree, close its tab).
- **Proof:** screenshots and test output that sessions send you with `pebtree proof`.
- **Journal:** one entry per day, written from your GitHub history by a Claude skill.
- **Look:** one dark, minimal style modeled on the stacked.com dashboard: near-black, hairline borders, no shadows. The only setting is the font (Inter + Roboto Mono by default), in Settings → Appearance.
- **Keyboard:** `/` command bar, `⌘[` `⌘]` pages, `⌘⇧[` `⌘⇧]` cards, `⌘Z` reopen the session you just answered, `?` for the full list.

## Requirements

| Needs | Why | Without it |
|---|---|---|
| macOS | Memory, swap and process stats come from macOS tools | Does not run |
| Node 18 or newer | Runs the server | Does not run |
| tmux, here and on every host | Sessions pebtree starts run in it; titles and screens are read from it, replies typed into it | Only iTerm2 sessions are followed |
| python3 | Gives the page's terminals a pty | No terminals in the page |
| iTerm2 (optional) | Sessions already in iTerm2 tabs are followed | Those sessions are not shown |
| Automation permission for iTerm2 | AppleScript reads and writes the tabs | Same as above |
| Claude Code | Session transcripts in `~/.claude/projects` are the source of every message shown | Empty feed |
| [treehouse](#treehouse) | The worktree pool: which trees exist and which session uses which | No trees |
| `gh`, logged in | PR status for every repo the trees belong to | PRs show without status |
| A teardown command (optional, `teardown` in config.json) | Close tree stops a tree's dev servers first | Close tree skips that step |
| The `/daily-standup` skill (or your own) | Writes journal entries | Journal tab only |
| `send-proof` and `spinoff` skills (optional) | Let sessions send you proof and spin tasks off to new trees | Those features stay manual |

Run `pebtree doctor` at any time: it checks every row above and prints the fix for anything missing.

## Set it up on a new Mac

1. Get the tools.

   ```bash
   git clone https://github.com/<you>/pebtree.git ~/pebtree
   export PATH="$HOME/pebtree/bin:$PATH"   # add this line to ~/.zshrc too
   brew install node && brew install --cask iterm2
   npm i -g @anthropic-ai/claude-code
   ```

   Install the treehouse CLI as well, and run `treehouse init` once in your project.

2. Point pebtree at your project.
   Run this from the project's main checkout, after at least one tree exists (`treehouse get`):

   ```bash
   cd ~/code/your-project
   pebtree init
   ```

   It writes `~/.config/pebtree/config.json` with the checkout, the treehouse pool it found and the checkout's folder name.

3. Install the companion skills, if you want them:

   ```bash
   mkdir -p ~/.claude/skills
   cp -R ~/pebtree/skills/send-proof ~/pebtree/skills/spinoff ~/.claude/skills/
   ```

4. Check and start it:

   ```bash
   pebtree doctor
   pebtree            # then open http://localhost:4777
   ```

   The first time it scripts iTerm2, macOS asks whether your terminal may control iTerm2. Allow it.

To keep it running in the background: `nohup pebtree > ~/.config/pebtree.log 2>&1 & disown`.
To restart after an update: `kill $(lsof -tiTCP:4777 -sTCP:LISTEN)` and start it again.
Open pages reload themselves into the new version once you are not typing.

## Configuration

`~/.config/pebtree/config.json` (written by `pebtree init`, safe to edit by hand):

| Key | Meaning | Default |
|---|---|---|
| `main` | The project's main checkout | The checkout `pebtree init` ran in |
| `pool` | The treehouse pool folder that holds `<N>/<repoDir>` worktrees | Found from `treehouse status` |
| `repoDir` | The checkout's folder name inside each pool slot | Basename of `main` |
| `teardown` | Command that stops a tree's dev servers; `{tree}` is replaced by its number; `""` skips it | `treehouse-dev teardown {tree}` if `treehouse-dev` is installed, else none |
| `journalSkill` | The skill that writes journal entries | `/daily-standup` |
| `tickets` | Optional. `{ "url": "https://your-app.example.com", "key": "<PEBTREE_API_KEY>" }` turns on the Tickets tab (see below) | off |

`TREEHOUSE_MAIN` and `TREEHOUSE_POOL` override `main` and `pool`; `PEBTREE_TICKETS_URL` and `PEBTREE_TICKETS_KEY` override `tickets`.

### Tickets

The Tickets tab works off a project's engineering tickets API, the contract in the table under "Contracts with other tools".
pebtree polls it every minute with the incremental `updated_since` cursor and shows open tickets with their status, kind, priority, requester, tree and PR.
From a ticket you can set its status, save notes, and **Start in a new tree**: it spins off a tree with the ticket as the brief and marks the ticket `in_progress` with that tree.
Once that tree has a PR, pebtree writes the PR link back to the ticket.

The key is the server's `PEBTREE_API_KEY`, a secret your API checks as a Bearer token (make one with `openssl rand -hex 32`).
To save it, copy its value and run `pebtree tickets-key`: it reads the clipboard, writes `config.json` as owner-only, and never prints the key.
It lives only in `config.json`, is sent only in the `Authorization` header, and is never logged or shown on the page.
`pebtree doctor` checks the API answers with it.
`pebtree --port <n>` serves on another port.

pebtree follows one project at a time.
To switch projects, run `pebtree init` in the other project and restart pebtree.

Settings you change on the page (tree cap, idle minutes, dev-server budget, journal on or off) live in `settings.json` next to it.

## What it reads and writes

It writes inside `~/.config/pebtree/`, plus one folder per tree for what you drop into a session:

| File | Holds |
|---|---|
| `config.json` | The setup above |
| `token` (mode 0600) | The secret the page sends with every action, so other websites cannot trigger actions |
| `settings.json` | Settings from the Settings page |
| `ui.json` | Layout and choices from the page: column widths, pinned, skipped and hidden PRs, card order |
| `titles.json` | Names you gave sessions |
| `actions.jsonl`, `history.jsonl` | The action log and 24 hours of resource history |
| `proof/`, `journal/`, `spinoffs/` | Proof entries, journal entries, spin-off briefs |
| `tickets.json` | Which tree pebtree started each ticket in, so its PR can be written back |
| `uploads/` | Images pasted into a reply when no tree is known (otherwise they go to the tree, below) |

Files, folders and images you drop or paste into a session's reply are copied to `<tree>/.pebtree-drops/` (git-ignored by a `.gitignore` pebtree writes there), and the copy's path goes into the message.
The page reads the dropped files itself and uploads them, so it works wherever they came from; the originals are never touched.

It reads, and never changes:

- `~/.claude/sessions/*.json` and `~/.claude/projects/**` for sessions, transcripts and subagents;
- `~/.claude/skills`, `.claude/skills` in the repo and enabled plugins, for the `/` list;
- `ps`, `lsof`, `vm_stat`, `sysctl`, `top` for processes and memory;
- iTerm2 tab titles and screen contents;
- `treehouse status`, `git` in each tree, and `gh-axi pr list` / `pr view`.

It changes things only when you click: it types into a session's iTerm tab, stops processes you choose, runs the teardown command and `treehouse return`, renames simulators and sessions.

## Contracts with other tools

pebtree reads formats it does not own.
When one of these changes, the matching feature breaks; this table says where to look.

| Depends on | Format it expects | Code to update |
|---|---|---|
| Claude Code session map | `~/.claude/sessions/<pid>.json` with `sessionId` | `sessionFileFor` |
| Claude Code transcripts | `~/.claude/projects/<dir with / and . as ->/<sessionId>.jsonl`, one JSON entry per line (`type`, `message.content`, `timestamp`, `isSidechain`) | `transcriptInfo`, `chatHistory` |
| Claude Code subagents | `<sessionId>/subagents/<id>.jsonl` plus `<id>.meta.json` (`description`, `agentType`, `finished`) | `subagentsFor`, `/api/subchat` |
| Claude Code PR links | `{"type":"pr-link","prNumber":…}` entries in the transcript | `prLinks` |
| Claude Code tab titles | `✳` first when waiting, a spinner glyph when working | `claudeStateFromTitle` |
| Claude Code menus on screen | Numbered options with an `Esc to cancel` or `Enter to select` footer; `Ready to submit your answers?` | `parseMenu` |
| Claude Code status line | `· Verb… (12s · ↓ tokens)` | `liveStatus` |
| iTerm2 AppleScript | `tty`, `name`, `contents` of sessions; `write text … newline NO`, then a separate carriage return to submit | `readItermTitles`, `readScreens`, `writeToTty` |
| treehouse | `treehouse status` rows: `<N> <status> <path> [ttys]`; `treehouse get --lease`, `treehouse return <path> --force` | `readTreehouse`, `closeTree`, `spinoff` |
| gh-axi | `pr list --fields updatedAt,url` CSV rows; `pr view` lines `state:`, `merged:`, `merge_state:`, `checks:`; `api repos/<repo>/pulls?head=<owner>:<branch>` `number:` lines | `refreshPRs` |
| Tickets API | `GET /api/engineering/tickets?updated_since=` -> `{ tickets, next_updated_since, has_more }`; `PATCH /api/engineering/tickets/<id>` with `status`, `tree`, `pr_url`, `notes` | `pollTickets`, `tkPatch` |
| Captain decisions | `~/.claude/swarm/decisions.json`: `{ decisions: [{ id, status, worker, title, why, context, options: [{ label, reply, recommended }] }] }` | `readDecisions` |

After a Claude Code or treehouse upgrade, `pebtree doctor` plus a look at the Feed and one detail view is the smoke test.

## Hosts and tmux (this fork)

`~/.config/pebtree/config.json` (only `hosts` is needed for another machine; the rest is optional):

```json
{
  "localHost": "mac",
  "hosts": { "mininav": { "ssh": "mininav", "label": "mininav", "repoRoots": ["~/workspace"] } },
  "claudeArgs": ["--dangerously-skip-permissions"],
  "branchPrefix": "arnav/",
  "presets": [
    { "id": "tw", "label": "Ditto worktree", "host": "mininav", "kind": "tree", "repo": "~/workspace/cbc-ditto" },
    { "id": "cx", "label": "Codex workspace", "host": "mininav", "kind": "shell", "session": "codex", "repo": "~/workspace" },
    { "id": "hx", "label": "Hermes shell", "host": "mininav", "kind": "shell", "session": "hermes", "repo": "~/workspace/cbc-ditto", "cmd": "~/bin/hermes-shell" }
  ],
  "spinoff": { "host": "mininav", "repo": "~/workspace/cbc-ditto" }
}
```

| Key | Meaning |
|---|---|
| `hosts.<id>.ssh` | The ssh host to reach it by. `ssh <it>` must work without a prompt. The host needs Node 18+ and tmux (and treehouse and claude to start sessions there). |
| `hosts.<id>.repoRoots` | Folders whose git checkouts the New session dialog offers (default `~/workspace`, `~` there; `~`, `~/Developer`, `~/src`, `~/code` here) |
| `localHost` | This Mac's id in session ids (default `mac`) |
| `claudeArgs` | Flags every Claude pebtree starts gets |
| `presets` | One-click starts on the Terminals page and `pebtree new <id>`. `kind`: `tree` (Claude in a fresh treehouse worktree of `repo`), `claude`, `codex`, `shell` (with `session` it reuses that tmux session, like `tmux new -A`; `cmd` runs instead of a shell) |
| `spinoff` | Where a spin-off with no session to come from goes |
| `branchPrefix` | Prefix for spin-off branch names |

**Ids.** Every tree and session is `<host>:<repo>:<slot>`: a treehouse slot number, `main` for a checkout, `dir` for any other
folder (`mininav:cbc-ditto:24`, `mac:CatchBack:main`). The page shows them as "cbc-ditto 24 · mininav".

**The agent.** On connect pebtree compares a hash of itself with `~/.local/share/pebtree/sha` on the host and copies itself over
when they differ, then runs `node ~/.local/share/pebtree/pebtree agent` over one ssh connection: one JSON request per line on stdin,
one answer per line on stdout (`AGENT_OPS` in the code). It reconnects with backoff when the connection drops; sessions there
keep running in tmux meanwhile.

**Sessions it starts.** Each runs in its own detached tmux session from a script in `~/.local/share/pebtree/launch/` on its host:
`tw-<repo>-<N>` for a worktree (the same contract as `tw`: when Claude exits or the session is killed the worktree goes back to the
pool, and treehouse keeps it leased while it has uncommitted changes), `cl-…`, `cx-…`, `sh-…` otherwise.

**Stale trees.** A pool slot treehouse has leased (v3) or that has a live owner (v2), with no Claude process in it, is listed on the
Terminals page under "Where you left off". Attach opens the tmux session still in it; Resume starts `claude --continue` there
(plain `claude` if it never had a conversation); Return runs `treehouse return --force` after checking for uncommitted changes.

**Terminals in the page** need python3 on this Mac (it gives `tmux attach`, or `ssh -tt <host> tmux attach`, a pty). xterm.js is
fetched once from jsDelivr, checked against pinned SHA-256 hashes, and kept in `~/.config/pebtree/vendor/`.

**PRs** come from `gh pr list -R <owner/repo>` for every repo a tree belongs to, and `gh pr view` for merge state.

**Without iTerm2.** Sessions in iTerm2 tabs are still followed (read and typed into with AppleScript); everything started from the
dashboard lives in tmux instead.

## Security

- It listens on 127.0.0.1 only; nothing is reachable from the network.
- Every action needs the token in `~/.config/pebtree/token`, which the page embeds; a page from another site cannot post actions.
- Sending a reply types into your terminal as you.
  A question or permission prompt open on screen is never answered by a reply: free-text questions get your text as their answer, and anything else is refused until you pick an option.
- It stores no credentials and never reads `.env` files.

## Sharing it with someone else

Send them this repo (or `bin/pebtree`, `skills/` and this document).
They follow "Set it up on a new Mac".
Nothing in pebtree is specific to one project once `config.json` is written; the defaults in the code are only a fallback for the original machine.

## treehouse

treehouse is the CLI that keeps a pool of reusable git worktrees so several agents can work on one repo at once.
pebtree treats each pool slot as a tree, numbered as treehouse numbers them, plus `main` for the main checkout.
If you have a script that stops a tree's dev servers, set it as `teardown` and Close tree runs it first.

## Troubleshooting

| You see | Do |
|---|---|
| "pebtree is not running" on the page | Start `pebtree`; the page reconnects by itself |
| Empty feed, sessions exist | `pebtree doctor`; check the Automation permission and that sessions run in iTerm2 |
| A question is in the terminal but not on the page | Make sure the question is visible in its tab (scrolled to the bottom); it is read off the screen |
| PRs without status | `npx -y gh-axi pr list` must work in `main` (GitHub login) |
| Close tree did not stop servers | Check `teardown` in `config.json` with `pebtree doctor` |
| Side panel shows "Side panel error" | The message names the failing code; send it to whoever maintains your copy |
