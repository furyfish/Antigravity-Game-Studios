# Antigravity Game Studios (AGS) — Game Studio Agent Architecture

Indie game development managed through 49 coordinated Antigravity & AI subagents.
Each agent owns a specific domain, enforcing separation of concerns, high code quality, and structured game development.

> **Fork & Upstream Compatibility**: This project is ported to native **Antigravity** (supporting both Antigravity IDE/App and Antigravity CLI) while maintaining 100% backward and upstream sync compatibility with [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios).

---

## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.
---

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md

> **Engine Configuration Synchronization**:
> Whenever `/setup-engine` or an architectural decision modifies the Technology Stack or the Engine Reference Import, the agent MUST propose the identical update for both `ANTIGRAVITY.md` and `CLAUDE.md` (or run `bash scripts/sync-engine-config.sh` to mirror changes).


---

## Project Structure

For full tree details, see [.agent/docs/directory-structure.md](.agent/docs/directory-structure.md) (or `@.claude/docs/directory-structure.md`).

```text
├── .agent/                  # Canonical Antigravity agent configuration & tools (symlink to .claude)
│   ├── agents/              # 49 Subagent role specifications (.md)
│   ├── skills/              # 74 Workflow skills & slash commands
│   ├── workflows/           # Workflows directory (symlink to skills)
│   ├── rules/               # 13 Contextual domain rules
│   ├── hooks/               # 14 Lifecycle hook scripts
│   ├── scripts/             # 10 Deterministic analysis & observability scripts
│   ├── docs/                # Architectural, coordination, and standard docs
│   ├── settings.json        # Permissions, hooks, and statusline config
│   └── statusline.sh        # Dynamic terminal statusline script
├── .antigravity/            # Symlink alias to .agent
├── .claude/                 # Upstream source directory (kept for seamless git merge)
├── ANTIGRAVITY.md           # Master Antigravity instruction file (this file)
├── GEMINI.md                # Symlink to ANTIGRAVITY.md (for Gemini CLI / Antigravity CLI)
├── AGENTS.md                # Symlink to ANTIGRAVITY.md (Universal multi-agent spec)
├── CLAUDE.md                # Claude Code instruction file
├── project.yaml             # Primary project configuration store
├── design/                  # Game Design Documents (GDDs), UX specs, and design systems
├── docs/                    # Architecture Decision Records (ADRs) & engine references
│   └── engine-reference/   # Version-pinned API reference guides (Godot, Unity, Unreal)
├── production/              # Epics, stories, sprints, milestones, and session state
│   └── session-state/       # active.md session recovery checkpoint
├── src/                     # Game source code (or Assets/ for Unity, Source/ for Unreal)
├── tests/                   # Automated unit, integration, and smoke tests
└── CCGS Skill Testing Framework/ # Quality assurance layer for all skills and agents
```

---

## Contextual Domain Rules (in `.agent/rules/`)

Before inspecting, authoring, or modifying files in specific project domains, agents MUST read and follow the corresponding rule in `.agent/rules/`:
- **AI Systems**: `ai-code.md` for AI architectures, behavior trees, utility AI (`src/ai/**`, `Assets/**/AI/**`).
- **Data Schemas & JSON**: `data-files.md` for data schemas, balance tables, and game data definitions (`assets/data/**`).
- **Design Documents**: `design-docs.md` for GDDs, concept briefs, system mechanics, and economy designs (`design/**`).
- **Engine Integration**: `engine-code.md` for node hierarchy, lifecycle methods, and engine API conventions.
- **Gameplay Code**: `gameplay-code.md` for core loop mechanics, state machines, and player controllers.
- **Narrative**: `narrative.md` for dialogue data, quests, lore, and text localization keys.
- **Network & Multiplayer**: `network-code.md` for client-server boundaries, state synchronization, and lag compensation.
- **Prototypes**: `prototype-code.md` for throwaway prototype guardrails, hack isolation, and timeboxes.
- **Shaders & VFX**: `shader-code.md` for custom shaders, materials, performance budgets, and passes.
- **Skill Authoring**: `skill-authoring.md` for standards when creating or modifying skills and workflows.
- **Test Standards**: `test-standards.md` for unit, integration, smoke, and headless test requirements.
- **UI & UX**: `ui-code.md` for UI component hierarchy, layout responsiveness, and accessibility hooks.
- **Agent Memory**: `agent-memory.md` for persistent agent notes and project memory boundaries.

---

## Technical Preferences & Configuration

`project.yaml` at the repo root is the **single source of truth** for project settings — engine, language, specialist routing, naming conventions, target platform, performance budgets, and operational modes (`modes.rigor`, `modes.automation`).
Skills resolve configuration via `resolve_config` (see [.agent/docs/config-resolution.md](.agent/docs/config-resolution.md)).

