#!/usr/bin/env python3
"""Read-only snapshot. Ownership and blocking issues require human review."""
from pathlib import Path
import subprocess


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True)


def main():
    root = Path(git(Path.cwd(), 'rev-parse', '--show-toplevel').strip())
    print(f'현재 저장소: {root}')
    records = git(root, 'worktree', 'list', '--porcelain', '-z').split('\0')
    for record in records:
        if record.startswith('worktree '):
            tree = Path(record[len('worktree '):])
            print(f'\nworktree: {tree}')
            try:
                print(git(tree, 'status', '--short', '--branch'), end='')
            except subprocess.CalledProcessError:
                print('조회 실패: 경로·접근 권한·worktree 상태를 직접 확인하세요.')
    local = Path(__file__).resolve().parents[1]
    print('\n활성 태스크 issue (해결된 항목도 포함):')
    issues = sorted((local / 'tasks/IN_PROGRESS').glob('*/issues/*.issue.md'))
    for issue in issues:
        print(f'\n{issue}\n{issue.read_text()}')
    if not issues:
        print('없음')
    print('\n현재 unstaged / staged 변경 파일:')
    print(git(root, 'diff', '--name-only'), end='')
    print(git(root, 'diff', '--cached', '--name-only'), end='')
    print('\n이 조회 결과는 자동 검증 통과 판정이 아닙니다.')


if __name__ == '__main__':
    main()
