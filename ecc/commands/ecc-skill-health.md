---
name: ecc-skill-health
description: スキルポートフォリオのヘルスダッシュボード（チャート・分析付き）を表示する
command: true
---

# Skill Health Dashboard

Shows a comprehensive health dashboard for all skills in the portfolio with success rate sparklines, failure pattern clustering, pending amendments, and version history.

## Implementation

Run the skill health CLI in dashboard mode:

```bash
node .claude/scripts/skills-health.js --dashboard
```

For a specific panel only:

```bash
node .claude/scripts/skills-health.js --dashboard --panel failures
```

For machine-readable output:

```bash
node .claude/scripts/skills-health.js --dashboard --json
```

## Usage

```
/ecc-skill-health                    # Full dashboard view
/ecc-skill-health --panel failures   # Only failure clustering panel
/ecc-skill-health --json             # Machine-readable JSON output
```

## What to Do

1. Run the skills-health.js script with --dashboard flag
2. Display the output to the user
3. If any skills are declining, highlight them and suggest running /ecc-evolve
4. If there are pending amendments, suggest reviewing them

## Panels

- **Success Rate (30d)** — Sparkline charts showing daily success rates per skill
- **Failure Patterns** — Clustered failure reasons with horizontal bar chart
- **Pending Amendments** — Amendment proposals awaiting review
- **Version History** — Timeline of version snapshots per skill
