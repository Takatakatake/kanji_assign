# プロジェクト指示書 (Claude Code 起動時に自動読み込み)

このディレクトリは **PEJVO/PIV 統合 Esperanto 辞書編集プロジェクト** の作業ディレクトリです。Claude Code はこのディレクトリで起動された際、本ファイルを自動的に読み込みます。

## ★ 文脈の自動復元手順 (新 PC で初回起動時に Claude Code が実行)

このディレクトリは、別 PC からマイグレーションされたものである可能性があります。`_claude_context/memory/` ディレクトリが存在し、かつ通常の auto-memory (`~/.claude/projects/<project_key>/memory/`) が空または未設定の場合、Claude Code は以下を実行してください:

### Step 1: `_claude_context/memory/MEMORY.md` を Read tool で読み込む

このファイルは旧 PC で蓄積された auto-memory のインデックスです。

### Step 2: MEMORY.md に記載された各 memory ファイルを順に読み込む

`_claude_context/memory/` 配下の以下のファイルを Read tool で取得し、その内容を **本セッション中の auto-memory として扱う**:
- `user_role.md` — ユーザーの役割
- `feedback_clarity.md` — わかりやすい説明を好む
- `feedback_reverse_question.md` — 逆質問を積極的に行うべき
- `feedback_loanword_skip.md` — Loanword 既知性は skip 根拠
- `feedback_no_spelling_change.md` — 綴り変更は不可
- `feedback_overdecomp_root_level.md` — 過細分解は語根レベル
- `feedback_define_jargon.md` — 内部用語は事前定義
- `project_pejvo.md` — プロジェクト構造
- `reference_files.md` — 参照ファイル一覧

### Step 3: 通常の auto-memory として運用

これらの内容は **新セッション以降、auto-memory と同等のものとして保持** します。Claude Code 自身の auto-memory システム (新 PC 上の `~/.claude/projects/...../memory/`) に書き込みたい場合は、上記内容をそのままコピーすれば、以降の起動から自動読み込みされます (詳細は `_claude_context/README_復元手順.md` 参照)。

---

## プロジェクト概要

- **目的**: PEJVO (世界语全部单词 約44100語) を PIV2020 を一次参照として整備し、二つの版を生成・維持する
  - 学習者版: 学習補助分解を積極展開、`##偽分解` / `##過細分解` マーカー併用
  - 学術版: PEJVO 設計尊重、最小限の系列内不整合補正のみ
- **作業履歴**: Phase 1 から Phase 40 まで実施済 (2026-05-09 時点)
- **canonical 知識リポジトリ**: `修正傾向まとめ_20260416.md` (約 1900 行、全方針・全実施履歴記録)

## 主要ファイル

| ファイル | 役割 |
|---|---|
| `修正傾向まとめ_20260416.md` | **指針書 + audit 履歴** (最重要、Phase 1-40 全記録) |
| `世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt` | 学習者版辞書 (生成物) |
| `世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt` | 学術版辞書 (生成物) |
| `世界语全部单词_大约44100个(原pejvo.txt)_original2024620.txt` | PEJVO 元データ (GB18030 encoding) |
| `世界语全部单词列表_约44700个(原pejvo.txt)_utf8转换_..._最终版202501.txt` | PEJVO 改訂版 (UTF-8) |
| `PIV2020_structured.txt` / `PIV2020.html` | PIV2020 一次参照 |
| `_claude_context/` | 旧 PC 文脈バックアップ (memory + 過去会話 transcript) |

## 作業再開時の standard prompt

ユーザーがプロジェクト作業の再開を要求したら、Claude Code は:

1. `_claude_context/memory/` を読み込み (本ファイル先頭の Step 1-2)
2. `修正傾向まとめ_20260416.md` の以下を確認:
   - 現況サマリ (line 95 周辺): 最新の `##偽分解` 件数・累計 fragment 認定数等
   - 「保留中の認定候補」節 (line 107 周辺): 次に着手すべき deferred 候補
   - 監査表 末尾 (line 535 周辺): 直近 Phase の実施内容
3. ユーザーに状況サマリと次の選択肢を提示

## 編集判断の優先順位

1. PIV2020 (`PIV2020_structured.txt` / `PIV2020.html`) を一次参照として確認
2. PEJVO 元データの両版 (`*original2024620.txt` と `*最终版202501.txt`) を比較確認
3. `修正傾向まとめ_20260416.md` の確立済原則 (基本原則 1-9、技法 1-14) に従う
4. 不確実な判断は逆質問でユーザーに確認 (memory `feedback_reverse_question.md` 参照)
