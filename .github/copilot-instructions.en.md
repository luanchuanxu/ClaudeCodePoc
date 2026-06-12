# Copilot / AI Agent Instructions for SECOM-BPR-Project/salesforce

## Purpose

This file serves as a **lightweight hub** for AI agents. Refer to `docs/` as the authoritative source for detailed specifications.

## Reading Order (For Both Humans and AI)

1. `docs/README.md`
2. `docs/salesforce-naming-rules.md`
3. `docs/apex-development.md`
4. `docs/apex-testing.md`
5. `docs/alfa-guide.md`
6. `docs/lwc-development.md`
7. `docs/alfa-component.md`
8. `docs/front-cpt-usage.md` (CPT team only, other teams may skip)

## Repository Overview

- `force-app/main/default` : Apex/LWC/Metadata
- `alfa/` : ALFA Framework assets
- `manifest/` : Deploy target management (`package.xml`, `package_cpt.xml`, `package_crm.xml`, etc.)
- `docs/` : Development standards & design documentation (authoritative)

## AI Implementation Rules (Required)

- Do NOT directly modify custom object/field physical names.
- Large-scale changes assume split PRs; enumerate scope (SOQL/UI/Tests/Integration).
- When modifying Apex logic, propose/implement related test updates.
- When adding new Apex/LWC, update the team-specific manifest (`manifest/package_cpt.xml`, `manifest/package_crm.xml`, `manifest/package.xml`, etc.).

## LWC/ALFA Critical Rules (Summary)

- `disabled` is synchronized on reducers side.
- `alfaButton` references `store.disabled.view.button[name]`; direct `@api disabled` is fundamentally prohibited.
- Avoid new use of SLDS (`slds-*`); utilize global CSS instead.
- LWC individual `.css` files are prohibited for Experience site LWCs. Allowed for Platform (internal admin) LWCs.

## Button Icon Policy

- Forward action: `icon-next-w.svg`
- Back action: `icon-back-k.svg`
- Background color requirement exceptions allowed

## Deployment Example (SFDX)

```bash
sfdx force:auth:web:login -a targetOrg
sfdx force:source:deploy -p force-app/main/default -u targetOrg -w 10
sfdx force:apex:test:run --resultformat human --wait 10 -u targetOrg
```

## Notes

Feature-specific design docs: refer to `docs/design/`; operational notes: refer to `docs/misc/`.

---

**⚠️ Documentation Language Notice:**

This project is primarily maintained in **Japanese** by the Japan-based development team. English versions (`*.en.md`) are provided for non-Japanese speaking team members and are automatically generated from Japanese sources. For the most current and authoritative information, always reference the Japanese versions (without the `.en` suffix).
