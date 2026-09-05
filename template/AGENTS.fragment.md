<!-- local-task-template:begin -->
## 로컬 프로젝트·태스크 운영

작업 전에 `.local/README.md`와 `.local/docs/progress.md`를 읽는다.
- 장기 기준은 `.local/spec-design/`, 태스크 기록은 `.local/tasks/{TO_DO,IN_PROGRESS,DONE}/`에서 관리한다.
- 태스크 번호는 프로젝트 전체에서 고유한 3자리 ID다. 작업 시작·완료 시 디렉터리 전체를 이동한다.
- 판단·체크리스트·검증·handoff는 태스크 디렉터리에 기록한다. 생성·시작·변경·완료 때 progress를 갱신한다.
- `.local/`은 Git과 GitHub에 올리지 않는다. 내부 기록을 `docs/`로 자동 복사하지 않는다.
- 구현은 `agent/{task-id}-{slug}` branch와 별도 worktree에서 수행한다. 파일 소유 범위와 공용 파일 작성자를 먼저 정한다.
- 검증된 설명 가능한 작업 단위마다 별도 요청을 기다리지 않고 local commit한다. 관련 검증 실패나 영향 범위의 미해결 BLOCKER가 있으면 완료 commit을 보류한다.
- commit 전에 명시적으로 stage한 파일·diff·비밀값·생성물·`.local/` 제외·OPEN issue를 확인한다.
- commit 후 branch·SHA·검증 결과·남은 위험을 보고한다. checkpoint는 미완료 범위와 다음 gate를 기록한다.
- push·PR·main 통합·배포·branch/worktree 삭제는 local commit 권한에 포함하지 않는다. 사용자의 명시적 요청 또는 이미 승인된 구체적 범위에서 수행한다.
- 다른 태스크에 영향이 있으면 `.local/tasks/IN_PROGRESS/ISSUE-RULES.md`에 따라 기록하고 affected 파일을 임의 수정하지 않는다.
<!-- local-task-template:end -->
