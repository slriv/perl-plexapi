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
is $fake->last_call->{path},           '/library/sections/3/all', 'section_all path';
is $fake->last_call->{params}{type},   1,                         'section_all type param';
is $fake->last_call->{params}{sort},   'titleSort',               'section_all sort param';

$lib->section_search(3, 'Inception');
is $fake->last_call->{path},           '/library/sections/3/search', 'section_search path';
is $fake->last_call->{params}{query},  'Inception',                  'section_search query param';

$lib->section_search(3, 'Inception', type => 1);
is $fake->last_call->{params}{query}, 'Inception', 'section_search query with extra params';
is $fake->last_call->{params}{type},  1,           'section_search extra param forwarded';

# --- discovery ---

$lib->recently_added;
is $fake->last_call->{method}, 'get',                    'recently_added uses GET';
is $fake->last_call->{path},   '/library/recentlyAdded', 'recently_added path';

$lib->on_deck;
is $fake->last_call->{path}, '/library/onDeck', 'on_deck path';

$lib->search('Breaking Bad');
is $fake->last_call->{path},          '/hubs/search',  'search path';
is $fake->last_call->{params}{query}, 'Breaking Bad',  'search query param';

$lib->search('foo', limit => 10);
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

$lib->refresh_metadata(12345);
is $fake->last_call->{method}, 'put',                              'refresh_metadata uses PUT';
is $fake->last_call->{path},   '/library/metadata/12345/refresh',  'refresh_metadata path';

$lib->empty_trash(3);
is $fake->last_call->{method}, 'put',                             'empty_trash uses PUT';
is $fake->last_call->{path},   '/library/sections/3/emptyTrash',  'empty_trash path';

# --- playback state ---

$lib->mark_played(12345);
is $fake->last_call->{method},            'get',                        'mark_played uses GET';
is $fake->last_call->{path},              '/:/scrobble',                 'mark_played path';
is $fake->last_call->{params}{key},       12345,                         'mark_played key param';
is $fake->last_call->{params}{identifier},'com.plexapp.plugins.library', 'mark_played identifier';

$lib->mark_unplayed(12345);
is $fake->last_call->{path},             '/:/unscrobble',                'mark_unplayed path';
is $fake->last_call->{params}{key},       12345,                         'mark_unplayed key param';

$lib->update_progress(12345, 60_000);
is $fake->last_call->{path},               '/:/timeline', 'update_progress path';
is $fake->last_call->{params}{ratingKey},  12345,         'update_progress ratingKey';
is $fake->last_call->{params}{time},       60_000,        'update_progress time';
is $fake->last_call->{params}{state},      'stopped',     'update_progress default state';

$lib->update_progress(12345, 60_000, 'playing');
is $fake->last_call->{params}{state}, 'playing', 'update_progress custom state';

done_testing;
