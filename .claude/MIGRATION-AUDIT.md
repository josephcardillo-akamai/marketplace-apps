# Migrated Tooling Audit — Final Verdicts

When `.claude` became a real committed directory (branch `add/claude-skills`, 2026-06-08), the
`review:*` commands, `setup-cloud-manager-dev`, and 3 agents were ported **unchanged** from the
private `marketplace-docs-private` repo. They were then audited against the new skills pipeline and
the team's actual practice. These verdicts are **final** (decided 2026-06-09 with the operator), not
pending calibration.

## Verdicts

| Item | Verdict | Rationale |
|---|---|---|
| `review:validate-config` (command) | **KEEP** | Phase 5 of the pipeline; the only review command in active use. Unchanged. |
| `setup-cloud-manager-dev` (command) | **KEEP** | Unrelated to the app pipeline, but the team makes Cloud Manager PRs periodically. Stays as a command. |
| `marketplace-app-creator` (agent) | **CUT** | The new `/app-ansibilize` skill replaces it, with the empirical boilerplate-vs-fresh table and grounded scaffolding. |
| `marketplace-app-documenter` (agent) | **CUT** | The new `/app-pr` skill writes the README from validated artifacts and assembles the PR body. |
| `code-reviewer` (agent) | **CUT** | Its description targeted generic feature work (OAuth logins, etc.), not this repo's Ansible/bash standards review. The review criteria already live in `CLAUDE.md` (§"Code Review Checklist", §"Marketplace App Deployment Standards") and are folded **inline** into `/app-ansibilize` and `/app-pr`. |
| `review:app-review` (command) | **CUT** | Superseded — its checklist is in `CLAUDE.md` and runs inline at the ansibilize/pr checkpoints. |
| `review:marketplace-pr` (command) | **CUT** | Same — duplicate of the CLAUDE.md-grounded review. |
| `review:quick-check` (command) | **CUT** | Same — ad-hoc triage subset of the inline review. |
| `review:github-pr` (command) | **CUT** | PR triage; `/app-pr` + `gh` cover the pipeline's PR step. |
| `review:create-app` (command) | **CUT** | Scaffolding folded into `/app-ansibilize`. |

## Notes
- The 3 agents and 5 cut commands remain available in the private repo
  (`../marketplace-docs-private/.claude/`) as a backup if any pattern needs to be revisited.
- `.claude/agents/` is empty after the cuts; the directory may be removed.
- The inline review at the `/app-ansibilize` and `/app-pr` checkpoints is grounded in `CLAUDE.md`,
  not a separate agent — one source of truth for the standards.
