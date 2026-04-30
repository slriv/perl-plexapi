#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP;
use Getopt::Long;
use WebService::Plex;
use File::Basename;
use Cwd qw(abs_path);

my $endpoint;
my $params_json = '{}';
my $baseurl;
my $token;
my $timeout = 30;
my $help;

GetOptions(
    'endpoint=s' => \$endpoint,
    'params=s'   => \$params_json,
    'baseurl=s'  => \$baseurl,
    'token=s'    => \$token,
    'timeout=i'  => \$timeout,
    'help'       => \$help,
) or exit 1;

if ($help || !$endpoint || !$baseurl) {
    print <<'USAGE';
Usage: compare-perl-api.pl --endpoint <name> --baseurl <url> [--token <token>] [--params '{"foo":1}']

Options:
  --endpoint   Endpoint inventory name, e.g. server.sessions
  --baseurl    Plex base URL
  --token      Plex auth token
  --params     JSON string of request parameters
  --timeout    HTTP timeout in seconds
  --help       Show this message
USAGE
    exit 0;
}

my $params;
{
    local $@;
    $params = eval { JSON::PP->new->decode($params_json) };
    if ($@) {
        die "Invalid JSON for params: $@";
    }
}

my $plex = WebService::Plex->new(
    baseurl => $baseurl,
    token   => $token // '',
    timeout => $timeout,
);

my $result = run_endpoint($plex, $endpoint, $params);
print JSON::PP->new->canonical->encode({ endpoint => $endpoint, params => $params, result => $result });

sub simplify_item {
    my ($item) = @_;
    return {} unless ref $item eq 'HASH';
    my %simplified;
    for my $key (keys %$item) {
        my $value = $item->{$key};
        next if ref $value;
        $simplified{$key} = $value;
    }
    return \%simplified;
}

sub simplify_items {
    my ($items) = @_;
    return [] unless ref $items eq 'ARRAY';
    return [ map { simplify_item($_) } @$items ];
}

sub run_endpoint {
    my ($plex, $name, $params) = @_;
    if ($name eq 'server.sessions') {
        my $result = $plex->server->sessions(%$params);
        return simplify_items($result->{MediaContainer}{Video} // []);
    }
    if ($name eq 'library.sections') {
        my $sections = $plex->library->sections(%$params);
        return $sections->{MediaContainer}{Directory} // [];
    }
    if ($name eq 'video.movies') {
        my $result = $plex->video->movies($params->{section_id});
        return simplify_items($result->{MediaContainer}{Metadata} // []);
    }
    if ($name eq 'audio.albums') {
        my $result = $plex->audio->albums($params->{section_id});
        return simplify_items($result->{MediaContainer}{Metadata} // []);
    }
    die "Unsupported endpoint: $name";
}
