# Bookshelf: ECS Challenge Solution

Reference solution for the **Bookshelf track** of the [ECS challenges](https://github.com/turnes-labs/ecs): one product, a Go REST API on Amazon ECS Fargate, evolved over three levels.

| Level | Challenge | Finished at |
| --- | --- | --- |
| Easy | [v1: MVP on ECS Fargate](https://github.com/turnes-labs/ecs/blob/main/easy/01-bookshelf-v1-mvp-terraform/README.md) | tag `level-v1-done` |
| Medium | [v2: reliable releases](https://github.com/turnes-labs/ecs/blob/main/medium/01-bookshelf-v2-releases-terraform/README.md) | tag `level-v2-done` |
| Hard | [v3: production at scale](https://github.com/turnes-labs/ecs/blob/main/hard/01-bookshelf-v3-production-terraform/README.md) | tag `level-v3-done` |

> **Spoiler warning:** this repository contains the full solution. Try the challenge first.

## How this repository works

There is **one codebase**, not one copy per level. Each level starts from the end of the previous one, the way a real product evolves. `main` always holds the latest level, and an annotated git tag marks where each level was finished.

To see a level as it was finished:

```sh
git checkout level-v1-done
```

To see everything that changed from one level to the next:

```sh
git diff level-v1-done level-v2-done --stat
git diff level-v1-done level-v2-done -- infra/
```

The diff is the most useful part of this repository. It shows how the infrastructure was refactored without downtime, not just the end state.

## Layout per level

```text
v1 (easy)                     v2 (medium)                         v3 (hard)
─────────                     ───────────                         ─────────
bootstrap/                    bootstrap/  (+3 OIDC roles)         bootstrap/  (per-env roles)
app/                          app/                                app/
  cmd/api/                      cmd/api/  cmd/migrate/              cmd/api/ cmd/migrate/ cmd/backfill/
  internal/                     internal/                           internal/
  migrations/                   migrations/                         migrations/
  Dockerfile                    deploy/taskdef.json                 deploy/taskdef.json
infra/  (one root)            infra/                              infra/
                                modules/network/                    modules/...
                                modules/database/                   envs/staging/
                                modules/ecs-service/                envs/prod/
.github/workflows/            .github/workflows/                  .github/workflows/
  ci.yml                        ci.yml  infra.yml                   + reusable release workflow
  deploy.yml                    build.yml  release.yml              per environment
docs/v1.md                    docs/v2.md                          docs/v3.md  RUNBOOK.md
```

## Working across levels

Only one level is live at a time: the one on `main`. Moving from v1 to v2 (or v2 to v3) isn't a switch you flip. It's a series of ordinary pull requests that turn the v1 code into v2 code while the service keeps running.

```text
main ──●──●──●──◆────●──●──●──●──◆────●──●──●──◆──▶
                │                │              │
         level-v1-done    level-v2-done   level-v3-done
          (v1 is live)     (v2 is live)    (v3 is live)

        ●  merged PR (CI runs, may deploy)
        ◆  annotated level tag (nothing runs)
```

### Moving from one level to the next

1. **Close the current level.** Tick off every criterion in `docs/vN.md`, then push the `level-vN-done` tag (see [Close the level](#4-close-the-level)).
2. **Update bootstrap first, if needed.** v2 adds OIDC roles and v3 splits them per environment. Apply `bootstrap/` by hand *before* merging any workflow that assumes the new roles, or CI fails with `AssumeRoleWithWebIdentity` errors.
3. **Refactor infra in small PRs.** Each PR must apply cleanly against the live state with no replacement of the ALB, service or database. Use `moved {}` blocks for v1 → v2 (one root to modules) and `terraform state mv` / a new state key for v2 → v3 (one root to `envs/*`). Read the plan in the PR before merging.
4. **Swap the workflows in a single PR.** When a level changes how deploys happen (for example, v1's `deploy.yml` is replaced by v2's `build.yml` + `release.yml`), delete the old workflow and add the new ones in the **same** PR. If both are on `main` at once, one merge deploys twice through two paths; if neither is, nothing deploys.
5. **Cut the first release the new way**, prove it works, then go back to step 1.

### Fixing or revisiting an earlier level

Checking out a `level-*` tag is for **reading**, not for running. The cloud only holds one level's resources, and an old level's Terraform would plan to destroy or recreate what the current level built. See [Fixing an earlier level](#fixing-an-earlier-level) for how to correct a snapshot without deploying it.

## How CI/CD decides what runs

CI/CD never picks a level. GitHub Actions has one rule:

> A workflow runs from the files in `.github/workflows/` **in the commit that triggered the event**.

So the level that runs is the level in the commit, and the trigger (`on:`) in each file decides *whether* it runs. There is no level variable, matrix or flag to set.

| Event | Workflow files used | In practice |
| --- | --- | --- |
| `pull_request` | the PR's merge commit | A PR that changes a workflow is tested with its **new** version |
| `push` to `main` | the new `main` commit | The current level's build / deploy |
| `push` of a tag | the tagged commit | `v*` → release; `level-*` → nothing |
| `workflow_dispatch` | the ref picked in the UI or `--ref` | Can run an old ref; that's why old levels must not deploy from it |
| `schedule` | always the default branch | Always the current level |

### Triggers per level

| Workflow | v1 (easy) | v2 (medium) | v3 (hard) |
| --- | --- | --- | --- |
| `ci.yml` | PR + push to `main`: Go tests, `terraform fmt`/`validate`/`plan` | PR: tests, image build (no push), `plan` | PR: same, `plan` runs as a matrix over `envs/staging` and `envs/prod` |
| `deploy.yml` | push to `main`: build, push to ECR, `terraform apply` with the new image tag | **removed** | — |
| `infra.yml` | — | push to `main`, `paths: infra/**`: `terraform apply` | push to `main`, `paths: infra/**`: apply staging, then prod behind a GitHub environment approval |
| `build.yml` | — | push to `main`, `paths: app/**`: build and push image tagged with the commit SHA | same |
| `release.yml` | — | push tag `v*`: run `migrate` task, register task definition from `app/deploy/taskdef.json`, update the service | push tag `v*`: calls the reusable deploy workflow for `staging`, then `prod` |
| `_deploy.yml` | — | — | `workflow_call` only, input `environment`; never runs by itself |

What this means in practice:

- **v1:** merging to `main` is a deploy. Infra and app ship together in one `terraform apply`.
- **v2:** merging to `main` changes infra (`infra/**`) or produces an image (`app/**`), but never changes what's serving traffic. Only a `v*` tag deploys a new app version. Infra and app are separate layers with separate pipelines.
- **v3:** the same as v2, but every apply and release goes to `staging` first and reaches `prod` only after the staging job succeeds and someone approves the `prod` environment. Each environment assumes its own IAM role, so a staging job can't touch prod.

### Why level tags never deploy

- Release workflows listen to `tags: ['v*']`. Tag globs are anchored, so `level-v2-done` doesn't match `v*`.
- Workflows that deploy on `main` use `branches: [main]`. A push event filtered by branch ignores tag pushes.
- Never write a bare `on: push` (no filters) in a workflow that deploys: it fires on **every** tag push, `level-*` included.

### Running an old level

You almost never should. If you have to (for example, to reproduce a v1 experiment):

- A branch made from a level tag (`git switch -c level/v1 level-v1-done`) only runs `ci.yml`, because deploy triggers are bound to `main` and `v*` tags. That's safe.
- Old workflows assume the IAM roles of their level. After bootstrap has moved on, they may no longer exist, and v1's role may still have rights you don't want to use.
- To deploy it, destroy the current stack first and apply the old level from your machine against a **separate state key**. Never point an old level's Terraform at the live state.

## Getting started (v1)

### Prerequisites

- An AWS **sandbox** account with an AWS Budget alert configured
- Go 1.23+, Docker with `buildx`, AWS CLI v2, Terraform 1.9+, [k6](https://k6.io/)
- This repository on GitHub. Workflows only run from `.github/workflows/` at the repository root, which is why the solution lives in its own repository.

### 1. Bootstrap (once, from your machine)

CI authenticates to AWS with OIDC, but the OIDC provider and roles must exist before CI can use them. `bootstrap/` is a small Terraform root applied by hand, with your own credentials:

- S3 bucket for Terraform state (versioning on, public access blocked)
- GitHub OIDC identity provider
- The IAM roles CI assumes, with trust policies scoped to this repository

```sh
cd bootstrap
terraform init
terraform apply
```

Bootstrap keeps its own state local or in a separate key. Everything after this point runs through CI, and no AWS access keys go into GitHub.

### 2. Build the level

Follow the challenge README for the current level. Work on short-lived branches and merge into `main` through pull requests, so `ci.yml` runs on every change.

### 3. Prove it

Each level has acceptance criteria. Copy them into `docs/vN.md` and tick each one off with evidence: k6 summaries, CLI output, screenshots of rollbacks or alarms. Put the files in `docs/evidence/vN/` and link to them.

### 4. Close the level

```sh
git tag -a level-v1-done -m "v1: MVP on ECS Fargate"
git push origin level-v1-done
```

Then start the next level from `main`.

## Tags

Two kinds of tags live in this repository. Keep their prefixes distinct:

| Tag | Example | Meaning | Triggers a deploy |
| --- | --- | --- | --- |
| `level-vN-done` | `level-v2-done` | A level is finished | No |
| `v*` (from v2 on) | `v1.4.0` | An app release | Yes, `release.yml` |

`level-*` tags must never match the `v*` pattern that release workflows listen to.

## Fixing an earlier level

Tags are snapshots, so a bug found in v1 after starting v2:

1. Fix it on `main` if it still applies there
2. If the v1 snapshot itself must be corrected, branch from the tag (`git switch -c level/v1 level-v1-done`), fix, then move the tag (`git tag -fa level-v1-done`) and record the change in `docs/v1.md`

Prefer option 1 and a note in the docs. Moving tags rewrites what other people may have checked out.

## Documentation

`SOLUTION.md` in the challenges asks for decisions and trade-offs. Here it is split per level so each one stays readable:

| File | Contents |
| --- | --- |
| `docs/v1.md` | healthz vs readyz, execution vs task role, results of the deploy-under-load and broken release experiments |
| `docs/v2.md` | Pool sizing math, the infra/app layer boundary, the zero-downtime migration from v1, rollback-safe migrations |
| `docs/v3.md` | Read-your-writes strategy, pool math with RDS Proxy, NAT vs endpoints with numbers, cost table, Spot trade-offs, RTO/RPO |
| `RUNBOOK.md` (v3) | Step-by-step restore procedure |

Each file also has a **"What broke"** section: the problems you hit and how you fixed them. It's usually the most valuable part.

## Costs and cleanup

NAT gateways, ALBs and RDS charge by the hour. Destroy the stack when you stop for the day, and recreate it from code: that's an acceptance criterion anyway.

```sh
cd infra && terraform destroy            # v1–v2
cd infra/envs/prod && terraform destroy  # v3, then envs/staging
```

Task definition revisions registered by CI (v2+) aren't in Terraform state; deregister and delete them separately. Destroy `bootstrap/` only when you're done with the whole track.
