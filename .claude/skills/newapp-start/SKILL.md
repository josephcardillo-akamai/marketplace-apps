---
description: Phase 1 (new app) — research an upstream application's repo + official docs for single-node install best practices, reconcile with repo standards, and produce a cited architecture_decisions.md + initialize STATE.md. User-invoked only.
disable-model-invocation: true
arguments: [app]
---

# New App: Start (R&D + Analyze the Upstream)

Front-end for a **brand-new marketplace app** (no legacy StackScript exists). Studies the
application's upstream repo + official docs for single-node install best practices, reconciles
them with this repo's standards, and produces the grounded `architecture_decisions.md`.
Initializes the per-app `STATE.md`.

This is the first command in the pipeline for new apps. The only difference from
`/backport-start` is the front end — there's no legacy app to deploy, so the research is purely
upstream. Every downstream phase (`/app-manual-install` onward) is identical.

## Usage
```
/newapp-start <app> --repo <git-url> [--docs <url>]
```
Parse `--repo` (required) and `--docs` from `$ARGUMENTS`; `$app` is the first positional.

## Arguments
- `<app>`: short app name, lowercase (e.g. `langflow`). Used for `apps/linode-marketplace-<app>/`
  and `.documentation/<app>/`.
- `--repo <git-url>`: **required.** The upstream source repository to clone and analyze.
- `--docs <url>`: optional pointer to the official documentation root (otherwise discovered via search).

## Grounding contract (non-negotiable)
Every decision must cite a source — a **doc URL**, a **repo `file:line` + commit SHA**, or an
**empirical observation**. Pull sources in explicitly; never reason from memory:
- Official docs → `WebFetch` / `WebSearch`, capture the exact URL.
- Upstream source → `git clone` into `.reference/<repo>` (gitignored) and read the *actual*
  install scripts, Dockerfiles/compose files, config templates, and defaults. Also consult the
  repo's own `ansible/` clone for module params.
- Live behavior → confirmed later, during `/app-manual-install`, on a real box.

**If a fact cannot be grounded, record it as an OPEN QUESTION and STOP for the operator. Do not guess.**

## Process

### Phase 0 — Upstream R&D
1. `git clone <repo>` into `.reference/<repo>` (gitignored scratch). **Capture the commit SHA** —
   i.e. record the exact commit hash you are reading at (e.g. `git -C .reference/<repo> rev-parse HEAD`).
   Every later `file:line` citation is written as `path:line @ <sha>` so that if upstream changes,
   the citation still points to exactly what you saw. Store the SHA in `STATE.md`.
2. Determine the upstream-preferred single-node install method by reading the *actual* repo +
   docs, in this priority order (per `CLAUDE.md`): Docker/Compose → official package repo →
   source build → binary release → (never execute install scripts — analyze and Ansibilize them).
3. Capture current version pins, runtime/dependency requirements, exposed ports (review **all**
   services in any compose file, not just the web one), and the app's native auth model.
4. Read official docs: install guide, security/hardening guide, production deployment notes,
   config reference.

### Phase 1 — Reconcile with repo standards
5. Compare upstream recommendations against `CLAUDE.md` mandates + how the closest existing apps
   structure things. **Pick those reference apps via `.claude/shared/reference-apps.md`:** classify
   this app's archetype (install method, web/proxy, auth model, GPU?/DB?/PHP?) → match one bucket →
   rank that bucket's members by date-added (`git log --diff-filter=A --format=%cs -- apps/linode-marketplace-<m> | tail -1`,
   newest first) → read the **newest 2–3 members' actual files** and cite `file:line` for borrowed
   patterns. Then layer the marketplace security requirements on top of the upstream-blessed install:
   systemd, nginx reverse proxy for non-standard ports, certbot SSL + HTTP→HTTPS, generated
   credentials (no defaults), no open installer/setup wizard (§7/§7a), authentication on all
   data-ingestion endpoints (§6), API on loopback where applicable.
6. **Auth layering — exactly ONE layer is required, and an unauthenticated visitor must NEVER reach
   an installer or admin console.** Provide native login **OR** nginx basic auth — *either, not both*:
   - **Native login (preferred):** use it whenever the app has one, configured to be *enforced*
     (e.g. Langflow `AUTO_LOGIN=false` + a seeded superuser; a CMS admin login). That native login
     IS the auth layer — do **not** stack basic auth on top.
   - **nginx basic auth (fallback):** use ONLY when the app has no enforceable native login, so the
     console/UI isn't left open (e.g. Nomad's no-ACL UI).
   - **Both, transiently:** layer basic auth in front of native login ONLY when a post-install step
     must happen behind protection before native auth is fully live (e.g. HaltDOS waiting on an
     emailed 6-digit code). Once native auth is active, **remove the basic-auth layer** in favor of
     native login. Never ship standing two-layer.
   See `CLAUDE.md` §"Hard Rules for Backports".

### Phase 2 — Write `architecture_decisions.md` + init `STATE.md`
7. Write `.documentation/<app>/architecture_decisions.md` as a numbered decision log
   (`D1`, `D2`, …). Each `Dn` states the decision, alternatives considered, and a **source
   citation** (doc URL / repo `file:line`+SHA). Flag anything ungroundable (e.g. behavior that can
   only be confirmed by running it) as `OPEN QUESTION` to resolve during manual install.
8. Initialize `.documentation/<app>/STATE.md` from the bundled template
   `.claude/skills/backport-start/templates/state.md` (repo-relative; skills run with cwd at the
   repo root): set `type: newapp`, the branch, the upstream clone path + SHA, mark `research/analyze`
   done, set `next_step: /app-manual-install`.

## Output
- `.documentation/<app>/architecture_decisions.md` — cited decision log (this command owns it).
- `.documentation/<app>/STATE.md` — initialized handoff file.
- A short operator summary: chosen install method (with citation), exposed ports, auth model, and
  any OPEN QUESTIONS.

## STOP — manual review (checkpoint)
Before the next command, the operator verifies:
- [ ] `architecture_decisions.md` is sound and every `Dn` carries a real citation.
- [ ] The install method matches current upstream and the priority order in `CLAUDE.md`.
- [ ] The auth model is decided (does the public URL need an outer layer?).
- [ ] OPEN QUESTIONS are listed for empirical resolution during manual install.

**Next:** `/app-manual-install`
