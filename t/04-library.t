use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Library;

my $fake = FakePlex->new;
my $lib  = WebService::Plex::Library->new(plex => $fake);

# --- sections ---

$lib->sections;
is $fake->last_call->{method}, 'get',               'sections uses GET';
is $fake->last_call->{path},   '/library/sections', 'sections path';

$lib->section(3);
is $fake->last_call->{path}, '/library/sections/3', 'section path';

$lib->section_all(3, type => 1, sort => 'titleSort');
is $fake->last_call->{path},           '/library/sections/3/all?sort=titleSort&type=1', 'section_all path';
is $fake->last_call->{params}{type},   1,                         'section_all type param';
is $fake->last_call->{params}{sort},   'titleSort',               'section_all sort param';

$lib->section_search(3, 'Inception');
is $fake->last_call->{path},           '/library/sections/3/search?query=Inception', 'section_search path';
is $fake->last_call->{params}{query},  'Inception',                  'section_search query param';

$lib->section_search(3, 'Inception', type => 1);
is $fake->last_call->{path},           '/library/sections/3/search?query=Inception&type=1', 'section_search path with params';
is $fake->last_call->{params}{query}, 'Inception', 'section_search query with extra params';
is $fake->last_call->{params}{type},  1,           'section_search extra param forwarded';

# --- discovery ---

$lib->recently_added;
is $fake->last_call->{method}, 'get',                    'recently_added uses GET';
is $fake->last_call->{path},   '/library/recentlyAdded', 'recently_added path';

$lib->on_deck;
is $fake->last_call->{path}, '/library/onDeck', 'on_deck path';

$lib->search('Breaking Bad');
is $fake->last_call->{path},          '/hubs/search?query=Breaking%20Bad',  'search path';
is $fake->last_call->{params}{query}, 'Breaking Bad',  'search query param';

$lib->search('foo', limit => 10);
is $fake->last_call->{path},          '/hubs/search?limit=10&query=foo', 'search path with params';
is $fake->last_call->{params}{limit}, 10, 'search extra param forwarded';

# --- metadata ---

$lib->metadata(12345);
is $fake->last_call->{method}, 'get',                       'metadata uses GET';
is $fake->last_call->{path},   '/library/metadata/12345',   'metadata path';

$lib->metadata_children(12345);
is $fake->last_call->{path}, '/library/metadata/12345/children', 'metadata_children path';

# --- maintenance ---

$lib->refresh_section(3);
is $fake->last_call->{method}, 'get',                         'refresh_section uses GET';
is $fake->last_call->{path},   '/library/sections/3/refresh', 'refresh_section path';

$lib->refresh_section(3, path => '/some/folder');
is $fake->last_call->{path},           '/library/sections/3/refresh?path=%2Fsome%2Ffolder', 'refresh_section path with query param';
is $fake->last_call->{params}{path},  '/some/folder',                  'refresh_section path param';

$lib->refresh_metadata(12345);
is $fake->last_call->{method}, 'put',                              'refresh_metadata uses PUT';
is $fake->last_call->{path},   '/library/metadata/12345/refresh',  'refresh_metadata path';

$lib->empty_trash(3);
is $fake->last_call->{method}, 'put',                             'empty_trash uses PUT';
is $fake->last_call->{path},   '/library/sections/3/emptyTrash',  'empty_trash path';

# --- playback state ---

$lib->mark_played(12345);
is $fake->last_call->{method},            'get',                        'mark_played uses GET';
is $fake->last_call->{path},              '/:/scrobble?identifier=com.plexapp.plugins.library&key=12345', 'mark_played path';
is $fake->last_call->{params}{key},       12345,                         'mark_played key param';
is $fake->last_call->{params}{identifier},'com.plexapp.plugins.library', 'mark_played identifier';

$lib->mark_unplayed(12345);
is $fake->last_call->{path},              '/:/unscrobble?identifier=com.plexapp.plugins.library&key=12345',                'mark_unplayed path';
is $fake->last_call->{params}{key},        12345,                         'mark_unplayed key param';
is $fake->last_call->{params}{identifier},'com.plexapp.plugins.library',  'mark_unplayed identifier';

$lib->update_progress(12345, 60_000);
is $fake->last_call->{path},              '/:/progress?identifier=com.plexapp.plugins.library&key=12345&state=stopped&time=60000',                  'update_progress path';
is $fake->last_call->{params}{key},       12345,                          'update_progress key param';
is $fake->last_call->{params}{time},      60_000,                         'update_progress time';
is $fake->last_call->{params}{state},     'stopped',                      'update_progress default state';
is $fake->last_call->{params}{identifier},'com.plexapp.plugins.library',  'update_progress identifier';

$lib->update_progress(12345, 60_000, 'playing');
is $fake->last_call->{path},              '/:/progress?identifier=com.plexapp.plugins.library&key=12345&state=playing&time=60000', 'update_progress path playing';
is $fake->last_call->{params}{state}, 'playing', 'update_progress custom state';

$lib->update_progress(12345, 60_000, 'paused');
is $fake->last_call->{path},              '/:/progress?identifier=com.plexapp.plugins.library&key=12345&state=paused&time=60000', 'update_progress path paused';
is $fake->last_call->{params}{state}, 'paused', 'update_progress paused state';

# --- continue watching ---

$lib->continue_watching;
is $fake->last_call->{method}, 'get',                               'continue_watching uses GET';
is $fake->last_call->{path},   '/hubs/continueWatching/items',      'continue_watching path';

# --- hubs ---

$lib->hubs;
is $fake->last_call->{path}, '/hubs', 'hubs path';

$lib->section_hubs(1);
is $fake->last_call->{path}, '/hubs/sections/1', 'section_hubs path';

$lib->metadata_hubs(12345);
is $fake->last_call->{path}, '/hubs/metadata/12345', 'metadata_hubs path';

$lib->related_hubs(12345);
is $fake->last_call->{path}, '/hubs/metadata/12345/related', 'related_hubs path';

# --- first character / tags ---

$lib->first_character(1);
is $fake->last_call->{method}, 'get',                                    'first_character uses GET';
is $fake->last_call->{path},   '/library/sections/1/firstCharacters',    'first_character path';

$lib->tags(1);
is $fake->last_call->{path},           '/library/tags?type=1', 'tags path';
is $fake->last_call->{params}{type},   1,                      'tags type param';

# --- history ---

$lib->history;
like $fake->last_call->{path},       qr{/status/sessions/history/all}, 'library history path';
is $fake->last_call->{params}{sort}, 'viewedAt:desc',                  'library history default sort';

$lib->history(accountID => 2);
is $fake->last_call->{params}{accountID}, 2, 'library history accountID param';

# --- metadata_related ---

$lib->metadata_related(12345);
is $fake->last_call->{path}, '/library/metadata/12345/related', 'metadata_related path';

# --- maintenance: clean_bundles / optimize ---

$lib->clean_bundles;
is $fake->last_call->{method}, 'put',                   'clean_bundles uses PUT';
is $fake->last_call->{path},   '/library/clean/bundles','clean_bundles path';

$lib->optimize;
is $fake->last_call->{method}, 'put',              'optimize uses PUT';
is $fake->last_call->{path},   '/library/optimize','optimize path';

done_testing;
