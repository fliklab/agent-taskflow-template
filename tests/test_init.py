import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'scripts/init.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='local task test ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.git('init', '-b', 'main')

    def git(self, *args):
        return installer.git(self.root, *args)

    def test_preview_does_not_write(self):
        installer.install(self.root)
        self.assertFalse((self.root / '.local').exists())
        self.assertFalse((self.root / 'AGENTS.md').exists())
        self.assertFalse((self.root / '.gitignore').exists())

    def test_preserve_existing_content_and_ignore_local(self):
        (self.root / 'AGENTS.md').write_text('# 사용자 기존 규칙\n')
        (self.root / '.gitignore').write_text('build/\n!/.local/\n')
        (self.root / 'app.txt').write_text('existing code')
        installer.install(self.root, True)
        self.assertTrue((self.root / 'AGENTS.md').read_text().startswith('# 사용자 기존 규칙\n'))
        self.assertTrue((self.root / '.gitignore').read_text().startswith('build/\n!/.local/\n'))
        self.assertEqual((self.root / 'app.txt').read_text(), 'existing code')
        self.assertEqual(self.git('check-ignore', '.local/README.md'), '.local/README.md')
        self.assertEqual(self.git('ls-files', '.local'), '')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')
        self.assertTrue((self.root / '.local/templates/task/003-handoff.log.md').is_file())

    def test_existing_local_and_repeat_are_rejected_without_changes(self):
        installer.install(self.root, True)
        before = (self.root / 'AGENTS.md').read_bytes()
        with self.assertRaises(ValueError):
            installer.install(self.root, True)
        self.assertEqual(before, (self.root / 'AGENTS.md').read_bytes())

    def test_symlink_rejected(self):
        real = self.root / 'real.md'
        real.write_text('preserve')
        (self.root / 'AGENTS.md').symlink_to(real)
        with self.assertRaises(ValueError):
            installer.install(self.root, True)
        self.assertFalse((self.root / '.local').exists())
        self.assertEqual(real.read_text(), 'preserve')

    def test_tracked_but_deleted_local_rejected(self):
        local = self.root / '.local'
        local.mkdir()
        (local / 'note').write_text('private')
        self.git('add', '.local/note')
        (local / 'note').unlink()
        local.rmdir()
        with self.assertRaises(ValueError):
            installer.install(self.root, True)

    def test_subdirectory_uses_actual_root(self):
        sub = self.root / 'sub'
        sub.mkdir()
        installer.install(sub, True)
        self.assertTrue((self.root / '.local/README.md').exists())
        self.assertFalse((sub / '.local').exists())

    def test_default_cli_target_from_nested_directory(self):
        sub = self.root / 'nested'
        sub.mkdir()
        subprocess.run(['python3', str(ROOT / 'scripts/init.py'), '--apply'],
                       cwd=sub, check=True, capture_output=True, text=True)
        local = self.root / '.local'
        self.assertTrue(local.exists())
        for name in ['README.md', 'docs/progress.md', 'spec-design/001-git-workflow.md']:
            text = (local / name).read_text()
            self.assertIn(str(self.root.resolve()), text)
            self.assertNotIn('{{', text)
        self.assertNotIn(str(self.root.resolve()), (self.root / 'AGENTS.md').read_text())

    def test_special_paths_are_safe_in_generated_shell(self):
        root = self.root / "repo ' $(touch UNEXPECTED)"
        root.mkdir()
        installer.git(root, 'init', '-b', 'main')
        installer.install(root, True)
        text = (root / '.local/spec-design/001-git-workflow.md').read_text()
        assignments = [line for line in text.splitlines()
                       if line.startswith(('repo_root=', 'worktree_root='))]
        command = '\n'.join(assignments) + '\nprintf \'%s\n%s\' "$repo_root" "$worktree_root"'
        output = subprocess.check_output(['sh', '-c', command], cwd=root, text=True)
        self.assertEqual(output.splitlines(), [str(root.resolve()),
                          str(root.resolve().parent / (root.name + '-worktrees'))])
        self.assertFalse((root / 'UNEXPECTED').exists())

    def test_non_repository_rejected(self):
        with tempfile.TemporaryDirectory() as other:
            with self.assertRaises(subprocess.CalledProcessError):
                installer.install(other, True)

    def test_task_lifecycle_and_shared_worktree_snapshot(self):
        installer.install(self.root, True)
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '--allow-empty', '-m', 'test baseline')
        import shutil
        todo = self.root / '.local/tasks/TO_DO/000-example'
        shutil.copytree(self.root / '.local/templates/task', todo)
        active = todo.rename(self.root / '.local/tasks/IN_PROGRESS/000-example')
        (active / 'issues').mkdir()
        (active / 'issues/example.issue.md').write_text('status: OPEN\nseverity: WARNING\n')
        tree = self.root / 'task worktree'
        self.git('worktree', 'add', '-b', 'agent/000-example', str(tree), 'main')
        (tree / '.local').symlink_to(self.root / '.local', target_is_directory=True)
        result = subprocess.check_output(['python3', str(tree / '.local/tools/check-parallel-impact.py')],
                                         cwd=tree, text=True)
        self.assertIn('severity: WARNING', result)
        self.assertIn(str(tree), result)
        active.rename(self.root / '.local/tasks/DONE/000-example')
        self.assertFalse(todo.exists())
        self.assertFalse(active.exists())
        self.assertEqual(self.git('ls-files', '.local'), '')


if __name__ == '__main__':
    unittest.main()
