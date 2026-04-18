#!/usr/bin/env bash
#
# ai-kit installer — Claude Code / Cursor 用のコマンドとエージェントをプロジェクトに追加する
#
# 使い方:
#   install.sh [--claude] [--cursor] <source> <workflow-or-name...>
#
# 例:
#   install.sh ecc core                   # 両方に core を入れる
#   install.sh --claude ecc core          # Claude Code だけ
#   install.sh --cursor ecc core          # Cursor だけ
#   install.sh ecc ecc-plan ecc-code-review
#   curl -sL https://raw.githubusercontent.com/kaito5757/ai-kit/main/install.sh | bash -s -- ecc core
#
set -euo pipefail

REPO_BASE="${AI_KIT_REPO_BASE:-https://raw.githubusercontent.com/kaito5757/ai-kit/main}"

usage() {
  cat <<'EOF'
使い方: install.sh [--claude] [--cursor] <source> <workflow-or-name...>

引数:
  <source>             ソースディレクトリ名（例: "ecc"）
  <workflow-or-name>   ワークフロー名（core | prp | learn | all）または
                       個別のコマンド/エージェント名（例: ecc-plan）

オプション:
  --claude             Claude Code のみにインストール
  --cursor             Cursor のみにインストール
  （省略時は両方にインストール）
  -h, --help           このヘルプを表示

インストール先:
  Claude Code → <git-root>/.claude/{commands,agents}/
  Cursor      → <git-root>/.cursor/{commands,agents}/

注意: git 管理下のプロジェクト内で実行してください。リポジトリルートが自動検出されます。

例:
  install.sh ecc core
  install.sh --claude ecc core prp
  install.sh --cursor ecc ecc-plan
EOF
}

# ---- ワークフロー定義 ------------------------------------------------------

workflow_commands() {
  case "$1" in
    core)
      echo "ecc-plan ecc-tdd ecc-code-review ecc-build-fix ecc-rules-distill"
      ;;
    prp)
      echo "ecc-prp-prd ecc-prp-plan ecc-prp-implement ecc-prp-commit ecc-prp-pr"
      ;;
    learn)
      echo "ecc-learn ecc-learn-eval ecc-evolve ecc-promote ecc-instinct-status ecc-instinct-export ecc-instinct-import ecc-skill-create ecc-skill-health"
      ;;
    all)
      echo "ecc-plan ecc-tdd ecc-code-review ecc-build-fix ecc-rules-distill ecc-prp-prd ecc-prp-plan ecc-prp-implement ecc-prp-commit ecc-prp-pr ecc-learn ecc-learn-eval ecc-evolve ecc-promote ecc-instinct-status ecc-instinct-export ecc-instinct-import ecc-skill-create ecc-skill-health"
      ;;
    *)
      return 1
      ;;
  esac
}

workflow_agents() {
  case "$1" in
    core)
      echo "ecc-planner ecc-tdd-guide ecc-code-reviewer ecc-build-error-resolver ecc-refactor-cleaner"
      ;;
    prp)
      echo "ecc-planner ecc-code-reviewer"
      ;;
    learn)
      echo ""
      ;;
    all)
      echo "ecc-planner ecc-tdd-guide ecc-code-reviewer ecc-build-error-resolver ecc-refactor-cleaner"
      ;;
    *)
      return 1
      ;;
  esac
}

is_workflow() {
  case "$1" in
    core|prp|learn|all) return 0 ;;
    *) return 1 ;;
  esac
}

command_deps() {
  case "$1" in
    ecc-plan)        echo "ecc-planner" ;;
    ecc-tdd)         echo "ecc-tdd-guide" ;;
    ecc-code-review) echo "ecc-code-reviewer" ;;
    ecc-build-fix)   echo "ecc-build-error-resolver" ;;
    *)               echo "" ;;
  esac
}

# ---- 引数パース -----------------------------------------------------------

