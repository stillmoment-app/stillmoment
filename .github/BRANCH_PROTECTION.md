# GitHub Branch Protection Setup

This document describes the required Branch Protection Rules for the `main` branch.

## Setup Instructions

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Branches**
3. Click **Add rule** (or edit existing rule for `main`)
4. Configure as follows:

## Branch Protection Rules for `main`

### Branch Name Pattern
```
main
```

### Required Settings

#### ✅ Require a pull request before merging
- **Require approvals**: 1 (recommended for team projects, can be 0 for solo)
- **Dismiss stale pull request approvals when new commits are pushed**: ✅ Enabled
- **Require review from Code Owners**: ❌ Disabled (unless you have CODEOWNERS file)

#### ✅ Require status checks to pass before merging
- **Require branches to be up to date before merging**: ✅ Enabled

**Required Status Checks** (add these after first CI run):
- ✅ `Code Quality (SwiftLint + SwiftFormat)`
- ✅ `Build & Unit Tests`
- ✅ `UI Tests`
- ✅ `Static Analysis (Xcode Analyzer)`

**Note**: Status checks will only appear in the list after they've run at least once. Push your first commit to trigger the CI workflow, then add these checks.

#### ✅ Require conversation resolution before merging
- Ensures all PR comments are addressed before merging

#### ✅ Require signed commits (Optional)
- ❌ Disabled by default
- ✅ Enable if your team uses GPG signing

#### ✅ Include administrators
- Enforce all rules for administrators too
- Recommended for consistency

### Optional Settings

#### Do not allow bypassing the above settings
- ❌ Disabled (allows emergency fixes if needed)
- ✅ Enable for maximum strictness

#### Allow force pushes
- ❌ Disabled (recommended)
- Force pushes can break history and cause issues

#### Allow deletions
- ❌ Disabled (recommended)
- Prevents accidental branch deletion

## CI Workflow Status Checks

The CI workflow (`.github/workflows/ci.yml`) runs 4 parallel jobs:

1. **Code Quality (SwiftLint + SwiftFormat)** (~2-3 min)
   - SwiftLint strict mode
   - SwiftFormat lint check
   - **Blocks if**: Linting violations found

2. **Build & Unit Tests** (~3-5 min)
   - Builds app
   - Runs unit tests with coverage
   - **Blocks if**: Build fails, tests fail, or coverage <80%

3. **UI Tests** (~5-8 min)
   - Runs UI integration tests
   - **Blocks if**: UI tests fail

4. **Static Analysis (Xcode Analyzer)** (~2-3 min)
   - Runs Xcode static analyzer
   - **Blocks if**: Analyzer warnings found

## Coverage Comment Workflow

The `coverage-comment.yml` workflow runs after CI completes successfully:
- Posts coverage report as PR comment
- Updates comment on subsequent pushes
- Does not block merging (informational only)

## Verification

After setting up branch protection:

1. Create a test branch: `git checkout -b test/branch-protection`
2. Make a small change and push
3. Create a PR to `main`
4. Verify all 4 status checks appear and must pass
5. Verify you cannot merge until all checks pass
6. Verify coverage comment appears on PR

## Troubleshooting

### Status checks don't appear in branch protection settings
**Solution**: Status checks only appear after they've run at least once. Push code to trigger CI, then return to branch protection settings to add them.

### Accidentally broke main branch
**Solution**: If administrators are included in branch protection rules, you'll need to:
1. Temporarily disable branch protection
2. Fix the issue
3. Re-enable branch protection
4. (Better: Create a hotfix PR that passes all checks)

### CI is too slow
**Solution**:
- First run: 8-12 minutes (no cache)
- Subsequent runs: 3-5 minutes (with cache)
- If consistently slow, check GitHub Actions runner status

### False positives in static analysis
**Solution**: If Xcode Analyzer produces false positives:
1. Review the warning carefully
2. If legitimate false positive, add `// swiftlint:disable:next` comment
3. Document why it's a false positive
4. Consider making static analysis advisory instead of blocking (edit ci.yml)

## Updating These Rules

When CI workflow changes:
1. Update this document
2. Update branch protection rules in GitHub
3. Notify team members
4. Update `CLAUDE.md` if necessary
