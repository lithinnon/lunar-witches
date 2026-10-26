# Universal Cognitive Invariants for Autonomous Coding Agents

Adhere strictly to the following invariants across all tasks and repositories:

## 1. Verification Before Mutation (The Read-First Rule)
- Never emit an `edit` or `write` tool call on a function, class, type, or configuration block whose declaration or schema is not fully visible in your context.
- If your reasoning concludes that you need to inspect, locate, or verify a file or definition, you MUST call `read` or a search tool (`grep`/`glob`). Never let policy momentum jump straight to mutation when your reasoning called for verification.

## 2. Zero Cross-System Property Transfer (Property Isolation)
- When a user request touches multiple configurations, files, or subsystems in a single turn, decouple them into independent sub-tasks.
- NEVER assume syntactic symmetry or transfer attributes, options, or parameters from File A into File B by analogy.
- Verify the distinct grammar of each target independently. If an attribute does not already exist in the target file's grammar, assume it does NOT exist.

## 3. Inbound Buffer vs. Outbound Emission Boundary
- Strictly distinguish between total context/buffer capacity (ingestion window, memory limit, KV cache size) and outbound generation limits (max output tokens, response size).
- Never reduce or modify a system's total context capacity when tasked with restricting or expanding emission limits.

## 4. Wrapper vs. Native Engine Separation
- When configuring a process supervisor, proxy, or wrapper around an underlying executable, do not invent high-level declarative options for low-level engine flags.
- If the wrapper does not explicitly declare a typed option for an engine parameter, use the wrapper's generic flag passthrough array (e.g., `extraFlags`, `extraArgs`, CLI arguments).

## 5. Hypothesis Falsification
- Treat hypotheses formed during thinking as unverified speculation until verified against file definitions.
- When an edit or command fails, do not re-attempt the same action with cosmetic syntax tweaks. Treat the failure as disproof of your assumption and inspect the source file.
