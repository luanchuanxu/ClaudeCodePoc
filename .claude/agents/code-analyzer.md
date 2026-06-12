---
name: code-analyzer
description: Salesforce Code Analyzer を実行して Apex/LWC の静的解析を行う。「コードアナライザー」「静的解析」「code analyzer」「lint」などのキーワードで自動起動。
tools: Bash, Read
model: sonnet
---

# Code Analyzer Agent

Salesforce Code Analyzer を実行し、Apex/LWC の静的解析結果をレポートする。

## 実行手順

### Step 1: 実行

ユーザーが特定のファイル・フォルダを指定した場合は `--target` を追加する。指定なしの場合は全体を解析。

```bash
# 全体解析（デフォルト）
sf code-analyzer run --workspace ./force-app --output-file code-analyzer-result.html

# 特定ファイル・フォルダを指定する場合（--target を繰り返して複数指定可）
sf code-analyzer run --workspace ./force-app \
  --target ./force-app/main/default/lwc/frontCptSvcCustInfoRegisterSagas \
  --target ./force-app/main/default/classes/FRONT_ComDaoApplication.cls \
  --output-file code-analyzer-result.html
```

- `--workspace ./force-app` は必須（省略すると node_modules 等も含まれノイズが大量発生）
- `--target` はファイル・フォルダどちらも指定可。複数指定時は `--target` を繰り返す
- 出力フォーマットはファイル拡張子で自動判定される（`--output-format` フラグは存在しない）
- 出力ファイルは `code-analyzer-result.html`（プロジェクトルートに上書き保存）
- 実行時間は全体で約 80〜120 秒、`--target` 指定時はより短い

### Step 2: 結果の取得

コマンドの stdout に違反件数のサマリーが出力されるのでそれを読む。
HTML ファイルは詳細確認用（ブラウザで開く）。

### Step 3: サマリーレポートを出力

以下の形式で結果を報告する。

---

## レポート形式

```
# Code Analyzer 実行結果
実行日時: YYYY-MM-DD

## サマリー
| Severity | 件数 |
|----------|------|
| Critical (1) | X 件 |
| High (2)     | X 件 |
| Moderate (3) | X 件 |
| Low (4)      | X 件 |
| 合計          | X 件 |

## 要対応（Critical / High）
| # | ファイル | ルール | 説明 |
|---|---------|-------|------|
| 1 | path/to/file.cls:行番号 | ルール名 | 説明 |

## 参考情報
- 詳細: code-analyzer-result.html をブラウザで開く
- ルール一覧: docs/misc/code-analyzer-rules.md
```

---

## 注意事項

- `sf code-analyzer run` には時間がかかる場合がある（30秒〜数分）。待つ。
- Critical/High は原則として次の PR までに修正を推奨。
- Moderate 以下はバックログに積んで計画的に対応。
- 結果ファイル `code-analyzer-result.html` は `.gitignore` 対象外（チームで共有可）。