- **`modes.rigor`**:
  - `minimal` (Solo/Jam mode: game brief, lightweight ADRs, lean reviews)
  - `standard` (Indie production: GDDs, critical ADRs, structured gates)
  - `full` (Commercial release: complete 8-section GDDs, full ADR coverage, director sign-offs)
- **`modes.automation`**:
  - `collaborative` (Default: confirms decisions, reviews drafts before writing)
  - `semi-autonomous` (Auto-executes within approved phases)
  - `autonomous` (Headless/batch execution against validated specs)

Per-developer local overrides belong in `project.local.yaml` (gitignored).

---

## Antigravity Native Tool Mapping Matrix

When operating in Antigravity (App/IDE or CLI), agents map standard workflows to Antigravity tools:

| Workflow Action | Antigravity Tool | Description |
|-----------------|------------------|-------------|
| **Read File** | `view_file` | Read source code, specs, GDDs, and documentation |
| **Write File** | `write_to_file` | Create new files after approval |
| **Edit File** | `replace_file_content` | Make targeted, contiguous modifications to existing files |
| **Run Command** | `run_command` | Execute tests, build scripts, analysis tools, and git |
| **Ask User** | `ask_question` | Present interactive questions, option menus, and decisions |
| **Delegate Subagent** | `invoke_subagent` | Spawn specialized agents (e.g. `lead-programmer`, `qa-lead`) |
| **Define Subagent** | `define_subagent` | Instantiate custom subagents from `.agent/agents/*.md` |
| **Manage Tasks** | `manage_task` | Monitor or interact with background processes |
| **Schedule / Wait** | `schedule` | One-shot timers or recurring monitoring |
| **Web Search** | `search_web` / `read_url_content` | Fetch external engine docs, asset specs, or libraries |
| **Image Generation** | `generate_image` | Generate concept art, UI mockups, or textures |

---

## Dynamic Subagent Registration & Delegation

In Antigravity, subagents are registered via `define_subagent` and executed via `invoke_subagent`:

1. **Check Registration**: When delegating to any studio specialist (from the 49 agents below), if the subagent is not yet present in the conversation's available subagents, extract its definition using:
   ```bash
   python3 scripts/get-agent-def.py <agent-name>
   ```
2. **Define**: Call `define_subagent` with the name, description, system prompt, and capabilities output by the helper.
3. **Invoke**: Call `invoke_subagent` with `TypeName: "<agent-name>"`.

---

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

1. **Ask before writing**: Agents MUST ask *"May I write this to [filepath]?"* before invoking `write_to_file` or `replace_file_content` (exempt: `production/session-state/active.md` appends, agent memory, and orchestrator-directed new files).
2. **Drafts first**: Agents MUST show code drafts or specification summaries before requesting write approval.
3. **Multi-file changes**: Require explicit approval for the full changeset before modifying files.
4. **No unauthorized commits**: No git commits without explicit user instruction.
5. **A skipped question is not an answer**: Re-ask in plain text and wait for confirmation.
6. **Started outside project root?**: Warn first — hooks, rules, and configuration resolve relative to the project root.

See [docs/COLLABORATIVE-DESIGN-PRINCIPLE.md](docs/COLLABORATIVE-DESIGN-PRINCIPLE.md) for full protocol details.

> **First session?** If the project has no engine configured and no game concept, run `/start` to begin the guided onboarding flow.

---

## Coordination Rules & Agent Hierarchy

See [.agent/docs/coordination-rules.md](.agent/docs/coordination-rules.md) for full coordination rules.

### Studio Roster (49 Specialized Agents in `.agent/agents/`):
- **Directors (4)**: `creative-director` (Vision), `technical-director` (Architecture), `producer` (Scope/Timeline), `art-director` (Visual style).
- **Department Leads (7)**: `lead-programmer`, `narrative-director`, `audio-director`, `game-designer`, `systems-designer`, `level-designer`, `qa-lead`.
- **Specialists (13)**: `gameplay-programmer`, `engine-programmer`, `network-programmer`, `ai-programmer`, `tools-programmer`, `ui-programmer`, `ux-designer`, `technical-artist`, `sound-designer`, `performance-analyst`, `prototyper`, `writer`, `world-builder`.
- **Engine Specialists (15)**:
  - *Godot*: `godot-specialist`, `godot-gdscript-specialist`, `godot-csharp-specialist`, `godot-shader-specialist`, `godot-gdextension-specialist`.
  - *Unity*: `unity-specialist`, `unity-ui-specialist`, `unity-shader-specialist`, `unity-dots-specialist`, `unity-addressables-specialist`.
  - *Unreal*: `unreal-specialist`, `ue-gas-specialist`, `ue-replication-specialist`, `ue-umg-specialist`, `ue-blueprint-specialist`.
