---
name: test
description: Apexテスト・LWCテストの設計・実装・カバレッジ検証を行う。テスト関連タスクでproactiveに使う。
tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
user-invokable: false
---

`.github/agents/salesforce.test.agent.md` のガイドラインと手順に従ってテストを実装・検証せよ。

追加ルール:

- テストクラス名は `<クラス名>Test` に統一
- カバレッジ目標は 80% 以上
- `docs/apex-testing.md` を必ず参照
