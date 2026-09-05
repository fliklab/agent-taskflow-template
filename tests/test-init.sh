#!/usr/bin/env bash
# Integration checks using only Bash, Git and standard system utilities.
set -euo pipefail
source_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
installer="$source_root/scripts/init.sh"
fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/local-task-test.XXXXXX")
trap 'rm -rf -- "$fixture_root"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
passed=0
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
ok() { passed=$((passed + 1)); printf 'PASS %s: %s\n' "$passed" "$*"; }
new_repo() {
    repo="$fixture_root/$1"
    mkdir -p -- "$repo"
    repo=$(cd -- "$repo" && pwd -P)
    git -C "$repo" init -q -b main
}
install() { bash "$installer" "$repo" --apply > "$fixture_root/output" 2>&1 || { cat "$fixture_root/output"; fail '설치 실패'; }; }
reject() { if bash "$installer" "$@" > "$fixture_root/output" 2>&1; then fail '거부해야 할 설치 성공'; fi; }
contains() { grep -Fq -- "$2" "$1" || fail "$1 에 기대한 내용 없음"; }

new_repo 'preview with spaces'
bash "$installer" "$repo" > "$fixture_root/output"
[ ! -e "$repo/.local" ] && [ ! -e "$repo/AGENTS.md" ] && [ ! -e "$repo/.gitignore" ] || fail '미리보기 파일 변경'
ok '미리보기 무변경'

new_repo 'preserve existing'
printf '# 기존 사용자 규칙\n' > "$repo/AGENTS.md"
printf 'build/\n!/.local/\n' > "$repo/.gitignore"
printf 'existing code' > "$repo/app.txt"
install
[ "$(head -n 1 "$repo/AGENTS.md")" = '# 기존 사용자 규칙' ] || fail '기존 AGENTS 변경'
[ "$(head -n 2 "$repo/.gitignore")" = $'build/\n!/.local/' ] || fail '기존 ignore 변경'
[ "$(cat "$repo/app.txt")" = 'existing code' ] || fail '제품 코드 변경'
git -C "$repo" check-ignore .local/README.md > /dev/null
[ -z "$(git -C "$repo" ls-files -- .local)" ] || fail '.local 추적'
[ -z "$(git -C "$repo" diff --cached --name-only)" ] || fail '자동 staging'
ok '기존 내용 보존·Git 제외·자동 staging 없음'
cp "$repo/AGENTS.md" "$fixture_root/before"
reject "$repo" --apply
cmp "$repo/AGENTS.md" "$fixture_root/before"
ok '재설치·기존 .local 보호'

for filename in AGENTS.md .gitignore; do
    new_repo "symlink $filename"
    printf 'preserve' > "$repo/real"
    ln -s "$repo/real" "$repo/$filename"
    reject "$repo" --apply
    [ ! -e "$repo/.local" ] && [ "$(cat "$repo/real")" = preserve ] || fail 'symlink 대상 변경'
done
ok 'AGENTS·gitignore symlink 보호'

new_repo 'dangling local'
ln -s "$repo/missing" "$repo/.local"
reject "$repo" --apply
[ -L "$repo/.local" ] && [ ! -e "$repo/AGENTS.md" ] || fail '기존 .local 링크 변경'
ok '끊어진 .local symlink 보호'

new_repo 'tracked deleted local'
mkdir "$repo/.local"
printf private > "$repo/.local/note"
git -C "$repo" add .local/note
rm "$repo/.local/note"
rmdir "$repo/.local"
reject "$repo" --apply
[ ! -e "$repo/AGENTS.md" ] || fail '추적 중 .local 설치'
ok '추적 중이지만 삭제된 .local 보호'

new_repo 'nested explicit path'
mkdir "$repo/sub"
bash "$installer" "$repo/sub" --apply > "$fixture_root/output"
[ -f "$repo/.local/README.md" ] && [ ! -e "$repo/sub/.local" ] || fail '하위 경로 root 탐지 실패'
ok '하위 디렉터리에서 실제 Git root 탐지'

new_repo 'nested default target'
mkdir "$repo/sub"
(cd "$repo/sub" && bash "$installer" --apply) > "$fixture_root/output"
for name in README.md docs/progress.md spec-design/001-git-workflow.md; do
    contains "$repo/.local/$name" "$repo"
    if grep -q '{{' "$repo/.local/$name"; then fail '치환 안 된 표식'; fi
done
if grep -Fq "$repo" "$repo/AGENTS.md"; then fail '공유 지침에 절대 경로 유출'; fi
ok '경로 인자 생략·실제 경로 문서 반영'

new_repo "repo ' \$(touch UNEXPECTED) & | \\ {{REPO_ROOT}}"
install
grep -E '^(repo_root|worktree_root)=' "$repo/.local/spec-design/001-git-workflow.md" > "$fixture_root/assignments.sh"
printf '\nprintf "%%s\\n%%s\\n" "$repo_root" "$worktree_root"\n' >> "$fixture_root/assignments.sh"
(cd "$repo" && bash "$fixture_root/assignments.sh") > "$fixture_root/actual"
printf '%s\n%s\n' "$repo" "${repo%/*}/${repo##*/}-worktrees" > "$fixture_root/expected"
cmp "$fixture_root/expected" "$fixture_root/actual"
[ ! -e "$repo/UNEXPECTED" ] || fail '경로가 명령으로 실행됨'
ok '공백·따옴표·명령문자·역슬래시·표식 같은 경로 보존'

mkdir "$fixture_root/not-a-repo"
reject "$fixture_root/not-a-repo" --apply
[ ! -e "$fixture_root/not-a-repo/.local" ] || fail 'Git 외부 설치'
ok 'Git 외부 경로 거부'

new_repo 'duplicate marker'
printf '<!-- local-task-template:begin -->\n' > "$repo/AGENTS.md"
reject "$repo" --apply
[ ! -e "$repo/.local" ] || fail '중복 표식 설치'
reject --unknown
ok '중복 지침·알 수 없는 옵션 거부'

new_repo 'shared worktree snapshot'
install
git -C "$repo" -c user.name=Test -c user.email=test@example.invalid commit -q --allow-empty -m baseline
cp -R "$repo/.local/templates/task" "$repo/.local/tasks/TO_DO/000-example"
mv "$repo/.local/tasks/TO_DO/000-example" "$repo/.local/tasks/IN_PROGRESS/"
active="$repo/.local/tasks/IN_PROGRESS/000-example"
mkdir "$active/issues"
printf 'status: OPEN\nseverity: WARNING\n' > "$active/issues/example.issue.md"
tree="$fixture_root/task worktree"
git -C "$repo" worktree add -q -b agent/000-example "$tree" main
tree=$(cd -- "$tree" && pwd -P)
ln -s "$repo/.local" "$tree/.local"
(cd "$tree" && bash .local/tools/check-parallel-impact.sh) > "$fixture_root/snapshot"
contains "$fixture_root/snapshot" 'severity: WARNING'
contains "$fixture_root/snapshot" "$tree"
mv "$active" "$repo/.local/tasks/DONE/"
[ ! -e "$active" ] && [ -d "$repo/.local/tasks/DONE/000-example" ] || fail '상태 이동 실패'
[ -z "$(git -C "$repo" ls-files -- .local)" ] || fail '태스크 기록 추적'
ok '태스크 이동·공유 .local·worktree 현황 조회'

printf '\n%s개 테스트 통과\n' "$passed"
