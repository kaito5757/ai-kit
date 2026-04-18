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

ソースごとにワークフローやコマンド群が定義されています。各ソースの詳細は個別の README を参照してください。

| ソース | 内容 | 詳細 |
|--------|------|------|
| `ecc`  | [everything-claude-code](https://github.com/affaan-m/everything-claude-code) から抽出したコマンド・エージェント。開発サイクル支援（core）、PRD → PR 一気通貫（prp）、継続的学習（learn）の 3 ワークフロー。 | [ecc/README.md](ecc/README.md) |

新しいソースを追加する場合は `<source-name>/commands/` と `<source-name>/agents/` のディレクトリ構造で置き、`install.sh` の `workflow_commands` / `workflow_agents` / `command_deps` にワークフロー定義を追加します。

## install.sh の使い方

```
install.sh [--claude] [--cursor] <source> <workflow-or-name...>
```

### 引数

| 引数 | 説明 |
|------|------|
| `<source>` | ソースディレクトリ名（例: `ecc`） |
| `<workflow-or-name>` | ワークフロー名、または個別のコマンド/エージェント名 |

指定できるワークフロー名・コマンド名はソースごとに異なります。各ソースの README を参照してください。

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
# Claude Code と Cursor の両方にソース ecc の core ワークフローを入れる
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core

# Claude Code だけに入れる
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- --claude ecc core

# Cursor だけに入れる
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- --cursor ecc core

# 複数ワークフローを一度に
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core prp

# 特定のコマンドだけ（依存エージェントは自動で付いてくる）
curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc ecc-plan ecc-code-review
```

ソースごとの具体例は各ソースの README（例: [ecc/README.md](ecc/README.md)）を参照してください。

## Claude Code / Cursor の互換性について

- **Commands**: どちらのツールも同じマークダウン形式（frontmatter 付き）を使うので、ファイルはそのまま互換。
- **Agents**: Cursor 2.4+ は `.cursor/agents/` を公式サポート。また `.claude/agents/` もフォールバックとして読み込むので、Claude 用の agent ファイルはそのまま Cursor でも動きます（`tools` や `model: opus` などの Claude 固有フィールドは Cursor 側で無視されます）。
- **Hooks**: Cursor の hooks は現状グローバル（`~/.cursor/hooks.json`）のみで project 単位は未対応のため、本キットには含めていません。

## アンインストール

レジストリは使っていないので、インストール先のファイルを消すだけです。

```bash
# 個別ファイルを消す
rm .claude/commands/ecc-plan.md
rm .cursor/commands/ecc-plan.md

# 丸ごと外す場合
rm -rf .claude .cursor
```

## ライセンス / クレジット

- ソースに由来するコマンド・エージェントのライセンスや出典は各ソースの README を参照してください。
- 本リポジトリのインストーラ（`install.sh`）とラッパー構成は自由に使ってください。
