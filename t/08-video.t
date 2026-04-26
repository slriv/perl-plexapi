use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Video;

my $fake  = FakePlex->new;
my $video = WebService::Plex::Video->new(plex => $fake);

# --- type constants ---

is WebService::Plex::Video::TYPE_MOVIE,   1,  'TYPE_MOVIE = 1';
is WebService::Plex::Video::TYPE_SHOW,    2,  'TYPE_SHOW = 2';
is WebService::Plex::Video::TYPE_SEASON,  3,  'TYPE_SEASON = 3';
is WebService::Plex::Video::TYPE_EPISODE, 4,  'TYPE_EPISODE = 4';
is WebService::Plex::Video::TYPE_CLIP,    12, 'TYPE_CLIP = 12';

# --- movies ---

$video->movies(1);
is $fake->last_call->{method},        'get',                    'movies uses GET';
is $fake->last_call->{path},          '/library/sections/1/all?type=1','movies path';
is $fake->last_call->{params}{type},  1,                        'movies type=1';

$video->movies(1, sort => 'titleSort');
is $fake->last_call->{path},          '/library/sections/1/all?sort=titleSort&type=1','movies path with params';
is $fake->last_call->{params}{type},  1,           'movies type still 1 with extra params';
is $fake->last_call->{params}{sort},  'titleSort', 'movies extra param forwarded';

# --- shows ---

$video->shows(2);
is $fake->last_call->{path},         '/library/sections/2/all?type=2', 'shows path';
is $fake->last_call->{params}{type}, 2,                         'shows type=2';

$video->shows(2, unwatched => 1);
is $fake->last_call->{path},         '/library/sections/2/all?type=2&unwatched=1', 'shows path with params';
is $fake->last_call->{params}{unwatched}, 1, 'shows extra param forwarded';

# --- seasons ---

$video->seasons(100);
is $fake->last_call->{method}, 'get',                          'seasons uses GET';
is $fake->last_call->{path},   '/library/metadata/100/children','seasons path';

$video->seasons(100, includeExtras => 1);
is $fake->last_call->{params}{includeExtras}, 1, 'seasons forwards params';

# --- episodes ---

$video->episodes(200);
is $fake->last_call->{method}, 'get',                          'episodes uses GET';
is $fake->last_call->{path},   '/library/metadata/200/children','episodes path';

# --- all_episodes ---

$video->all_episodes(100);
is $fake->last_call->{method}, 'get',                            'all_episodes uses GET';
is $fake->last_call->{path},   '/library/metadata/100/allLeaves','all_episodes path';

$video->all_episodes(100, sort => 'originallyAvailableAt');
is $fake->last_call->{path}, '/library/metadata/100/allLeaves?sort=originallyAvailableAt', 'all_episodes path with params';
is $fake->last_call->{params}{sort}, 'originallyAvailableAt', 'all_episodes extra param';

# --- search ---

$video->search('Inception');
is $fake->last_call->{method},         'get',           'search uses GET';
is $fake->last_call->{path},           '/hubs/search?query=Inception',  'search path';
is $fake->last_call->{params}{query},  'Inception',     'search query param';

$video->search('Breaking Bad', mediatype => 'show');
is $fake->last_call->{path},           '/hubs/search?mediatype=show&query=Breaking%20Bad', 'search path with params';
is $fake->last_call->{params}{query},     'Breaking Bad', 'search with mediatype query';
is $fake->last_call->{params}{mediatype}, 'show',         'search mediatype param';

$video->search('Ozymandias', mediatype => 'episode');
is $fake->last_call->{params}{mediatype}, 'episode', 'search episode mediatype';

# --- analyze ---

$video->analyze(12345);
is $fake->last_call->{method}, 'put',                              'analyze uses PUT';
is $fake->last_call->{path},   '/library/metadata/12345/analyze',  'analyze path';

# --- optimize ---

$video->optimize(12345);
is $fake->last_call->{method}, 'put',                               'optimize uses PUT';
is $fake->last_call->{path},   '/library/metadata/12345/optimize',  'optimize path';

# --- subtitles ---

$video->search_subtitles(12345);
is $fake->last_call->{method}, 'get',                               'search_subtitles uses GET';
like $fake->last_call->{path}, qr{/library/metadata/12345/subtitles},'search_subtitles path';
is $fake->last_call->{params}{language},        'en', 'search_subtitles default language';
is $fake->last_call->{params}{hearingImpaired},  0,   'search_subtitles default hearingImpaired';
is $fake->last_call->{params}{forced},           0,   'search_subtitles default forced';

$video->search_subtitles(12345, language => 'fr', forced => 1);
is $fake->last_call->{params}{language}, 'fr', 'search_subtitles language param';
is $fake->last_call->{params}{forced},   1,    'search_subtitles forced param';

$video->download_subtitle(12345, '/library/streams/99');
is $fake->last_call->{method},       'put',                               'download_subtitle uses PUT';
like $fake->last_call->{path},       qr{/library/metadata/12345/subtitles},'download_subtitle path';
is $fake->last_call->{params}{key},  '/library/streams/99',               'download_subtitle key param';

$video->remove_subtitle('/library/streams/99/subtitle');
is $fake->last_call->{method}, 'delete',                       'remove_subtitle uses DELETE';
is $fake->last_call->{path},   '/library/streams/99/subtitle', 'remove_subtitle path';

done_testing;
