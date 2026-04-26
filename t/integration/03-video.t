use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use PlexIntegration qw(plex_or_skip section_key items_in);

my $plex       = plex_or_skip();
my $movies_key = section_key($plex, 'Movies');
my $shows_key  = section_key($plex, 'TV Shows');

# --- movies ---

my $movies = $plex->video->movies($movies_key);
my $items  = items_in($movies);
$items = [$items] unless ref $items eq 'ARRAY';
ok scalar @$items >= 1, 'movies() returns at least 1 item';

my ($movie) = @$items;
ok $movie->{title},     'movie has title';
ok $movie->{year},      'movie has year';
ok $movie->{ratingKey}, 'movie has ratingKey';
is $movie->{type}, 'movie', 'movie type is "movie"';

# --- shows ---

my $shows     = $plex->video->shows($shows_key);
my $show_list = items_in($shows);
$show_list = [$show_list] unless ref $show_list eq 'ARRAY';
ok scalar @$show_list >= 1, 'shows() returns at least 1 show';

my ($show) = @$show_list;
ok $show->{title},     'show has title';
ok $show->{ratingKey}, 'show has ratingKey';
is $show->{type}, 'show', 'show type is "show"';

# --- seasons ---

my $seasons     = $plex->video->seasons($show->{ratingKey});
my $season_list = items_in($seasons);
$season_list = [$season_list] unless ref $season_list eq 'ARRAY';
ok scalar @$season_list >= 1, 'seasons() returns at least 1 season';

my ($season) = @$season_list;
ok $season->{ratingKey}, 'season has ratingKey';
is $season->{type}, 'season', 'season type is "season"';

# --- episodes ---

my $eps     = $plex->video->episodes($season->{ratingKey});
my $ep_list = items_in($eps);
$ep_list = [$ep_list] unless ref $ep_list eq 'ARRAY';
ok scalar @$ep_list >= 1, 'episodes() returns at least 1 episode';

my ($ep) = @$ep_list;
ok $ep->{title},           'episode has title';
is $ep->{type}, 'episode', 'episode type is "episode"';

# --- all_episodes ---

my $all_eps = $plex->video->all_episodes($show->{ratingKey});
my $all_list = items_in($all_eps);
$all_list = [$all_list] unless ref $all_list eq 'ARRAY';
ok scalar @$all_list >= scalar @$ep_list, 'all_episodes() >= episodes in first season';

# --- search ---

my $results = $plex->video->search('Big Buck');
ok $results, 'video search returns data';

done_testing;
