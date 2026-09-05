#!/usr/bin/env bash
# Read-only snapshot. Ownership and blocking issues require human review.
set -euo pipefail
repo_root=$(git rev-parse --show-toplevel)
# Physical parent directory resolves a shared .local directory symlink.
local_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
printf '현재 저장소: %s\n' "$repo_root"
while IFS= read -r -d '' record; do
    case "$record" in
        'worktree '*)
            tree=${record#worktree }
            printf '\nworktree: %s\n' "$tree"
            git -C "$tree" status --short --branch || printf '조회 실패: 경로·접근 권한·worktree 상태를 직접 확인하세요.\n'
            ;;
    esac
done < <(git -C "$repo_root" worktree list --porcelain -z)
printf '\n활성 태스크 issue (해결된 항목도 포함):\n'
found=false
while IFS= read -r -d '' issue; do
    found=true
    printf '\n%s\n' "$issue"
    cat -- "$issue"
done < <(find "$local_root/tasks/IN_PROGRESS" -type f -path '*/issues/*.issue.md' -print0)
[ "$found" = true ] || printf '없음\n'
printf '\n현재 unstaged / staged 변경 파일:\n'
git -C "$repo_root" diff --name-only
git -C "$repo_root" diff --cached --name-only
printf '\n이 조회 결과는 자동 검증 통과 판정이 아닙니다.\n'
