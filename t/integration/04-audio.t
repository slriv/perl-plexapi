use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use PlexIntegration qw(plex_or_skip section_key items_in);

my $plex      = plex_or_skip();
my $music_key = section_key($plex, 'Music');

# --- artists ---

my $artists     = $plex->audio->artists($music_key);
my $artist_list = items_in($artists);
$artist_list = [$artist_list] unless ref $artist_list eq 'ARRAY';
ok scalar @$artist_list >= 1, 'artists() returns at least 1 artist';

my ($artist) = @$artist_list;
ok $artist->{title},     'artist has title';
ok $artist->{ratingKey}, 'artist has ratingKey';
is $artist->{type}, 'artist', 'artist type is "artist"';

# --- albums ---

my $albums     = $plex->audio->albums($music_key);
my $album_list = items_in($albums);
$album_list = [$album_list] unless ref $album_list eq 'ARRAY';
ok scalar @$album_list >= 1, 'albums() returns at least 1 album';

my ($album) = @$album_list;
ok $album->{title},     'album has title';
ok $album->{ratingKey}, 'album has ratingKey';
is $album->{type}, 'album', 'album type is "album"';

# --- albums_for artist ---

my $artist_albums = $plex->audio->albums_for($artist->{ratingKey});
my $aa_list       = items_in($artist_albums);
$aa_list = [$aa_list] unless ref $aa_list eq 'ARRAY';
ok scalar @$aa_list >= 1, 'albums_for() returns at least 1 album';

# --- tracks ---

my $tracks     = $plex->audio->tracks($album->{ratingKey});
my $track_list = items_in($tracks);
$track_list = [$track_list] unless ref $track_list eq 'ARRAY';
ok scalar @$track_list >= 1, 'tracks() returns at least 1 track';

my ($track) = @$track_list;
ok $track->{title},     'track has title';
ok $track->{ratingKey}, 'track has ratingKey';
is $track->{type}, 'track', 'track type is "track"';

# --- all_tracks ---

my $all     = $plex->audio->all_tracks($artist->{ratingKey});
my $all_list = items_in($all);
$all_list = [$all_list] unless ref $all_list eq 'ARRAY';
ok scalar @$all_list >= 1, 'all_tracks() returns at least 1 track';

# --- search ---

my $results = $plex->audio->search('Broke');
ok $results, 'audio search returns data';

done_testing;
