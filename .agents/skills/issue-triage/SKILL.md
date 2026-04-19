# Issue Triage Skill

Automatically triages new GitHub issues by analyzing content, applying labels, assigning priority, and routing to appropriate team members.

## What This Skill Does

- Reads newly opened or updated GitHub issues
- Classifies issue type (bug, feature request, question, documentation)
- Assigns relevant labels based on content analysis
- Determines priority level (critical, high, medium, low)
- Identifies affected components (agents, tools, tracing, streaming, etc.)
- Posts a structured triage comment summarizing findings
- Optionally requests additional information when issue is unclear

## Trigger Conditions

This skill runs when:
- A new issue is opened in the repository
- An issue is edited with significant content changes
- Manually triggered via workflow dispatch

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `issue_number` | GitHub issue number to triage | Yes |
| `repo` | Repository in `owner/repo` format | Yes |
| `github_token` | GitHub token with issues write permission | Yes |

## Outputs

The skill will:
1. Apply one or more labels from the defined taxonomy
2. Post a triage comment with structured analysis
3. Set issue assignees if routing rules match

## Label Taxonomy

### Type Labels
- `bug` — Something isn't working as expected
- `enhancement` — New feature or improvement request
- `question` — User asking for help or clarification
- `documentation` — Docs missing, incorrect, or unclear
- `performance` — Performance degradation or optimization request

### Priority Labels
- `priority: critical` — Blocks core functionality, needs immediate attention
- `priority: high` — Significant impact, address in current cycle
- `priority: medium` — Moderate impact, address soon
- `priority: low` — Minor issue, address when convenient

### Component Labels
- `component: agents` — Core agent runtime
- `component: tools` — Tool definitions and execution
- `component: tracing` — Tracing and observability
- `component: streaming` — Streaming responses
- `component: handoffs` — Agent handoff mechanism
- `component: guardrails` — Input/output guardrails
- `component: memory` — Memory and context management
- `component: examples` — Example scripts and notebooks

## Configuration

Routing rules and label mappings can be customized in `config/triage-rules.yaml`.

## Example Triage Comment

```
### 🏷️ Issue Triage Summary

**Type:** Bug  
**Priority:** High  
**Component:** component: streaming  

**Analysis:**  
This issue describes unexpected behavior in the streaming response handler where tokens are dropped under high load. Reproducible with the provided script.

**Next Steps:**  
- Assigned to streaming component owner for investigation
- Added to current sprint backlog
```
