# API Comparison Tools

This directory contains helpers for comparing API behavior between `perl-plexapi` and `python-plexapi`.

Usage
- `perl scripts/compare-perl-api.pl --endpoint <name> --baseurl <url> [--token <token>] [--params '{"foo":1}']`
- `python tools/python_api_compare.py --endpoint <name> --baseurl <url> [--token <token>] [--params '{"foo":1}']`
- `python -m tools.api_compare.compare perl.json python.json`
- `python tools/api_compare/run_all.py --baseurl http://127.0.0.1:32400 --token <token>`

Components
- `scripts/compare-perl-api.pl`: Perl runner for named endpoints.
- `tools/python_api_compare.py`: Python runner for named endpoints.
- `tools/api-endpoint-list.yml`: shared endpoint inventory.
- `tools/api_compare/normalize.py`: normalize responses before comparison.
- `tools/api_compare/compare.py`: compare normalized results.
- `tools/api_compare/run_all.py`: run all inventory endpoints and report matches.
