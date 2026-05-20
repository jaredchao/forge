# Forge Dashboard Web UI — Design

## Summary

Build a local single-project web console for Forge. The dashboard scans a Forge-enabled project, shows PRDs, specs, tasks, jobs, logs, and review outputs, and can start Forge workflows through a Fastify backend. Each write-capable job runs in its own git worktree and branch so multiple jobs from the same project can run without modifying the main working directory.

## Goals

- Provide a Vite React + Fastify local dashboard for one configured `PROJECT_DIR`.
- Scan and display Forge project state from `.claude/`, `docs/prd/`, and `docs/specs/`.
- Start spec generation and feature execution jobs from the UI.
- Isolate each job in a dedicated git worktree and branch.
- Support multiple jobs for the same project through worktree isolation.
- Stream job logs and inferred Forge phases to the UI.
- Show completed job diffs, task changes, lessons updates, and merge readiness.
- Let users explicitly merge, keep, cancel, or clean up job worktrees.

## Non-Goals

- Do not build a multi-user hosted team service in the first version.
- Do not automatically merge job output into the main project directory.
- Do not replace Forge's existing command and skill system with a full custom orchestrator.
- Do not build a full PRD editor or collaborative spec editor in the first version.
- Do not support multiple configured projects in the first version, though the backend should avoid designs that prevent it later.

## Architecture

The system has four main locations:

- `apps/web`: Vite + React dashboard.
- `apps/server`: Fastify API server, job runner, git/worktree integration, and log streaming.
- `PROJECT_DIR`: the user's Forge-enabled code repository.
- `.forge-dashboard/`: local dashboard metadata stored inside `PROJECT_DIR`.

The main project directory is the control-plane view of the baseline state. It is scanned for `.claude/CLAUDE.md`, `.claude/rules/`, `docs/prd/`, `docs/specs/*/requirements.md`, `design.md`, `tasks.md`, and `docs/specs/LESSONS.md`.

All jobs that may write files run in separate worktrees under a configurable base directory such as:

```text
../.forge-worktrees/{project-name}/{job-id}/
```

Each job gets a branch named with a stable prefix, for example:

```text
forge/job-{jobId}-{slug}
```

Different projects may run jobs without a dashboard-level concurrency limit. For the first single-project version, multiple jobs may run concurrently because each job has its own worktree. The UI should block or warn on duplicate running jobs for the same feature unless the user explicitly starts a separate experimental branch.

Dashboard metadata lives at:

```text
{PROJECT_DIR}/.forge-dashboard/dashboard.sqlite
{PROJECT_DIR}/.forge-dashboard/logs/
```

The server must ensure `.forge-dashboard/` is ignored by git. If the directory is not covered by `.gitignore`, the UI shows a warning and offers to add it. Dashboard metadata is not copied or synchronized into job worktrees. Job worktrees get their own ignored `.forge-dashboard/` only if a command needs local runtime scratch space.

## User Experience

The first version uses four main UI regions.

### Project Bar

The top bar shows:

- Current `PROJECT_DIR`
- Current target git branch
- Forge initialization state
- Claude configuration state
- Actions: scan, generate specs, run selected feature, open worktrees

### Feature List

The left column is populated from `docs/specs/*/`. Each feature shows:

- Feature number and name
- Task completion ratio
- `[CHANGED]` and `[DROPPED]` indicators
- Latest related job status
- Unmerged branch/result indicator

### Feature Detail

The center panel shows the selected feature:

- `requirements.md` summary and open questions
- `design.md` module, interface, and risk summary
- `tasks.md` rendered as structured task rows
- Task dependency and risk sections
- Actions to start a feature job, view logs, and view diffs

### Job Panel

The right panel shows current and historical jobs:

- Job type: `spec_generate`, `feature_execute`, or `change_request`
- Status: `queued`, `preparing_worktree`, `running`, `failed`, `ready_for_review`, `merging`, `merged`, `kept`, `canceled`, `interrupted`, or `merge_conflict`
- Realtime logs
- Inferred Forge phase such as N1 initialization, N2 feature entry, N3 task execution, N4 review, N5 mark done, N6 QA, N7 context, or N8 finish
- Branch name, worktree path, exit code, and duration
- Completed job actions: view diff, merge into target branch, keep branch, delete worktree

## Job Flows

### Spec Generation

The user starts a spec generation job from the project bar. The source input is `docs/prd/`; the expected output is new or changed `docs/specs/{N}.{feature}/requirements.md`, `design.md`, and `tasks.md` files. The backend creates a job worktree, runs the Forge PRD-to-specs flow for that worktree, records logs and events, then compares the job branch against the target branch. The UI shows created or changed specs. The user can merge the resulting branch or keep it for manual review.

Required command contract:

```bash
/forge:prd {PROJECT_DIR}
```

Example:

```bash
/forge:prd /path/to/job-worktree
```

