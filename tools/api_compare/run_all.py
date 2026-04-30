#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    print('This script requires PyYAML. Install it with pip install pyyaml', file=sys.stderr)
    sys.exit(1)

try:
    from plexapi.server import PlexServer
except ImportError:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    sibling_python_root = os.path.abspath(os.path.join(repo_root, '..', 'python-plexapi'))
    for candidate in (repo_root, sibling_python_root):
        if os.path.isdir(candidate) and candidate not in sys.path:
            sys.path.insert(0, candidate)
    try:
        from plexapi.server import PlexServer
    except ImportError:
        print('python-plexapi is not installed in this environment', file=sys.stderr)
        sys.exit(1)


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
INVENTORY_PATH = os.path.join(ROOT, 'tools', 'api-endpoint-list.yml')
PERL_SCRIPT = os.path.join(ROOT, 'scripts', 'compare-perl-api.pl')
PYTHON_SCRIPT = os.path.join(ROOT, 'tools', 'python_api_compare.py')
COMPARE_MODULE = 'tools.api_compare.compare'


def load_inventory(path):
    with open(path, 'r', encoding='utf-8') as fh:
        return yaml.safe_load(fh)


def get_section_id(plex, section_type):
    for section in plex.library.sections():
        if getattr(section, 'type', None) == section_type:
            return section.key
    raise ValueError(f'No library section found with type {section_type}')


def resolve_params(name, plex):
    if name == 'video.movies':
        return {'section_id': get_section_id(plex, 'movie')}
    if name == 'audio.albums':
        return {'section_id': get_section_id(plex, 'artist')}
    return {}


def run_script(cmd, env=None, cwd=None):
    result = subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=cwd)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{result.stderr}")
    return result.stdout


def compare_files(a_path, b_path, env, cwd):
    cmd = [sys.executable, '-m', COMPARE_MODULE, a_path, b_path]
    return run_script(cmd, env=env, cwd=cwd)


def main():
    parser = argparse.ArgumentParser(description='Run all API comparison endpoints from inventory')
    parser.add_argument('--baseurl', default='http://127.0.0.1:32400')
    parser.add_argument('--token', default='')
    parser.add_argument('--timeout', type=int, default=30)
    parser.add_argument('--inventory', default=INVENTORY_PATH)
    parser.add_argument('--perl5lib', default='lib:~/perl5/lib/perl5')
    parser.add_argument('--verbose', action='store_true')
    args = parser.parse_args()

    endpoints = load_inventory(args.inventory)
    plex = PlexServer(args.baseurl, args.token)

    runner_env = os.environ.copy()
    runner_env['PYTHONPATH'] = os.pathsep.join(
        [os.path.abspath(os.path.join(ROOT, '..', 'python-plexapi')), runner_env.get('PYTHONPATH', '')]
    ).strip(os.pathsep)
    perl_env = os.environ.copy()
    perl_env['PERL5LIB'] = os.pathsep.join(
        [os.path.expanduser(args.perl5lib), perl_env.get('PERL5LIB', '')]
    ).strip(os.pathsep)

    summary = []

    with tempfile.TemporaryDirectory() as tempdir:
        for item in endpoints:
            name = item['name']
            params = resolve_params(name, plex)
            params_json = json.dumps(params)
            if args.verbose:
                print(f'Running endpoint: {name} params={params_json}')

            perl_output = os.path.join(tempdir, f'perl-{name}.json')
            python_output = os.path.join(tempdir, f'python-{name}.json')

            perl_cmd = [
                'perl', PERL_SCRIPT,
                '--endpoint', name,
                '--baseurl', args.baseurl,
                '--params', params_json,
                '--timeout', str(args.timeout),
            ]
            if args.token:
                perl_cmd += ['--token', args.token]

            python_cmd = [
                sys.executable, PYTHON_SCRIPT,
                '--endpoint', name,
                '--baseurl', args.baseurl,
                '--params', params_json,
            ]
            if args.token:
                python_cmd += ['--token', args.token]

            with open(perl_output, 'w', encoding='utf-8') as fh:
                fh.write(run_script(perl_cmd, env=perl_env, cwd=ROOT))
            with open(python_output, 'w', encoding='utf-8') as fh:
                fh.write(run_script(python_cmd, env=runner_env, cwd=ROOT))

            compare_output = compare_files(perl_output, python_output, env=runner_env, cwd=ROOT)
            result = json.loads(compare_output)
            summary.append({'endpoint': name, 'status': result['status']})
            print(f"{name}: {result['status']}")

        print('\nSummary:')
        for item in summary:
            print(f"  {item['endpoint']}: {item['status']}")

if __name__ == '__main__':
    main()
