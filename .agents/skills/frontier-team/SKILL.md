---
name: frontier-team
description: Coordinate independently authenticated frontier-model peers through T3 Code's native MCP thread and task tools, with real peer exchange, bounded collaboration, and attributable evidence. Use when an owner requests a multi-provider AI team, cross-review, or divide-and-conquer work. Do not simulate other models.
---

# Frontier-model team — native T3 collaboration

Use this skill when asked to collaborate with **other actual provider instances**. Never impersonate another AI, pretend local Codex is this ChatGPT conversation, or claim a sibling's work occurred without its thread/run evidence.

This skill is for genuine inter-provider collaboration on an owner-authorized project. It is not permission to install apps, expose a server, read unrelated files, change permissions or credentials, or write to the Nervous System database directly.

## Preflight: identify and bound the team

1. Call `orchestrator_capabilities`. Inspect the actual provider instance IDs and available models. If fewer than two different authenticated frontier-provider kinds are operational, report the blocker; don't substitute a role-play or spawn two copies of the same model.
2. Use two providers first: **Claude Code** and **Codex**. Add Grok Build and Antigravity only if their own provider instances are available and a task warrants them. Distinguish a hosted ChatGPT MCP client from a local Codex provider. Do not label Codex "ChatGPT" as though they were the same running session.
3. Inspect this project's working directory and active work. Keep unrelated work untouched. For code edits, choose isolated worktrees; for a non-editing review, separate project threads are enough.
4. Confirm the owner has authorized the requested activity and that execution will run within the active runtime permission ceiling. Prefer **Supervised**. Never bypass pending approvals, copy credentials into messages, or increase permissions through child delegation.

## First working team

A team is a set of **distinct T3 threads backed by distinct provider instance IDs**, not simply personas written by a single model.

- **Coordinator**: initially the invoking provider's T3 thread. Owns the objective, task boundaries, completion accounting, cross-review, evidence inventory, and final answer.
- **Peer A (Claude)**: examines one independently testable part of the goal.
- **Peer B (Codex)**: examines a different part, then reviews one specific claim from Peer A.
- **Optional peers**: add only after the first two providers can exchange verified messages.

Use `create_threads` to launch independent top-level peer threads with explicit `target.providerInstanceId` and `target.model`. Use `delegate_task` for a bounded child whose result returns automatically to its parent; it starts with **only the task text**, not the parent's entire conversation. Put required context in the task prompt and references.

Do not start multiple expensive agents unless the work can be split meaningfully. Avoid spawning nested children by default.

## Cross-agent conversation

Use the native MCP tools. Do not implement another message bus just for the proof.

1. Record both thread IDs and actual provider/model selections returned by T3.
2. Send an explicit, finite request to the other peer with `t3_thread_send` `mode:"queue"`. `queue` avoids interrupting work in progress. Use `steer` or `restart` only for an owner-authorized intervention.
3. Include source thread ID, objective, exact question, scope, expected reply, and `reply_to`/conversation token in the message text. Tool delivery and model claims are not proof of completion.
4. Receiver reads the linked peer thread with `t3_thread_read` (usually `view:"messages"` first, `"activity"` for evidence) and answers in **its own thread**. To ask the sender a challenge, use `t3_thread_send` addressed to the sender's actual thread ID.
5. Sender acknowledges the challenge at most once. Then both report results to the coordinator. Use `t3_thread_wait` or `task_status` for genuine completion as appropriate. Do not tight-poll or assume a running task is done just because it emitted a partial answer.

### Bounded first exchange

For the first proof, perform exactly:
- one explicit **Claude → Codex** critique request through `t3_thread_send`,
- one explicit **Codex → Claude** counterquestion through `t3_thread_send`,
- Claude's answer to that counterquestion in its own thread,
- a joint summary.

An exchange counts only when T3's retained activity identifies the caller thread, recipient thread, and completed turns from distinct provider instances. Two identical model names written in plain text do not count.

Do **not** create infinite "reply to every reply" loops. No unsolicited extra sends, no unbounded automatic follow-ups, one outstanding cross-peer request per direction, and a maximum of two cross-thread messages per peer in the pilot. A stopped, blocked, or awaiting-approval peer stays visible as such.

## Evidence and synthesis

Produce a final coordinator response with:
- provider instance IDs, model names, T3 project and thread IDs, run/task IDs;
- the cross-peer question, counterquestion, and resolved/unresolved disagreement;
- sources/commits/tests each peer actually inspected (not mere descriptions);
- status `complete`, `blocked`, or `partial` for each task;
- a combined recommendation that preserves dissent and uncertainty.

T3 retains its native event log. The owner's **Nervous System** remains the authority for shared project decisions, provenance, and long-term cross-agent records. If an authorized Nervous System connector is available, write a compact receipt with the T3 IDs and evidence links via **named NS operations**, never by writing `ns.sqlite3`. When the connector is absent, return the receipt for the operator to capture; never claim it was stored.

## When unavailable

If T3 is only cloned, the server is not running, provider authentication is missing, the native MCP tools are unavailable, or the named target is outside the current permissions, state that exact blocker and stop the live proof. You may still produce a dry-run plan, but label it simulation/planning and not a working team.

## Pointers

- `docs/experiments/frontier-team-proof.md` (owner's test and operator instructions).
- `scripts/frontier-team-preflight.sh` (non-mutating readiness check).
- `scripts/frontier-team-proof.sh` (opt-in creation of two real provider threads).
- `apps/server/src/mcp/toolkits/orchestrator/tools.ts` (native T3 tool declarations).
- `packages/contracts/src/orchestratorMcp.ts` (thread and task schemas).
- `docs/user/outside-agents.md` (OAuth for agents not launched by T3).
- `docs/user/permission-modes.md` (Supervised/Auto/Full access semantics).
