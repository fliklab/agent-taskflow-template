# 템플릿 저장소 작업 규칙

작업 전 README.md와 로컬 운영 기록이 있으면 `.local/README.md`, `.local/docs/progress.md`를 읽는다.
- `template/local/`은 공유할 빈 양식이다. 실제 프로젝트 기록·고객 정보·비밀값을 넣지 않는다.
- 이 저장소 자체의 운영 기록은 `.local/`에 작성하고 Git에서 제외한다.
- 설치 도구는 기존 파일과 작업 내용을 보존해야 한다. 변경 후 `python3 -m unittest discover -s tests -v`를 실행한다.
- 전용 `agent/{task-id}-{slug}` branch에서 검증된 단위마다 local commit한다.
- 최초 빈 저장소 bootstrap은 task branch에서 commit한 뒤 승인된 최초 공개 범위에서 main을 생성할 수 있다. 이후 구현은 별도 worktree에서 수행한다.
- push·PR·main 통합·배포·branch/worktree 삭제는 사용자 요청 범위에서만 수행한다.
- 설명과 문서는 자연스러운 한국어로 작성한다.
