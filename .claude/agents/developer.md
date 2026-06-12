---
name: developer
description: Apex/LWC実装を行う。コード変更・新規実装時にproactiveに使う。
tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
user-invokable: false
---

`.github/agents/salesforce.developer.agent.md` のガイドラインと手順に従って実装を行え。

追加ルール:

- ALFA フレームワークのパターンは `docs/alfa-guide.md`、`docs/alfa-component.md` を必ず確認
- ビューに業務ロジックを書かない（dispatch のみ → Sagas で処理）
- チーム対応の manifest（`manifest/package_cpt.xml`, `manifest/package_crm.xml`, `manifest/package.xml` 等）の更新を忘れないこと
