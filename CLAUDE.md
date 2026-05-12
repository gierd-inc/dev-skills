Skills are organized under `skills/`:

- `engineering/` — daily code work, process tools (grill, triage, tdd, etc.)
- `rails-expert/` — hub-and-spoke Rails skill; `SKILL.md` is the hub, `references/` holds one file per layer
- `oop/` — hub-and-spoke OOP patterns skill; `SKILL.md` is the hub, `references/` holds one file per pattern
- `rails-antipatterns/` — hub-and-spoke antipatterns skill; `SKILL.md` is the hub, `references/` holds one file per smell
- `agency/` — Gierd Dev Skills PRD-to-shipped workflow skills
- `productivity/` — daily non-code workflow tools
- `misc/` — kept around but rarely used
- `deprecated/` — no longer used

Every skill in `engineering/`, `agency/`, `productivity/`, or `misc/` must have a reference in that bucket's `README.md`. The three hub skills (`rails-expert`, `oop`, `rails-antipatterns`) are self-indexing — their `SKILL.md` contains the routing table; no bucket `README.md` is needed for them. Skills in `deprecated/` must not appear in any README.

The plugin uses Claude Code's auto-discovery from `skills/`, so `.claude-plugin/plugin.json` does not enumerate skills.

Slash commands under `commands/` are namespaced as `/gierd:<command>` because the plugin is named `gierd`.

Each skill entry in a bucket README must link the skill name to its `SKILL.md`. Each bucket folder has a `README.md` that lists every skill in the bucket with a one-line description (except the three hub skills, which are self-indexed).
