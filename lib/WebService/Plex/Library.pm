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

    # ----------------------------------------------------------- metadata

    method metadata ($rating_key) {
        $plex->get("/library/metadata/$rating_key");
    }

    method metadata_children ($rating_key) {
        $plex->get("/library/metadata/$rating_key/children");
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

    # ----------------------------------------------------------- playback state
    # TODO: may move to WebService::Plex::Video / WebService::Plex::Audio
    #       once typed media objects are introduced

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
        $plex->get('/:/timeline',
            ratingKey  => $rating_key,
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

  # Browse sections
  my $sections = $lib->sections;
  my $movies   = $lib->section_all(1, type => 1);

  # Metadata
  my $item     = $lib->metadata(12345);
  my $episodes = $lib->metadata_children(12345);

  # Search
  my $results  = $lib->search('Inception');

  # Playback state
  $lib->mark_played(12345);
  $lib->update_progress(12345, 60_000, 'playing');

=head1 DESCRIPTION

C<WebService::Plex::Library> provides access to library sections, item
metadata, cross-library search, library maintenance operations, and playback
state tracking.

Do not instantiate this class directly.  Obtain an instance through the
C<library> accessor on a L<WebService::Plex> object:

  my $lib = $plex->library;

The accessor is lazily instantiated on first call and cached for the lifetime
of the parent connection.

=head1 METHODS

=head2 Sections

=head3 sections

Returns all configured library sections (C</library/sections>).

=head3 section($key)

Returns the section metadata for the library identified by C<$key>.

=head3 section_all($key, %params)

Returns all items in the library section identified by C<$key>.  Optional
C<%params> are forwarded as query parameters (e.g. C<type>, C<sort>).

=head3 section_search($key, $query, %params)

Searches within a library section for C<$query>.  Additional C<%params> are
forwarded as query parameters.

=head2 Discovery

=head3 recently_added

Returns recently added items across all libraries
(C</library/recentlyAdded>).

=head3 on_deck

Returns the On Deck list (C</library/onDeck>).

=head3 search($query, %params)

Cross-library hub search (C</hubs/search>).

=head2 Metadata

=head3 metadata($rating_key)

Returns metadata for a single item identified by its rating key.

=head3 metadata_children($rating_key)

Returns the direct children of C<$rating_key> (e.g. episodes of a season,
tracks of an album).

=head2 Maintenance

=head3 refresh_section($key)

Triggers a metadata refresh for a library section.

=head3 refresh_metadata($rating_key)

Triggers a metadata refresh for a single item.

=head3 empty_trash($key)

Empties the trash for a library section.

=head2 Playback State

=head3 mark_played($rating_key)

Marks an item as played.

=head3 mark_unplayed($rating_key)

Marks an item as unplayed.

=head3 update_progress($rating_key, $time_ms, $state)

Updates the playback position for C<$rating_key> to C<$time_ms> milliseconds.
C<$state> defaults to C<'stopped'>; valid values are C<'playing'>,
C<'paused'>, and C<'stopped'>.

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

This software is released under the same terms as Perl 5 itself.
See L<perlartistic> and L<perlgpl> for details.

=cut
