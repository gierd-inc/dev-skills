Skills are organized into bucket folders under `skills/`:

- `engineering/` — daily code work, process tools (grill, triage, tdd, etc.)
- `rails/` — Rails-domain references, loaded on-demand
- `oop/` — OOP design patterns for Rails (value objects, presenters, service objects, etc.)
- `rails-antipatterns/` — named Rails antipatterns with idiomatic fixes
- `agency/` — Agency PRD-to-shipped workflow skills
- `productivity/` — daily non-code workflow tools
- `misc/` — kept around but rarely used
- `deprecated/` — no longer used

Every skill in `engineering/`, `rails/`, `oop/`, `rails-antipatterns/`, `agency/`, `productivity/`, or `misc/` must have a reference in the appropriate bucket `README.md`. The top-level `README.md` references each bucket's `README.md` (the rails and agency buckets are too large to enumerate inline). Skills in `deprecated/` must not appear in either.

The plugin uses Claude Code's auto-discovery from `skills/`, so `.claude-plugin/plugin.json` does not enumerate skills.

Slash commands under `commands/` are namespaced as `/gierd:<command>` because the plugin is named `gierd`.

Each skill entry in a bucket README must link the skill name to its `SKILL.md`. Each bucket folder has a `README.md` that lists every skill in the bucket with a one-line description.
