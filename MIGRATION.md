# Migration: agency-plugin → gierd

This repo absorbed `~/Projects/agency-plugin`. To switch Grips (and other projects) over, follow these steps once this branch is merged and pushed to `gierd/dev-skills`.

## 1. Publish the fork

```bash
# from ~/Projects/dev-skills
git push origin gierd-fork
# open PR, merge to main
# create the GitHub remote if not yet pointed at gierd/dev-skills:
git remote set-url origin git@github.com:gierd/dev-skills.git
git push -u origin main
```

## 2. Install the new plugin

In any Claude Code session:

```
/plugin install gierd/dev-skills
```

(Or via the marketplace flow your team prefers — `npx skills@latest add gierd/dev-skills` works if you use the skills.sh marketplace.)

## 3. Disable / uninstall the old agency plugin

`installed_plugins.json` currently has an `agency@agency` entry pointing at `~/.claude/plugins/cache/agency/agency/0.1.0`. After the new plugin works:

```
/plugin disable agency
# or, to fully remove:
/plugin uninstall agency
```

Leave `~/Projects/agency-plugin/` on disk for reference (`DEPRECATED.md` was added there in this PR).

## 4. Verify in Grips

In `~/Projects/grips/`:

```
# Skills should resolve under the gierd: namespace
/gierd:status
/gierd:list
```

The `.agency/<feature>/` state directory is untouched, so any in-progress feature picks up where it left off.

## 5. No changes required to Grips' settings

`~/Projects/grips/.claude/settings.local.json` only contains permissions and hooks — it does not reference plugins by name. No edit needed there.
