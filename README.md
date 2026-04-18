# ai-kit

Claude Code と Cursor で使える、コマンドとエージェントの詰め合わせキット。
必要なワークフローだけをプロジェクトのルートに追加できます。

## クイックスタート

```bash
# git 管理下のプロジェクトのルートで実行（Claude Code と Cursor の両方に入る）
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core
```

インストール後、プロジェクトルートに以下が追加されます:

```
.claude/
├── commands/   # Claude Code 用 slash コマンド
└── agents/     # Claude Code 用 subagent
.cursor/
├── commands/   # Cursor 用 slash コマンド
└── agents/     # Cursor 用 subagent（Cursor 2.4+）
```

## 収録ソース

| ソース | 説明 |
|--------|------|
| `ecc`  | [everything-claude-code](https://github.com/affaan-m/everything-claude-code) から抽出したコマンドとエージェント。 |

## ワークフロー

各ソースにはワークフロー（コマンドとエージェントの束）が定義されています。

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

## 使い方

```
install.sh [--claude] [--cursor] <source> <workflow-or-name...>
```

### 引数

| 引数 | 説明 |
|------|------|
| `<source>` | ソースディレクトリ名（例: `ecc`） |
| `<workflow-or-name>` | ワークフロー名（`core` / `prp` / `learn` / `all`）または個別のコマンド/エージェント名（例: `ecc-plan`） |

### オプション

| フラグ | 説明 |
|--------|------|
| `--claude` | Claude Code のみにインストール |
| `--cursor` | Cursor のみにインストール |
| （省略時） | Claude Code と Cursor の両方にインストール |
| `-h`, `--help` | ヘルプを表示 |

### 前提条件

- **git 管理下のプロジェクト内で実行すること**
  - `git rev-parse --show-toplevel` でリポジトリルートを自動検出し、そこにインストール
  - 非 git ディレクトリで実行するとエラーになります

### 例

```bash
# Claude Code と Cursor の両方に core を入れる
./install.sh ecc core

# Claude Code だけに入れる
./install.sh --claude ecc core

# Cursor だけに入れる
./install.sh --cursor ecc core

# core と prp をまとめて（両方のツールに）
./install.sh ecc core prp

# 特定のコマンドだけ（依存エージェントは自動で付いてくる）
./install.sh ecc ecc-plan ecc-code-review

# リモートから curl 経由で
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- --cursor ecc prp
```

## 個別コマンド指定時の自動依存解決

特定のコマンドを指定した場合、そのコマンドが呼び出すエージェントは自動で一緒にインストールされます。

| Command | 自動で入る Agent |
|---------|-----------------|
| `ecc-plan` | `ecc-planner` |
| `ecc-tdd` | `ecc-tdd-guide` |
| `ecc-code-review` | `ecc-code-reviewer` |
| `ecc-build-fix` | `ecc-build-error-resolver` |

## Claude Code / Cursor の互換性について

- **Commands**: どちらのツールも同じマークダウン形式（frontmatter 付き）を使うので、ファイルはそのまま互換。
- **Agents**: Cursor 2.4+ は `.cursor/agents/` を公式サポート。また `.claude/agents/` もフォールバックとして読み込むので、Claude 用の agent ファイルはそのまま Cursor でも動きます（`tools` や `model: opus` などの Claude 固有フィールドは Cursor 側で無視されます）。
- **Hooks**: Cursor の hooks は現状グローバル（`~/.cursor/hooks.json`）のみで project 単位は未対応のため、本キットには含めていません。

## アンインストール

レジストリは使っていないので、インストール先のファイルを消すだけです。

```bash
# core をプロジェクトから剥がす例
rm .claude/commands/ecc-plan.md .claude/commands/ecc-tdd.md ...
rm .cursor/commands/ecc-plan.md ...
```

丸ごと外したい場合は `.claude/` / `.cursor/` ディレクトリごと削除でも OK。

## クレジット

- `ecc/` 配下のコマンド・エージェントは [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) を元にしています。
