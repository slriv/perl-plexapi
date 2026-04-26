use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Library {
    field $plex :param;

    # ----------------------------------------------------------- sections

    method sections { $plex->get('/library/sections') }

    method section ($key) { $plex->get("/library/sections/$key") }

    method section_all ($key, %params) {
        $plex->get("/library/sections/$key/all", %params);
    }

    method section_search ($key, $query, %params) {
        $plex->get("/library/sections/$key/search", query => $query, %params);
    }

    # ----------------------------------------------------------- discovery

    method recently_added { $plex->get('/library/recentlyAdded') }
    method on_deck        { $plex->get('/library/onDeck') }

    method search ($query, %params) {
        $plex->get('/hubs/search', query => $query, %params);
    }

    method continue_watching { $plex->get('/hubs/continueWatching/items') }

    # ----------------------------------------------------------- hubs

    method hubs (%params)             { $plex->get('/hubs', %params) }
    method section_hubs ($key, %params) {
        $plex->get("/hubs/sections/$key", %params);
    }
    method metadata_hubs ($rating_key, %params) {
        $plex->get("/hubs/metadata/$rating_key", %params);
    }
    method related_hubs ($rating_key, %params) {
        $plex->get("/hubs/metadata/$rating_key/related", %params);
    }
    method postplay_hubs ($rating_key, %params) {
        $plex->get("/hubs/metadata/$rating_key}/postplay", %params);
    }

    # ----------------------------------------------------------- metadata

    method metadata ($rating_key) {
        $plex->get("/library/metadata/$rating_key");
    }

    method metadata_children ($rating_key) {
        $plex->get("/library/metadata/$rating_key/children");
    }

    method metadata_related ($rating_key) {
        $plex->get("/library/metadata/$rating_key/related");
    }

    # ----------------------------------------------------------- sections / first char / tags

    method first_character ($key) {
        $plex->get("/library/sections/$key/firstCharacters");
    }

    method tags ($type) {
        $plex->get('/library/tags', type => $type);
    }

    # ----------------------------------------------------------- history

    method history (%params) {
        $params{sort} //= 'viewedAt:desc';
        $plex->get('/status/sessions/history/all', %params);
    }

    # ----------------------------------------------------------- maintenance

    method refresh_section ($key) {
        $plex->get("/library/sections/$key/refresh");
    }

    method refresh_metadata ($rating_key) {
        $plex->put("/library/metadata/$rating_key/refresh");
    }

    method empty_trash ($key) {
        $plex->put("/library/sections/$key/emptyTrash");
    }

    method clean_bundles {
        $plex->put('/library/clean/bundles');
    }

    method optimize {
        $plex->put('/library/optimize');
    }

    # ----------------------------------------------------------- playback state
    # Note: these operate on any library item by rating key. Final home may be
    # on typed Video/Audio objects once those are introduced (see python-plexapi
    # PlayedUnplayedMixin / Playable). Current placement is intentional for v0.01.

    method mark_played ($rating_key) {
        $plex->get('/:/scrobble',
            key        => $rating_key,
            identifier => 'com.plexapp.plugins.library',
        );
    }

    method mark_unplayed ($rating_key) {
        $plex->get('/:/unscrobble',
            key        => $rating_key,
            identifier => 'com.plexapp.plugins.library',
        );
    }

    method update_progress ($rating_key, $time_ms, $state = 'stopped') {
        $plex->get('/:/progress',
            key        => $rating_key,
            time       => $time_ms,
            state      => $state,
            identifier => 'com.plexapp.plugins.library',
        );
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Library - Library sections, metadata, search, and playback state

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $lib = $plex->library;

  my $sections = $lib->sections;
  my $movies   = $lib->section_all(1, type => 1);
  my $item     = $lib->metadata(12345);
  my $hubs     = $lib->section_hubs(1);
  my $chars    = $lib->first_character(1);
  my $hist     = $lib->history(accountID => 1);

  $lib->mark_played(12345);
  $lib->clean_bundles;
  $lib->optimize;

=head1 DESCRIPTION

C<WebService::Plex::Library> provides access to library sections, item
metadata, hubs, history, cross-library search, maintenance operations,
and playback state tracking.

Obtain an instance through the C<library> accessor on a L<WebService::Plex>
object -- do not instantiate directly.

=head1 METHODS

=head2 Sections

=head3 sections

Returns all library sections (C<GET /library/sections>).

=head3 section($key)

Returns a single section by key.

=head3 section_all($key, %params)

Returns all items in the section.  C<%params> forwarded as query parameters
(e.g. C<type>, C<sort>).

=head3 section_search($key, $query, %params)

Searches within a section.

=head3 first_character($key)

Returns the first-character index for a section
(C<GET /library/sections/$key/firstCharacters>).

=head3 tags($type)

Returns available tag values for a given type code
(C<GET /library/tags?type=$type>).

=head2 Discovery

=head3 recently_added

Returns recently added items (C<GET /library/recentlyAdded>).

=head3 on_deck

Returns the On Deck list (C<GET /library/onDeck>).

=head3 search($query, %params)

Cross-library hub search (C<GET /hubs/search>).

=head3 continue_watching

Returns items from the Continue Watching hub
(C<GET /hubs/continueWatching/items>).

=head2 Hubs

=head3 hubs(%params)

Returns all home screen hubs (C<GET /hubs>).

=head3 section_hubs($key, %params)

Returns hubs for a specific library section
(C<GET /hubs/sections/$key>).

=head3 metadata_hubs($rating_key, %params)

Returns hubs related to a metadata item
(C<GET /hubs/metadata/$rating_key>).

=head3 related_hubs($rating_key, %params)

Returns related-content hubs for a metadata item
(C<GET /hubs/metadata/$rating_key/related>).

=head3 postplay_hubs($rating_key, %params)

Returns post-play hubs for a metadata item
(C<GET /hubs/metadata/$rating_key/postplay>).

=head2 Metadata

=head3 metadata($rating_key)

Returns metadata for a single item.

=head3 metadata_children($rating_key)

Returns direct children of an item (episodes, tracks, etc.).

=head3 metadata_related($rating_key)

Returns related items for a metadata item.

=head2 History

=head3 history(%params)

Returns watched history (C<GET /status/sessions/history/all>).
Defaults to C<sort =E<gt> 'viewedAt:desc'>.  Accepts optional
C<accountID>, C<metadataItemID>, C<librarySectionID> filters.

=head2 Maintenance

=head3 refresh_section($key)

Triggers a metadata refresh for a section.

=head3 refresh_metadata($rating_key)

Triggers a metadata refresh for a single item.

=head3 empty_trash($key)

Empties the trash for a section.

=head3 clean_bundles

Cleans up orphaned metadata bundles (C<PUT /library/clean/bundles>).

=head3 optimize

Optimizes the media database (C<PUT /library/optimize>).

=head2 Playback State

=head3 mark_played($rating_key)

Marks an item as played.

=head3 mark_unplayed($rating_key)

Marks an item as unplayed.

=head3 update_progress($rating_key, $time_ms, $state)

Updates the playback position to C<$time_ms> milliseconds.
C<$state> defaults to C<'stopped'>.

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<WebService::Plex::Server>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
