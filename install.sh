#!/usr/bin/env bash
#
# ai-kit installer — Claude Code / Cursor 用のコマンド・エージェント・スキルをプロジェクトに追加する
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
  Claude Code → <git-root>/.claude/{commands,agents,skills}/
  Cursor      → <git-root>/.cursor/{commands,agents,skills}/
  共通スクリプト → <git-root>/.claude/scripts/

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
    core)  echo "ecc-planner ecc-tdd-guide ecc-code-reviewer ecc-build-error-resolver ecc-refactor-cleaner" ;;
    prp)   echo "ecc-planner ecc-code-reviewer" ;;
    learn) echo "" ;;
    all)   echo "ecc-planner ecc-tdd-guide ecc-code-reviewer ecc-build-error-resolver ecc-refactor-cleaner" ;;
    *)     return 1 ;;
  esac
}

workflow_skills() {
  case "$1" in
    core)  echo "tdd-workflow rules-distill" ;;
    prp)   echo "" ;;
    learn) echo "continuous-learning-v2" ;;
    all)   echo "tdd-workflow rules-distill continuous-learning-v2" ;;
    *)     return 1 ;;
  esac
}

workflow_needs_skills_health_scripts() {
  # skills-health.js とその lib/ 依存を必要とするワークフロー
  case "$1" in
    learn|all) return 0 ;;
    *) return 1 ;;
  esac
}

is_workflow() {
  case "$1" in
    core|prp|learn|all) return 0 ;;
    *) return 1 ;;
  esac
}

command_deps() {
  # コマンドが必要とするエージェント
  case "$1" in
    ecc-plan)        echo "ecc-planner" ;;
    ecc-tdd)         echo "ecc-tdd-guide" ;;
    ecc-code-review) echo "ecc-code-reviewer" ;;
    ecc-build-fix)   echo "ecc-build-error-resolver" ;;
    *)               echo "" ;;
  esac
}

command_skills() {
  # コマンドが必要とするスキル（skills/<name>/ ディレクトリ丸ごと）
  case "$1" in
    ecc-tdd)          echo "tdd-workflow" ;;
    ecc-rules-distill) echo "rules-distill" ;;
    ecc-evolve|ecc-promote|ecc-instinct-status|ecc-instinct-import|ecc-instinct-export)
                      echo "continuous-learning-v2" ;;
    *)                echo "" ;;
  esac
}

command_needs_skills_health_scripts() {
  # ecc-skill-health は scripts/skills-health.js + lib/ を必要とする
  [[ "$1" == "ecc-skill-health" ]]
}

# スキルディレクトリ配下のファイル一覧（skills/<name>/ からの相対パス）
skill_files() {
  case "$1" in
    continuous-learning-v2)
      echo "SKILL.md config.json agents/observer.md agents/observer-loop.sh agents/session-guardian.sh agents/start-observer.sh hooks/observe.sh scripts/detect-project.sh scripts/instinct-cli.py scripts/test_parse_instinct.py"
      ;;
    tdd-workflow)
      echo "SKILL.md"
      ;;
    rules-distill)
      echo "SKILL.md scripts/scan-rules.sh scripts/scan-skills.sh"
      ;;
    *)
      return 1
      ;;
  esac
}

# skills-health.js とその依存の一覧（scripts/ からの相対パス）
skills_health_script_files() {
  echo "skills-health.js lib/utils.js lib/skill-evolution/dashboard.js lib/skill-evolution/health.js lib/skill-evolution/index.js lib/skill-evolution/provenance.js lib/skill-evolution/tracker.js lib/skill-evolution/versioning.js"
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
  mkdir -p "$GIT_ROOT/.claude/commands" "$GIT_ROOT/.claude/agents" "$GIT_ROOT/.claude/skills"
  TARGET_DIRS+=("claude:$GIT_ROOT/.claude")
fi
if [[ "$INSTALL_CURSOR" == "true" ]]; then
  mkdir -p "$GIT_ROOT/.cursor/commands" "$GIT_ROOT/.cursor/agents" "$GIT_ROOT/.cursor/skills"
  TARGET_DIRS+=("cursor:$GIT_ROOT/.cursor")
fi

# scripts はコマンドが参照するのが .claude/scripts/ 固定なので、常に .claude/ に置く
SCRIPTS_DIR="$GIT_ROOT/.claude/scripts"

# ---- ローカル/リモート判定 ------------------------------------------------

LOCAL_MODE="false"
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -d "$SCRIPT_DIR/$SOURCE/commands" ]]; then
    LOCAL_MODE="true"
  fi
