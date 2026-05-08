# Issue tracker: Linear

Issues and PRDs for this repo live in Linear. Use the Linear MCP tools for all operations.

## Conventions

- **Create an issue**: `mcp__claude_ai_Linear__save_issue` with `title`, `description` (markdown), `team`, and any labels. Linear issue IDs look like `GRP-1234`.
- **Read an issue**: `mcp__claude_ai_Linear__get_issue` by ID. Use `mcp__claude_ai_Linear__list_comments` for the comment thread.
- **List issues**: `mcp__claude_ai_Linear__list_issues` filtered by team, state, label, or assignee.
- **Comment on an issue**: `mcp__claude_ai_Linear__save_comment` with the issue ID and body.
- **Apply / remove labels**: `mcp__claude_ai_Linear__save_issue` with the updated `labels` array (Linear replaces, not appends).
- **Close**: `mcp__claude_ai_Linear__save_issue` with the issue's terminal state (e.g. `Done`, `Cancelled`). Use `mcp__claude_ai_Linear__list_issue_statuses` to find the right state ID for the team.

Always pass markdown content with real newlines, not literal `\n` escape sequences.

## When a skill says "publish to the issue tracker"

Create a Linear issue in the team configured for this repo. If the team is ambiguous, ask the user before creating.

## When a skill says "fetch the relevant ticket"

Call `mcp__claude_ai_Linear__get_issue` with the Linear issue ID (e.g. `GRP-1234`).

## Cross-linking with GitHub PRs

When opening a PR for a Linear issue, include the Linear ID in the PR title (e.g. `GRP-1234: Fix pricing rollup`). Linear's GitHub integration will pick it up and link the PR to the issue automatically.
