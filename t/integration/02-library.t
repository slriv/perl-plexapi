use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use PlexIntegration qw(plex_or_skip section_key items_in);

my $plex = plex_or_skip();

# --- sections ---

my $data     = $plex->library->sections;
my $mc       = $data->{MediaContainer};
ok $mc, 'sections returns MediaContainer';

my $dirs = $mc->{Directory} // [];
$dirs = [$dirs] unless ref $dirs eq 'ARRAY';
ok scalar @$dirs >= 3, 'at least 3 library sections (Movies, TV Shows, Music)';

my %by_title = map { $_->{title} => $_ } @$dirs;
ok $by_title{Movies},    'Movies section exists';
ok $by_title{'TV Shows'}, 'TV Shows section exists';
ok $by_title{Music},     'Music section exists';

my $movies_key = $by_title{Movies}{key};
ok $movies_key, 'Movies section has a key';

# --- section detail ---

my $section = $plex->library->section($movies_key);
is $section->{MediaContainer}{Directory}[0]{title} // $section->{MediaContainer}{title},
   'Movies', 'section returns correct title';

# --- section_all: movies ---

my $movies = $plex->library->section_all($movies_key, type => 1);
my $items  = items_in($movies);
$items = [$items] unless ref $items eq 'ARRAY';
ok scalar @$items >= 1, 'Movies section has at least 1 movie after bootstrap';

my ($first) = @$items;
ok $first->{title},     'movie has title';
ok $first->{year},      'movie has year';
ok $first->{ratingKey}, 'movie has ratingKey';

# --- metadata ---

my $rating_key = $first->{ratingKey};
my $meta = $plex->library->metadata($rating_key);
ok $meta->{MediaContainer}, 'metadata returns MediaContainer';

# --- recently_added ---

my $recent = $plex->library->recently_added;
ok $recent->{MediaContainer}, 'recently_added returns MediaContainer';

# --- search ---

my $results = $plex->library->search('Big Buck');
ok $results, 'search returns data';

# --- mark_played / mark_unplayed round-trip ---

$plex->library->mark_played($rating_key);
pass 'mark_played did not throw';

$plex->library->mark_unplayed($rating_key);
pass 'mark_unplayed did not throw';

done_testing;