The command runs with `cwd` set to the job worktree root. `{PROJECT_DIR}` must also point at the job worktree root, not the main project directory. Input PRDs are read from `{PROJECT_DIR}/docs/prd/`. Generated specs are written to `{PROJECT_DIR}/docs/specs/{N}.{feature}/requirements.md`, `design.md`, and `tasks.md`. Exit code `0` means the spec generation flow completed and the job can move to dashboard review. Non-zero exit codes mark the job as `failed`. If `docs/prd/` does not exist or contains no usable PRD files, the command must exit non-zero before modifying files and emit a clear diagnostic. If PRDs exist but no spec changes are needed, the command exits `0` after emitting a clear no-op message.

### Feature Execution

The user selects a feature and starts a feature execution job. The backend creates a job worktree and runs a feature-scoped Forge execution flow. On completion, the UI shows code diff, task checkbox changes, `LESSONS.md` additions, tests or QA summaries, and merge readiness.

The current Forge `/forge:ai` command executes all features. The dashboard MVP requires a feature-scoped execution entry point before the feature execution UI is considered complete.

Required command contract:

```bash
/forge:ai --feature {feature-dir-name} {PROJECT_DIR}
```

Example:

```bash
/forge:ai --feature 1.user-auth /path/to/job-worktree
```

The command runs with `cwd` set to the job worktree root. `{PROJECT_DIR}` must also point at the job worktree root, not the main project directory. `{feature-dir-name}` must exactly match a directory name under `{PROJECT_DIR}/docs/specs/`, such as `1.user-auth`. Exit code `0` means the selected feature finished and is ready for dashboard review. Non-zero exit codes mark the job as `failed`. If the feature does not exist, the command must exit non-zero before modifying files. If the feature has no incomplete tasks, the command exits `0` after emitting a clear no-op message.

The feature-scoped command must apply the same N1-N8 rules as `/forge:ai`, but N2 only enters the selected feature and N8 summarizes only that job's scope. It must not execute unrelated feature directories.

## Backend Components

### ProjectScanner

Responsibilities:

- Validate `PROJECT_DIR`.
- Check `.claude/CLAUDE.md` and `.claude/rules/`.
- Scan `docs/prd/`.
- Scan feature directories under `docs/specs/`.
- Parse task checkboxes, `[CHANGED]`, and `[DROPPED]` markers.
- Read `LESSONS.md`.
- Read git branch, dirty state, and target branch metadata.

### WorktreeManager

Responsibilities:

- Generate unique branch names and worktree paths.
- Create worktrees from the selected target branch.
- Record branch and worktree metadata.
- Detect branch name conflicts and target branch changes.
- Remove worktrees only after explicit cleanup.

### JobRunner

Responsibilities:

- Own the job queue and process lifecycle.
- Transition jobs through the canonical persisted state machine.
- Spawn commands in job worktrees.
- Capture stdout and stderr.
- Persist job events.
- Infer Forge phases from command output.
- Cancel processes with SIGTERM, then SIGKILL after a timeout.

Canonical persisted job transitions:

```text
queued
  -> preparing_worktree
  -> running
  -> ready_for_review
  -> merging
  -> merged

queued | preparing_worktree | running -> canceled
running -> failed
running -> interrupted
ready_for_review -> kept
ready_for_review -> merge_conflict
merging -> merge_conflict
merging -> failed
```

`completed` is not a persisted status. A successful process exit is an internal event that transitions the job from `running` to `ready_for_review` after diff and review metadata are collected.

### ForgeCommandAdapter

Responsibilities:

- Convert dashboard actions into Forge-compatible command invocations.
- Support `spec_generate`.
- Support the required feature-scoped `/forge:ai --feature {feature-dir-name} {PROJECT_DIR}` execution contract.
- Capture command environment and diagnostics when commands are unavailable.

### ReviewIntegrator

Responsibilities:

- Compute diff summaries between target branch and job branch.
- List changed files.
- Detect `tasks.md` checkbox changes.
- Extract `LESSONS.md` additions.
- Summarize test and QA output from job logs.
- Check whether the job branch can merge cleanly into the target branch.

## Persistence

Use SQLite for the first version. It is still local and low-maintenance, but it handles job queue history, restart recovery, and event queries better than ad hoc JSON files.

Suggested tables:

- `projects`: `id`, `root_path`, `name`, `target_branch`, `worktree_base_path`, `created_at`
- `features`: `id`, `project_id`, `spec_path`, `number`, `name`, `task_total`, `task_done`, `has_changes`, `last_scanned_at`
- `jobs`: `id`, `project_id`, `feature_id`, `type`, `status`, `branch_name`, `worktree_path`, `command`, `pid`, `target_branch`, `target_start_sha`, `exit_code`, `started_at`, `finished_at`, `error_summary`
- `job_events`: `id`, `job_id`, `timestamp`, `level`, `phase`, `message`, `raw_line`
- `merge_records`: `job_id`, `target_branch`, `merge_strategy`, `result_commit`, `status`, `conflict_summary`

