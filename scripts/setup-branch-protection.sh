#!/usr/bin/env bash
#
# Setup branch protection rules for a Perimentex project repo.
# Requires: gh CLI authenticated with admin access to the org.
#
# Usage:
#   ./scripts/setup-branch-protection.sh <owner/repo>
#
# Example:
#   ./scripts/setup-branch-protection.sh perimentex/crypto-board
#

set -euo pipefail

REPO="${1:?Usage: $0 <owner/repo>}"

echo "🔒 Setting up branch protection for: $REPO"
echo "================================================"

# ── Main branch protection ────────────────────────────────────────────
echo ""
echo "→ Protecting 'main' branch..."

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Validate Branch Name (Linear)",
      "Lint & Format Check",
      "Unit & Integration Tests",
      "Security Scan",
      "Build Docker Image"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF

echo "✅ Main branch protected"

# ── Rulesets for additional controls ──────────────────────────────────
# Rulesets provide finer-grained control than legacy branch protection.
# Uncomment if your org plan supports them (Team or Enterprise).

# echo ""
# echo "→ Creating commit signing ruleset..."
# gh api \
#   --method POST \
#   -H "Accept: application/vnd.github+json" \
#   "/repos/${REPO}/rulesets" \
#   --input - <<'RULESET'
# {
#   "name": "Require signed commits",
#   "target": "branch",
#   "enforcement": "active",
#   "conditions": {
#     "ref_name": {
#       "include": ["refs/heads/main"],
#       "exclude": []
#     }
#   },
#   "rules": [
#     { "type": "required_signatures" }
#   ]
# }
# RULESET
# echo "✅ Commit signing ruleset created"

# ── Tag protection ────────────────────────────────────────────────────
echo ""
echo "→ Protecting release tags (v*)..."

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/tags/protection" \
  --input - <<'EOF'
{
  "pattern": "v*"
}
EOF

echo "✅ Tag protection set for v* pattern"

# ── Environment protection ────────────────────────────────────────────
# Uncomment when you're ready to deploy beyond local development:
#
# echo ""
# echo "→ Creating 'staging' environment..."
# gh api \
#   --method PUT \
#   -H "Accept: application/vnd.github+json" \
#   "/repos/${REPO}/environments/staging" \
#   --input - <<'EOF'
# {
#   "deployment_branch_policy": {
#     "protected_branches": true,
#     "custom_branch_policies": false
#   }
# }
# EOF
# echo "✅ Staging environment created"
#
# echo ""
# echo "→ Creating 'production' environment with required reviewers..."
# gh api \
#   --method PUT \
#   -H "Accept: application/vnd.github+json" \
#   "/repos/${REPO}/environments/production" \
#   --input - <<'EOF'
# {
#   "deployment_branch_policy": {
#     "protected_branches": true,
#     "custom_branch_policies": false
#   },
#   "wait_timer": 5
# }
# EOF
# echo "✅ Production environment created"

# ── Repository settings ──────────────────────────────────────────────
echo ""
echo "→ Configuring repository settings..."

gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}" \
  --input - <<'EOF'
{
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "squash_merge_commit_title": "PR_TITLE",
  "squash_merge_commit_message": "PR_BODY",
  "delete_branch_on_merge": false,
  "allow_auto_merge": true
}
EOF

echo "✅ Repo settings configured (squash-only, branches preserved)"

echo ""
echo "================================================"
echo "🎉 Done! Branch protection fully configured for ${REPO}"
echo ""
echo "Summary of what was set:"
echo "  • Branch names must match Linear issue format"
echo "  • main: protected, CI must pass before merge"
echo "  • No review requirement (re-enable via CODEOWNERS when ready)"
echo "  • Linear history enforced (squash merge only)"
echo "  • No force pushes, no branch deletion"
echo "  • Conversation resolution required"
echo "  • Tags matching v* protected"
echo "  • Merge strategy: squash-only, branches preserved after merge"
echo "  • Environments: commented out (local dev only until MVP)"
