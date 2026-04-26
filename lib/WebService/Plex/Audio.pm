use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Audio {
    field $plex :param;

    # Plex media type codes for audio content
    use constant {
        TYPE_ARTIST => 8,
        TYPE_ALBUM  => 9,
        TYPE_TRACK  => 10,
    };

    # ----------------------------------------------------------- browse

    method artists ($section_key, %params) {
        $plex->get("/library/sections/$section_key/all", type => TYPE_ARTIST, %params);
    }

    method albums ($section_key, %params) {
        $plex->get("/library/sections/$section_key/all", type => TYPE_ALBUM, %params);
    }

    method albums_for ($artist_key, %params) {
        $plex->get("/library/metadata/$artist_key/children", %params);
    }

    method tracks ($album_key, %params) {
        $plex->get("/library/metadata/$album_key/children", %params);
    }

    method all_tracks ($artist_key, %params) {
        $plex->get("/library/metadata/$artist_key/allLeaves", %params);
    }

    # ----------------------------------------------------------- search

    method search ($query, %params) {
        # Pass mediatype => 'artist', 'album', or 'track' to influence results.
        # Verified: 'artist','album','track','audio' all accepted by live server.
        # Note: mediatype does not filter hubs -- all hub types are returned.
        $plex->get('/hubs/search', query => $query, %params);
    }

    # ----------------------------------------------------------- maintenance

    method analyze ($rating_key) {
        $plex->put("/library/metadata/$rating_key/analyze");
    }

    # ----------------------------------------------------------- sonic

    method sonically_similar ($rating_key, %params) {
        $plex->get("/library/metadata/$rating_key/nearest", %params);
    }

    method sonic_adventure ($from_key, $to_key, %params) {
        $plex->get('/library/sections/all/sonicAdventure',
            fromKey => $from_key,
            toKey   => $to_key,
            %params,
        );
    }

    method station ($artist_key) {
        $plex->get("/library/metadata/$artist_key/station");
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Audio - Audio library browsing: Artists, Albums, Tracks

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $audio = $plex->audio;

  # Browse by type
  my $artists = $audio->artists(3);
  my $albums  = $audio->albums(3);
  my $alb     = $audio->albums_for($artist_key);
  my $tracks  = $audio->tracks($album_key);
  my $all     = $audio->all_tracks($artist_key);

  # Search
  my $results = $audio->search('Radiohead', mediatype => 'artist');

  # Maintenance
  $audio->analyze(12345);

=head1 DESCRIPTION

C<WebService::Plex::Audio> provides audio-specific browsing for Artists,
Albums, and Tracks.  It wraps C</library/sections> and
C</library/metadata> endpoints using Plex media type codes.

Do not instantiate directly.  Access via C<< $plex->audio >>.

=head1 MEDIA TYPE CONSTANTS

  WebService::Plex::Audio::TYPE_ARTIST  # 8
  WebService::Plex::Audio::TYPE_ALBUM   # 9
  WebService::Plex::Audio::TYPE_TRACK   # 10

=head1 METHODS

=head2 artists($section_key, %params)

Returns all artists in a library section (C<type=8>).

=head2 albums($section_key, %params)

Returns all albums in a library section (C<type=9>).

=head2 albums_for($artist_key, %params)

Returns the albums for an artist via
C</library/metadata/$artist_key/children>.

=head2 tracks($album_key, %params)

Returns the tracks of an album via
C</library/metadata/$album_key/children>.

=head2 all_tracks($artist_key, %params)

Returns all tracks for an artist across all albums via
C</library/metadata/$artist_key/allLeaves>.

=head2 search($query, %params)

Searches for audio content via C</hubs/search>.  Pass
C<mediatype =E<gt> 'artist'>, C<'album'>, or C<'track'> to narrow results.

=head2 analyze($rating_key)

Triggers media analysis via C<PUT /library/metadata/$key/analyze>.

=head2 sonically_similar($rating_key, %params)

Returns sonically similar audio items
(C<GET /library/metadata/$key/nearest>).  Optional params:
C<limit> (default 50) and C<maxDistance> (0.0-1.0, default 0.25).

=head2 sonic_adventure($from_key, $to_key, %params)

Returns a list of tracks forming a sonic path from one track to another.

=head2 station($artist_key)

Returns the radio station for an artist
(C<GET /library/metadata/$key/station>).

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<WebService::Plex::Library>

=item L<WebService::Plex::Video>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
