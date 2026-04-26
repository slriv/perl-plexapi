use v5.42;
use Test::More;
use File::Spec;
use Cwd qw(abs_path cwd);
use YAML::XS ();
use HTTP::Tiny;

# Load the Plex OpenAPI spec.  Resolution order:
#   1. OPENAPI_JSON_URL / OPENAPI_YAML_URL env var (remote fetch)
#   2. ../plex-api-spec/plex-api-spec.yaml  (sibling repo on disk)
#   3. blib/openapi.json or blib/openapi.yaml (local fixture)

my $spec = _load_spec();
BAIL_OUT "Could not load Plex OpenAPI spec -- place plex-api-spec repo alongside this one"
    unless $spec;

# ---------------------------------------------------------------------------
# Spec structure
# ---------------------------------------------------------------------------

ok ref $spec eq 'HASH',           'spec root is a hash';
ok $spec->{openapi},              'openapi version field present';
like $spec->{openapi}, qr/^3\.\d+\.\d+$/, 'openapi version is 3.x';

ok ref $spec->{info} eq 'HASH',   'info object present';
ok $spec->{info}{title},          'info.title present';
ok $spec->{info}{version},        'info.version present';

ok ref $spec->{paths} eq 'HASH',  'paths object present';
my $path_count = scalar keys %{ $spec->{paths} };
ok $path_count > 50, "spec has >50 paths (got $path_count)";

ok ref $spec->{components} eq 'HASH',             'components present';
ok ref $spec->{components}{schemas} eq 'HASH',    'components.schemas present';
ok keys %{ $spec->{components}{schemas} } > 0,    'components.schemas non-empty';
ok ref $spec->{servers} eq 'ARRAY',               'servers array present';
ok @{ $spec->{servers} } > 0,                     'at least one server entry';

# ---------------------------------------------------------------------------
# Contract: our module methods map to documented spec paths
#
# Authority note: plex-api-spec is community-maintained and incomplete.
# Methods using undocumented endpoints (e.g. /:/progress, /:/timeline)
# are explicitly noted as UNDOCUMENTED below.
# ---------------------------------------------------------------------------

my %paths = %{ $spec->{paths} };

my @contract = (
    # [ method, spec_path, description ]
    # Spec path must match exactly what appears in plex-api-spec.yaml.

    # Server -- documented
    [ 'get',    '/identity',                                         'Server::identity' ],
    [ 'get',    '/',                                                 'Server::capabilities' ],
    [ 'get',    '/:/prefs',                                          'Server::preferences' ],
    [ 'get',    '/activities',                                       'Server::activities' ],
    [ 'get',    '/status/sessions',                                  'Server::sessions' ],
    [ 'get',    '/status/sessions/background',                       'Server::background_tasks' ],
    [ 'get',    '/hubs',                                             'Server::hubs' ],
    [ 'get',    '/hubs/promoted',                                    'Server::promoted_hubs' ],
    [ 'get',    '/hubs/search',                                      'Server::hub_search' ],
    [ 'get',    '/status/sessions/history/all',                      'Server::history' ],
    [ 'delete', '/status/sessions/history/{historyId}',              'Server::delete_history' ],
    [ 'get',    '/butler',                                           'Server::scheduled_tasks' ],
    [ 'post',   '/butler/{butlerTask}',                              'Server::run_task' ],
    [ 'delete', '/butler/{butlerTask}',                              'Server::stop_task' ],
    [ 'get',    '/updater/status',                                   'Server::update_status' ],
    [ 'put',    '/updater/apply',                                    'Server::apply_updates' ],

    # Library -- documented
    [ 'get',    '/library/sections/all',                             'Library::sections (spec uses /all suffix)' ],
    [ 'get',    '/hubs/continueWatching',                            'Library::continue_watching' ],
    [ 'get',    '/hubs/sections/{sectionId}',                        'Library::section_hubs' ],
    [ 'get',    '/hubs/metadata/{metadataId}',                       'Library::metadata_hubs' ],
    [ 'get',    '/hubs/metadata/{metadataId}/related',               'Library::related_hubs' ],
    [ 'get',    '/library/sections/{sectionId}/firstCharacters',     'Library::first_character' ],
    [ 'get',    '/library/tags',                                     'Library::tags' ],
    [ 'put',    '/library/optimize',                                 'Library::optimize' ],

    # Playlist -- documented
    [ 'get',    '/playlists',                                        'Playlist::all' ],
    [ 'post',   '/playlists',                                        'Playlist::create' ],
    [ 'get',    '/playlists/{playlistId}/items',                     'Playlist::items' ],
    [ 'put',    '/playlists/{playlistId}/items',                     'Playlist::add_items' ],
    [ 'delete', '/playlists/{playlistId}/items',                     'Playlist::clear' ],
    [ 'put',    '/playlists/{playlistId}/items/{playlistItemId}/move', 'Playlist::move_item' ],

    # Collection -- documented
    [ 'put',    '/library/collections/{collectionId}/items/{itemId}/move', 'Collection::move_item' ],

    # Photo -- documented
    [ 'get',    '/photo/:/transcode',                                'Photo::transcode' ],

    # PlayQueue -- documented
    [ 'post',   '/playQueues',                                       'PlayQueue::create' ],

    # Video / Audio -- documented
    [ 'get',    '/library/sections/{sectionId}/all',                 'Video::movies/shows Audio::artists/albums' ],
    [ 'put',    '/library/metadata/{ids}/analyze',                   'Video::analyze Audio::analyze' ],
);

