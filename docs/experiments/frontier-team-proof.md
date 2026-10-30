# First experiment: Claude ↔ Codex, then a frontier-model team

> **Status:** source implementation and operator-run test, **not proof that two models have exchanged messages on the Mac**.
>
> This document applies to the owner's T3 Code fork `vannostrand1/t3code`. It does not modify the running Nervous System and does not require a new orchestration server.

## What we are proving

An actual Claude Code runtime and an actual Codex runtime, selected as different **T3 provider instances**, must communicate through T3's own MCP tools while preserving the names, message origins, thread IDs, and output of each model. A single model impersonating two agents is an invalid test. Model names appearing in messages are not evidence.

The complete upstream project already implements the machinery:
- `orchestrator_capabilities` lists available provider instances and model choices.
- `create_threads` launches independent top-level T3 threads.
- `delegate_task` launches a bounded subagent task, with optional `isolation:"worktree"`. The task gets the given task prompt, not the full parent history.
- `t3_thread_send` sends to another thread and supports `mode:"queue"` without an interruption.
- `t3_thread_read` reads the target thread's messages/activity.
- `t3_thread_wait` and `task_status` expose actual progress and completion.

We first use **top-level peer threads**, rather than provider-native subagents, because the requirement is **independently authenticated frontier models working together**. A coordinator may use subagents for separate work once the cross-provider communication proof succeeds.

## Phase 0: keep the Mac safe

1. Leave the existing `~/AdamVoiceLab` dashboard, port 8790, and its launchd jobs unchanged. Leave NS data and credentials unchanged.
2. Launch T3 in its **own environment** on a separate test project. A Git checkout alone is not a running T3 server. The official T3 desktop app/CLI is a separate runtime; start it only after reviewing it.
3. In T3 **Settings → Threads → New threads → Permissions**, change the initial default from **Full access** to **Supervised**. Confirm any project override is also Supervised.
4. In **Settings → Providers**, verify Claude Code and Codex with their actual account logins. Record two *different provider instance IDs* and their supported model slugs using `orchestrator_capabilities`. A second Claude instance is not a Codex instance.
5. Keep this first experiment read-only. Prefer a disposable Git project with harmless text files; do not give the agents your real files, secrets, or ability to modify a protected project.
6. Do not enable T3 Connect, open an internet tunnel, or grant a cloud MCP client `Full access` just to prove local Claude–Codex cooperation. Local providers can talk within one T3 server.

## Phase 1: local preflight

In the personal fork's checkout:

```bash
cd "$HOME/Developer/t3code"
bash scripts/frontier-team-preflight.sh
```

The preflight only checks local commands and never installs anything. `t3` must be installed and its server must be running before a real experiment; binaries or sign-ins alone do not prove a live T3 environment.

For a source development build, T3's official instructions use `vp i` and `vp run dev` and isolate `.t3` development state. Read `docs/operations/development.md` before choosing this route. An official packaged CLI instead uses `t3` to launch the server. **Do not run a dev server against the live `~/.t3/userdata`.**

## Phase 2: run the bounded two-model test

Pick a disposable project directory with no private information, then copy the **real** IDs and model slugs returned from T3 provider discovery:

```bash
bash scripts/frontier-team-proof.sh --run \
  "$HOME/Developer/t3-frontier-pilot" \
  "ACTUAL_CLAUDE_PROVIDER_INSTANCE_ID" "ACTUAL_CLAUDE_MODEL_SLUG" \
  "ACTUAL_CODEX_PROVIDER_INSTANCE_ID" "ACTUAL_CODEX_MODEL_SLUG"
```

**Do not paste the placeholders as though they were real IDs.** If the provider is missing, first connect that provider through T3.

The harness:
- creates a new Claude thread via `t3 thread start --provider ... --model ... --json`;
- creates a distinct Codex thread the same way and supplies the actual Claude thread ID;
- uses the CLI only to send a kickoff instruction **to Claude**;
- asks Claude to initiate a `t3_thread_send` message to Codex; asks Codex to send its own counterquestion to Claude;
- saves only the returned thread-launch metadata and kickoff instruction to a private temporary receipt directory;
- prints `LAUNCHED, NOT YET VERIFIED` rather than claiming both models have exchanged messages.

