---
description: One-time prerequisites check / install for the Gierd Dev Skills plugin. Verifies worktrunk, jq, and gh; warns on missing critical skills.
---

You are running Gierd Dev Skills' preflight setup.

## Required tools

For each, check `command -v <tool>`:

1. **`jq`** — required for state.sh. If missing: tell the user to install via their package manager (`apt install jq`, `brew install jq`, etc.). Do not auto-install.
2. **`gh`** — GitHub CLI, used as a fallback to the GitHub MCP. If missing: tell the user to install (`brew install gh`, `apt install gh`).
3. **`wt`** — worktrunk. Required for `/build`. If missing:
   - Show the user the install instructions from https://worktrunk.dev.
   - Offer to run the install command if you can determine the platform.
   - Otherwise print the documented install one-liner and stop.

## Required skills

Probe (best effort) the user's installed skills. The following are leaned on heavily and Gierd Dev Skills degrades meaningfully without them. Warn (do not fail) if missing:

- `brainstorming`
- `writing-plans`
- `tdd` or `test-driven-development`
- `verification-before-completion`
- `requesting-code-review`
- `create-pull-request`

If you cannot enumerate skills directly, tell the user which skills Gierd Dev Skills benefits from and ask them to confirm presence.

## Repo prep

- Ensure `.dev-skills/` is in `.gitignore`. If a project root `.gitignore` exists and doesn't list it, append a line `.dev-skills/`.
- Ensure `scripts/` is executable (`chmod +x scripts/*.sh`).

## Output

Print a checklist:
```
[x] jq                    available
[x] gh                    available
[ ] wt (worktrunk)        MISSING — install: ...
[x] .dev-skills/ in .gitignore
```

Stop. Do not dispatch any subagents.
