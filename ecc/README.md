# ecc — everything-claude-code

[affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) から抽出したコマンド・エージェント・スキル・スクリプトをまとめたソースです。

frontmatter の `description` フィールドは日本語化していますが、本文は基本的に上流のままです。コマンド内の CLI パスは project-local（`.claude/skills/...`）に調整済みです。

## このソースに含まれるもの

| 種別 | 場所 | 内容 |
|------|------|------|
| Commands | `ecc/commands/` | 19 個の slash コマンド |
| Agents | `ecc/agents/` | 5 個の subagent |
| Skills | `ecc/skills/` | `continuous-learning-v2`, `tdd-workflow`, `rules-distill` の 3 つ（付属 Python / Shell スクリプト込み） |
| Scripts | `ecc/scripts/` | `/ecc-skill-health` が使う Node.js スクリプト群（`skills-health.js` とその lib） |

## インストール

git 管理下のプロジェクトのルートで以下のいずれかを実行してください。

### ワークフロー単位で入れる

```bash
# core（開発サイクルの基本装備）を Claude Code と Cursor の両方に
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core

# prp（PRD → PR 一気通貫）
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc prp

# learn（継続的学習）
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc learn

# ecc の全ワークフロー（core + prp + learn）をまとめて
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc all

# 複数ワークフローを選んで
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core prp
```

### ツールを絞って入れる

```bash
# Claude Code だけに core
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- --claude ecc core

# Cursor だけに prp
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- --cursor ecc prp
```

### 個別のコマンド/エージェントだけ入れる

```bash
# ecc-plan だけ（依存 agent の ecc-planner も自動で入る）
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc ecc-plan

# 複数のコマンドをピンポイントで
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc ecc-plan ecc-code-review ecc-build-fix

# エージェントだけ単体で入れる
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc ecc-refactor-cleaner
```

## ワークフロー

### `core` — 開発サイクルの基本装備

計画 → テスト → レビュー → ビルド修正の一連を回すための最小セット。

- **Commands**: `ecc-plan` / `ecc-tdd` / `ecc-code-review` / `ecc-build-fix` / `ecc-rules-distill`
- **Agents**: `ecc-planner` / `ecc-tdd-guide` / `ecc-code-reviewer` / `ecc-build-error-resolver` / `ecc-refactor-cleaner`

### `prp` — Product Requirement Prompt

PRD 作成から PR 出しまでを一気通貫で進めるワークフロー。

- **Commands**: `ecc-prp-prd` / `ecc-prp-plan` / `ecc-prp-implement` / `ecc-prp-commit` / `ecc-prp-pr`
- **Agents**: `ecc-planner` / `ecc-code-reviewer`（core と共通）

### `learn` — 継続的学習

セッションから知見を抽出し、スキル・instinct として育てていくワークフロー。

- **Commands**: `ecc-learn` / `ecc-learn-eval` / `ecc-evolve` / `ecc-promote` / `ecc-instinct-*` / `ecc-skill-*`

### `all`

上記すべて。

## ワークフローの使い方

各ワークフローの典型的な流れです。コマンド名は Claude Code / Cursor のチャット入力欄で `/ecc-plan` のようにスラッシュコマンドとして実行します。

### `core` の流れ — 普段使いの開発サイクル

```
1. /ecc-plan <やりたいこと>        # 要件整理 → リスク洗い出し → 段階的な実装計画
   ↓ ユーザー確認
2. /ecc-tdd <実装対象>             # テストファーストで RED → GREEN → REFACTOR
   ↓ ビルドエラーが出たら
3. /ecc-build-fix                  # 最小差分でビルド/型エラーを潰す
   ↓ 実装が落ち着いたら
4. /ecc-code-review                # ローカル変更または PR をレビュー
   ↓ 知見が溜まったら（任意）
5. /ecc-rules-distill              # セッションからルールを抽出
```

**使いどころ**: 新機能追加、バグ修正、リファクタリングなど、日常的なコーディング作業。`/ecc-plan` でまず全体像を固めてから着手するのが基本です。