- **Operations (7)**: `devops-engineer`, `release-manager`, `live-ops-designer`, `community-manager`, `analytics-engineer`, `economy-designer`, `localization-lead`.
- **QA & Reliability (3)**: `qa-tester`, `security-engineer`, `accessibility-specialist`.

---

## Workflow Skills & Slash Commands (74 Skills in `.agent/skills/`)

Skills can be triggered via slash commands (e.g. `/start`, `/setup-engine`) or invoked during workflow progression:

| Category | Primary Skills | Description |
|----------|----------------|-------------|
| **Gate** | `/gate-check` | Evaluate stage transition gates (Concept → Prototype → Pre-Prod → Prod → Polish → Launch) |
| **Review** | `/design-review`, `/architecture-review`, `/review-all-gdds`, `/ux-review` | Formal design and code architecture reviews |
| **Authoring** | `/design-system`, `/quick-design`, `/architecture-decision`, `/art-bible`, `/create-architecture`, `/ux-design` | Author GDDs, ADRs, Art Bibles, and UX specifications |
| **Readiness** | `/story-readiness`, `/story-done` | Validate stories meet Definition of Ready and Definition of Done |
| **Pipeline** | `/create-epics`, `/create-stories`, `/dev-story`, `/create-control-manifest`, `/propagate-design-change`, `/map-systems`, `/vertical-slice` | Decompose design into epics, stories, and implemented tasks |
| **Analysis** | `/consistency-check`, `/balance-check`, `/content-audit`, `/code-review`, `/tech-debt`, `/scope-check`, `/estimate`, `/perf-profile`, `/asset-audit`, `/security-audit`, `/test-evidence-review`, `/test-flakiness` | Deterministic analysis, performance profiling, and code health audits |
| **Team** | `/team-combat`, `/team-narrative`, `/team-audio`, `/team-level`, `/team-ui`, `/team-qa`, `/team-release`, `/team-polish`, `/team-live-ops` | Multi-agent collaboration squads for specific domains |
| **Sprint** | `/sprint-plan`, `/sprint-status`, `/milestone-review`, `/retrospective`, `/changelog`, `/patch-notes` | Agile sprint lifecycle management |
| **Utility** | `/start`, `/setup-engine`, `/test-setup`, `/smoke-check`, `/soak-test`, `/prototype`, `/adopt`, `/onboard`, `/help` | Onboarding, engine configuration, testing, and assistance |

---

## Coding Standards

See [.agent/docs/coding-standards.md](.agent/docs/coding-standards.md) (or `@.claude/docs/coding-standards.md`) for full guidelines:
- All public APIs require doc comments.
- Gameplay values must be **data-driven** (external config/resources), never hardcoded in logic.
- Prefer dependency injection over singletons for testability.
- Commits must reference the relevant story ID or design document.
- Follow engine-specific idioms (Godot node composition, Unity Component/DOTS, Unreal GAS/Actor patterns).

---

## Context Management & Session Checkpointing

- **`production/session-state/active.md` is the session checkpoint**: Memory persists on disk across session resets, restarts, and compacts. Always read `active.md` when resuming work.
- **Active Session Initialization**: At the beginning of each session or before starting a major task, run `bash .agent/hooks/session-start.sh` and `bash .agent/hooks/detect-gaps.sh` to load current branch context, uncommitted status, and missing documentation artifacts.
- **Deterministic Helpers in `.agent/scripts/` emit observations, never verdicts**: Scripts such as `project-coherence.sh`, `artifact-check.sh`, `story-status.sh`, and `gdd-structure-check.sh` output factual checks; the agent and user determine the verdict.

---

## Running in Antigravity

### 1. In Antigravity IDE / App
- Open this workspace folder in Antigravity IDE.
- The IDE automatically detects `ANTIGRAVITY.md`, `.agent/rules/`, and `.agent/skills/`.
- Use slash commands in chat (e.g. `/start`, `/setup-engine`, `/gate-check`) or ask questions naturally.
- The AI assistant uses `ask_question` for interactive decisions and respects the collaboration protocol.

### 2. In Antigravity CLI / Gemini CLI
- Launch your terminal in the workspace directory.
- Run commands with full access to hooks and scripts in `.agent/hooks/` and `.agent/scripts/`.
- The terminal statusline is driven by `.agent/statusline.sh`.

### 3. Upstream Sync
- To sync updates from the upstream Claude-Code-Game-Studios repository in the future, follow [FORK-SYNC-GUIDE.md](FORK-SYNC-GUIDE.md) or run `bash scripts/sync-upstream.sh`.
