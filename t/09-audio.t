use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Audio;

my $fake  = FakePlex->new;
my $audio = WebService::Plex::Audio->new(plex => $fake);

# --- type constants ---

is WebService::Plex::Audio::TYPE_ARTIST, 8,  'TYPE_ARTIST = 8';
is WebService::Plex::Audio::TYPE_ALBUM,  9,  'TYPE_ALBUM = 9';
is WebService::Plex::Audio::TYPE_TRACK,  10, 'TYPE_TRACK = 10';

# --- artists ---

$audio->artists(3);
is $fake->last_call->{method},        'get',                    'artists uses GET';
is $fake->last_call->{path},          '/library/sections/3/all?type=8','artists path';
is $fake->last_call->{params}{type},  8,                        'artists type=8';

$audio->artists(3, sort => 'titleSort');
is $fake->last_call->{path},          '/library/sections/3/all?sort=titleSort&type=8', 'artists path with params';
is $fake->last_call->{params}{type}, 8,           'artists type still 8 with extra params';
is $fake->last_call->{params}{sort}, 'titleSort', 'artists extra param forwarded';

# --- albums ---

$audio->albums(3);
is $fake->last_call->{path},         '/library/sections/3/all?type=9', 'albums path';
is $fake->last_call->{params}{type}, 9,                         'albums type=9';

# --- albums_for ---

$audio->albums_for(500);
is $fake->last_call->{method}, 'get',                           'albums_for uses GET';
is $fake->last_call->{path},   '/library/metadata/500/children','albums_for path';

$audio->albums_for(500, sort => 'year');
is $fake->last_call->{path}, '/library/metadata/500/children?sort=year', 'albums_for path with params';
is $fake->last_call->{params}{sort}, 'year', 'albums_for extra param forwarded';

# --- tracks ---

$audio->tracks(600);
is $fake->last_call->{method}, 'get',                           'tracks uses GET';
is $fake->last_call->{path},   '/library/metadata/600/children','tracks path';

# --- all_tracks ---

$audio->all_tracks(500);
is $fake->last_call->{method}, 'get',                            'all_tracks uses GET';
is $fake->last_call->{path},   '/library/metadata/500/allLeaves','all_tracks path';

$audio->all_tracks(500, sort => 'titleSort');
is $fake->last_call->{path}, '/library/metadata/500/allLeaves?sort=titleSort', 'all_tracks path with params';
is $fake->last_call->{params}{sort}, 'titleSort', 'all_tracks extra param forwarded';

# --- search ---

$audio->search('Radiohead');
is $fake->last_call->{method},        'get',          'search uses GET';
is $fake->last_call->{path},          '/hubs/search?query=Radiohead', 'search path';
is $fake->last_call->{params}{query}, 'Radiohead',    'search query param';

$audio->search('OK Computer', mediatype => 'album');
is $fake->last_call->{path}, '/hubs/search?mediatype=album&query=OK%20Computer', 'search path with params';
is $fake->last_call->{params}{mediatype}, 'album', 'search mediatype param';

$audio->search('Creep', mediatype => 'track');
is $fake->last_call->{path}, '/hubs/search?mediatype=track&query=Creep', 'search path with params';
is $fake->last_call->{params}{mediatype}, 'track', 'search track mediatype';

# --- analyze ---

$audio->analyze(12345);
is $fake->last_call->{method}, 'put',                             'analyze uses PUT';
is $fake->last_call->{path},   '/library/metadata/12345/analyze', 'analyze path';

# --- sonically_similar ---

$audio->sonically_similar(12345);
is $fake->last_call->{method}, 'get',                              'sonically_similar uses GET';
is $fake->last_call->{path},   '/library/metadata/12345/nearest',  'sonically_similar path';

$audio->sonically_similar(12345, limit => 10, maxDistance => 0.3);
is $fake->last_call->{params}{limit},       10,  'sonically_similar limit param';
is $fake->last_call->{params}{maxDistance}, 0.3, 'sonically_similar maxDistance param';

# --- station ---

$audio->station(12345);
is $fake->last_call->{method}, 'get',                              'station uses GET';
is $fake->last_call->{path},   '/library/metadata/12345/station',  'station path';

# --- sonic_adventure ---

$audio->sonic_adventure(100, 200);
is $fake->last_call->{method},          'get',                 'sonic_adventure uses GET';
like $fake->last_call->{path},          qr{sonicAdventure},    'sonic_adventure path';
is $fake->last_call->{params}{fromKey}, 100,                   'sonic_adventure fromKey';
is $fake->last_call->{params}{toKey},   200,                   'sonic_adventure toKey';

done_testing;
