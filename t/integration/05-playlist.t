use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use PlexIntegration qw(plex_or_skip section_key items_in);

my $plex       = plex_or_skip();
my $movies_key = section_key($plex, 'Movies');

# --- setup: pick a movie to add ---

my $movies = $plex->video->movies($movies_key);
my $items  = items_in($movies);
$items = [$items] unless ref $items eq 'ARRAY';

if (!@$items) {
    Test::More::plan(skip_all => 'No movies found -- bootstrap may not have scanned yet');
}

my $movie      = $items->[0];
my $rating_key = $movie->{ratingKey};

# Build the server URI needed to add items to a playlist.
# Plex expects: server://<machineId>/com.plexapp.plugins.library/library/metadata/<key>
my $identity = $plex->server->identity;
my $machine_id = $identity->{MediaContainer}{machineIdentifier};
my $item_uri = "server://$machine_id/com.plexapp.plugins.library/library/metadata/$rating_key";

# --- all (baseline: may be empty) ---

my $all = $plex->playlist->all(playlistType => 'video');
ok $all, 'playlist->all returns data';

# --- create ---

my $created = $plex->playlist->create(
    title => 'Integration Test Playlist',
    type  => 'video',
    smart => 0,
    uri   => $item_uri,
);
ok $created, 'create returns data';

# Plex returns the new playlist in the response
my $pl_data = $created->{MediaContainer}{Metadata};
$pl_data = ref $pl_data eq 'ARRAY' ? $pl_data->[0] : $pl_data;
my $pl_id = $pl_data->{ratingKey};
ok $pl_id, "new playlist has ratingKey ($pl_id)";

# --- get ---

my $got = $plex->playlist->get($pl_id);
is $got->{MediaContainer}{Metadata}[0]{title} // $got->{MediaContainer}{Metadata}{title},
   'Integration Test Playlist', 'get returns correct title';

# --- items ---

my $pl_items = $plex->playlist->items($pl_id);
my $pl_item_list = items_in($pl_items);
$pl_item_list = [$pl_item_list] unless ref $pl_item_list eq 'ARRAY';
ok scalar @$pl_item_list >= 1, 'playlist has at least 1 item after creation';

# --- update ---

$plex->playlist->update($pl_id, title => 'Integration Test Playlist (Renamed)');
my $updated = $plex->playlist->get($pl_id);
my $new_title = $updated->{MediaContainer}{Metadata}[0]{title}
             // $updated->{MediaContainer}{Metadata}{title};
is $new_title, 'Integration Test Playlist (Renamed)', 'update changes title';

# --- remove_item ---

my $pl_item_id = $pl_item_list->[0]{playlistItemID};
ok $pl_item_id, 'playlist item has playlistItemID field';

$plex->playlist->remove_item($pl_id, $pl_item_id);
my $after = $plex->playlist->items($pl_id);
my $after_list = items_in($after);
$after_list = [$after_list] unless ref $after_list eq 'ARRAY';
ok scalar @$after_list < scalar @$pl_item_list, 'remove_item reduces item count';

# --- delete ---

$plex->playlist->delete($pl_id);

# Confirm gone: get should 404 (croak) or return empty MediaContainer
my $gone = eval { $plex->playlist->get($pl_id) };
ok $@ || !$gone->{MediaContainer}{Metadata}, 'playlist gone after delete';

done_testing;
