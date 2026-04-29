// SPDX-License-Identifier: Apache-2.0
//
// Identity primitives shared across every TAP message. See
// project-context.md §6.2 for derivation rules and trust semantics.

package schemas

// Stable per-user identifier. GitHub login during Phase 1–3; SAML/OIDC
// subject claim in enterprise deployments. Lowercased.
#DeveloperId: =~"^[a-z0-9][a-z0-9-]{0,38}$"

// Ephemeral per-session agent identifier. Derived as
//   agent_id = blake3(developer_id || machine_id || editor || session_id)
// Hex-encoded, 64 chars.
#AgentId: =~"^[0-9a-f]{64}$"

// Stable workstation identifier. Locally generated, persisted across
// daemon restarts.
#MachineId: =~"^[0-9a-f]{32}$"

// Editor identifier. Open enum — adapters may register additional values
// during Phase 5+ ecosystem expansion.
#Editor: "claude-code" | "cursor" | "codex" | "aider" | "generic-mcp" | string

// Canonical repo URL. Phase 1 supports https and ssh forms; the relay
// normalizes to a canonical https form before storage.
#RepoUrl: =~"^(https://|git@)[A-Za-z0-9._-]+(/|:)[A-Za-z0-9._/-]+(\\.git)?$"

// Git branch name. Restrictive subset of git's allowed characters; the
// daemon rejects branch names with control characters or path traversal.
#BranchName: =~"^[A-Za-z0-9_./-]{1,255}$" & !~"^\\." & !~"\\.\\."

// Filesystem path to a worktree, absolute, no trailing slash.
#WorktreePath: =~"^/[^\\0]+[^/]$"

// Capability strings declared at registration. Capabilities are advisory;
// the relay does not interpret them but routes them through to peers.
#Capability: =~"^[a-z][a-z0-9._-]*$"
