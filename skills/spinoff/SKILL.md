---
name: spinoff
description: Hand an unrelated task off to a fresh treehouse tree with its own Claude session, instead of doing it in the current tree. Use when the user says "spin this off", "siphon this", "do that in another tree", "start a new tree for this", "have another session do X", or asks for a change unrelated to the current tree's work while this tree is mid-task.
---

# Spin a task off to a new tree

The user is in the middle of something here and wants an unrelated change done elsewhere.
Do not make that change in this tree. Write a brief, run one command, and report the tree number.

## 1. Write the brief

The new session starts with no memory of this conversation, so the brief is everything it knows.
Write it to a file in your scratchpad (or `/tmp`), in plain words:

- **Goal:** what to change and why, in the user's terms.
- **Context:** files, functions, error text, PR or Sentry links, anything you already found. Quote exact paths.
- **Constraints:** what not to touch, decisions the user already made, relevant gotchas from CLAUDE.md or docs.
- **Done when:** how to check it works (test command, page to look at in Chrome).

Keep it self-contained and short. Never put secrets, tokens or customer personal data in it.

## 2. Spin it off

```bash
pebtree spinoff --title "Short name, under 50 chars" --from <this tree's number> --brief-file /path/to/brief.md
```

It leases a free tree from the treehouse pool, opens a new iTerm tab in the background (focus stays on the user's tab), and starts Claude there named after the title.
The new session is told to check the tree is clean, create `az/<title-slug>` from `origin/master`, do the task, commit, and ask before pushing.
It shows up in the user's pebtree feed (http://localhost:4777) when it needs them.

Find this tree's number from the path: `~/.treehouse/<pool>/<N>/<repo>` (use `main` for the main checkout).

If it prints `no free tree in the pool`, tell the user; do not take one by hand.

## 3. Report

One or two lines: which tree took it, the branch name, and that you are carrying on with the current work.
Then continue what you were doing here.