### `prp` の流れ — PRD から PR まで一気通貫

```
1. /ecc-prp-prd <アイデア>          # 対話型で PRD（要件定義書）を作成
   ↓ PRD を確定
2. /ecc-prp-plan <path/to/prd.md>   # コードベース解析込みの実装計画を生成
   ↓ 計画を確認
3. /ecc-prp-implement <plan.md>     # 検証ループ付きで計画を実行
   ↓ 実装完了
4. /ecc-prp-commit <説明>           # 自然言語でファイル指定してコミット
   ↓ コミット済み
5. /ecc-prp-pr [base-branch]        # push + PR 作成（テンプレート自動検出）
```

**使いどころ**: 新機能の企画〜リリースまでをまとめて回したい時、仕様を明文化して残したい時。`core` が「目の前の実装」寄りなのに対し、`prp` は「企画を含む一連のデリバリ」寄り。

### `learn` の流れ — 知見を蓄積・進化させる

```
セッション中に非自明な解決をしたら
  ↓
1. /ecc-learn-eval                  # パターン抽出 → 品質評価 → 保存先判定（Global/Project）
   ↓ 溜まっていく
2. /ecc-instinct-status             # 学習済み instinct を confidence 付きで確認
   ↓ プロジェクト横断で有用なものを
3. /ecc-promote <instinct-id>       # プロジェクト → グローバルスコープへ昇格
   ↓ instinct が成熟してきたら
4. /ecc-evolve [--generate]         # クラスタ化 → skill / command / agent に進化

補助:
  /ecc-skill-create                 # git 履歴から SKILL.md を自動生成
  /ecc-skill-health                 # スキルポートフォリオのダッシュボード
  /ecc-instinct-export / -import    # 共有・移行用
```

**使いどころ**: 同じ問題に何度も遭遇している、チームで知見を共有したい、自分用の AI アシスタントを継続的に育てたい。単発の作業で使うより、日常に組み込んで長期運用するタイプのワークフロー。

### 3 つの関係

- `core` = 実装作業中の手足
- `prp` = 企画〜リリースの骨格
- `learn` = 蓄積される記憶

組み合わせて使うのが前提です。例: `prp` で仕様から実装を進めつつ、途中で詰まった箇所は `core` の `/ecc-plan` や `/ecc-build-fix` を挟み、セッション終盤で `/ecc-learn-eval` に流す。

## シナリオ別の使い分け

`prp` と `core` は「フロー全体の骨格」と「作業中のツールボックス」という関係です。粒度が違うだけで、どちらも計画系コマンドを持っているので混乱しやすいポイントを整理します。

- `/ecc-prp-plan` = PRD を元にコードベース解析込みで作る**重量級**の実装計画
- `/ecc-plan` = 今やることを段取る**軽量**な計画

### パターン A: 新機能をゼロから作る（prp を骨格に、core で補強）

```
/ecc-prp-prd <アイデア>       # PRD 作成
  ↓
/ecc-prp-plan <prd.md>        # 実装計画
  ↓
/ecc-prp-implement <plan.md>  # 実装実行
  │
  ├─ 型エラー出た    → /ecc-build-fix      ← core
  ├─ テスト書きたい  → /ecc-tdd            ← core
  └─ 詳しくレビュー  → /ecc-code-review    ← core
  ↓
/ecc-prp-commit <説明>        # コミット
  ↓
/ecc-prp-pr                   # PR 作成
```

### パターン B: バグ修正・小さな改修（core だけで十分）

```
/ecc-plan <直したいこと>      # 軽めに段取り
  ↓
/ecc-tdd                      # 失敗するテスト → 修正
  ↓
/ecc-build-fix                # ビルド確認
  ↓
/ecc-code-review              # 自己レビュー
  ↓
git commit & gh pr create     # 普通のコミット & PR
```

### パターン C: リファクタリングだけ（core を部分的に）

```
/ecc-plan → 手で変更 → /ecc-code-review
```

### core の各コマンドの使いどころ

