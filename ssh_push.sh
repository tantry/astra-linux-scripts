#!/bin/bash
# Generic safe GitHub push using SSH
# Works in any git repository, converts HTTPS remote to SSH if needed.
# Assumes SSH key is already added to GitHub (test with: ssh -T git@github.com)

set -e  # Exit on error

# ---------- Functions ----------
error_exit() {
    echo "❌ ERROR: $1"
    exit 1
}

check_ssh() {
    echo "🔐 Checking SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "   ✓ SSH authentication OK"
    else
        echo "   ✗ SSH authentication failed."
        echo "   Please run: ssh -T git@github.com"
        echo "   and fix any issues (e.g., add your SSH key to GitHub)."
        exit 1
    fi
}

ensure_ssh_remote() {
    local current_url
    current_url=$(git remote get-url origin 2>/dev/null) || error_exit "No remote 'origin' found. Run: git remote add origin <url>"
    if [[ "$current_url" =~ ^https://github.com/ ]]; then
        local ssh_url
        ssh_url=$(echo "$current_url" | sed 's|https://github.com/|git@github.com:|')
        echo "🔁 Converting remote from HTTPS to SSH:"
        echo "   Old: $current_url"
        echo "   New: $ssh_url"
        git remote set-url origin "$ssh_url"
    elif [[ "$current_url" =~ ^git@github.com: ]]; then
        echo "✓ Remote already uses SSH: $current_url"
    else
        error_exit "Remote URL not recognized (should be github.com). Current: $current_url"
    fi
}

# ---------- Main ----------
echo "=== GitHub Push (SSH) ==="
echo "Repository: $(git remote get-url origin 2>/dev/null || echo 'unknown')"
echo ""

check_ssh

if [ ! -d ".git" ]; then
    echo "📦 Initializing git repository..."
    git init
    if git show-ref --verify --quiet refs/heads/main; then
        git checkout main
    elif git show-ref --verify --quiet refs/heads/master; then
        git checkout master
    else
        git checkout -b main 2>/dev/null || git checkout -b master
    fi
fi

ensure_ssh_remote

if [ -z "$(git config user.name)" ]; then
    git config user.name "$(whoami)"
fi
if [ -z "$(git config user.email)" ]; then
    git config user.email "$(whoami)@users.noreply.github.com"
fi

echo ""
echo "📊 CURRENT GIT STATUS:"
echo "----------------------"
git status --short
echo ""

echo "📦 SELECT FILES TO ADD:"
echo "   a) Add ALL changes (including untracked)"
echo "   b) Add only modified/deleted files (no untracked)"
echo "   c) Cancel"
read -p "   Your choice (a/b/c): " choice

case $choice in
    a)
        echo "   Adding ALL changes..."
        git add .
        ;;
    b)
        echo "   Adding modified/deleted files..."
        git add -u
        ;;
    c)
        echo "   Cancelled."
        exit 0
        ;;
    *)
        error_exit "Invalid choice"
        ;;
esac

echo ""
echo "✅ STAGED CHANGES:"
echo "-----------------"
git diff --cached --name-status
echo ""

if git diff --cached --quiet; then
    echo "📭 No changes staged. Nothing to commit."
    exit 0
fi

echo "💾 COMMIT CHANGES:"
read -p "   Commit message (Enter for default): " user_msg
if [ -z "$user_msg" ]; then
    user_msg="Update: $(date '+%Y-%m-%d %H:%M:%S') - $(hostname)"
fi

git commit -m "$user_msg"
echo "   ✅ Commit created."

current_branch=$(git branch --show-current)

echo ""
echo "🚀 PUSH TO GITHUB:"
echo "   Remote: $(git remote get-url origin)"
echo "   Branch: $current_branch"
read -p "   Push these changes? (y/N): " push_choice

if [[ $push_choice =~ ^[Yy]$ ]]; then
    echo "   Pushing..."
    if git push -u origin "$current_branch"; then
        echo "   ✅ Successfully pushed to GitHub!"
        repo_display=$(git remote get-url origin | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
        echo "   🌐 View: $repo_display"
    else
        echo "   ❌ Push failed."
        echo "   Try: git pull --rebase origin $current_branch"
        echo "   Then run this script again."
        exit 1
    fi
else
    echo "   Changes committed locally but NOT pushed."
    echo "   Run 'git push origin $current_branch' manually when ready."
fi

echo ""
echo "=== Complete ==="