fi

# ---- ファイル取得/配置ヘルパ ----------------------------------------------

INSTALLED_COUNT=0
FAILED_COUNT=0

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
  mkdir -p "$(dirname "$dest")"
  if [[ "$LOCAL_MODE" == "true" ]]; then
    cp "$SCRIPT_DIR/$rel" "$dest"
  else
    curl -fsSL "$REPO_BASE/$rel" -o "$dest" 2>/dev/null
  fi
}

install_file() {
  # kind: "commands" または "agents"（.claude と .cursor の両方に入れる）
  local kind="$1" name="$2"
  local rel="$SOURCE/$kind/${name}.md"

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

install_skill() {
  local skill="$1"
  local files
  if ! files="$(skill_files "$skill")"; then
    printf '  \033[31m✗\033[0m skill %s （未定義）\n' "$skill" >&2
    FAILED_COUNT=$((FAILED_COUNT + 1))
    return 1
  fi

  for f in $files; do
    local rel="$SOURCE/skills/$skill/$f"
    for td in "${TARGET_DIRS[@]}"; do
      local tool="${td%%:*}"
      local base="${td#*:}"
      local dest="$base/skills/$skill/$f"
      if fetch_to "$rel" "$dest"; then
        printf '  \033[32m✓\033[0m [%-6s] skills/%s/%s\n' "$tool" "$skill" "$f"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
      else
        rm -f "$dest"
        printf '  \033[31m✗\033[0m [%-6s] skills/%s/%s （取得失敗）\n' "$tool" "$skill" "$f" >&2
        FAILED_COUNT=$((FAILED_COUNT + 1))
      fi
    done
  done

  # スクリプトはシェル実行されるので実行ビットを付けておく
  for td in "${TARGET_DIRS[@]}"; do
    local base="${td#*:}"
    find "$base/skills/$skill" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
  done
}

install_skills_health_scripts() {
  mkdir -p "$SCRIPTS_DIR"
  for f in $(skills_health_script_files); do
    local rel="$SOURCE/scripts/$f"
    local dest="$SCRIPTS_DIR/$f"
    if fetch_to "$rel" "$dest"; then
      printf '  \033[32m✓\033[0m [claude ] scripts/%s\n' "$f"
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
      rm -f "$dest"
      printf '  \033[31m✗\033[0m scripts/%s （取得失敗）\n' "$f" >&2
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

# 重複インストールを避けるため、インストール済みの skills/scripts を記録
INSTALLED_SKILLS=" "
INSTALLED_SCRIPTS="false"

install_skill_once() {
  local skill="$1"
  case "$INSTALLED_SKILLS" in
    *" $skill "*) return 0 ;;
  esac
  install_skill "$skill"
  INSTALLED_SKILLS="$INSTALLED_SKILLS$skill "
}

install_scripts_once() {
  [[ "$INSTALLED_SCRIPTS" == "true" ]] && return 0
  install_skills_health_scripts
  INSTALLED_SCRIPTS="true"
}

for target in "${TARGETS[@]}"; do
  if is_workflow "$target"; then
    echo "[ワークフロー: $target]"
    for c in $(workflow_commands "$target"); do
      install_file commands "$c" || true
      for d in $(command_deps "$c"); do
        [[ -z "$d" ]] && continue
        install_file agents "$d" || true
      done
    done
    for a in $(workflow_agents "$target"); do
      [[ -z "$a" ]] && continue
      install_file agents "$a" || true
    done
    for s in $(workflow_skills "$target"); do
      [[ -z "$s" ]] && continue
      install_skill_once "$s"
    done
    if workflow_needs_skills_health_scripts "$target"; then
      install_scripts_once
    fi
  else
    echo "[$target]"
    if target_exists_as commands "$target"; then
      install_file commands "$target" || true
      for d in $(command_deps "$target"); do
        [[ -z "$d" ]] && continue
        install_file agents "$d" || true
      done
      for s in $(command_skills "$target"); do
        [[ -z "$s" ]] && continue
        install_skill_once "$s"
      done
      if command_needs_skills_health_scripts "$target"; then
        install_scripts_once
      fi
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
