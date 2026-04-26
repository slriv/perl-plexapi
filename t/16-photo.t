use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Photo;

my $fake  = FakePlex->new;
my $photo = WebService::Plex::Photo->new(plex => $fake);

$photo->transcode(url => 'http://example.com/img.jpg', maxWidth => 400);
is $fake->last_call->{method}, 'get', 'transcode uses GET';
is $fake->last_call->{path}, '/photo/:/transcode?maxWidth=400&url=http%3A%2F%2Fexample.com%2Fimg.jpg', 'transcode path + params';

# --- section browsing ---

$photo->albums(4);
is $fake->last_call->{method},        'get',                        'albums uses GET';
is $fake->last_call->{path},          '/library/sections/4/all?type=13', 'albums path + type=13';
is $fake->last_call->{params}{type},  13,                           'albums type=13';

$photo->albums(4, sort => 'titleSort');
is $fake->last_call->{params}{sort}, 'titleSort', 'albums extra param forwarded';

$photo->album(500);
is $fake->last_call->{path}, '/library/metadata/500', 'album path';

$photo->photos(500);
is $fake->last_call->{method}, 'get',                            'photos uses GET';
is $fake->last_call->{path},   '/library/metadata/500/children', 'photos path';

$photo->clips(500);
is $fake->last_call->{path},           '/library/metadata/500/children?type=12', 'clips path + type=12';
is $fake->last_call->{params}{type},   12,                                        'clips type=12';

$photo->search(4, 'vacation');
is $fake->last_call->{path},           '/library/sections/4/search?query=vacation&type=13', 'search path';
is $fake->last_call->{params}{query},  'vacation',  'search query param';
is $fake->last_call->{params}{type},   13,          'search type=13';

$photo->recently_added(4);
is $fake->last_call->{path}, '/library/sections/4/recentlyAdded?type=14', 'recently_added path + type=14';

done_testing;
