---
description: Phase 6 (last) — write the app README from the validated final version, assemble the PR body with validation + deploy evidence, and open the PR with operator approval. Claude never pushes or merges. User-invoked only.
disable-model-invocation: true
arguments: [app]
---

# App: PR (Phase 6 — README + Pull Request)

Runs **last**, only after `/app-deploy` and `/review:validate-config` have confirmed the final
version. This is the **only** command that writes `apps/linode-marketplace-<app>/README.md`
(nothing earlier touches it). It assembles the PR description and opens the PR.

Shared by both paths. Reads `STATE.md` + all four `.documentation/<app>/*.md` artifacts.

## Usage
```
/app-pr <app>
```

## Critical rules
- **Claude never pushes or merges.** Opening the PR is done with the operator's explicit approval;
  the operator controls the push of the branch.
- **The generated README is a starting point, not authoritative.** Like everything else in this
  pipeline it **must be manually reviewed** by the operator before the PR is considered ready.
  State this in the PR description and to the operator. Do not represent it as final.

## Process

### Phase 6a — Write the README
1. Pick the matching template and fill it from the validated artifacts (cite nothing from memory —
   pull names/ports/versions from `architecture_decisions.md`, `manual_install.md`, the playbook,
   and `e2e_testing.md`):
   - **Standard app** → `${CLAUDE_SKILL_DIR}/templates/README-standard.md`
     (HashiCorp-style / CMS / service apps — Nomad, Vault, Joomla, HaltDOS, MCP-Gateway shape).
   - **Model-serving / AI app** → `${CLAUDE_SKILL_DIR}/templates/README-model.md`
     (GPU inference / vector DB — DeepSeek, Qwen, GPT-OSS, Gemma3, Milvus, Chroma shape).
2. Write it to `apps/linode-marketplace-<app>/README.md`. Flag every spot where a human must
   confirm a detail (sample workload, scaling guidance, screenshots) with an inline
   `<!-- REVIEW: ... -->` note rather than guessing.

### Phase 6b — Assemble the PR body
3. Build the PR description from the artifacts:
   - What the backport fixes / what the new app is (from `architecture_decisions.md`).
   - The `validation_findings.md` LOAD-BEARING / DEFENSIVE / DEAD-CODE matrix.
   - Fresh-deploy evidence from `e2e_testing.md`: stackscript id + box id + smoke results.
   - A note that the README is a first draft pending manual review, and (if relevant) that Claude
     never ran destructive commands or pushed — those were operator steps.

### Phase 6c — Open the PR (operator-approved)
4. Confirm the branch is pushed (operator's responsibility). With the operator's explicit go-ahead,
   open the PR against `develop` via `gh pr create` using the assembled body. Do **not** merge.
5. Update `STATE.md`: mark `pr` done, record the PR URL.

## Output
- `apps/linode-marketplace-<app>/README.md` — user-facing doc (this command owns it; review required).
- An opened PR against `develop` with the full evidence body.
- `STATE.md` updated.

## STOP — manual review (checkpoint)
- [ ] Operator has read the README and confirms it's accurate (not blindly trusted).
- [ ] PR body carries the validation matrix + fresh-deploy evidence.
- [ ] CI is green on the PR.
- [ ] Branch was pushed by the operator; PR opened, not merged.