| コマンド | 使うタイミング |
|---------|---------------|
| `/ecc-plan` | 「これからやることを整理したい」瞬間。数行の変更でも迷ったらとりあえず通す |
| `/ecc-tdd` | テストから書きたいとき。バグ修正では「再現テスト → 修正」の基本形 |
| `/ecc-build-fix` | `npm run build` / `tsc` / `cargo build` で赤が出た瞬間。最小差分で潰す |
| `/ecc-code-review` | commit / PR 前の自己レビュー。PR 番号を渡すと他人の PR レビューモードになる |
| `/ecc-rules-distill` | セッションで溜まった「こうすべき」知見をルール化したいとき |

### 迷ったときのガイドライン

| 状況 | 使うもの |
|------|---------|
| ユーザーストーリーから実装まで通す | `prp` フル |
| issue に書いてある bug fix | `core` だけ |
| 急ぎでエラー直したい | `/ecc-build-fix` 単発 |
| 「なんか計画立てたい」 | `/ecc-plan`（軽）or `/ecc-prp-plan`（重） |
| PR 作成フェーズだけ | `/ecc-prp-commit` + `/ecc-prp-pr` だけ |

## learn のシナリオ別使い分け

`learn` は単発で使うものではなく、**日常の `core` / `prp` セッションに挟み込みながら長期運用する**ワークフロー。使い方は大きく 4 パターン。

### パターン L1: セッション中の即席取り込み（最頻）

非自明な解決をした瞬間に打つ。気付いた時にその場で。

```
セッション中に「これ他のプロジェクトでも使えそう」と感じた
  ↓
/ecc-learn-eval
  ↓ 品質評価 → Global か Project か自動判定
  ↓
自動で `.claude/skills/<name>/SKILL.md` または `~/.claude/skills/<name>/SKILL.md` に保存
```

> **注意**: Claude Code の skill スキャンはフラット 1 階層のみ（`~/.claude/skills/<name>/SKILL.md`）。`~/.claude/skills/learned/<name>/` のような中間ディレクトリを作ると**自動参照されない**。ai-kit の ecc-learn 系はフラット保存するよう調整済み。

**判断基準**:
- 非自明（ググっても出てこない / 試行錯誤の結果）→ 保存する価値あり
- typo 修正、自明な書き換え → 保存しない

### パターン L2: 既存リポからの一括抽出（初回セットアップ時）

新しいプロジェクトで「このリポのパターンを AI に学ばせたい」時。

```
新しいリポに ai-kit を入れた直後
  ↓
/ecc-skill-create
  ↓ git log 解析 → コーディングパターン抽出
  ↓
SKILL.md を `.claude/skills/` に生成
```

**使いどころ**: 既にコミット履歴がある中規模以上のプロジェクトに途中参加する時、レガシーコードを継続メンテする時。

### パターン L3: 定期棚卸し（週次〜月次）

溜まった instinct を整理する。

```
1. /ecc-instinct-status            # 今どれだけ溜まっているか確認
   ↓ 複数プロジェクトで見た「当たり」の instinct を
2. /ecc-promote <instinct-id>      # project → global に昇格
   ↓ 似た instinct が 3〜5 個以上溜まってきたら
3. /ecc-evolve                     # クラスタ分析 + 進化提案（ドライラン）
   ↓ 内容を確認して納得したら
4. /ecc-evolve --generate          # skill / command / agent として実体化
   ↓ 最後に
5. /ecc-skill-health               # ポートフォリオの健全性チェック（どれが廃れてるか等）
```

**頻度**: 週 1 〜 月 1 くらい。毎日やるものではない。

### パターン L4: チーム共有 / マシン移行

他人に渡す、または新しいマシンに移す時。

```
エクスポート側:
  /ecc-instinct-export --scope global --min-confidence 0.7 --output team-instincts.yaml

インポート側:
  /ecc-instinct-import team-instincts.yaml --scope global --min-confidence 0.7
  /ecc-instinct-import https://example.com/team.yaml   # URL 直接も可
```

**使いどころ**: チーム標準の instinct を共有、プロジェクトテンプレートに同梱、マシン買い替え時のバックアップ。

