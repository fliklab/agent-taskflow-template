#!/usr/bin/env bash
# Bash 3.2+ and standard macOS/Linux utilities. No package installation required.
set -euo pipefail

fail() { printf '설치 중단: %s\n' "$*" >&2; exit 1; }
usage() { printf '사용법: bash scripts/init.sh [대상 저장소 또는 내부 경로] [--apply]\n'; }
apply=false
target=.
target_set=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply) apply=true ;;
        -h|--help) usage; exit 0 ;;
        --) shift; [ "$#" -eq 1 ] && [ "$target_set" = false ] || fail '대상 경로 하나를 지정하세요.'
            target=$1; target_set=true; break ;;
        -*) fail "알 수 없는 옵션: $1" ;;
        *) [ "$target_set" = false ] || fail '대상 경로 하나를 지정하세요.'
            target=$1; target_set=true ;;
    esac
    shift
done

source_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../template" && pwd -P)
repo_root=$(git -C "$target" rev-parse --show-toplevel) || fail 'Git 저장소 안에서 실행하거나 대상 경로를 지정하세요.'
repo_root=$(cd -- "$repo_root" && pwd -P)
project_name=${repo_root##*/}
worktree_root="${repo_root%/*}/${project_name}-worktrees"
local_root="$repo_root/.local"
printf '대상 저장소: %s\nworktree 기본 경로: %s\n' "$repo_root" "$worktree_root"

[ ! -e "$local_root" ] && [ ! -L "$local_root" ] || fail '기존 .local을 보존합니다. 자동 덮어쓰기·업그레이드는 지원하지 않습니다.'
[ -z "$(git -C "$repo_root" ls-files -- .local)" ] || fail '.local이 이미 Git에서 추적됩니다. 추적 경위를 먼저 확인하세요.'
for name in AGENTS.md .gitignore; do
    path="$repo_root/$name"
    [ ! -L "$path" ] && { [ ! -e "$path" ] || [ -f "$path" ]; } || fail "$name 파일이 일반 파일이 아닙니다."
done
if [ -f "$repo_root/AGENTS.md" ] && grep -Fq '<!-- local-task-template:begin -->' "$repo_root/AGENTS.md"; then
    fail '기존 템플릿 지침이 있습니다. 중복 설치 대신 수동 비교하세요.'
fi
printf '기존 내용 뒤에 추가: %s/AGENTS.md\n기존 내용 뒤에 추가: %s/.gitignore\n빈 양식 생성: %s\n' "$repo_root" "$repo_root" "$local_root"
if [ "$apply" = false ]; then
    printf '미리보기입니다. 실제 적용에는 --apply를 사용하세요.\n'
    exit 0
fi

# Render before touching destination files. Only this invocation's staging directory is removed.
staging=$(mktemp -d "$repo_root/.local-task-init.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cp -R "$source_root/local" "$staging/local"
export LOCAL_TASK_REPO_ROOT="$repo_root" LOCAL_TASK_PROJECT_NAME="$project_name" LOCAL_TASK_WORKTREE_ROOT="$worktree_root"
while IFS= read -r -d '' document; do
    # ENVIRON preserves backslashes in paths. Match source tokens in one pass; never eval paths.
    awk '
    function shell_quote(value, result, i, char, quote) {
        quote = sprintf("%c", 39)
        result = quote
        for (i = 1; i <= length(value); i++) {
            char = substr(value, i, 1)
            if (char == quote) result = result quote "\\" quote quote
            else result = result char
        }
        return result quote
    }
    BEGIN {
        values["{{PROJECT_NAME}}"] = ENVIRON["LOCAL_TASK_PROJECT_NAME"]
        values["{{REPO_ROOT}}"] = ENVIRON["LOCAL_TASK_REPO_ROOT"]
        values["{{WORKTREE_ROOT}}"] = ENVIRON["LOCAL_TASK_WORKTREE_ROOT"]
        values["{{REPO_ROOT_SHELL}}"] = shell_quote(ENVIRON["LOCAL_TASK_REPO_ROOT"])
        values["{{WORKTREE_ROOT_SHELL}}"] = shell_quote(ENVIRON["LOCAL_TASK_WORKTREE_ROOT"])
    }
    {
        rest = $0
        while (match(rest, /\{\{[A-Z_]+\}\}/)) {
            token = substr(rest, RSTART, RLENGTH)
            printf "%s%s", substr(rest, 1, RSTART - 1), (token in values ? values[token] : token)
            rest = substr(rest, RSTART + RLENGTH)
        }
        print rest
    }' "$document" > "$staging/rendered"
    mv -- "$staging/rendered" "$document"
done < <(find "$staging/local" -type f -name '*.md' -print0)

# mkdir refuses a concurrently created .local instead of copying into existing records.
mkdir -- "$local_root"
cp -R "$staging/local/." "$local_root/"
{ printf '\n\n'; cat "$source_root/AGENTS.fragment.md"; } >> "$repo_root/AGENTS.md"
printf '\n# Local task records (including a worktree symlink)\n/.local\n/.local/\n' >> "$repo_root/.gitignore"
git -C "$repo_root" check-ignore .local/README.md > /dev/null
printf '적용 완료. AGENTS.md와 .gitignore diff를 검토하고 프로젝트 기준을 채우세요.\n'
