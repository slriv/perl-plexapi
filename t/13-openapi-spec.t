use v5.42;
use Test::More;
use HTTP::Tiny;
use JSON::XS;
use File::Spec;
use Cwd qw(abs_path);

# This test is intended to validate a Plex OpenAPI spec rather than the
# current client implementation. It attempts to fetch a runtime spec URL
# if provided, but falls back to a local `blib/openapi.json` fixture when
# available in the repo working tree.
my $url = $ENV{OPENAPI_JSON_URL} || $ENV{PLEX_OPENAPI_URL} || $ENV{OPENAPI_URL};
my $local_spec = File::Spec->catfile('blib', 'openapi.json');
my $local_path = -e $local_spec ? abs_path($local_spec) : undef;
plan skip_all => 'Set OPENAPI_JSON_URL or provide blib/openapi.json to run OpenAPI spec validation tests' unless $url || $local_path;

my ($content, $source);
if ($url) {
    my $http = HTTP::Tiny->new(agent => 'perl-plexapi OpenAPI validation test', timeout => 30);
    my $response = $http->get($url);

    ok($response->{success}, "fetched OpenAPI JSON from $url");
    if ($response->{success}) {
        $content = $response->{content};
        $source = $url;
    }
}
elsif ($local_path) {
    ok(1, "using local OpenAPI JSON fixture at $local_path");
    open my $fh, '<', $local_path or die "Unable to open $local_path: $!";
    local $/;
    $content = <$fh>;
    close $fh;
    $source = $local_path;
}

note "spec source: $source" if $source;

if ($content) {
    my $spec;
    eval { $spec = JSON::XS->new->decode($content); };
    ok(!$@, 'decoded JSON successfully');
    if (!$@) {
        ok(ref $spec eq 'HASH', 'root spec is an object');
        ok($spec->{openapi}, 'OpenAPI field exists');
        like($spec->{openapi}, qr/^3\.\d+\.\d+$/, 'OpenAPI version is 3.x');

        ok(ref $spec->{info} eq 'HASH', 'info object exists');
        ok($spec->{info}{title}, 'info.title exists');
        ok($spec->{info}{version}, 'info.version exists');

        ok(ref $spec->{paths} eq 'HASH', 'paths object exists');
        ok(keys %{ $spec->{paths} } > 0, 'paths contain at least one endpoint');

        ok(ref $spec->{components} eq 'HASH', 'components object exists');
        ok(ref $spec->{components}{schemas} eq 'HASH', 'components.schemas exists');
        ok(keys %{ $spec->{components}{schemas} } > 0, 'components.schemas contain definitions');

        ok(ref $spec->{servers} eq 'ARRAY', 'servers array exists');
        ok(@{ $spec->{servers} } > 0, 'servers array contains at least one entry');
        ok(ref $spec->{components}{securitySchemes} eq 'HASH', 'components.securitySchemes exists');

        my @methods = qw(get post put delete patch options head trace);
        my $tested = 0;
        for my $path (sort keys %{ $spec->{paths} }) {
            last if $tested++ >= 10;
            ok(ref $spec->{paths}{$path} eq 'HASH', "path $path is an object");

            my @ops = grep { exists $spec->{paths}{$path}{$_} } @methods;
            ok(@ops > 0, "path $path has at least one operation");
            for my $op (@ops) {
                ok(ref $spec->{paths}{$path}{$op}{responses} eq 'HASH', "$path $op has responses");
            }
        }

        # TODO: Add a dedicated OpenAPI schema validator (JSON::Validator or similar)
        # TODO: Replace local fixture fallback with a stable Plex docs/OpenAPI endpoint for CI
        # TODO: Add contract coverage tests that map library module methods to specific paths
    }
}

done_testing;