### learn の各コマンドの使いどころ

| コマンド | 使うタイミング |
|---------|---------------|
| `/ecc-learn-eval` | **最も使う**。セッション中に「これ保存したい」と思った瞬間 |
| `/ecc-learn` | `learn-eval` と同じだが評価なしで強制 Global 保存（軽量） |
| `/ecc-skill-create` | プロジェクト開始時、既存リポのパターンを一括抽出したい時 |
| `/ecc-instinct-status` | 棚卸し開始時、現状把握 |
| `/ecc-promote` | 複数プロジェクトで見た instinct を global に昇格したい時 |
| `/ecc-evolve` | 似た instinct が 3〜5 個溜まってきた時。クラスタ化で高次構造へ |
| `/ecc-skill-health` | 月 1 くらい。skill の成功率や廃れ具合を可視化 |
| `/ecc-instinct-export` / `-import` | チーム共有、マシン移行、バックアップ |

### Auto memory との棲み分け

Claude Code には組み込みの **auto memory**（`~/.claude/projects/<project>/memory/`）もあるが、役割が違う。

| | ecc の `learn` 系 | Claude Code の auto memory |
|--|-------------------|---------------------------|
| 起動 | ユーザーが `/ecc-learn-eval` 等を明示的に打つ | Claude が会話中に自動判断 |
| 保存先 | `~/.claude/skills/learned/`, `~/.claude/homunculus/` | `~/.claude/projects/<project>/memory/` |
| 粒度 | 再利用可能なパターン（SKILL.md、instinct） | プロジェクト固有の feedback・設定・方針 |
| 共有 | export / import でチーム共有可能 | 個人ローカル |

**棲み分けの目安**:
- 「このプロジェクトでの決めごと・好み」→ auto memory に任せる（Claude が自動）
- 「他プロジェクトでも使える解法・パターン」→ `/ecc-learn-eval` で明示的に保存

## 個別コマンド指定時の自動依存解決

特定のコマンドを指定した場合、そのコマンドが呼び出す **agent / skill / scripts** は自動で一緒にインストールされます。

### Agent の自動追加

| Command | 自動で入る Agent |
|---------|-----------------|
| `ecc-plan` | `ecc-planner` |
| `ecc-tdd` | `ecc-tdd-guide` |
| `ecc-code-review` | `ecc-code-reviewer` |
| `ecc-build-fix` | `ecc-build-error-resolver` |

### Skill の自動追加

| Command | 自動で入る Skill |
|---------|-----------------|
| `ecc-tdd` | `tdd-workflow` |
| `ecc-rules-distill` | `rules-distill` |
| `ecc-evolve` / `ecc-promote` / `ecc-instinct-*` | `continuous-learning-v2` |

### Scripts の自動追加

| Command | 自動で入る Scripts |
|---------|-------------------|
| `ecc-skill-health` | `skills-health.js` + `lib/skill-evolution/` 一式 |

## ランタイム要件

| ランタイム | 必要なコマンド |
|-----------|--------------|
| Python 3 | `/ecc-evolve`, `/ecc-promote`, `/ecc-instinct-*`（`continuous-learning-v2` の instinct CLI） |
| Node.js | `/ecc-skill-health`（ダッシュボード表示） |
| Bash | スキル付属のシェルスクリプト各種 |

該当コマンドを使わない場合、ランタイムは未インストールで問題ありません。

## コマンド一覧

