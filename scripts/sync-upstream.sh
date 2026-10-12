#!/usr/bin/env bash
#
# scripts/sync-upstream.sh — Automated upstream synchronization script
# for Antigravity-Game-Studios (forked from Claude-Code-Game-Studios).
#
# Usage:
#   bash scripts/sync-upstream.sh             # Fetch and merge upstream changes
#   bash scripts/sync-upstream.sh --check     # Check for new upstream commits without merging
#   bash scripts/sync-upstream.sh --repair    # Only verify and fix symlinks/permissions
#   bash scripts/sync-upstream.sh --help      # Show help message
#

set -euo pipefail

# --- Root Resolution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
cd "$ROOT"

UPSTREAM_REMOTE="upstream"
UPSTREAM_URL="https://github.com/Donchitos/Claude-Code-Game-Studios.git"
UPSTREAM_BRANCH="main"
MODE="sync"

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check|--dry-run)
      MODE="check"
      shift
      ;;
    --repair|--fix-symlinks)
      MODE="repair"
      shift
      ;;
    --remote)
      UPSTREAM_REMOTE="$2"
      shift 2
      ;;
    --url)
      UPSTREAM_URL="$2"
      shift 2
      ;;
    --branch)
      UPSTREAM_BRANCH="$2"
      shift 2
      ;;
    -h|--help)
      echo "Antigravity Game Studios — Upstream Fork Synchronization Tool"
      echo ""
      echo "Usage:"
      echo "  bash scripts/sync-upstream.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --check, --dry-run    Check for upstream updates without modifying the working tree"
      echo "  --repair              Verify and repair symlinks & permissions only (no git fetch/merge)"
      echo "  --remote <name>       Name of upstream remote (default: 'upstream')"
      echo "  --url <url>           URL of upstream repository (default: '$UPSTREAM_URL')"
      echo "  --branch <branch>     Upstream branch to track (default: 'main')"
      echo "  -h, --help            Show this help text"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- Helper Functions ---
say()  { echo "[$1] $2"; }
info() { say "INFO" "$*"; }
warn() { say "WARN" "$*"; }
pass() { say "PASS" "$*"; }
fail() { say "FAIL" "$*" >&2; }

ensure_symlink() {
  local target="$1"
  local link_name="$2"
  
  if [ -L "$link_name" ]; then
    local current_target
    current_target=$(readlink "$link_name")
    if [ "$current_target" != "$target" ]; then
      warn "Symlink $link_name points to $current_target, correcting to $target..."
      rm -f "$link_name"
      ln -sf "$target" "$link_name"
    fi
  elif [ -e "$link_name" ]; then
    warn "$link_name exists but is not a symlink! Retaining existing file/dir."
  else
    info "Creating symlink: $link_name -> $target"
    ln -sf "$target" "$link_name"
  fi
}

repair_architecture() {
  info "Verifying and repairing Antigravity architecture symlinks and permissions..."
  
  # 1. Root core symlinks
  ensure_symlink ".claude" ".agent"
  ensure_symlink ".claude" ".antigravity"
  ensure_symlink "ANTIGRAVITY.md" "GEMINI.md"
  ensure_symlink "ANTIGRAVITY.md" "AGENTS.md"
  
  # 2. Workflows symlink inside .claude
  if [ -d ".claude" ]; then
    (cd .claude && ensure_symlink "skills" "workflows")
  fi
  
  # 3. Subdirectory instructions symlinks
  for dir in design docs src "CCGS Skill Testing Framework"; do
    if [ -d "$dir" ]; then
      (
        cd "$dir"
        ensure_symlink "CLAUDE.md" "ANTIGRAVITY.md"
        ensure_symlink "ANTIGRAVITY.md" "GEMINI.md"
        ensure_symlink "ANTIGRAVITY.md" "AGENTS.md"
      )
    fi
  done
  
  # 4. Testing framework alias & documentation symlinks
  if [ -d "CCGS Skill Testing Framework" ]; then
    ensure_symlink "CCGS Skill Testing Framework" "AGS Skill Testing Framework"
  fi
  if [ -d "docs" ] && [ -f "FORK-SYNC-GUIDE.md" ]; then
    (cd docs && ensure_symlink "../FORK-SYNC-GUIDE.md" "FORK-SYNC-GUIDE.md")
  fi
  
  # 5. Fix executable permissions for scripts and hooks
  chmod +x .claude/hooks/*.sh 2>/dev/null || true
  chmod +x .claude/scripts/*.sh 2>/dev/null || true
  chmod +x .claude/statusline.sh 2>/dev/null || true
  chmod +x scripts/*.sh 2>/dev/null || true
  chmod +x scripts/*.py 2>/dev/null || true
  
  pass "All symlinks and script permissions are in order."
}

if [ "$MODE" = "repair" ]; then
  repair_architecture
  exit 0
fi

# --- Check Git Working Tree ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "Not inside a valid git repository!"
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  warn "Working tree has unstaged or uncommitted changes."
  if [ "$MODE" = "sync" ]; then
    fail "Aborting merge to prevent accidental conflicts. Please commit or stash your changes before running sync."
    exit 1
  fi
fi

# --- Configure Upstream Remote ---
if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  info "Remote '$UPSTREAM_REMOTE' does not exist. Adding: $UPSTREAM_URL"
  git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
else
  info "Using existing remote '$UPSTREAM_REMOTE' ($(git remote get-url "$UPSTREAM_REMOTE"))"
fi

# --- Fetch Upstream ---
info "Fetching upstream updates from $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

UPSTREAM_REF="$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
BEHIND_COUNT=$(git rev-list --count HEAD.."$UPSTREAM_REF")

if [ "$BEHIND_COUNT" -eq 0 ]; then
  pass "Your branch '$CURRENT_BRANCH' is already completely up to date with upstream '$UPSTREAM_REF'."
  repair_architecture
  exit 0
fi

info "Upstream has $BEHIND_COUNT new commit(s) ready to be merged:"
git log --oneline -n 10 HEAD.."$UPSTREAM_REF"

if [ "$MODE" = "check" ]; then
  info "Mode is --check. Exiting without merging."
  exit 0
fi

# --- Perform Merge ---
info "Merging $UPSTREAM_REF into '$CURRENT_BRANCH'..."
if git merge "$UPSTREAM_REF" --no-edit -m "chore(sync): merge upstream $UPSTREAM_BRANCH into $CURRENT_BRANCH"; then
  pass "Successfully merged upstream commits!"
else
  fail "Merge conflict detected! Please resolve conflicts manually, then run: bash scripts/sync-upstream.sh --repair"
  exit 1
fi

# --- Post-Merge Architecture Verification ---
repair_architecture

# --- Run Project Coherence Check ---
if [ -f ".claude/scripts/project-coherence.sh" ]; then
  info "Running coherence check..."
  bash .claude/scripts/project-coherence.sh || true
fi

pass "Fork sync completed successfully! Your Antigravity Game Studios repository is up to date."
