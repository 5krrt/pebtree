#!/bin/sh
# Installs pebtree and what it needs: treehouse, and a link to bin/pebtree on your PATH.
# Safe to run again. It never touches your projects; `pebtree init` does the per-project setup.
set -e
here=$(cd "$(dirname "$0")" && pwd)
bindir="$HOME/.local/bin"

[ "$(uname)" = "Darwin" ] || { echo "pebtree needs macOS (it reads memory and processes with macOS tools)."; exit 1; }

if ! command -v node >/dev/null 2>&1; then
  echo "Node 18 or newer is required: brew install node"; exit 1
fi
major=$(node -p 'process.versions.node.split(".")[0]')
[ "$major" -ge 18 ] || { echo "Node $major is too old; pebtree needs 18 or newer."; exit 1; }

if command -v treehouse >/dev/null 2>&1; then
  echo "treehouse: already installed ($(treehouse --version 2>/dev/null | head -1))"
else
  echo "treehouse: installing from https://github.com/kunchenguid/treehouse"
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

[ -d /Applications/iTerm.app ] || echo "note: pebtree reads and types into iTerm2 tabs. Install it: brew install --cask iterm2"
command -v claude >/dev/null 2>&1 || echo "note: Claude Code is not on your PATH. Install it: npm i -g @anthropic-ai/claude-code"

mkdir -p "$bindir"
chmod +x "$here/bin/pebtree"
ln -sf "$here/bin/pebtree" "$bindir/pebtree"
echo "pebtree: linked $bindir/pebtree -> $here/bin/pebtree"
case ":$PATH:" in *":$bindir:"*) ;; *) echo "note: add $bindir to your PATH (in ~/.zshrc): export PATH=\"\$HOME/.local/bin:\$PATH\"";; esac

if [ -d "$HOME/.claude" ]; then
  mkdir -p "$HOME/.claude/skills"
  for s in send-proof spinoff; do
    if [ -e "$HOME/.claude/skills/$s" ]; then echo "skill $s: already there, left as is"; else cp -R "$here/skills/$s" "$HOME/.claude/skills/" && echo "skill $s: installed"; fi
  done
fi

cat <<'NEXT'

Next:
  cd ~/code/your-project     # your project's main checkout
  treehouse get --lease      # once, so the pool exists (then: treehouse return <path>)
  pebtree init               # writes ~/.config/pebtree/config.json
  pebtree doctor             # checks everything and says how to fix what is missing
  pebtree                    # then open http://localhost:4777
NEXT
