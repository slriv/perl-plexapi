import json
import os
import sys

try:
    from .normalize import normalize
except ImportError:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from normalize import normalize


def compare_responses(a, b):
    normalized_a = normalize(a)
    normalized_b = normalize(b)
    return {
        'match': normalized_a == normalized_b,
        'a': normalized_a,
        'b': normalized_b,
    }


def report(result):
    if result['match']:
        return {'status': 'match'}
    return {
        'status': 'mismatch',
        'a': result['a'],
        'b': result['b'],
    }


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Compare normalized API responses')
    parser.add_argument('file_a')
    parser.add_argument('file_b')
    args = parser.parse_args()

    with open(args.file_a) as fa, open(args.file_b) as fb:
        a = json.load(fa)
        b = json.load(fb)

    result = compare_responses(a['result'], b['result'])
    print(json.dumps(report(result), indent=2))