The `features` table is a cache. The source of truth remains the project files under `docs/specs`.

## API

Initial endpoints:

- `GET /api/project`: project path, git branch, Forge initialization state, and Claude configuration state.
- `POST /api/scan`: rescan project files and refresh cached feature state.
- `GET /api/features`: list scanned features.
- `GET /api/features/:id`: return structured summary and raw markdown for a feature.
- `POST /api/jobs`: create a job.
- `GET /api/jobs`: list jobs.
- `GET /api/jobs/:id`: return job details.
- `GET /api/jobs/:id/events`: stream job events over SSE.
- `POST /api/jobs/:id/cancel`: cancel a running job.
- `GET /api/jobs/:id/diff`: return diff summary for a completed job.
- `POST /api/jobs/:id/merge`: merge a completed job branch after user confirmation.
- `POST /api/jobs/:id/keep`: mark a completed job branch as intentionally retained.
- `POST /api/jobs/:id/cleanup`: remove a job worktree after user confirmation.

`keep` changes `ready_for_review` jobs to `kept`. It does not delete the branch or worktree. `cleanup` may remove the worktree for `ready_for_review`, `kept`, `merged`, `failed`, `canceled`, `interrupted`, or `merge_conflict` jobs after confirmation, but it must not delete the branch unless a future API explicitly asks for branch deletion.

## Merge Behavior

The first version never merges automatically. A successful job enters `ready_for_review`.

Each job records `target_start_sha` when its worktree is created. Merge readiness is always recomputed against the current target branch head, not only against the job's original base.

Merge operations are serialized per `project_id + target_branch` with an in-process lock and a database lock record. Before merge, the backend revalidates:

- `PROJECT_DIR` exists and is a git repository.
- The target branch still exists.
- The current target branch head and the job's `target_start_sha` relationship are known.
- The default integration-worktree merge does not require the main project working tree to be clean because it does not write into `PROJECT_DIR`. If a future UI offers a direct-in-`PROJECT_DIR` merge, that direct merge must require a clean main working tree.
- The job branch exists and has commits or file changes relative to the target branch.

Default merge runs in a temporary integration worktree, not directly in `PROJECT_DIR`. The server creates the integration worktree at the current target branch head, attempts `git merge --no-ff {job_branch}`, and records conflicts or the merge commit. If the merge succeeds, the target branch ref is advanced to the merge commit and the main project directory is left untouched until the user updates or checks out that branch. If conflicts are detected, the job becomes `merge_conflict`, the job worktree is preserved, and the UI shows the conflicted files and git output.

## Frontend State

Use React Query for server state: project, features, jobs, and diffs. Use SSE for live job events. Use a small local state layer for selected feature, selected job, panel tabs, and log auto-scroll preference.

Markdown display should use a markdown renderer. Task rendering should use structured data from the backend so the frontend does not duplicate task parsing rules.

## Error Handling

- Invalid feature specs should mark only that feature as invalid, not break the whole page.
- Missing commands, such as `claude`, should fail the job with environment diagnostics.
- Worktree creation errors should distinguish path permission problems, branch conflicts, dirty target branch, and missing target branch.
- Merge failures must preserve the job worktree and git output.
- Jobs based on stale target heads should remain reviewable, but the UI must show a stale-base warning and recompute merge readiness against the current target head.
- Concurrent spec generation jobs are allowed only when the user explicitly starts an experimental branch; otherwise the UI should block duplicate running `spec_generate` jobs for the same project.
- Concurrent feature jobs for the same feature are blocked by default and require an explicit experimental branch override.
- Destructive operations, including canceling a running job, deleting a worktree, and merging into the target branch, require explicit confirmation.
- On server restart, jobs marked running are reconciled with actual processes. Missing processes become `interrupted`, and their worktrees remain available.

## Testing

Backend unit tests should cover:

- `tasks.md` parsing
- specs scanning
- job state transitions
- log phase inference
- worktree branch naming and conflict detection

Backend integration tests should create temporary git repositories with fake Forge specs, create worktrees, run fake Forge commands, capture logs, produce diffs, and verify merge success and merge conflict paths.

Frontend tests should cover:

- feature list rendering
- job panel states
- log stream rendering
- failed, ready-for-review, merge-conflict, and interrupted states

E2E tests should start the local server and web app against a sample project, create a spec generation job, create a feature job, inspect diff output, and verify merge or cleanup.

## MVP Acceptance Criteria

- Given a Forge-initialized project, the dashboard scans and displays specs and task progress.
- The user can start two different feature jobs that run in separate worktrees and record their target branch start SHA.
- The UI streams logs for running jobs.
- Completed jobs show branch, worktree path, changed files, diff summary, and task changes.
- The user can merge one completed job into the target branch through an integration worktree or keep the branch for manual review.
- Canceling, failed jobs, interrupted jobs, and merge conflicts preserve worktrees and logs for inspection.