INSTALL_CLAUDE="false"
INSTALL_CURSOR="false"
SOURCE=""
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)  INSTALL_CLAUDE="true"; shift ;;
    --cursor)  INSTALL_CURSOR="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        if [[ -z "$SOURCE" ]]; then SOURCE="$1"; else TARGETS+=("$1"); fi
        shift
      done
      ;;
    -*)
      echo "エラー: 不明なオプション: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$SOURCE" ]]; then
        SOURCE="$1"
      else
        TARGETS+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ -z "$SOURCE" ]] || [[ ${#TARGETS[@]} -eq 0 ]]; then
  usage >&2
  exit 1
fi

# デフォルト: フラグ省略時は両方
if [[ "$INSTALL_CLAUDE" == "false" ]] && [[ "$INSTALL_CURSOR" == "false" ]]; then
  INSTALL_CLAUDE="true"
  INSTALL_CURSOR="true"
fi

# ---- git ルート検出 --------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
  echo "エラー: git コマンドが見つかりません" >&2
  exit 1
fi

if ! GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "エラー: git 管理下のプロジェクト内で実行してください" >&2
  echo "（カレントディレクトリ: $(pwd)）" >&2
  exit 1
fi

# ---- インストール先ディレクトリ --------------------------------------------

TARGET_DIRS=()
if [[ "$INSTALL_CLAUDE" == "true" ]]; then
  mkdir -p "$GIT_ROOT/.claude/commands" "$GIT_ROOT/.claude/agents"
  TARGET_DIRS+=("claude:$GIT_ROOT/.claude")
fi
if [[ "$INSTALL_CURSOR" == "true" ]]; then
  mkdir -p "$GIT_ROOT/.cursor/commands" "$GIT_ROOT/.cursor/agents"
  TARGET_DIRS+=("cursor:$GIT_ROOT/.cursor")
fi

# ---- ローカル/リモート判定 ------------------------------------------------

LOCAL_MODE="false"
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -d "$SCRIPT_DIR/$SOURCE/commands" ]]; then
    LOCAL_MODE="true"
  fi
fi

# ---- ファイル取得/配置 -----------------------------------------------------

target_exists_as() {
  local kind="$1" name="$2"
  local rel="$SOURCE/$kind/${name}.md"
  if [[ "$LOCAL_MODE" == "true" ]]; then
    [[ -f "$SCRIPT_DIR/$rel" ]]
  else
    curl -fsI "$REPO_BASE/$rel" >/dev/null 2>&1
  fi
}

fetch_to() {
  local rel="$1" dest="$2"
  if [[ "$LOCAL_MODE" == "true" ]]; then
    cp "$SCRIPT_DIR/$rel" "$dest"
  else
    curl -fsSL "$REPO_BASE/$rel" -o "$dest" 2>/dev/null
  fi
}

INSTALLED_COUNT=0
FAILED_COUNT=0

install_file() {
  # kind: "commands" または "agents"
  local kind="$1" name="$2"
  local rel="$SOURCE/$kind/${name}.md"

  # ソースに存在するか先に確認
  if ! target_exists_as "$kind" "$name"; then
    printf '  \033[31m✗\033[0m %s/%s （ソースに見つかりません）\n' "$kind" "$name" >&2
    FAILED_COUNT=$((FAILED_COUNT + 1))
    return 1
  fi

  for td in "${TARGET_DIRS[@]}"; do
    local tool="${td%%:*}"
    local base="${td#*:}"
    local dest="$base/$kind/${name}.md"
    if fetch_to "$rel" "$dest"; then
      printf '  \033[32m✓\033[0m [%-6s] %s/%s\n' "$tool" "$kind" "$name"
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
      rm -f "$dest"
      printf '  \033[31m✗\033[0m [%-6s] %s/%s （取得失敗）\n' "$tool" "$kind" "$name" >&2
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  done
}

# ---- 実行 -----------------------------------------------------------------

echo "ai-kit/$SOURCE をインストールします"
echo "  配置先: $GIT_ROOT"
echo "  対象  : $([[ "$INSTALL_CLAUDE" == "true" ]] && echo -n "Claude Code ")$([[ "$INSTALL_CURSOR" == "true" ]] && echo -n "Cursor")"
if [[ "$LOCAL_MODE" == "true" ]]; then
  echo "  モード: ローカル ($SCRIPT_DIR)"
else
  echo "  モード: リモート ($REPO_BASE)"
fi
echo

for target in "${TARGETS[@]}"; do
  if is_workflow "$target"; then
    echo "[ワークフロー: $target]"
    for c in $(workflow_commands "$target"); do
      install_file commands "$c" || true
    done
    for a in $(workflow_agents "$target"); do
      [[ -z "$a" ]] && continue
      install_file agents "$a" || true
    done
  else
    echo "[$target]"
    if target_exists_as commands "$target"; then
      install_file commands "$target" || true
      for d in $(command_deps "$target"); do
        [[ -z "$d" ]] && continue
        install_file agents "$d" || true
      done
    elif target_exists_as agents "$target"; then
      install_file agents "$target" || true
    else
      printf '  \033[31m✗\033[0m %s （%s/commands にも %s/agents にも見つかりません）\n' "$target" "$SOURCE" "$SOURCE" >&2
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  fi
done

echo
if [[ $FAILED_COUNT -eq 0 ]]; then
  echo "完了: $INSTALLED_COUNT 件のファイルをインストールしました"
else
  echo "完了: 成功 $INSTALLED_COUNT 件 / 失敗 $FAILED_COUNT 件" >&2
  exit 1
fi
