"""Exercise the actual release script with a fake Flutter; never upload."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name('publish.sh')


class PublishTest(unittest.TestCase):
    def run_release(self, scenario, mode='--publish'):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake = root / 'flutter'
            fake.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ['CALL_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
scenario = os.environ['SCENARIO']
if args == ['pub', 'publish', '--dry-run']:
    assert not Path('pub-validation.log').exists(), 'Validation log entered release directory'
    assert 'publish_to:' not in Path('pubspec.yaml').read_text()
    if scenario == 'success':
        print('Package has 0 warnings.')
        sys.exit(0)
    if scenario == 'network':
        print('Network failure')
        sys.exit(65)
    if scenario == 'error':
        print('Package validation found an error.')
        sys.exit(65)
    if scenario == 'server':
        print('Message from server: Invalid `publish_to` value: `https://pub.dev`.')
        sys.exit(65)
    extra = scenario == 'other_warning'
    count = 2 if extra else 1
    print('Package validation found the following potential issue:' if not extra
          else 'Package validation found the following 2 potential issues:')
    print('* It\\'s strongly recommended to include a "homepage" or "repository" field in your pubspec.yaml')
    if extra:
        print('* Package contains an unexpected file.')
    print(f'Package has {count} warnings.')
    sys.exit(65)
if scenario == args[0] or (scenario == 'get' and args == ['pub', 'get']):
    sys.exit(1)
''')
            fake.chmod(0o755)
            log = root / 'calls.jsonl'
            result = subprocess.run(
                ['bash', str(SCRIPT), mode],
                env={**os.environ, 'FLUTTER_BIN': str(fake),
                     'SCENARIO': scenario, 'CALL_LOG': str(log)},
                capture_output=True, text=True,
            )
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            return result, calls

    def test_only_missing_homepage_allows_upload(self):
        result, calls = self.run_release('homepage')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('不阻止发布', result.stdout)
        self.assertEqual(calls[-1], ['pub', 'publish', '--force'])

    def test_clean_validation_allows_upload(self):
        result, calls = self.run_release('success')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1], ['pub', 'publish', '--force'])

    def test_other_failures_prevent_upload(self):
        for scenario in ['other_warning', 'error', 'server', 'network', 'get', 'analyze', 'test']:
            with self.subTest(scenario=scenario):
                result, calls = self.run_release(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn(['pub', 'publish', '--force'], calls)

    def test_dry_run_never_uploads(self):
        result, calls = self.run_release('homepage', '--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(['pub', 'publish', '--force'], calls)


if __name__ == '__main__':
    unittest.main()
