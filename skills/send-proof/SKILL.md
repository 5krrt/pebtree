---
name: send-proof
description: Send the user proof of finished work - screenshots, GIFs or recordings of the UI, and test or check output with its pass/fail - to their pebtree dashboard (Proof tab). Use when finishing a task that changed UI or behavior, before saying work is done or ready to merge, after an E2E check in Chrome, or when the user asks for proof, evidence, screenshots or test results.
---

# Send proof to pebtree

The user reviews work from many trees on one page: http://localhost:4777/#proof.
Every entry shows the tree and branch it came from, so run the command from inside your worktree.

## Commands

```bash
# screenshots / GIFs / screen recordings (png, jpg, gif, webp, mp4, mov, webm)
pebtree proof before-390.png after-390.png after-1440.png \
  --title "Pack page fits at phone width" \
  --note "Before/after at 390px; laptop at 1440 unchanged."

# a test or check: output and exit code are recorded, passed/failed is shown
pebtree proof --title "Rarity tier tests" --run "pnpm test:rarity-tier"

# both in one entry
pebtree proof flow.gif --title "Gift flow end to end" --run "pnpm test:all"
```

`--run` exits with the command's own exit code, so a failing run is still recorded and you still see the failure.

## What good proof looks like

- **Title says what is proven**, in the user's terms ("Swipe no longer sticks between packs"), not what was run.
- **UI changes:** before and after, at phone width (390) and laptop (1440) when the surface has both; a GIF for anything that moves.
- **Bug fixes:** the reproduction before the fix and the same steps after.
- **Tests:** the narrowest command that covers the change, plus lint/typecheck when they are part of the claim.
- **Note:** one or two lines on what to look at, and anything not covered (e.g. "mobile app not run; device checklist in the PR").

Chrome screenshots: the Chrome tool's `save_to_disk: true` returns a file path you can pass straight to `pebtree proof`.

Send proof once per finished piece of work, not after every step. Never include secrets, tokens or customer personal data in screenshots or output.