| Command | 説明 |
|---------|------|
| `ecc-plan` | 要件整理 → リスク洗い出し → 段階的実装計画（`ecc-planner` 起動） |
| `ecc-tdd` | `tdd-workflow` スキルへの互換エントリポイント |
| `ecc-code-review` | ローカル変更 or GitHub PR のコードレビュー |
| `ecc-build-fix` | ビルド/型エラーを最小差分で修正 |
| `ecc-rules-distill` | `rules-distill` スキルへの互換エントリポイント |
| `ecc-prp-prd` | 対話型 PRD ジェネレーター |
| `ecc-prp-plan` | PRD → コードベース解析込みの実装計画 |
| `ecc-prp-implement` | 計画を検証ループ付きで実行 |
| `ecc-prp-commit` | 自然言語でファイル指定してコミット |
| `ecc-prp-pr` | push + GitHub PR 作成 |
| `ecc-learn` | セッションから再利用パターンを抽出 |
| `ecc-learn-eval` | 抽出 + 品質評価 + 保存先判定 |
| `ecc-evolve` | instinct を skill/command/agent に進化 |
| `ecc-promote` | project 限定の instinct を global に昇格 |
| `ecc-instinct-status` | 学習済み instinct を confidence 付きで表示 |
| `ecc-instinct-export` | instinct をファイルにエクスポート |
| `ecc-instinct-import` | ファイル/URL から instinct をインポート |
| `ecc-skill-create` | git 履歴から SKILL.md を生成 |
| `ecc-skill-health` | スキルポートフォリオのヘルスダッシュボード |

## エージェント一覧

| Agent | 説明 |
|-------|------|
| `ecc-planner` | 複雑な機能・リファクタリングの計画立案（model: opus） |
| `ecc-code-reviewer` | 品質・セキュリティ・保守性のコードレビュー（model: sonnet） |
| `ecc-tdd-guide` | TDD 強制、カバレッジ 80%+ を確保（model: sonnet） |
| `ecc-build-error-resolver` | 最小差分でビルド/型エラー解消（model: sonnet） |
| `ecc-refactor-cleaner` | デッドコード削除・統合（model: sonnet） |

## スキル一覧

| Skill | 説明 | 呼び出し元 |
|-------|------|-----------|
| `tdd-workflow` | TDD 手順（RED → GREEN → REFACTOR）の playbook | `/ecc-tdd`、TDD 文脈で自動参照 |
| `rules-distill` | セッションから always-follow ルールを抽出する手順 | `/ecc-rules-distill`、ルール抽出文脈で自動参照 |
| `continuous-learning-v2` | Instinct ベースの学習システム本体（Python CLI と hook 一式を含む） | `/ecc-evolve` `/ecc-promote` `/ecc-instinct-*` |

各スキルのファイル構成:

| Skill | ファイル数 | 主な中身 |
|-------|----------|---------|
| `tdd-workflow` | 1 | `SKILL.md`（playbook のみ） |
| `rules-distill` | 3 | `SKILL.md` + `scripts/scan-rules.sh` + `scripts/scan-skills.sh` |
| `continuous-learning-v2` | 10 | `SKILL.md`, `config.json`, `scripts/instinct-cli.py`（本体）, `hooks/observe.sh`, `agents/*.sh` 等 |

## スクリプト一覧

`/ecc-skill-health` のためだけに使われる Node.js スクリプト群。他のコマンドは使わないので `/ecc-skill-health` を使わない場合は不要。

| ファイル | 行数 | 役割 |
|---------|------|------|
| `skills-health.js` | 132 | エントリポイント。`--dashboard` `--panel` `--json` 引数をさばく |
| `lib/utils.js` | 629 | クロスプラットフォームのファイル/パス操作ユーティリティ |
| `lib/skill-evolution/index.js` | 20 | 下記 5 ファイルをまとめる barrel export |
| `lib/skill-evolution/dashboard.js` | 401 | ダッシュボード UI レンダラ（チャート・パネル） |
| `lib/skill-evolution/health.js` | 263 | 各 skill の健全性スコア算出（成功率、頻度など） |
| `lib/skill-evolution/provenance.js` | 187 | skill の出自・由来の追跡 |
| `lib/skill-evolution/tracker.js` | 146 | skill 使用履歴の記録 |
| `lib/skill-evolution/versioning.js` | 237 | skill のバージョン履歴管理 |

依存関係:

```
/ecc-skill-health
  └─ skills-health.js
     ├─ lib/utils.js
     └─ lib/skill-evolution/*.js
```

## クレジット

このソースのコマンドとエージェントは [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) を元にしています。ライセンスと出典の詳細は上流のリポジトリを参照してください。