If either `t3 thread start` fails, a partial pilot thread may remain. Do not automatically delete user threads, cancel jobs, or claim success. The printed receipts and T3 interface show which thread was created.

### A real success receipt requires all of these

| Evidence | Acceptance |
| --- | --- |
| Provider identity | Two distinct actual T3 provider instance IDs; one Claude, one Codex; models confirmed in thread detail |
| Execution | Both threads have completed real provider turns with nonempty outputs |
| Peer exchange | Claude issued a genuine T3 `t3_thread_send` tool call directed at Codex and Codex received it |
| Reverse exchange | Codex issued a genuine T3 `t3_thread_send` tool call directed at Claude and Claude received it |
| Bounded behavior | No runaway replies, duplicates, silent task failures, or unsolicited third agent |
| Combined outcome | Coordinator or owner receives a summary preserving facts, critique, and unresolved differences |
| Durability | Same threads and peer messages visible after refreshing or restarting **only T3**, without rerunning the kickoff |
| Permissions | New-thread/peer permission ceilings remained Supervised and the experiment touched only the disposable project |

Check each thread's **Activity** view in T3 for actual tool calls. The CLI `t3 thread show --json THREAD_ID` supplies thread and message details, but that alone does not prove the tool origin. Use the full activity read through `t3_thread_read` `view:"activity"` for a tool-level audit.

## Phase 3: move from a pilot to a useful team

Once the two-provider experiment passes:
1. Coordinator splits a real task into independent research/review/implementation parts.
2. Claude and Codex run in parallel, and each peer reviews one specific result of the other.
3. If useful and separately authenticated, add Grok Build or Antigravity/Gemini providers by their own instance IDs.
4. If the owner wants *this hosted ChatGPT session* at the table, connect T3 as a separate external OAuth MCP app over an approved reachable HTTPS endpoint. T3's docs recommend T3 Connect for hosted agents; a Mac-local or private Tailscale address is not enough for ChatGPT cloud access.
5. Persist the final joint result, disagreement, source evidence, provider identities, and T3 thread/run links through authorized named **Nervous System operations**. Do not bypass the NS rule that no stored field can contain an unqualified bare zero.

The desired multi-column Round Table with the owner's column, individual AI lanes, podium, voting and combined synthesis is **a later UX/governance layer** over these working T3 threads. This pilot must pass before that development work is undertaken.

## Failure modes to expect

- **T3 cloned but CLI not installed:** source checkout is not executable service. Do not claim installed.
- **No `t3` command:** the pilot script stops without changing anything.
- **Provider auth incomplete:** T3's start call returns an error, not a substitute model.
- **Two provider IDs identical:** the pilot script refuses to run.
- **MCP tool absent from provider:** the model may not have inherited the native T3 tools. Check the launched provider and T3 environment. Do not substitute Terminal scripts and call it agent-to-agent.
- **One thread stuck on permission prompt:** mark blocked; the user decides. Do not elevate automatically.
- **Tool reports delivery queued:** delivery is not completion. Wait for and verify the receiving provider's turn.
- **Cross-provider context switch:** T3 transfers a bounded conversation selection, not the full native provider session or the model's KV cache.
- **Nervous System connector absent:** keep T3 native evidence and return a receipt for later NS capture; never fabricate a record address.

## Source documents examined

`apps/server/src/cli/thread.ts`, `apps/server/src/mcp/toolkits/orchestrator/{tools,handlers}.ts`, `packages/contracts/src/orchestratorMcp.ts`, `docs/user/{outside-agents,permission-modes,portable-handoffs,providers-claude,providers-codex}.md`, and `docs/internals/{overview,environment-auth}.md`.

Parent project requirement: [AI-SHARED-PROJECTS issue #3](https://github.com/vannostrand1/AI-SHARED-PROJECTS/issues/3).
