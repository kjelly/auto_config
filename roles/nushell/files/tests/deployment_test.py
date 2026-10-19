"""Offline installer fixtures; all destination writes stay in temporary directories."""
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

try:
    import yaml
except ImportError:
    yaml = None

REPO = Path(os.environ.get('AUTO_CONFIG_REPO', Path.home() / 'nfs/auto_config'))
SCRIPTS = ['gamepad.nu', 'gamepad-tools.nu', 'gamepad-edit.nu', 'gamepad-workflows.nu', 'gamepad-tasks.nu', 'gamepad-task-worker.nu', 'history-query.nu', 'shell-integration.nu', 'secure-edit.nu', 'login-env.nu']


@unittest.skipUnless(yaml and shutil.which('nu') and (REPO / 'roles/nushell/tasks/config.yml').exists(), 'requires PyYAML, Nushell and auto_config checkout')
class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nu-deployment-')
        self.base = Path(self.temp.name)
        self.target = self.base / 'nushell'
        self.target.mkdir()
        self.assets = REPO / 'roles/nushell/files'
        (self.target / 'login.nu').write_text('# USER LOGIN\n')

    def tearDown(self):
        self.temp.cleanup()

    def verify(self, iteration):
        for name in SCRIPTS:
            self.assertEqual((self.target / 'scripts' / name).read_bytes(), (self.assets / 'scripts' / name).read_bytes())
        expected = b'USER FAVORITES\n' if iteration else (self.assets / 'gamepad-favorites.nuon').read_bytes()
        self.assertEqual((self.target / 'gamepad-favorites.nuon').read_bytes(), expected)
        login = (self.target / 'login.nu').read_text()
        self.assertIn('# USER LOGIN', login)
        self.assertEqual(login.count('# BEGIN AUTO_CONFIG LOGIN ENV'), 1)
        self.assertEqual(login.count('login-env.nu'), 1)

    def make_stale(self):
        (self.target / 'gamepad-favorites.nuon').write_text('USER FAVORITES\n')
        for name in SCRIPTS:
            (self.target / 'scripts' / name).write_text('stale\n')

    @unittest.skipUnless(shutil.which('ansible-playbook'), 'requires ansible-playbook')
    def test_ansible_updates_all_helpers_and_preserves_user_files(self):
        tasks = yaml.safe_load((REPO / 'roles/nushell/tasks/config.yml').read_text())[:4]
        self.assertEqual(tasks[-1]['name'], 'Import POSIX profile only for login shells')
        tasks = copy.deepcopy(tasks)
        for task in tasks:
            for module in ['ansible.builtin.file', 'ansible.builtin.copy', 'ansible.builtin.blockinfile']:
                if module not in task:
                    continue
                options = task[module]
                for key in ['path', 'dest']:
                    if key in options:
                        options[key] = options[key].replace('~/.config/nushell', str(self.target))
                if 'src' in options:
                    options['src'] = str(self.assets / options['src'])
        playbook = self.base / 'test.yml'
        playbook.write_text(yaml.safe_dump([{'hosts': 'localhost', 'gather_facts': False, 'vars': {'ansible_python_interpreter': sys.executable, 'ansible_remote_tmp': str(self.base / 'remote-tmp')}, 'tasks': tasks}]))
        config = self.base / 'ansible.cfg'
        config.write_text('[defaults]\nlocal_tmp=' + str(self.base / 'local-tmp') + '\n')
        for iteration in range(2):
            if iteration:
                self.make_stale()
            result = subprocess.run(['ansible-playbook', '-i', 'localhost,', '-c', 'local', str(playbook)], env=dict(os.environ, ANSIBLE_CONFIG=str(config)), text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.verify(iteration)

    def test_nu_initializer_updates_all_helpers_and_preserves_user_files(self):
        initializer = (REPO / 'scripts/init_nushellrc.nu').read_text()
        body = initializer.split('def main [ ] {\n', 1)[1].split('  config nu --default', 1)[0]
        body = body.replace('mkdir ~/.config/nushell', 'mkdir $test_config').replace('$nu.default-config-dir', '$test_config')
        code = '\n'.join([
            'let test_config = ' + json.dumps(str(self.target)),
            'def "http get" [url: string, --raw] {',
            "let relative = ($url | str replace 'https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/' '')",
            'open --raw (' + json.dumps(str(self.assets)) + ' | path join $relative)',
            '}', body,
        ])
        for iteration in range(2):
            if iteration:
                self.make_stale()
            result = subprocess.run(['nu', '-n', '-c', code], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.verify(iteration)


if __name__ == '__main__':
    unittest.main()