my @undocumented = (
    # These endpoints work on the live server but are absent from plex-api-spec.
    # python-plexapi is the authority for these.
    'Server::check_for_updates  => PUT /updater/check  (spec says PUT; our impl uses GET per python-plexapi)',
    'Server::transcode_sessions => GET /transcode/sessions  (not in spec)',
    'Server::clients            => GET /clients  (not in spec)',
    'Server::devices            => GET /devices  (not in spec)',
    'Server::agents             => GET /system/agents  (not in spec)',
    'Library::recently_added    => GET /library/recentlyAdded  (not in spec)',
    'Library::on_deck           => GET /library/onDeck  (not in spec)',
    'Library::mark_played       => GET /:/scrobble  (spec says PUT; python-plexapi uses GET)',
    'Library::mark_unplayed     => GET /:/unscrobble  (spec says PUT; python-plexapi uses GET)',
    'Library::update_progress   => GET /:/progress  (not in spec; python-plexapi authority)',
    'Library::clean_bundles     => PUT /library/clean/bundles  (not in spec)',
    'Library::postplay_hubs     => GET /hubs/metadata/{id}/postplay  (not in spec)',
    'Library::history           => GET /status/sessions/history/all  (confirmed works; spec also has it)',
);

note "Undocumented endpoints in use (python-plexapi authority):";
note "  - $_" for @undocumented;

my $pass = 0;
my $fail = 0;
for my $c (@contract) {
    my ($method, $path, $desc) = @$c;

    # Find the path in the spec -- exact match or match after stripping {param}
    my $found = exists $paths{$path};
    unless ($found) {
        # Try matching path templates with our path template
        for my $sp (keys %paths) {
            if ($sp eq $path) { $found = 1; last }
        }
    }

    if ($found) {
        my $op_exists = exists $paths{$path}{$method};
        if (ok $op_exists, "$desc: $method $path in spec") {
            $pass++;
        } else {
            $fail++;
        }
    } else {
        ok 0, "$desc: path $path missing from spec";
        $fail++;
    }
}

note "$pass contract checks passed, $fail failed";
note "Spec has $path_count documented paths";

done_testing;

# ---------------------------------------------------------------------------

sub _load_spec {
    # 1. Remote URL
    for my $env (qw(OPENAPI_YAML_URL OPENAPI_JSON_URL PLEX_OPENAPI_URL)) {
        next unless $ENV{$env};
        my $res = HTTP::Tiny->new(timeout => 30)->get($ENV{$env});
        return _parse($res->{content}, $ENV{$env}) if $res->{success};
    }

    # 2. Sibling plex-api-spec repo (../plex-api-spec relative to project root)
    my $project_root = abs_path(File::Spec->catdir(cwd(), File::Spec->updir));
    for my $candidate (
        File::Spec->catfile($project_root, 'plex-api-spec', 'plex-api-spec.yaml'),
        File::Spec->catfile($project_root, 'plex-api-spec', 'plex-api-spec.json'),
    ) {
        next unless -f $candidate;
        note "loading spec from $candidate";
        open my $fh, '<', $candidate or next;
        local $/;
        return _parse(<$fh>, $candidate);
    }

    # 3. Local fixture
    for my $fixture (qw(blib/openapi.yaml blib/openapi.json)) {
        next unless -f $fixture;
        open my $fh, '<', $fixture or next;
        local $/;
        return _parse(<$fh>, $fixture);
    }

    return undef;
}

sub _parse {
    my ($content, $source) = @_;
    return undef unless $content;
    if ($source =~ /\.ya?ml$/i) {
        local $YAML::XS::Boolean = 'JSON::PP';
        my $data = eval { YAML::XS::Load($content) };
        return $@ ? undef : $data;
    }
    return eval { JSON::XS->new->decode($content) };
}
