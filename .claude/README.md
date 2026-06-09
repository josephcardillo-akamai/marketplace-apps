# Marketplace App Workflow — Claude Code Skills

A chain of **user-invoked skills** that encode the team's end-to-end process for bringing apps
into the Linode Marketplace — both **backports** (legacy StackScript → modern Ansible playbook)
and **new apps** (R&D → playbook). Each skill does one phase, hands off through a per-app state
file, and **stops at a manual-review checkpoint** so a human verifies the work before the next
phase runs.

These live in `.claude/skills/` and are shared by the whole team. They were previously in a
private experimental repo; this is the consolidated, reviewable home.

> **Skills vs. commands.** Custom commands are deprecated and merged into skills, so the pipeline
> ships as skills (`.claude/skills/<name>/SKILL.md`). Each carries `disable-model-invocation: true`
> so it is **only ever run when you type `/<name>`** — Claude never auto-triggers a phase. Skill
> names come from the directory, so they are flat + hyphenated (`/app-deploy`, not `/app:deploy`).
> Two older utilities remain as commands (`/review:validate-config`, `/setup-cloud-manager-dev`);
> skills and commands coexist fine.

## Order of operations

```
BACKPORT:  /backport-start <app> --stackscript <id> ─┐
NEW APP:   /newapp-start   <app> --repo <git-url>  ──┤   each →
                                                      ▼   architecture_decisions.md + STATE.md
            /app-manual-install <app>      ──STOP: SSH + UI login test the box──▶
            /app-ansibilize     <app>      ──STOP: inline review + local lint──▶
            /app-deploy         <app>      ──STOP: clean fresh deploy + smoke tests──▶
            /review:validate-config <app> --instance <ip>   ──STOP: directive matrix──▶
            /app-pr             <app>      ──▶ README (written last) + PR vs develop
```

`/backport-start` and `/newapp-start` are the two entry points — pick one per app. Everything from
`/app-manual-install` onward is identical for both. **You can also start at `/app-manual-install`**
if you did your own R&D and hand-wrote `architecture_decisions.md` + `STATE.md` — the pipeline only
needs grounded decisions to install against, not a particular skill that produced them.

| Phase | Skill / command | Owns artifact | Checkpoint before next |
|---|---|---|---|
| 1 Research / analyze | `/backport-start` or `/newapp-start` | `architecture_decisions.md` | decisions sound + cited |
| 2 Manual install | `/app-manual-install` | `manual_install.md` | SSH + UI login/smoke test |
| 3 Ansibilize | `/app-ansibilize` | playbook + stackscript | inline review + lint clean |
| 4 Deploy | `/app-deploy` | `e2e_testing.md` | clean fresh deploy + smoke tests |
| 5 Config validation | `/review:validate-config` *(command)* | `validation_findings.md` | every directive classified |
| 6 README + PR | `/app-pr` | app `README.md` (written **last**) | PR review, CI green |

## The handoff file — `.documentation/<app>/STATE.md`

Every skill **reads** this at start and **writes** it at end. It's the connective tissue: where
the pipeline is, which boxes/stackscripts exist, the upstream clone + SHA, and the next step +
checkpoint. (`.documentation/` is local working material — gitignored, never committed.) The
template is bundled at `.claude/skills/backport-start/templates/state.md`.

## Core principles (enforced by every skill)

- **Grounding / no hallucination.** Every decision cites a source — a doc URL, a repo `file:line`+SHA,
  or an empirical observation (command + output + box id). Anything ungroundable is flagged as an
  OPEN QUESTION and the skill STOPS. No guessing.
- **Claude never pushes to GitHub.** Pushing (and merging) is always a manual operator step. The
  `/app-deploy` fix loop pauses for the operator to review + push before each fresh redeploy.
- **Claude never runs destructive commands without permission.** `rm -rf` (e.g. the lint scratch
  cleanup) prompts the operator first.
- **README is written last** (`/app-pr`), after the validated final version is known, and is
  explicitly a manual-review starting point — never blindly trusted.
- **Back up before destructive edits**; remove the backup once the new version is verified.
- **`linode-team` MCP only** (see setup below) — never `linode-personal`.
- **Reference apps** are curated in [`shared/reference-apps.md`](shared/reference-apps.md), updated
  by PR. The `:start` skills read it and cite the apps' actual files.

## Configure the `linode-team` MCP (one-time, per teammate)

The deploy/manual-install skills drive Linode via the `mcp__linode-team__*` tools, which require a
**Cloud Manager API token for the team account**. The token is **never committed** — it lives in
your user-scope MCP config, outside this repo.

1. In Cloud Manager (team account) → **My Profile → API Tokens → Create a Personal Access Token**
   with read/write on Linodes, StackScripts, Domains, Firewalls (scope to what you need).
2. Add the MCP server to your **user-scope** config (`~/.claude.json`) — not the repo. The server
   name must be `linode-team` so the tools resolve as `mcp__linode-team__*`. Supply the token via
   the server's documented auth (env var / header), not a literal in the file.
3. Verify: `list_linodes` via the `linode-team` MCP returns the team account's instances.

There is intentionally **no `.mcp.json` in this repo**, so no token is ever in version control.
`.claude/settings.local.json` and `.claude/*.lock` are gitignored for the same reason.
`.reference/` (upstream clones) and `.documentation/` (per-app scratch) are gitignored too.

> **Known dependency:** `/app-deploy` updates StackScripts by delete+recreate because the
> `linode-team` MCP has no `update_stackscript` tool yet. Add it to `linode-mcp` to simplify.

## Kept commands

- `/review:validate-config` — Phase 5, the empirical config-directive matrix (actively used).
- `/setup-cloud-manager-dev` — Cloud Manager dev environment setup (unrelated to the pipeline; the
  team makes CM PRs from time to time).

The earlier generic review commands and generator/reviewer agents were removed — see
[`MIGRATION-AUDIT.md`](MIGRATION-AUDIT.md).
