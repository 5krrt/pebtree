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

Requirements: macOS, Node 18+, iTerm2 with your Claude Code sessions in its tabs, and treehouse.
`pebtree doctor` checks all of it.

## Make it yours

Fork it and change whatever you like; it is one file.
[docs/pebtree.md](docs/pebtree.md) covers the configuration, every file it reads and writes, and the formats it depends on (Claude Code transcripts, iTerm2, treehouse, gh-axi), so you know where to look when something upstream changes.
