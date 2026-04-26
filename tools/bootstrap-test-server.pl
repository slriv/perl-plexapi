#!/usr/bin/env perl
# Bootstrap the Plex integration test server.
#
# Usage:
#   perl tools/bootstrap-test-server.pl
#
# Environment:
#   PLEX_TEST_BASEURL         default http://127.0.0.1:32400
#   PLEX_BOOTSTRAP_TIMEOUT    seconds to wait for server startup (default 120)
#
# The script is self-contained: it checks for Docker, docker compose, test
# media, and a running Plex container -- installing or starting anything that
# is missing before proceeding.  It is fully idempotent.

use v5.42;
use lib 'lib';

use WebService::Plex;
use HTTP::Request;
use JSON::XS ();
use LWP::UserAgent;
use URI;
use Time::HiRes qw(time sleep);
use Carp qw(croak);

my $BASEURL = $ENV{PLEX_TEST_BASEURL}      // 'http://127.0.0.1:32400';
my $TIMEOUT = $ENV{PLEX_BOOTSTRAP_TIMEOUT} // 120;

# ---------------------------------------------------------------------------
# --clean: stop container, remove volumes, wipe plex-test-data
# ---------------------------------------------------------------------------

if (@ARGV && $ARGV[0] eq '--clean') {
    say "==> Cleaning up test server...";
    system('docker', 'compose', 'down', '-v') == 0
        or warn "docker compose down failed (container may not have been running)\n";
    if (-d 'plex-test-data') {
        require File::Path;
        File::Path::remove_tree('plex-test-data');
        say "  removed plex-test-data/";
    }
    say "==> Clean complete. Re-run without --clean to bootstrap fresh.";
    exit 0;
}

# ---------------------------------------------------------------------------
# Preflight: Docker, docker compose, test media, running container
# ---------------------------------------------------------------------------

say "==> Preflight checks";
preflight();

# ---------------------------------------------------------------------------
# Wait for Plex to be ready
# ---------------------------------------------------------------------------

say "==> Waiting for Plex at $BASEURL (timeout ${TIMEOUT}s)...";
my $plex = wait_for_server($BASEURL, $TIMEOUT);
say "==> Server ready.";

# ---------------------------------------------------------------------------
# Idempotency check
# ---------------------------------------------------------------------------

my @existing = existing_sections($plex->library->sections);
if (@existing) {
    say "==> Already bootstrapped (" . scalar(@existing) . " section(s)):";
    say "      $_->{title} (key $_->{key})" for @existing;
    exit 0;
}

# ---------------------------------------------------------------------------
# Add library sections
# Plex expects POST /library/sections with all params in the query string.
# ---------------------------------------------------------------------------

say "==> Adding library sections...";

add_section($plex, {
    name     => 'Movies',
    type     => 'movie',
    agent    => 'tv.plex.agents.movie',
    scanner  => 'Plex Movie',
    language => 'en-US',
    location => '/data/Movies',
    expected => 4,
});

add_section($plex, {
    name     => 'TV Shows',
    type     => 'show',
    agent    => 'tv.plex.agents.series',
    scanner  => 'Plex TV Series',
    language => 'en-US',
    location => '/data/TV Shows',
    expected => 2,
});

add_section($plex, {
    name     => 'Music',
    type     => 'artist',
    agent    => 'tv.plex.agents.music',
    scanner  => 'Plex Music',
    language => 'en-US',
    location => '/data/Music',
    expected => 1,
});

say "==> Bootstrap complete.";
say "      PLEX_TEST_BASEURL=$BASEURL";
say "      (no token needed for an unclaimed server)";

# ---------------------------------------------------------------------------
# preflight
# ---------------------------------------------------------------------------

sub preflight {
    _check_docker();
    _check_compose();
    _check_media();
    _check_container();
}

sub _check_docker {
    _run_silent('docker', 'version')
        or croak "Docker is not installed or not running.\n"
               . "  Install: https://docs.docker.com/get-docker/";
    say "  docker:          ok";
}

sub _check_compose {
    unless (_run_silent('docker', 'compose', 'version')) {
        say "  docker compose:  not found -- attempting setup via Homebrew...";
        _install_compose_via_brew();
    }
    _run_silent('docker', 'compose', 'version')
        or croak "docker compose is not available.\n"
               . "  Install: https://docs.docker.com/compose/install/";
    say "  docker compose:  ok";
}

sub _install_compose_via_brew {
    _cmd_exists('brew')
        or croak "brew not found -- install docker compose manually:\n"
               . "  https://docs.docker.com/compose/install/";

    system('brew', 'install', 'docker-compose') == 0
        or croak "brew install docker-compose failed";

    # Wire the Homebrew binary as a Docker CLI plugin.
    my $plugin_dir = '/opt/homebrew/lib/docker/cli-plugins';
    if (-d $plugin_dir) {
        my $cfg_file = "$ENV{HOME}/.docker/config.json";
        my $cfg = -f $cfg_file
            ? do { open my $fh, '<', $cfg_file or croak "Cannot read $cfg_file: $!";
                   local $/; JSON::XS::decode_json(<$fh>) }
            : {};
        my $dirs = $cfg->{cliPluginsExtraDirs} //= [];
        unless (grep { $_ eq $plugin_dir } @$dirs) {
            push @$dirs, $plugin_dir;
            open my $fh, '>', $cfg_file or croak "Cannot write $cfg_file: $!";
            print $fh JSON::XS->new->pretty->encode($cfg);
            say "  configured Docker plugin path in ~/.docker/config.json";
        }
    }
}

