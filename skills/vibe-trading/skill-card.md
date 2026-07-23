## Description: <br>
Professional finance research toolkit for backtesting, factor analysis, options pricing, trade-journal analysis, shadow-account research, market-data access, and multi-agent finance research workflows. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[warren618](https://clawhub.ai/user/warren618) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
External developers, analysts, and agent users use this skill to connect Vibe Trading MCP tools for market research, strategy backtesting, factor analysis, options analysis, trade-journal review, and generated finance reports. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill may read local trade journals, generated strategy files, documents, and optional broker or account data. <br>
Mitigation: Use only with data you are comfortable exposing to the finance tool, and redact broker account identifiers from CSV exports where possible. <br>
Risk: Broad external MCP tool loading can expand what connected agents are allowed to call. <br>
Mitigation: Connect only trusted MCP servers and replace wildcard enabledTools settings with narrow allowlists. <br>
Risk: Broker OAuth tokens and market-data API keys can grant access to sensitive account or data-provider resources. <br>
Mitigation: Treat broker OAuth tokens and API keys as sensitive credentials and avoid sharing generated configs or logs that contain them. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/warren618/skills/vibe-trading) <br>
- [Publisher profile](https://clawhub.ai/user/warren618) <br>
- [IBKR MCP endpoint referenced by artifact](https://api.ibkr.com/v1/api/mcp) <br>


## Skill Output: <br>
**Output Type(s):** [Text, Markdown, Code, Shell commands, Configuration, Guidance] <br>
**Output Format:** [Markdown, JSON configuration snippets, shell commands, generated files, and finance analysis reports] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May read local strategy files, broker exports, documents, and optional broker or market-data credentials when users enable those workflows.] <br>

## Skill Version(s): <br>
0.1.11 (source: release evidence and SKILL.md frontmatter) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
