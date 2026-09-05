# 교차 태스크 이슈 규칙

병렬 작업 또는 다른 active task에 영향이 있는 경우 적용한다. 파일 소유권과 영향 판단은 사람이 확인한다.

| 단계 | 확인 시점 | 확인 내용 |
|---|---|---|
| C0 | 시작 전 | base·worktree·소유 범위·기존 issue |
| C1 | 계약·정책 결정 후 | API·상태·권한·소비자 영향 |
| C2 | 공용 파일 수정 전 | 단일 작성자·이관 기록·다른 diff |
| C3 | 부분 검증 후 | 범위 밖 회귀·전체 검증 필요성 |
| C4 | handoff·commit·통합 전 | staged/unstaged/untracked·미해결 issue·검증 |

보고자는 affected 파일을 직접 고치지 않고 자기 태스크의 `issues/` 아래에
`{YYYYMMDDTHHMMSS}-{reporter-id}-to-{affected-id-or-main}-{slug}.issue.md`를 생성한다.
같은 issue를 복제하지 않는다. 보고자는 증거를 보강하고 조정 담당자 한 명이 상태·resolution·이관을 갱신한다.

- BLOCKER: 코드·데이터·보안·통합 손상 또는 확정된 파일 충돌. 영향 범위의 완료·commit·통합을 중지한다.
- WARNING: 지금은 격리됐으나 통합·후속 재검증 필요. C4 전에 처리 계획을 기록한다.
- INFO: 예상되는 연계·확인 사항. handoff에 연결한다.

상태는 OPEN → ACKNOWLEDGED → RESOLVED 또는 ACCEPTED_RISK다.
ACKNOWLEDGED는 해결을 뜻하지 않는다. 미해결 BLOCKER는 계속 영향을 차단한다.
RESOLVED에는 실제 검증 증거, ACCEPTED_RISK에는 승인자·완화책·재검토 조건이 필요하다.
태스크 종료 전 unresolved issue는 해결하거나 책임 태스크로 이관하고 moved_from과 원래 태스크의 링크를 남긴다.

`bash .local/tools/check-parallel-impact.sh`는 읽기 전용 현황 조회다. 검사 통과나 자동 BLOCKER 판정 도구가 아니다.