sub _check_media {
    my $media = 'plex-test-data/media';
    if (-d "$media/Movies" && -d "$media/TV Shows" && -d "$media/Music") {
        say "  test media:      ok";
        return;
    }
    say "  test media:      missing -- running create-test-media.sh...";
    _cmd_exists('ffmpeg')
        or croak "ffmpeg not found -- install it first:\n"
               . "  brew install ffmpeg  /  apt install ffmpeg";
    system('bash', 'tools/create-test-media.sh') == 0
        or croak "create-test-media.sh failed";
    say "  test media:      created";
}

sub _check_container {
    my $id = qx(docker compose ps -q plex 2>/dev/null);
    chomp $id;
    if ($id) {
        say "  plex container:  running ($id)";
        return;
    }
    say "  plex container:  not running -- starting...";
    system('docker', 'compose', 'up', '-d') == 0
        or croak "docker compose up -d failed";
    say "  plex container:  started";
}

sub _run_silent { system("@_ >/dev/null 2>&1") == 0 }
sub _cmd_exists { system("which $_[0] >/dev/null 2>&1") == 0 }

# ---------------------------------------------------------------------------
# wait_for_server
# ---------------------------------------------------------------------------

sub wait_for_server {
    my ($baseurl, $timeout) = @_;
    my $ua       = LWP::UserAgent->new(timeout => 5);
    my $deadline = time() + $timeout;
    my $last_err = '';
    while (time() < $deadline) {
        # Probe /library/sections, not /identity: /identity responds before the
        # library manager is ready, causing 400s on the first add_section call.
        my $res = eval { $ua->get("$baseurl/library/sections",
                                  Accept => 'application/json') };
        if ($res && $res->is_success) {
            say '' if length $last_err;
            return WebService::Plex->new(baseurl => $baseurl);
        }
        my $err = $@ // '';
        $last_err = $err || ($res ? $res->status_line : 'no response');
        print ".";
        sleep 2;
    }
    say '';
    croak "Plex did not become ready within ${timeout}s at $baseurl\n"
        . "  Last error: $last_err";
}

# ---------------------------------------------------------------------------
# Library helpers
# ---------------------------------------------------------------------------

sub existing_sections {
    my ($data) = @_;
    my $dirs = $data->{MediaContainer}{Directory} // [];
    return ref $dirs eq 'ARRAY' ? @$dirs : ($dirs);
}

sub add_section {
    my ($plex, $spec) = @_;
    my $name = $spec->{name};

    my $ua = LWP::UserAgent->new(timeout => 30);
    $ua->default_header(Accept           => 'application/json');
    $ua->default_header('X-Plex-Product' => 'WebService::Plex');
    $ua->default_header('X-Plex-Version' => '0.01');

    my $uri = URI->new($plex->baseurl . '/library/sections');
    $uri->query_form(
        name     => $spec->{name},
        type     => $spec->{type},
        agent    => $spec->{agent},
        scanner  => $spec->{scanner},
        language => $spec->{language},
        location => $spec->{location},
    );

    # Retry while Plex reports it is still starting up (brief window after the
    # library manager first becomes reachable but before it accepts writes).
    my ($res, $deadline) = (undef, time() + 60);
    while (time() < $deadline) {
        $res = $ua->request(HTTP::Request->new(POST => "$uri"));
        last if $res->is_success;
        last unless ($res->decoded_content // '') =~ /still starting up/i;
        print ".";
        sleep 3;
    }
    unless ($res && $res->is_success) {
        croak "Failed to add section '$name': " . ($res ? $res->status_line : 'no response')
            . "\n  Body: " . ($res ? ($res->decoded_content // '') : '');
    }

    say "  Added '$name' -- waiting for scan...";
    poll_for_scan($plex, $name, $spec->{expected} // 0, $spec->{type});
}

sub poll_for_scan {
    my ($plex, $section_name, $expected_min, $type) = @_;
    my $deadline = time() + 120;
    my $key;

    while (time() < $deadline) {
        sleep 2;

        unless ($key) {
            my $data = eval { $plex->library->sections };
            next unless $data;
            for my $dir (existing_sections($data)) {
                $key = $dir->{key}, last if $dir->{title} eq $section_name;
            }
            next unless $key;
        }

        my $count_type = ($type eq 'movie') ? 1
                       : ($type eq 'show')   ? 2
                       : ($type eq 'artist') ? 8 : 1;

        my $items = eval { $plex->library->section_all($key, type => $count_type) };
        next unless $items;

        my $size = ($items->{MediaContainer} // {})->{size} // 0;
        print ".";
        if ($size >= $expected_min) {
            say " done ($size item(s)).";
            return;
        }
    }
    say " timed out (scan may still be in progress).";
}
