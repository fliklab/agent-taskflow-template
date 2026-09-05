#!/usr/bin/env python3
"""Install reviewed local task templates in an existing Git repository."""
import argparse
import re
from pathlib import Path
import shutil
import shlex
import subprocess
import sys

SOURCE = Path(__file__).resolve().parents[1] / 'template'
MARKER = '<!-- local-task-template:begin -->'
IGNORE = '\n# Local task records (including a worktree symlink)\n/.local\n/.local/\n'


def git(root, *args):
    return subprocess.run(['git', '-C', str(root), *args], check=True,
                          text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.strip()


def install(target='.', apply=False):
    location = Path(target).expanduser().resolve(strict=True)
    root = Path(git(location, 'rev-parse', '--show-toplevel')).resolve()
    worktree_root = root.parent / (root.name + '-worktrees')
    replacements = {
        '{{PROJECT_NAME}}': root.name,
        '{{REPO_ROOT}}': str(root),
        '{{WORKTREE_ROOT}}': str(worktree_root),
        '{{REPO_ROOT_SHELL}}': shlex.quote(str(root)),
        '{{WORKTREE_ROOT_SHELL}}': shlex.quote(str(worktree_root)),
    }
    print(f'대상 저장소: {root}')
    print(f'worktree 기본 경로: {worktree_root}')
    local = root / '.local'
    if local.exists() or local.is_symlink():
        raise ValueError('기존 .local을 보존합니다. 자동 덮어쓰기·업그레이드는 지원하지 않습니다.')
    if git(root, 'ls-files', '--', '.local'):
        raise ValueError('.local이 이미 Git에서 추적됩니다. 추적 경위를 먼저 확인하세요.')
    planned = {}
    for name in ['AGENTS.md', '.gitignore']:
        path = root / name
        if path.is_symlink() or (path.exists() and not path.is_file()):
            raise ValueError(f'{name}이 일반 파일이 아닙니다. 자동 수정하지 않습니다.')
        planned[name] = path.read_text() if path.exists() else ''
    if MARKER in planned['AGENTS.md']:
        raise ValueError('기존 템플릿 지침이 있습니다. 중복 설치 대신 수동 비교하세요.')
    planned['AGENTS.md'] += '\n\n' + (SOURCE / 'AGENTS.fragment.md').read_text()
    planned['.gitignore'] += IGNORE
    for name in planned:
        print(f'기존 내용 뒤에 추가: {root / name}')
    print(f'빈 양식 생성: {local}')
    if not apply:
        print('미리보기입니다. 실제 적용에는 --apply를 사용하세요.')
        return
    # No Git staging, commits, network operations, or modification of product files.
    shutil.copytree(SOURCE / 'local', local)
    for document in local.rglob('*.md'):
        content = document.read_text()
        # One pass prevents token-like characters in real paths being replaced again.
        content = re.sub(r'\{\{[A-Z_]+\}\}',
                         lambda match: replacements.get(match[0], match[0]), content)
        document.write_text(content)
    for name, content in planned.items():
        (root / name).write_text(content)
    git(root, 'check-ignore', '.local/README.md')
    print('적용 완료. AGENTS.md와 .gitignore diff를 검토하고 프로젝트 기준을 채우세요.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target', nargs='?', default='.',
                        help='대상 저장소 또는 내부 디렉터리 (기본: 현재 위치의 Git 저장소)')
    parser.add_argument('--apply', action='store_true', help='미리보기 내용을 실제 적용')
    args = parser.parse_args()
    try:
        install(args.target, args.apply)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'설치 중단: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
