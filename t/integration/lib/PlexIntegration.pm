package PlexIntegration;
# Shared helpers for WebService::Plex integration tests.
#
# Tests skip automatically when PLEX_TEST_BASEURL is unreachable, so
# the suite is safe to run in any environment -- only meaningful when
# the Docker test server is up.

use v5.42;
use experimental 'class';

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use WebService::Plex;
use LWP::UserAgent;
use Test::More ();
use Exporter 'import';

our @EXPORT_OK = qw(plex_or_skip section_key items_in);

my $BASEURL = $ENV{PLEX_TEST_BASEURL} // 'http://127.0.0.1:32400';
my $TOKEN   = $ENV{PLEX_TEST_TOKEN}   // '';

my $_plex;

sub plex_or_skip {
    my ($test_count) = @_;

    unless (_server_reachable()) {
        my $msg = "Plex test server not available at $BASEURL "
                . "(run: docker compose up -d && perl tools/bootstrap-test-server.pl)";
        if (defined $test_count) {
            Test::More::plan(skip_all => $msg);
        } else {
            Test::More::plan(skip_all => $msg);
        }
    }

    $_plex //= WebService::Plex->new(baseurl => $BASEURL, token => $TOKEN);
    return $_plex;
}

# Return the numeric key for a library section by title. Dies if not found.
sub section_key {
    my ($plex, $title) = @_;
    my $data = $plex->library->sections;
    my $dirs = $data->{MediaContainer}{Directory} // [];
    $dirs = [$dirs] unless ref $dirs eq 'ARRAY';
    for my $dir (@$dirs) {
        return $dir->{key} if $dir->{title} eq $title;
    }
    Test::More::BAIL_OUT("Library section '$title' not found -- did bootstrap run?");
}

# Return the arrayref of items from a MediaContainer response,
# trying common element names in order.
sub items_in {
    my ($data) = @_;
    my $mc = $data->{MediaContainer} // {};
    for my $key (qw(Video Directory Track Album Artist Metadata)) {
        return $mc->{$key} if exists $mc->{$key};
    }
    return [];
}

sub _server_reachable {
    my $ua  = LWP::UserAgent->new(timeout => 5);
    my $res = eval { $ua->get("$BASEURL/identity") };
    return $res && $res->is_success;
}

1;
