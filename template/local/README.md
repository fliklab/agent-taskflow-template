# 로컬 프로젝트·태스크 운영

이 디렉터리는 프로젝트 내부 기획·판단·진행·인수인계 기록이다. 전체를 Git에서 제외한다.
실제 비밀번호·토큰·개인정보는 여기에 보관하지 않고 승인된 비밀 관리 도구를 사용한다.

## 읽는 순서

1. 이 문서와 `docs/progress.md`
2. 외부 연동이 관련되면 `external-services/inventory.md`와 해당 서비스 기록
3. progress가 가리키는 `spec-design/` 기준 문서
4. 관련 `tasks/IN_PROGRESS/` 또는 시작할 `tasks/TO_DO/` 태스크
5. 과거 맥락이 필요할 때만 `tasks/DONE/`

## 구조와 역할

| 경로 | 역할 |
|---|---|
| `docs/progress.md` | 현재 단계·실제 작업·계획 대비 차이·다음 행동의 기준 |
| `spec-design/` | 장기 요구사항·설계·Git 운영·검증 기준 |
| `references/` | 원본 요구·회의·조사 자료 |
| `external-services/` | 서비스 소유자·접근 경로·준비·검증·인수 상태 |
| `tasks/TO_DO/` | 아직 시작하지 않은 작업 |
| `tasks/IN_PROGRESS/` | 실제 수행 중인 작업 |
| `tasks/DONE/` | 완료된 작업과 handoff |
| `templates/` | 새 태스크·외부 서비스에 복사할 빈 양식 |
| `tools/` | Git worktree·교차 영향 조회 도구 |

## 태스크 규칙

- 디렉터리 이름은 `{3자리 번호}-{kebab-case-title}`이다. 전체 상태 폴더의 최대 번호 + 1을 사용하며 첫 번호는 `000`이다.
- 번호 배정과 progress 수정은 조정 담당자 한 명이 수행한다. `999` 이후에는 자릿수 확장 정책을 먼저 결정한다.
- 동일 태스크는 하나의 상태 폴더에만 존재한다. `.local/task/`, `todo/`, `active/` 같은 변형 경로를 만들지 않는다.
- 생성은 TO_DO, 실제 시작 때 IN_PROGRESS, 완료 조건·검증·handoff를 갖춘 뒤 DONE으로 폴더 전체를 이동한다.
- 차단되거나 중단된 작업은 IN_PROGRESS에 사유·책임자·재개 조건을 남긴다. 요청 철회는 구현 완료와 구분해 종료 사유를 적는다.
- `templates/task/`를 복사한다. README는 필수이며 나머지 문서는 작업 규모에 맞춰 사용한다.
- 문서 번호는 태스크 내부에서 `000`부터 증가한다. `.human.md`는 사용자 원문, `.tasklist.md`는 실행·완료 조건, `.note.md`는 조사·판단, `.log.md`는 결과·handoff다.
- 생성·시작·변경·완료 시 progress의 현재 요약을 갱신하고 최근 기록을 추가한다. 오래된 상세 이력은 해당 태스크로 옮겨 progress가 지나치게 길어지지 않게 한다.

## 완료 기준

목표·체크리스트·설계를 최신화하고 실제 검증 명령·결과·환경·미실행 사유를 기록한다.
관련 미해결 BLOCKER는 해결하거나 작업 범위를 분리한다. unresolved issue를 이관하면 원래 경로와 새 책임 태스크를 연결한다.
DONE은 구현·검증 완료를 뜻한다. local commit, push, PR, main 통합, 배포는 각각 별도 상태로 남긴다.
기획만 바꿨다면 `.local` 기록만 갱신하며 commit을 만들기 위해 내부 문서를 추적하지 않는다.

## 병렬 작업

병렬 실행은 작업 방식의 선택 사항이며 자동으로 에이전트를 추가하라는 지시가 아니다.
병렬로 수행할 때는 `tasks/IN_PROGRESS/ISSUE-RULES.md`의 C0~C4 점검과 파일 소유권 규칙을 적용한다.
작업 worktree에서는 공유 `.local`을 읽기 전용으로 참조하고, 상태 이동·progress 수정은 기본 worktree의 조정 담당자가 수행한다.
