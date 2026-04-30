#!/usr/bin/env python3
import argparse
import json
import os
import sys

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


def run_endpoint(endpoint, params, baseurl, token):
    plex = PlexServer(baseurl, token)
    if endpoint == 'server.sessions':
        return [session._data.attrib for session in plex.sessions()]
    if endpoint == 'library.sections':
        result = []
        for section in plex.library.sections():
            attrs = dict(section._data.attrib)
            locations = [loc.attrib for loc in section._data.findall('Location')]
            attrs['Location'] = locations if locations else []
            result.append(attrs)
        return result
    if endpoint == 'video.movies':
        section = plex.library.sectionByID(int(params['section_id']))
        return [movie._data.attrib for movie in section.search(libtype='movie')]
    if endpoint == 'audio.albums':
        section = plex.library.sectionByID(int(params['section_id']))
        albums = []
        for album in section.albums():
            attrs = dict(album._data.attrib)
            for drop in ('allowSync', 'librarySectionID', 'librarySectionTitle', 'librarySectionUUID', 'leafCount'):
                attrs.pop(drop, None)
            albums.append(attrs)
        return albums
    raise ValueError(f'Unsupported endpoint: {endpoint}')


def main():
    parser = argparse.ArgumentParser(description='Run python-plexapi endpoint and emit JSON')
    parser.add_argument('--endpoint', required=True)
    parser.add_argument('--baseurl', required=True)
    parser.add_argument('--token', default='')
    parser.add_argument('--params', default='{}')
    args = parser.parse_args()

    params = json.loads(args.params)
    result = run_endpoint(args.endpoint, params, args.baseurl, args.token)
    print(json.dumps({'endpoint': args.endpoint, 'params': params, 'result': result}, default=str))


if __name__ == '__main__':
    main()
