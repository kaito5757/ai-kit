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

## クレジット

このソースのコマンドとエージェントは [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) を元にしています。ライセンスと出典の詳細は上流のリポジトリを参照してください。
