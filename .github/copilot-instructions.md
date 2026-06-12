# Copilot / AI Agent instructions for SECOM-BPR-Project/salesforce

## 目的

このファイルは AI 向けの**軽量ハブ**です。詳細規約は `docs/` を正本として参照してください。

## まず読む順序（人/AI共通）

1. `docs/README.md`
2. `docs/salesforce-naming-rules.md`
3. `docs/apex-development.md`
4. `docs/apex-testing.md`
5. `docs/alfa-guide.md`
6. `docs/lwc-development.md`
7. `docs/alfa-component.md`
8. `docs/front-cpt-usage.md`（CPTチーム向け、他チームはスキップ可）

## リポジトリ概要

- `force-app/main/default` : Apex/LWC/Metadata
- `alfa/` : ALFA フレームワーク資産
- `manifest/` : デプロイ対象管理（`package.xml`, `package_cpt.xml`, `package_crm.xml` 等）
- `docs/` : 開発規約・設計資料（正本）

## AI 実装ルール（必須）

- カスタムオブジェクト/項目の物理名変更を直接実施しない。
- 大規模変更は分割PR前提で、影響範囲（SOQL/UI/テスト/連携）を列挙する。
- Apex ロジック変更時は関連テスト更新を提案/実装する。
- 新規 Apex/LWC 追加時はチーム対応の manifest（`manifest/package_cpt.xml`, `manifest/package_crm.xml`, `manifest/package.xml` 等）を更新する。

## AI 行動原則（共通）

### コア原則

- **シンプル第一:** 変更は必要最小限に。影響するコードだけを触る
- **怠惰禁止:** 一時しのぎではなく根本原因を突き止める。シニアエンジニア水準を維持する
- **最小影響:** 必要な箇所だけ変更し、不注意で新たなバグを生まない

### 完了前の検証

- タスクを完了にする前に、動作を証明する（テスト実行・ログ確認・diff チェック）
- 自問する：「シニアエンジニアがこれを承認するか？」
- 特に Apex 変更後はテストクラスの実行結果を確認する

### エレガンスを求める（バランス重視）

- 重要な変更では「もっとエレガントな方法はないか？」を一度問う
- ハック的な解決策と感じたら、フルコンテキストで再実装を検討する
- 単純な修正には適用しない——過剰設計を避ける

### 自律的バグ修正

- バグ報告を受けたら、質問せずにまず自分で調査・修正する
- ログ・エラーメッセージを手がかりに自律的に解決する
- ユーザーのコンテキストスイッチをゼロにすることを目指す

## LWC/ALFA 重要ルール（抜粋）

- `disabled` は reducers 側で同期する。
- `alfaButton` は `store.disabled.view.button[name]` を参照するため、直接 `@api disabled` を基本禁止。
- SLDS (`slds-*`) の新規利用を避け、グローバルCSSを利用する。
- LWC 個別 `.css` は Experience サイト向けでは原則追加しない。Platform（内部管理画面等）向けでは許可。

## ボタンアイコン方針

- 進む系: `icon-next-w.svg`
- 戻る系: `icon-back-k.svg`
- 背景色要件で例外可

## デプロイ例（SFDX）

```bash
sfdx force:auth:web:login -a targetOrg
sfdx force:source:deploy -p force-app/main/default -u targetOrg -w 10
sfdx force:apex:test:run --resultformat human --wait 10 -u targetOrg
```

## 補足

## 機能固有設計書は `docs/design/`、運用メモは `docs/misc/` を参照してください。

## ⚠️ 多言語版ファイルについて

本プロジェクトでは以下の複数言語版ドキュメントが存在します。**AI（及び開発者）は以下の優先順位で参照してください：**

### ファイル版構成

```
.github/copilot-instructions.md       ← 【AI正本】日本語メイン（このファイル）
.github/copilot-instructions.en.md    ← 英語チーム向け参考版（自動生成）
docs/
  README.md                           ← 【正本】日本語
  README.en.md                        ← 英語参考版（自動生成）
  *.md                                ← 各ドキュメント【正本】日本語
  *_en.md                             ← 英語参考版（自動生成）
```

### 参照ルール（重要）

1. **AI/Copilot の指示読解時：** このファイル（日本語版）を常に優先する。
2. **ドキュメント参照時：** `docs/` 内の日本語版（`.md`）を正本として参照。
3. **英語版（`.en.md`）の役割：** 英語チームメンバーの参考値のみ。直接更新は不要。日本語版の変更があれば自動的に同期される。
4. **文言の差異：** 日本語版と英語版で微細な差異がある場合、**日本語版を正としてコード実装。**

この方針により、AI による実装指示の曖昧性を排除し、チーム全体で一貫性を保ちます。
