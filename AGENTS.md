# Instructions for AI agents (Claude, Codex, Copilot, Cursor, Gemini)

<!-- SF-SKILLS:BEGIN -->

## Salesforce build rules (all AI tools)

This repo ships Salesforce's official agent skills from [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills) in `.agents/skills/` (Claude Code reads the same folder through `.claude/skills`). They are synced weekly by `.github/workflows/sync-sf-skills.yml`. The list of installed skills is in `.agents/sf-skills.txt`.

### Use the skills first

1. Before creating or changing any Salesforce metadata, find the matching skill in `.agents/skills/` and follow its `SKILL.md`. Order of preference: skill, then Salesforce CLI (`sf`), then MCP tools, then hand-written files.
2. Check object, field and metadata names with `platform-data-and-tooling-api-context-get` or `platform-metadata-api-context-get`, or by retrieving from the org. Do not guess API names.
3. Start new metadata from Salesforce templates (`sf template generate ...`, for example `sf template generate flexipage`), not from blank XML.

### Declarative work

- Objects, fields, validation rules, picklists, list views, tabs, apps, permission sets, flows and reports each have a skill. Use it.
- Lightning record, app and home pages: use `platform-flexipage-generate`. Only place components that exist in the org or in this repo.
- Classic page layouts (`*.layout-meta.xml`) have no skill. Retrieve the current layout from the org first (`sf project retrieve start --metadata "Layout:<Object>-<Layout Name>"`), change only what was asked, and keep every existing field, section and related list unless told to remove it.
- Prefer configuration (fields, flows, pages, permission sets) over Apex and custom LWC when the standard feature does the job.

### Prove it before calling it done

Report these as separate levels of evidence. Never describe a lower level as a higher one.

1. Local checks: lint, Jest and Code Analyzer (`dx-code-analyzer-run`) pass.
2. Validated: `sf project deploy start --dry-run ...` succeeds against the target org.
3. Deployed: the real deploy succeeds and Apex tests pass in the org.
4. Accepted: a person has checked the result in the org (screenshot or walkthrough).

### Org safety

- Always validate (`--dry-run`) before a real deploy. No destructive changes unless the owner asks.
- Changes to users, profiles, sharing, site settings, licenses and standard picklists need owner approval.
- Use demo data only. Never commit credentials, tokens or `.env` files with secrets.

### Updating the skills

- Add or remove names in `.agents/sf-skills.txt`, then run `bash scripts/sync-sf-skills.sh`.
- Do not edit files inside `.agents/skills/<sf-skill>/`; the next sync overwrites them. Put repo-specific skills in their own folder under `.agents/skills/` with a name that does not start with `platform-`, `dx-`, `experience-`, `omnistudio-`, `automation-`, `integration-`, `education-cloud-` or `design-systems-`.

<!-- SF-SKILLS:END -->
