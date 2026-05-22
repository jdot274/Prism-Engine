# Git Commit Metadata & Tagging Spec

To maintain a "double-durable" audit trail across the **Prism Engine** development lifecycle, we enforce a strict git commit tagging convention. Every major implementation, optimization, or research milestone must embed structural metadata directly in the commit message.

This links codebase changes directly to the **Prism Ledger** (our GitHub Issues board) and enables automated changelogs, searchability, and clear lineage.

---

## Commit Message Format

Commit messages should follow the **Conventional Commits** standard, with specific trailing footer blocks containing our custom ledger tags.

```
<type>(<scope>): <short descriptive summary>

[Optional body describing technical details or changes]

Closes #<issue-number>
Finding: "<declarative-finding-summary-or-url>"
Decision: "<chosen-tech-or-path>"
Workflow-Innovation: <innovation-identifier>
```

### Supported Conventional Types
*   `feat`: A new feature (e.g., color picker, WebTransport network link)
*   `fix`: A bug fix or correction
*   `perf`: Performance optimization (e.g., shader optimizations, asset bundle size reduction)
*   `refactor`: Code changes that neither fix a bug nor add a feature
*   `docs`: Documentation only changes
*   `tools`: Infrastructure or internal developer tooling (e.g., Cursor hooks, CLI scripts)

---

## Ledger Footer Tags

At the end of your commit message body, add one or more of these structured key-value pairs (one per line, capitalized, separated by a colon and a space).

### 1. `Closes #<issue-number>`
The standard GitHub footer to automatically close a related `type/action-item` or `type/finding` issue when the commit is merged into `master`.

### 2. `Finding: "<finding-title-or-url>"`
Used when the commit directly implements or verifies a research finding. Embed the exact finding title in double quotes, or provide the URL to the corresponding GitHub issue.

*   *Example*: `Finding: "PlayCanvas WebGL viewer performs well with 10k entities"`

### 3. `Decision: "<decision-title-or-url>"`
Used when the commit represents the realization of an architectural decision. Links the code change directly to the strategic architectural choice.

*   *Example*: `Decision: "Adopt WebTransport over WebSockets for Fork B multiplayer netcode"`

### 4. `Workflow-Innovation: <identifier>`
Highlights a major workflow leap implemented in the codebase (e.g., custom code generators, agent hooks, CI loops). This flags high-value engineering achievements for retrospectives and onboarding.

*   *Example*: `Workflow-Innovation: cursor-github-bridge`

---

## Real-World Examples

### Example 1: Implementing a Feature from a Ledger Action Item
```
feat(color-picker): implement custom 3D HSL shader picker in web-client

Builds a responsive 3D HSL color wheel shader operating in UV space.
Provides an interactive on-mesh coordinate mapper so that pointer events paint
color values directly onto the material instance dynamic render target.

Closes #14
Finding: "3D HSL picker integrates with dynamic material instances"
Workflow-Innovation: custom-shader-interop
```

### Example 2: Resolving a Network Bug Based on a Discovery
```
fix(netcode): fix WebTransport packet serialization float precision

Forces single-precision float conversion (float32) for position vector encoding in
unreliable datagram payloads, resolving the 4-byte stream alignment mismatch on the Rust host.

Closes #22
Finding: "SpacetimeDB Rapier-WASM alignment requires packed structures"
```
