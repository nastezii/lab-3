# Branch Protection Rules

To ensure code quality and prevent merging of code that doesn't meet requirements, configure branch protection for your main/master branch:

## Required Settings

### 1. Branch Protection Rules

In GitHub repository settings > Branches > Branch protection rule:

**Branch name pattern:** `main` or `master`

**Require status checks to pass before merging:**
- [x] Require status checks to pass before merging
- [ ] Require branches to be up to date before merging

**Required status checks:**
- [x] code-analysis (flake8, mypy, tests, coverage)
- [x] dockerfile-lint (hadolint)
- [x] build (Docker image build)

**Additional protections:**
- [x] Require pull request reviews before merging
- [x] Dismiss stale PR approvals when new commits are pushed
- [x] Require review from CODE OWNERS
- [x] Restrict who can dismiss pull request reviews
- [x] Limit who can push to matching branches
- [x] Allow force pushes
- [ ] Allow deletions

### 2. CODEOWNERS File

Create `.github/CODEOWNERS`:

```
# Default code owners
* @your-username
```

### 3. Pull Request Templates

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] All tests pass
- [ ] Code coverage is >= 40%
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated if needed
```

## Enforcement

These settings ensure:
1. All code passes automated tests and analysis
2. Coverage requirements are met (40% minimum)
3. Code is reviewed before merging
4. Docker images build successfully
5. No direct pushes to main branch

## Verification

Test the protection by:
1. Creating a PR with failing tests - should be blocked
2. Creating a PR with passing tests - should be mergeable
3. Attempting direct push to main - should be blocked
