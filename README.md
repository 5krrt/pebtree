# pebtree

A local dashboard for running many Claude Code sessions in parallel, one per git worktree.
It shows which sessions are waiting on you and lets you answer them from one feed, shows what every tree is running and what it costs your Mac, and gives you controls to stop, clean up and close trees.

It is one dependency-free Node file, `bin/pebtree`, served at http://localhost:4777 and bound to 127.0.0.1 only.
It sits on top of [treehouse](https://github.com/kunchenguid/treehouse), which keeps the pool of reusable worktrees.

## Install

```bash
git clone https://github.com/alx-zheng/pebtree.git ~/pebtree
~/pebtree/install.sh
```

The script installs treehouse if you don't have it, links `pebtree` into `~/.local/bin`, and copies two optional Claude skills (`send-proof`, `spinoff`).
Then, in your project's main checkout: `pebtree init`, `pebtree doctor`, `pebtree`.

Requirements: macOS, Node 18+, tmux, python3, treehouse and `gh`. iTerm2 is optional: sessions already in its tabs are followed too.

## This fork: every machine, in one place

This branch follows Claude Code sessions on this Mac **and on other machines over ssh**, and replaces the
`ssh` + iTerm-tab + alias workflow (`tw`, `cx`, `hx`) with the dashboard:

- **Hosts.** Each machine in `config.json` `"hosts"` runs `pebtree agent` (this same file, copied over ssh and kept up to date
  automatically) on one long-lived connection that reconnects by itself. Sessions there show in the same feed: reply, answer
  questions and permission prompts, read the conversation, paste images (they land in that machine's tree).
- **Sessions live in tmux, on their host.** A dropped ssh connection, a sleeping laptop or a closed browser tab never ends one.
- **Terminals page.** Every tmux session on every host, attached right in the page (xterm.js); tabs reattach on their own after a
  drop. Closing a tab only detaches.
- **New session** (⌘N, or a preset): Claude in a fresh treehouse worktree (what `tw` did), Claude or Codex in a checkout, or a shell,
  on any host. `pebtree new <preset>` does the same from a terminal and attaches it there.
- **Where you left off.** A worktree you still hold with nothing running in it (ssh dropped, Claude exited, you forgot where you
  were) is listed with its branch, changes and last message, with **Attach / Resume** (Claude `--continue` in that same worktree)
  and **Return** (back to the pool).

See [docs/pebtree.md](docs/pebtree.md#hosts-and-tmux-this-fork) for the config.
`pebtree doctor` checks all of it.

## Make it yours

Fork it and change whatever you like; it is one file.
[docs/pebtree.md](docs/pebtree.md) covers the configuration, every file it reads and writes, and the formats it depends on (Claude Code transcripts, iTerm2, treehouse, gh-axi), so you know where to look when something upstream changes.
