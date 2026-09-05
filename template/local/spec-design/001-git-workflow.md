# Git·브랜치·worktree 운영

`main`은 통합 기준선이다. 장기 develop 없이 `main + agent/{task-id}-{slug}`를 기본으로 사용한다.
아임해피의 `work/` 접두사는 이 템플릿에서 Codex 기본값인 `agent/`로 일반화했다.
기존 저장소가 다른 접두사를 쓰면 이 문서와 루트 AGENTS를 함께 맞춘다.

## 시작

1. 태스크를 IN_PROGRESS로 이동하고 base branch·정확한 SHA·owned/shared/excluded 파일을 기록한다.
2. `git status --short --branch`, `git worktree list`, 기존 OPEN issue를 확인한다.
3. 일반 구현은 별도 worktree에서 수행한다. main의 기존 사용자 변경을 옮기거나 되돌리지 않는다.

```sh
# 설치한 저장소의 실제 경로가 아래에 채워진다. task_id만 해당 작업에 맞춘다.
repo_root={{REPO_ROOT_SHELL}}
worktree_root={{WORKTREE_ROOT_SHELL}}
task_id=001-example
git -C "$repo_root" worktree add -b "agent/$task_id" "$worktree_root/$task_id" main
# 선택 사항: 기본 worktree의 운영 기록을 읽기 전용 운영 방식으로 공유
ln -s "$repo_root/.local" "$worktree_root/$task_id/.local"
```

`.local` 링크 자체도 Git에서 제외되어야 한다. symlink는 운영 규칙상 읽기 전용일 뿐 OS 접근 제어가 아니다.
기본 worktree의 조정 담당자가 태스크 상태·공유 기록을 관리한다. 각 구현 담당자는 조사·handoff 내용을 전달한다.

하나의 태스크는 하나의 branch·worktree·파일 소유 범위를 가진다.
공용 manifest·lockfile·schema/migration·shared contract·전역 routing·AGENTS·gitignore는 단일 작성자로 조정한다.
의존 branch는 필요할 때만 최대 2단계로 만들고 parent branch/SHA·통합 순서·재검증 범위를 기록한다.
다른 worktree의 미완성 파일을 복사해 통합하지 않는다.

## 로컬 커밋

검증된 설명 가능한 단위마다 전용 task branch에서 local commit한다.
별도 승인 대기 없이 수행하되 실패한 검증·비밀값·관련 미해결 BLOCKER가 있으면 해당 완료 commit을 보류한다.
checkpoint는 독립적으로 되돌릴 수 있어야 하며 미완료 범위와 다음 gate를 handoff에 적는다.

```sh
git status --short --branch
git check-ignore .local/README.md
git ls-files .local
git add path/to/owned-file path/to/another-owned-file
git diff --cached --check
git diff --cached --stat
git diff --cached
# 프로젝트의 관련 검증과 비밀값·생성물 점검 후 실행
git commit -m 'feat(scope): describe the verified change'
```

`.local`이 `git ls-files`에 나오면 중단하고 추적 경위를 확인한다. `git add .`, `git add -A`, `git add -f .local`은 사용하지 않는다.
커밋에는 다른 사용자의 변경을 섞지 않는다. commit type은 feat/fix/refactor/test/chore/docs를 사용한다.

## 원격 반영과 통합

- push·PR·main 통합·배포·branch/worktree 삭제는 사용자 요청 또는 이미 구체적으로 승인된 범위에서만 수행한다.
- push 전 remote URL·대상 branch·commit 범위·ahead/behind를 요약한다. 하나의 branch만 명시하고 force push를 기본 사용하지 않는다.
- PR에는 문제·변경 동작·검증·migration·남은 위험을 적는다.
- main 통합 직전 최신 기준에서 관련 전체 검증을 수행한다. 기본은 태스크별 squash이며 보존할 commit이 있으면 합의한다.
- 공개된 commit 이력을 임의 rebase하거나 상대 변경을 일괄 덮어쓰지 않는다. 충돌은 소유 범위·계약·테스트로 판단한다.
- 통합 뒤 SHA와 원격·배포 상태를 별도로 검증한다.
- branch/worktree는 통합·handoff·clean 상태·보존된 commit을 확인하고 승인된 범위에서 정리한다. 미추적 파일이 있으면 제거하지 않는다.
- 빈 저장소의 최초 baseline commit은 예외적으로 전용 bootstrap branch에서 만들고 승인된 최초 업로드 시 main을 생성한다.
