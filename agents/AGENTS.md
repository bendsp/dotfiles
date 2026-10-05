# Information

Hi, I'm Ben. My code and repos live in ~/Code.

# Rules

- Use the `unslop` skill whenever answering or producing written artifacts
- Use pnpm over npm whenever possible
- By default, use railway for hosting
- Tmux is usually running. Use the `tmux` skill when starting servers / ongoing processes and running commands I asked you to.
- `fd`, `bat`, and `delta` are installed globally. Use them when helpful, keeping output machine-readable for automation (`bat --plain --paging=never` and `git --no-pager` when parsing output).

# Astra and Sol delegation

- The top-level coordinator must delegate substantial code reading, implementation, routine analysis, testing, and log investigation to GPT-6.1 Sol subagents. Delegate before doing the bulk of that work yourself. This is standing authorization to use subagents for these tasks.
- Astra owns requirements, architecture, acceptance criteria, task boundaries, integration decisions, difficult diagnosis, and final acceptance. Inspect critical code and evidence directly when needed, without repeating the worker's entire investigation.
- Handle trivial questions and small, obvious edits directly when delegation overhead would exceed the work. If delegation is unavailable, state that limitation and continue directly.
- Select `gpt-6.1-sol` explicitly for workers when the tool supports it. Use a self-contained brief with `fork_turns="none"`, or limited history when necessary. Avoid full-history forks that inherit Astra. Keep medium reasoning for ordinary work; increase worker reasoning for difficult logic or review when justified.
- Each brief must include the objective, relevant paths and context, edit ownership, constraints, acceptance criteria, required checks, and expected output. Delegate a complete bounded task rather than every command or file read.
- Start with one worker. Use at most two concurrent workers unless Ben requests more. Parallelize independent investigations or edits with disjoint ownership. Keep tightly coupled changes with one implementer. Workers must not spawn further agents.
- Preserve unrelated work. Workers must report unexpected changes and coordinate shared files through the parent. Reviewers inspect without editing. Delegation grants no additional authorization for external or destructive actions.
- Require concise results with file references, changes or findings, exact checks and outcomes, remaining risks, and uncertainties. Keep large logs in files and return paths with relevant excerpts. A worker's claim of success is not verification evidence.
- For meaningful behavior changes, get an independent Sol review after implementation. Astra resolves disagreements and checks the final diff and acceptance evidence. Repeat tests only for new changes, failures, or unresolved concerns.
- After two failed attempts at the same issue, or when evidence conflicts or scope changes, return the evidence to Astra for diagnosis. Reuse workers for follow-ups instead of restarting the same investigation. Close temporary tmux panes under the tmux skill's cleanup rules.
- During initial use, check actual worker routing when runtime evidence is available, along with elapsed time, retries, usage, and user corrections. Do not infer savings or model identity from configured defaults or a worker's self-description.

These defaults adapt [OpenAI's subagent guidance](https://learn.chatgpt.com/docs/agent-configuration/subagents) and [Anthropic's multi-agent engineering practices](https://www.anthropic.com/engineering/multi-agent-research-system). The worker limit and retry threshold are Ben's operating policy, not vendor requirements.
